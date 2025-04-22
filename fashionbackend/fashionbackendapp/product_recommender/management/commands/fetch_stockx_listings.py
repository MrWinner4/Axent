import os
import time
import requests
import datetime
from django.core.management.base import BaseCommand
import django

# Initialize Django
django.setup()

from product_recommender.models import Product, ProductImage, StockXSecret



MAX_DAILY_REQUESTS = 25000
MAX_BATCH_SIZE = 500
BATCH_INTERVAL = 300 #Seconds
REQUEST_INTERVAL = 1 #Seconds

class Command(BaseCommand):
    help = "Fetch StockX listings and save them to the database"
    global request_count, batch_count, last_batch_time

    def handle(self, *args, **options):
        request_count = 0
        batch_count = 0
        last_batch_time = datetime.datetime.now()
        
        try:
            token = StockXSecret.objects.latest("updated_at").access_token
        except StockXSecret.DoesNotExist:
            self.stderr.write("❌ No StockX access token found in database.")
            return

        keywords = ["Addidas shoes"]
        page_size = 1
        headers = {
            "Authorization": f"Bearer {token}",
            "x-api-key": os.getenv("STOCKX_API_KEY"),
        }

        for keyword in keywords:
            page = 1
            has_next_page = True

            while has_next_page:
                time.sleep(REQUEST_INTERVAL)
                
                if batch_count >= MAX_BATCH_SIZE:
                    elapsed = (datetime.datetime.now() - last_batch_time).total_seconds()
                    if elapsed < BATCH_INTERVAL:
                        wait_time = BATCH_INTERVAL - elapsed
                        self.stdout.write(f"⏳ Waiting for {wait_time} seconds to avoid hitting the batch limit...")
                        time.sleep(wait_time)
                    
                    last_batch_time = datetime.datetime.now()
                    batch_count = 0

                if request_count >= MAX_DAILY_REQUESTS:
                    self.stdout.write("❌ Daily request limit reached. Stopping the process.")
                    break

                params = {
                    "query": keyword,
                    "pageNumber": page,
                    "pageSize": page_size,
                }

                url = "https://api.stockx.com/v2/catalog/search"
                response = requests.get(url, headers=headers, params=params)

                if response.status_code == 429:
                    self.stdout.write("❌ Rate limit exceeded. Waiting for 5 seconds")
                    time.sleep(5)

                if response.status_code != 200:
                    self.stderr.write(f"❌ Failed to fetch data for '{keyword}' (page {page}): {response.status_code}")
                    break

                data = response.json()
                print(data)
                products = data.get("products", [])
                self.stdout.write(f"✅ Fetched {len(products)} products for '{keyword}' (page {page})")

                for product_data in products:
                    print(product_data)
                    save_product(product_data, headers)
                    # Check if there's a next page
                has_next_page = data.get("hasNextPage", False)
                batch_count += 1
                page += 1

        self.stdout.write(self.style.SUCCESS("🎉 Finished populating products."))


from django.db import IntegrityError

def save_product(product_data, headers):
    try:
        # Check if product already exists based on url_key
        if Product.objects.filter(url_key=product_data['urlKey']).exists():
            print(f"Product with URL key {product_data['urlKey']} already exists.")
            return 
        
        print(f"Fetching market data for productId: {product_data['productId']}")
        market_data = fetch_market_data(product_data['productId'], headers)
        lowest_ask = market_data.get("lowestAskAmount") if market_data else None
        highest_bid = market_data.get("highestBidAmount") if market_data else None
        currency = market_data.get("currencyCode", "USD") if market_data else "USD"

        product = Product(
            uuid=product_data['productId'],  # Use productId from StockX API
            brand=product_data['brand'],  # Use brand from the product data
            product_type=product_data['productType'],  # Use productType for category
            style_id=product_data['styleId'],  # Use styleId for the product's style
            url_key=product_data['urlKey'],  # Use urlKey for the unique URL
            title=product_data['title'],  # Use title for the product name
            colorway=product_data['productAttributes'].get('colorway'),  # Use colorway
            gender=product_data['productAttributes'].get('gender'),  # Use gender
            release_date=product_data['productAttributes'].get('releaseDate'),  # Use releaseDate
            retail_price=product_data['productAttributes'].get('retailPrice', 0.00),  # Use retailPrice
            season=product_data['productAttributes'].get('season'),  # Use season
            lowest_ask=lowest_ask,
            highest_bid=highest_bid,
            currency=currency
        )
        product.save()
        print(f"Product saved: {product.title}")
    except IntegrityError as e:
        print(f"IntegrityError: {e}")
    except Exception as e:
        print(f"Error saving product: {e}")


def fetch_market_data(product_id, headers):
    url = f"https://api.stockx.com/v2/catalog/products/{product_id}/market-data"
    params = {"currencyCode": "USD"}

    try:
        response = requests.get(url, headers=headers, params=params)
        if response.status_code == 200:
            data = response.json()
            # Sometimes it's a list, sometimes a dict
            if isinstance(data, list) and data:
                return data[0]
            return data
        else:
             print(f"⚠️ Failed market data [{response.status_code}] for {product_id}: {response.text}")
    except Exception as e:
        print(f"❌ Error fetching market data: {e}")
    return None
