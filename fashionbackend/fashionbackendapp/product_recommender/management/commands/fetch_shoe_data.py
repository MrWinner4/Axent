import datetime
import requests
from django.core.management.base import BaseCommand
from product_recommender.models import Product, ProductImage
from django.utils.dateparse import parse_date
import os

API_KEY = os.getenv("ZYLA_API_KEY")
BASE_URL = "https://zylalabs.com/api/916/sneakers+database+api/731"

MAX_REQUESTS = 1

HEADERS = {
    "Authorization": f"Bearer {API_KEY}"
}

class Command(BaseCommand):
    help = "Import sneakers from Zyla Sneakers Database API"

    def handle(self, *args, **options):
        
        request_count = 0
        page = 1

        while request_count < MAX_REQUESTS:
            url = f"{BASE_URL}/search+sneaker?limit=10&page={page}&query=nike" #!EDIT
            response = requests.get(url, headers=HEADERS)

            if response.status_code != 200:
                self.stderr.write(f"❌ Error: {response.status_code}")
                break

            data = response.json()
            sneakers = data.get("results", [])

            if not sneakers:
                break

            for item in sneakers:
                self.save_product(item)

            self.stdout.write(f"✅ Page {page} processed.")
            page += 1

    def save_product(self, data):
        title = data.get("name", "Unnamed Sneaker")
        images = data.get("image", {})
        image_360 = images.get("360", [])
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
                },
            )

            # Save 360 images
            for url in image_360:
                ProductImage.objects.get_or_create(product=product, image_url=url)

            # Save other image types
            for label, url in other_images.items():
                if url:
                    ProductImage.objects.get_or_create(product=product, image_url=url)

            action = "🆕 Created" if created else "🔁 Updated"
            self.stdout.write(f"{action}: {product.title} ({len(image_360)} 360° images)")

        except Exception as e:
            self.stderr.write(f"⚠️ Error saving product '{title}': {e}")

