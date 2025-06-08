import datetime
import time
from time import sleep
from django.core.management.base import BaseCommand
import os
import requests
from decimal import Decimal
from product_recommender.models import Product, ProductImage, ProductImage360, ProductVariant
from recombee_api_client.api_requests import AddItemProperty, Batch, AddItem, SetItemValues
from ...recombee import client



#CURRENT: Got this command working and pulling from API, need to fill out things like url and images more

API_KEY = os.getenv("KICKSAPIKEY")

url = "https://api.kicks.dev/v3/stockx/products"

headers = {"Authorization": API_KEY}

LIMIT_PER_REQUEST = 100

PRODUCT_TOTAL = 1000

REQUEST_DELAY = 1.1

class Command(BaseCommand):
    help = "Import sneakers from kicks.dev into database"

    def handle(self, *args, **options):
        self.stdout.write("Starting product data import...")

        after_rank = 0
        total_imported = 0

        while total_imported < PRODUCT_TOTAL:
            params = {
                "limit": LIMIT_PER_REQUEST,
                "after_rank": after_rank,
                "sort": "rank",
                "display[variants]":"true",
                "display[traits]":"true",
                "display[subtotal]":"true",
                "product_type":"sneakers"
            }

            response = requests.get(url, headers=headers, params=params)
            if response.status_code != 200:
                self.stderr.write(f"Error fetching data: {response.status_code} - {response.text}")
                break

            data = response.json().get("data", [])

            if not data:
                self.stdout.write("No more products to import.")
                break

           
            

            incoming_ids = [item.get("id") for item in data if item.get("id")]
            existing_products = Product.objects.filter(id__in=incoming_ids)
            existing_ids = set(str(p.id) for p in existing_products)
            existing_map = {str(p.id): p for p in existing_products}
            existing_variants_map = {
                (v.product_id, v.size, v.sizeMen): v
                for v in ProductVariant.objects.filter(product_id__in=[p.id for p in existing_products])
            }

            products_to_update = []
            products_to_create = []
            product_images = []
            product_images_360 = []
            variant_creates = []
            variant_updates = []

            recombee_list = []
                
            for product_data in data:
                product_id = product_data.get("id")
                if not product_id:
                    continue

                try:
                    # -- product core data
                    title = product_data.get("title", "Unnamed Sneaker")
                    traits = {trait["trait"]: trait["value"] for trait in product_data.get("traits", [])}
                    existing = existing_map.get(product_id)
                    if existing:
                        product = existing
                        existing.title = title
                        existing.brand = product_data.get("brand", "")
                        existing.model = product_data.get("model", "")
                        existing.description = product_data.get("description", "")
                        existing.sku = product_data.get("sku")
                        existing.slug = product_data.get("slug")
                        existing.category = product_data.get("category")
                        existing.secondary_category = product_data.get("secondary_category")
                        existing.upcoming = product_data.get("upcoming", False)
                        existing.updated_at = safe_parse_datetime(product_data.get("updated_at"))
                        existing.link = product_data.get("link")
                        existing.colorway = parse_colorway(traits.get("Colorway"))
                        existing.trait = traits.get("Featured", "false").lower() == "true"
                        existing.release_date = safe_parse_datetime(traits.get("Release Date"))
                        existing.retailprice = safe_decimal(traits.get("Retail Price"))
                        products_to_update.append(existing)
                    else:
                        product = Product(
                            id=product_id,
                            title=title,
                            brand=product_data.get("brand", ""),
                            model=product_data.get("model", ""),
                            description=product_data.get("description", ""),
                            sku=product_data.get("sku"),
                            slug=product_data.get("slug"),
                            category=product_data.get("category"),
                            secondary_category=product_data.get("secondary_category"),
                            upcoming=product_data.get("upcoming", False),
                            updated_at=safe_parse_datetime(product_data.get("updated_at")),
                            link=product_data.get("link"),
                            colorway=parse_colorway(traits.get("Colorway")),
                            trait=traits.get("Featured", "false").lower() == "true",
                            release_date=safe_parse_datetime(traits.get("Release Date")),
                            retailprice=safe_decimal(traits.get("Retail Price")),
                        )
                        products_to_create.append(product)
                    recombee_list.append(SetItemValues(
                        item_id=str(product.id),
                        values={
                            "title": product.title,
                            "brand": product.brand,
                            "model":  product.model,
                            "description": product.description,
                            "sku": product.sku,
                            "slug": product.slug,
                            "category": product.category,
                            "secondary_category": product.secondary_category,
                            "upcoming": product.upcoming,
                            "updated_at": product.updated_at.isoformat() if product.updated_at else None,
                            "link": product.link,
                            "colorway": product.colorway,
                            "trait": product.trait,
                            "release_date": product.release_date.isoformat() if product.release_date else None,
                            "retailprice": float(product.retailprice) if product.retailprice else None,
                        },
                        cascade_create=True
                    ))


                    # -- image (original)
                    image_url = product_data.get("image")
                    if image_url:
                        product_images.append(ProductImage(product=product, image_url=image_url, image_type="original"))

                    # -- 360 gallery
                    gallery_360 = product_data.get("gallery_360", [])
                    for index, img_url in enumerate(gallery_360, start=1):
                        product_images_360.append(ProductImage360(product=product, order=index, image_url=img_url))

                    # -- variants
                    for variant in product_data.get("variants", []):
                        size_type = variant.get("size_type", "").lower()
                        is_men = "m" in size_type
                        is_youth = "y" in size_type
                        is_kids = "k" in size_type or "c" in size_type
                        raw_size = variant.get("size", "").lower().strip()

                        if "w" in raw_size:
                            cleaned_size = raw_size.replace("w", "")
                        elif "y" in raw_size:
                            cleaned_size = raw_size.replace("y", "")
                            is_youth = True
                        elif "k" in raw_size or "c" in raw_size:
                            cleaned_size = raw_size.replace("k", "").replace("c", "")
                            is_kids = True
                        else:
                            cleaned_size = raw_size

                        variant_size = safe_decimal(cleaned_size)
                        if variant_size is None:
                            continue

                        key = (product_id, variant_size, is_men)
                        if key in existing_variants_map:
                            variant_obj = existing_variants_map[key]
                            variant_obj.lowest_ask = safe_decimal(variant.get("lowest_ask"))
                            variant_obj.total_asks = variant.get("total_asks") or 0
                            variant_obj.previous_lowest_ask = safe_decimal(variant.get("previous_lowest_ask"))
                            variant_obj.subtotal = variant.get("subtotal", {})
                            variant_obj.updated_at = safe_parse_datetime(variant.get("updated_at"))
                            variant_updates.append(variant_obj)
                        else:
                            variant_creates.append(ProductVariant(
                                product=product,
                                size=variant_size,
                                sizeMen=is_men,
                                sizeYouth=is_youth,
                                sizeKids=is_kids,
                                lowest_ask=safe_decimal(variant.get("lowest_ask")),
                                total_asks=variant.get("total_asks") or 0,
                                previous_lowest_ask=safe_decimal(variant.get("previous_lowest_ask")),
                                subtotal=variant.get("subtotal", {}),
                                updated_at=safe_parse_datetime(variant.get("updated_at")),
                            ))


                    total_imported += 1
                    if total_imported >= PRODUCT_TOTAL:  
                        break

                except Exception as e:
                    self.stderr.write(f"⚠️ Error processing product {product_id}: {e}")
                    continue

            # Save all at once
            Product.objects.bulk_create(products_to_create)
            
            ProductImage.objects.bulk_create(product_images)
            ProductImage360.objects.bulk_create(product_images_360)
            ProductVariant.objects.bulk_create(variant_creates)
            if products_to_update:
                Product.objects.bulk_update(products_to_update, [
                    "title", "brand", "model", "description", "slug", "category",
                    "secondary_category", "upcoming", "updated_at", "link", "colorway",
                    "trait", "release_date", "retailprice"
                ])
            if variant_updates:
                ProductVariant.objects.bulk_update(
                    variant_updates,
                    ["lowest_ask", "total_asks", "previous_lowest_ask", "subtotal", "updated_at"]
                )

            if recombee_list:
                try:
                    client.send(Batch(recombee_list))
                    self.stdout.write(self.style.SUCCESS(f"Recombee batch sent for {len(recombee_list)} items."))
                except Exception as e:
                    self.stderr.write(f"⚠️ Error sending Recombee batch: {e}")
                recombee_list.clear()
        
            after_rank = data[-1].get("rank") + 1
            self.stdout.write(f"Imported up to rank {after_rank - 1} ({total_imported} total)")
            time.sleep(REQUEST_DELAY)

            product_images.clear()
            product_images_360.clear()
            variant_creates.clear()
            variant_updates.clear()
            products_to_create.clear()
            products_to_update.clear()


        self.stdout.write(self.style.SUCCESS(f"Finished importing {total_imported} products."))



         
                
    


    
from decimal import Decimal, InvalidOperation

def safe_decimal(value):
    try:
        return Decimal(str(value))
    except (InvalidOperation, TypeError, ValueError):
        return None

from django.utils.dateparse import parse_datetime

def safe_parse_datetime(value):
    if isinstance(value, str):
        return parse_datetime(value)
    return None

import json

def parse_colorway(raw_value):
    if not raw_value:
        return []
    try:
        colors = raw_value.split('/')
        return [c.strip() for c in colors if c.strip()]
    except Exception as e:
        print(f"Error parsing colorway: {e}")
        return []
