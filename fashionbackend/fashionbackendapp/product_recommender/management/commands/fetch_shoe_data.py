import datetime
from time import sleep
import requests
from django.core.management.base import BaseCommand
from product_recommender.models import Product, ProductImage
from django.utils.dateparse import parse_date
import os


#CURRENT: Got this command working and pulling from API, need to fill out things like url and images more

API_KEY = os.getenv("ZYLA_API_KEY")
BASE_URL = "https://zylalabs.com/api/916/sneakers+database+api/731"

MAX_REQUESTS = 1000

HEADERS = {
    "Authorization": f"Bearer {API_KEY}"
}

class Command(BaseCommand):
    help = "Import sneakers from Zyla Sneakers Database API"

    def handle(self, *args, **options):
        
        request_count = 0

        queries = ["Jordan", "Nike", "Adidas", "New Balance", "Yeezy", "Converse", "Puma", "Asics", "Reebok", "Hoka"]
        limit = MAX_REQUESTS/len(queries)

        for query in queries:
            if request_count >= MAX_REQUESTS:
                break

            url = f"{BASE_URL}/search+sneaker?limit={limit}&query={query}" #!EDIT
            response = requests.get(url, headers=HEADERS)

            if response.status_code != 200:
                self.stderr.write(f"❌ Error: {response.status_code}")
                break

            data = response.json()
            print(data)
            sneakers = data.get("results", [])

            if not sneakers:
                break

            for item in sneakers:
                self.save_product(item)
            self.stdout.write(f"✅ Fetched {len(sneakers)} sneakers for query '{query}'")
            request_count += 1
            sleep(1)
                

    def save_product(self, data):
        title = data.get("name", "Unnamed Sneaker")
        images = data.get("image", {})
        links_dict = data.get("links", {})
        urls = list(links_dict.values())
        orginal_image = images.get("original")
        other_images = {
            "original": images.get("original"),
            "small": images.get("small"),
            "thumbnail": images.get("thumbnail"),
        }

        try:
            product, created = Product.objects.update_or_create(
                title=title,

                defaults={
                    "brand": data.get("brand", ""),
                    "colorway": data.get("colorway", ""),
                    "gender": data.get("gender"),
                    "silhouette": data.get("silhouette", data.get("model", "")),
                    "release_date": parse_date(data.get("releaseDate")),
                    "retailprice": data.get("retailPrice") or data.get("retail_price"),
                    "estimatedMarketValue": data.get("estimatedMarketValue") or data.get("estimated_market_value"),
                    "story": data.get("story"),
                    "urls": urls,
                    
                },
            )



            # Save other image types
            if orginal_image:
                ProductImage.objects.update_or_create(
                    product=product,
                    image_url=orginal_image,
                    defaults={"image_type": "original"}
                )

            action = "🆕 Created" if created else "🔁 Updated"
            self.stdout.write(f"{action}: {product.title}")

        except Exception as e:
            self.stderr.write(f"⚠️ Error saving product '{title}': {e}")

