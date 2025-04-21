import os
import requests
from django.core.management.base import BaseCommand
from product_recommender.models import Product, ProductImage

class Command(BaseCommand):
    help = 'Import products from StockX API'

    def handle(self, *args, **kwargs):
        # Define query parameters as needed
        query = {
            'query': 'Nike Shoes',
            'pageNumber': 1,
            'pageSize': 1,
        }
        # Define the StockX API endpoint
        api_url = 'https://api.stockx.com/v2/catalog/search?${query}'  # Replace with the correct endpoint

        STOCKX_API_KEY = os.getenv('STOCKX_API_KEY')

        # Set up headers, including authentication if required
        headers = {
            "x-api-key": STOCKX_API_KEY,
            "Content-Type": "application/json"
        }


        try:
            response = requests.get(api_url, headers=headers, params=query)
            response.raise_for_status()
        except requests.RequestException as e:
            self.stderr.write(f"API request failed: {e}")
            return

        data = response.json()

        print(data)

        """ # Process each product in the response
        for item in data('products', []):
            product_id = item('id')
            name = item('title')
            category = item('category')
            brand = item('brand')
            price = item('price', {})('amount')  # Adjust based on actual API response
            url = item('url')
            image_urls = item('media', {})('imageUrls', [])

            # Create or update the Product instance
            product, created = Product.objects.update_or_create(
                id=product_id,
                defaults={
                    'name': name,
                    'category': category,
                    'brand': brand,
                    'price': price,
                    'url': url,
                    'features': {},  # Populate as needed
                }
            )

            # Clear existing images
            product.images.all().delete()

            # Add new images
            for image_url in image_urls:
                ProductImage.objects.create(product=product, image_url=image_url)

            self.stdout.write(f"{'Created' if created else 'Updated'} product: {name}")
 """