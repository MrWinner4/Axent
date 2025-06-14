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
                        existing.normalized_colorway = parse_normalized_colorway(traits.get("Colorway"))
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
                            normalized_colorway=parse_normalized_colorway(traits.get("Colorway")),
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
                            "normalized_colorway": product.normalized_colorway,
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
                    "secondary_category", "upcoming", "updated_at", "link", "colorway", "normalized_colorway",
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

import re

color_keywords = {
    "red": [
        "red", "crimson", "carmine", "burgundy", "burgundy crush", "cardinal", "cardinal red", "challenge red", "chile red", "chili", "comet red", "crimson bliss", "crimson tint", "deep red", "dragon red", "fire red", "firewood orange", "gym red", "infrared", "infrared 23", "maroon", "picante red", "ritual red", "rose tone", "scarlet", "team red", "true red", "varsity red", "university red", "high risk red", "habanero red", "lava", "ember", "ember glow", "safety orange", "rustic", "rust pink", "rusty pink", "pimento", "pinkfire", "pinkfire 2", "pink-rose", "pink-orange-brown", "pink spell", "pink velvet", "pink blast", "pink foam", "pink punch", "pink", "rose", "rose smoke", "rose whisper", "rose tone", "rose", "rose whisper", "rose tone", "rose", "rose whisper", "rose tone"
    ],
    "orange": [
        "orange", "burnt sienna", "burnt sunrise", "canyon pink", "canyon purple", "canyon", "cinnabar", "cinnamon", "citron pulse", "citron tint", "citrus", "clay orange", "clay red", "clay taupe", "clay", "cosmic clay", "ember glow", "firewood orange", "hot lava", "lava", "magma orange", "max orange", "orange blaze", "orange frost", "orange glow", "orange quartz", "orange trance", "rustic", "rust pink", "rusty pink", "safety orange", "solar flare", "solar orange", "sun glow", "sunset pulse", "tart", "terra blush", "terra orange", "tour yellow", "turbo green", "turf orange", "varsity maize", "yellow ochre", "yellow strike"
    ],
    "yellow": [
        "yellow", "canary", "champagne", "champagne metallic", "citrine", "cream", "cream white", "creamy vanilla", "gold", "gold metallic", "golden harvest", "halo gold", "lemon", "lemon chiffon", "lemon peel", "lemon spark", "lemonade", "light lemon twist", "lucid lemon", "maize", "mustard", "pale vanilla", "pale yellow", "pro gold", "radiant blue", "strawberry cream", "sulfur", "tai chi yellow", "taxi", "vanilla ice", "vibrant yellow", "vintage coral", "warm vanilla", "wheat", "yellow ochre", "yellow strike"
    ],
    "green": [
        "green", "army", "bucktan", "cargo khaki", "chlorophyll", "classic green", "college green", "emerald rise", "fairway", "field purple", "fir", "forest", "gecko", "geode teal", "glen green", "gorge green", "grass green", "green apple", "green bean", "green gecko", "green glow", "green strike", "jade", "jade horizon", "jade smoke", "kale", "kinetic green", "lawn", "legion green", "life lime", "lime green", "lime punch", "lucky green", "lush green", "malachite", "mean green", "medium olive", "mica green", "military blue", "mint", "mint candy", "mint foam", "mint melt", "moss", "mx cinder", "mx granite", "mx oat", "mx rock", "natural ivory", "neutral olive", "new emerald", "new green", "olive", "olive aura", "olive canvas", "olive juice", "olive khaki", "olive", "oxford tan", "pale oak", "palomino", "pantone", "parachute beige", "paradise aqua", "particle grey", "peacoat", "pear", "pearl", "pearl grey", "pearl pink", "pearl white", "pine green", "pineapple juice", "preloved green", "pure", "pure platinum", "pure platinum-black-white", "pure platinum-glacier blue-metallic gold", "pure purple", "pure silver", "sage", "seafoam", "semi court green", "semi impact orange", "sesame", "shadow navy", "shadow red", "shimmer", "sienna", "silver", "silver birch", "silver green", "silver metallic", "sky blue", "sky grey", "slate", "slate bone", "slate carbon", "slate grey", "slate marine", "slate onyx", "slate white", "smoke grey", "soft yellow", "solar green", "space lavender", "spark", "speed blue", "sport red", "sport royal", "spruce aura", "strawberry cream", "sulfur", "summit white", "sun glow", "sundial", "sunset pulse", "supplier color", "sweet pink", "synth", "tai chi yellow", "talc", "tan", "tart", "taupe", "taupe grey", "taupe haze", "taxi", "teal tint", "team dark green", "team gold", "team light blue", "team orange", "team red", "team royal", "team royal blue", "team sky blue", "team victory red", "tech grey", "tephra", "terra blush", "terra orange", "thunder blue", "timberwolf", "total crimson abyss", "total orange", "tour yellow", "tourmaline", "treeline", "triple black", "trooper", "true blue", "true camo", "true red", "true white", "truffle grey", "turbo green", "turf orange", "turquoise blue", "turtledove", "twilight pulse", "university blue", "university gold", "utility black", "vachetta tan", "valerian blue", "vanilla ice", "vapor green", "varsity blue", "varsity maize", "varsity purple", "varsity red", "varsity royal", "vast grey", "vegas gold", "velvet brown", "vibrant yellow", "vintage coral", "vintage white", "violet", "violet ore", "vivid grape", "vivid green", "vivid purple", "vivid sulfur", "volt", "warm vanilla", "washed coral", "wheat", "white", "wild berry", "wild brown", "wolf grey", "wonder beige", "wonder clay", "wonder leopard", "wonder quartz", "wonder taupe", "wonder white", "woodland", "worn blue", "yecheil", "yecoraite", "yeezreel", "yellow", "yellow ochre", "yellow strike", "zyon"
    ],
    "blue": [
        "blue", "arctic", "azure", "calypso", "celestine blue", "chlorine blue", "classic cobalt", "clear blue", "clear sky", "cloud blue", "coastal blue", "cobalt bliss", "cobalt tint", "college navy", "collegiate navy", "concord", "concord grape", "cool grey", "court purple", "crystal white", "dazzling blue", "deep royal blue", "denim turquoise", "diffused blue", "doll", "faded azure", "fountain blue", "french blue", "frozen blue", "furious blue", "game royal", "gamma blue", "glacier", "glacier blue", "glacier grey", "glacier ice", "harbor grey", "hydrangeas", "hyper blue", "hyper cobalt", "hyper royal", "ice", "ice blue", "ice wine", "igloo", "incense", "jade", "jade horizon", "jade smoke", "kale", "kinetic green", "lagoon", "lagoon pulse", "lakeside", "laser blue", "legend blue", "legend ink", "legend light brown", "legend pink", "leche blue", "light aqua", "light arctic pink", "light armory blue", "light blue", "light blue-pink-yellow", "light blue-argon-white", "light bone", "light british tan", "light brown", "light carbon", "light chocolate", "light chocolate-crimson bliss-black-sail", "light cream", "light crimson", "light current blue", "light curry", "light fusion red-white-laser orange-black", "light graphite", "light graphite-orange peel-sport red", "light green", "light grey", "light iron ore", "light khaki", "light lemon twist", "light menta", "light olive", "light orange", "light orewood brown", "light pink", "light racer blue", "light silver", "light smoke grey", "light smoke grey-white", "light smoke grey-white-anthracite", "light steel grey", "light wild mango", "light zen grey", "light purple-pink-black", "light-light-light", "lightening", "lightning-chlorophyll", "lilac bloom", "lime green", "lime punch", "linen", "linen khaki", "lmnte", "lobster", "lotus pink", "lucid blue", "lucid cyan", "lucid lemon", "lucid lime", "lucid lime-aurora ink-core black", "lucid pink", "lucid red", "lucky green", "lucky green-white", "lunar rock", "lush green", "magic beige", "magic ember", "magic mauve", "magma orange", "magnet-college navy", "mahogany", "malachite", "maroon", "maroon-almost yellow-preloved brown", "matte silver", "max orange", "mean green", "medium ash", "medium curry", "medium grey", "medium grey-violet ore-white", "medium grey-white", "medium olive", "medium olive-black-sail-university red", "medium soft pink", "melon tint", "mercury grey", "mesa", "mesa-mesa-gum", "metallic", "metallic blue", "metallic burgundy", "metallic copper", "metallic copper-black", "metallic dark grey", "metallic gold", "metallic gold grain", "metallic gold-black", "metallic gold-black-sail", "metallic gold-obsidian", "metallic gold-phantom", "metallic grey-dove grey-cloud white", "metallic hematite", "metallic medium ash", "metallic pewter", "metallic platinum", "metallic red bronze", "metallic silver", "metallic silver-black-anthracite", "metallic silver-white", "metallic silver-black-pure platinum-white-pure platinum", "metallic silver-dark smoke grey-green strike-dusty sage-chrome", "metallic summit white", "metallic summit white-pure platinum-wolf grey-white", "mica green", "midnight", "midnight navy", "midnight navy-burnt sunrise-white", "midnight navy-white", "midnight spruce", "midnight-midnight", "military blue", "military blue-fire red-black-cement grey", "milk", "mineral beige", "mineral green", "mineral teal", "mink brown", "mint", "mint candy", "mint foam", "mint melt", "mirage grey", "misty rose", "mocha", "mocha brown", "monarch", "mono clay", "mono ice", "monsoon blue", "monument", "moonbeam", "multi", "multi-color", "multi-color-multi-color", "multi-color-multi-color-crimson", "multi-color-total orange", "multi-color-white-multi-color", "multi-color-multi-color", "multicolor", "muslin", "muslin-white-black", "muslin-black-bright cactus", "mutli-color", "mx cinder", "mx granite", "mx oat", "mx rock", "mystic hibiscus", "mystic red", "natural", "natural ivory", "navy", "neon yellow", "neptune blue", "net", "neutral grey", "neutral grey-sail-smoke grey", "neutral olive", "new emerald", "new emerald-black", "new green", "new navy", "niagara", "night indigo", "night indigo-cloud white-gum 3", "night maroon", "night metallic", "night navy", "night stadium", "nightfall", "nightwatch green", "noir", "noise aqua", "oatmeal", "obsidian", "ochre", "off", "off noir", "off noir-black", "off white", "off white-core black-pure ruby", "off white-off white-light brown", "off-noir", "oil", "oil green", "old royal-black", "olive", "olive aura", "olive canvas", "olive juice", "olympic blue", "onyx", "opti yellow", "orange", "orange blaze", "orange frost", "orange glow", "orange quartz", "orange trance", "orange-white-black", "orchid", "orewood brown", "outerspace", "oxford tan-almond milk-safari", "oxidized green", "oyster grey", "oyster white", "pink-pink", "puma black-mauve mist", "puma green", "pacific moss", "pale ivory", "pale ivory-dark grey-university red", "pale ivory-ground grey-team royal", "pale ivory-black-light bone-pale vanilla-aquarius blue", "pale magma", "pale oak", "pale vanilla", "pale vanilla-starfish", "pale yellow", "palomino", "pantone", "pantone-almost yellow-preloved ink", "paper white", "parachute beige", "paradise aqua", "particle grey", "peacoat", "pear", "pearl", "pearl grey", "pearl pink", "pearl white", "persian violet", "phantom", "phantom-light silver-white-black", "phantom-khaki-light bone-summit white", "phantom-metallic gold-white", "photo blue", "photo blue-lemon twist-tour yellow", "photon dust", "photon dust-gridiron-sail-chrome", "picante red", "piedmont grey", "pimento", "pine green", "pine green-pine green", "pineapple juice", "pink", "pink blast", "pink foam", "pink foam-playful pink-white", "pink spell", "pink velvet", "pink-orange-brown", "pinkfire", "pinkfire 2", "pinksicle", "pirate black", "platinum tint", "platinum violet", "plum brown", "plum dust", "polar", "polarized pink", "pollen", "preloved blue", "preloved brown", "preloved green", "preloved ink", "preloved purple", "preloved red", "preloved yellow", "pro gold", "psychic blue", "psychic blue-photon dust-pale ivory-thunder blue", "pulse magenta", "puma green", "puma red", "puma silver", "puma white", "pure", "pure platinum", "pure platinum-black-white", "pure platinum-glacier blue-metallic gold", "pure purple", "pure silver", "purple", "purple agate", "purple burst", "purple pulse", "purple pulse-white", "purple-orange-university gold", "putty", "putty grey", "putty grey-maroon-gold metallic", "putty mauve", "quarry blue", "quartz patina", "racer blue", "racer blue-black", "racer pink", "radiant blue", "rain cloud", "rainbloud", "raincloud", "rainy lake", "real tree camo", "red", "red crush", "red stardust", "red-purple", "reddish brown", "reflect silver", "reflection", "reflective", "reflective silver", "regal pink", "res red", "resin", "ridgerock", "ritual red", "rose smoke", "rose tone", "royal", "royal blue", "royal pulse", "royal tint", "running white", "rush orange", "rust pink", "rustic", "safety orange", "sage", "sail", "sail-black", "sail-metallic silver-gum medium brown", "sail-photon dust", "sail-sheen-straw-medium brown", "sail-star blue-midnight navy", "sail-black-burgundy crush", "sail-black-varsity red-muslin", "sail-black-light orewood brown-coconut milk", "sail-navy", "sail-obsidian-university blue", "sail-pink foam-sail-college grey", "sail-plum eclipse-diffused taupe", "sail-tour yellow-photo blue-university red", "sail-velvet brown-atmosphere", "salmon pink", "salt", "sand", "sand beige", "sand strata", "sand taupe-sand taupe-sand taupe", "sanddrift", "sanddrift-rugged orange", "sandy pink", "sandy pink-off white-clear brown", "sapphire", "sasquatch", "saturn gold", "scarlet", "scream green", "screaming green", "sea salt", "seafoam", "seafoam-yellow strike", "semi court green-core black-screaming green", "semi impact orange", "sepia", "sepia stone", "sesame", "sesame-sesame-sesame", "shadow grey", "shadow navy", "shadow red", "shimmer", "sienna", "silver", "silver birch", "silver green", "silver metallic", "silver-purple pulse", "sky blue", "sky grey", "slate", "slate bone", "slate carbon", "slate grey", "slate marine", "slate onyx", "slate white", "smoke grey", "soft yellow", "solar flare", "solar green", "solar orange", "solar power", "solar red", "solid grey", "space lavender", "spark", "speed blue", "sport red", "sport royal", "spruce aura", "stadium green", "stadium grey", "stadium grey-metallic silver-tour yellow", "starfish-white-black", "static", "stealth", "stealth-stealth", "steel grey", "steeple grey", "stone blue", "stone flax", "stone grey", "stone marine", "stone onyx", "stone sage-stone sage-stone sage", "stone salt", "stone taupe", "stone teal", "strawberry cream", "sulfur", "summit white", "summit white-industrial blue", "summit white-khaki-baroque brown-phantom-black", "sun glow", "sundial", "sunset pulse", "supplier color", "supplier color-core white-gum", "supplier colour", "sweet pink", "synth", "tai chi yellow", "talc", "tan", "tart", "taupe", "taupe grey", "taupe haze-oil grey-off white-infrared 23", "taxi", "teal tint", "team dark green", "team gold", "team light blue", "team orange", "team red", "team royal", "team royal blue", "team sky blue", "team victory red", "tech grey", "tephra", "terra blush-desert sand", "terra orange", "thunder blue", "timberwolf", "total crimson abyss", "total orange", "tour yellow", "tour yellow-white-dark blue grey", "tourmaline", "treeline", "triple black", "trooper", "true blue", "true blue-varsity red", "true camo", "true red", "true red-black", "true red-dark concord-white", "true white", "truffle grey", "turbo green", "turf orange", "turquoise blue-dark iris", "turtledove", "twilight pulse", "university blue", "university blue-cement grey", "university blue-chrome-black", "university blue-midnight navy", "university blue-varsity red-black", "university blue-white", "university blue-black-varsity red", "university blue-black-white", "university gold", "university gold-light bordeaux-white", "university red", "university red-black", "university red-black-white", "university red-cement grey-sail", "university red-obsidian-white", "university red-white-university red", "utility black", "vachetta tan", "valerian blue", "vanilla ice", "vapor green", "varsity blue", "varsity blue-black", "varsity maize", "varsity maize-court purple-ghost green-solar orange", "varsity purple", "varsity red", "varsity red-black", "varsity red-off noir-muslin", "varsity red-white", "varsity red-silver", "varsity royal", "varsity royal-cement grey", "varsity royal-white", "varsity royal-white-university red", "vast grey", "vegas gold", "vegas gold-white", "velvet brown", "veneer-autumn green-deep purple", "vibrant yellow", "vintage coral", "vintage white", "violet", "violet ore", "violet-light aqua", "vivid grape", "vivid green", "vivid purple", "vivid sulfur", "volt", "warm vanilla", "washed coral", "wheat", "wheat-black", "white", "white copper moon", "white onyx", "white-amarillo", "white-anthracite", "white-black", "white-dark blue grey", "white-multi-color", "white-off noir", "white-pure platinum", "white-pure purple", "white-sail-black", "white-university red", "white-university red-chilling blue", "white-white", "white-white-wolf grey", "white-yellow-black", "white-black", "white-black-burgundy crush", "white-black-dark mocha", "white-black-total orange", "white-black-university red", "white-black-white", "white-black-game royal", "white-black-gold", "white-black-gym red", "white-black-kinetic green", "white-black-metallic silver", "white-black-varsity red", "white-blue-gum", "white-cool grey-black", "white-court purple", "white-glacier blue", "white-grey fog-white", "white-gym red-black-true red", "white-gym red-black", "white-gym red-midnight navy-neutral grey-sail-muslin", "white-laser fuchsia", "white-legend blue-black", "white-light curry-cardinal red-cement grey", "white-lucky green-sail-light steel grey", "white-lucky green-varsity red-cement grey-sail", "white-medium olive-white", "white-metallic silver", "white-metallic silver-black-dusty cactus", "white-metallic silver-flat silver-black", "white-metallic silver-summit white-pure platinum", "white-midnight navy-metallic gold-university red", "white-midnight navy-metallic silver", "white-neutral grey-particle grey", "white-neutral grey-anthracite-midnight navy", "white-obsidian-dark powder blue", "white-phantom-metallic gold", "white-rose whisper", "white-sail-industrial blue", "white-sail-legend pink", "white-sky j mauve-white", "white-team green-white", "white-true blue-metallic copper-cement grey", "white-university blue", "white-university blue-white", "white-university blue-game royal-university red", "white-university blue-midnight navy", "white-university red", "white-university red-blue jay-black-metallic silver-team red", "white-valor blue-tech grey", "white-vintage green-white", "white-wheat", "white-white", "white-white-black-cool grey", "white-white-black", "white-white-gum light brown", "white-white-varsity maize", "white-white-white", "wild berry", "wild brown", "wolf grey", "wolf grey-reflective silver", "wolf grey-white-wolf grey", "wonder beige", "wonder clay", "wonder leopard", "wonder quartz", "wonder taupe", "wonder white", "wonder white-cream white-clear granite", "woodland", "worn blue", "yecheil", "yecoraite", "yeezreel", "yellow", "yellow ochre", "yellow ochre-black", "yellow strike", "zyon"
    ],
    "purple": [
        "purple", "amethyst", "club purple", "concord", "concord grape", "deep orchid", "eggplant", "field purple", "grape ice", "lilac", "lilac bloom", "plum", "plum brown", "plum dust", "psychic purple", "regal pink", "violet", "violet ore", "vivid grape", "vivid purple"
    ],
    "black": [
        "black", "anthracite", "carbon", "carbon beluga", "charcoal", "core black", "dark charcoal", "dark obsidian", "dark onyx", "dark pony", "dark smoke", "ebony", "iron", "iron grey", "iron metallic", "ironstone", "obsidian", "off noir", "onyx", "phantom", "pitch", "shadow", "shadow grey", "shadow navy", "smoke", "stealth", "utility black"
    ],
    "white": [
        "white", "bone", "chalk", "chalk purple", "chalk white", "cloud", "cloud grey", "cloud white", "cream", "cream white", "egret", "ivory", "ivory clay", "light cream", "off white", "pale ivory", "paper white", "pure", "pure platinum", "pure silver", "sail", "snow", "summit", "true white", "vintage white", "wonder white"
    ],
    "brown": [
        "brown", "bucktan", "burnt sienna", "burnt sunrise", "cacao wow", "calcite", "calcium", "cardboard", "caramel", "cashmere", "castlerock", "cave stone", "chamois", "chocolate", "clay", "clay brown", "clay canyon", "clay grey", "clay taupe", "coconut milk", "coconut milk-particle grey-white-gum yellow", "coconut milk-stadium green-beyond pink-green frost-playful pink", "coffee", "dark brown", "dark driftwood", "dark mocha", "dark mocha-black-velvet brown", "deep brown", "deep burgundy", "desert", "desert berry", "desert dust", "desert khaki", "desert moss", "desert sage", "desert sand", "desert white", "dust", "dusted clay", "dusty olive", "earth", "earth strata", "fawn", "fossil", "fossil stone", "fossilized", "golden harvest", "golden wren", "gum", "gum 3", "gum 5", "gum honey", "gum light brown", "gum medium brown", "gum yellow", "hemp", "incense", "ironstone", "legend brown", "legend light brown", "light army", "light bone", "light british tan", "light brown", "light chocolate", "light chocolate-crimson bliss-black-sail", "light curry", "light khaki", "light olive", "light orewood brown", "linen", "linen khaki", "mahogany", "maroon", "mesa", "mesa-mesa-gum", "milk", "mineral beige", "mocha", "mocha brown", "moss", "mx cinder", "mx granite", "mx oat", "mx rock", "natural", "natural ivory", "neutral olive", "oak", "oatmeal", "oil", "oil green", "olive", "olive aura", "olive canvas", "olive juice", "olive khaki", "palomino", "parachute beige", "peanut", "putty", "putty grey", "putty mauve", "quartz patina", "ridgerock", "rustic", "rust pink", "rusty pink", "sable", "sail", "sand", "sand beige", "sand strata", "sand taupe", "sanddrift", "sanddrift-rugged orange", "sandy pink", "sesame", "sesame-sesame-sesame", "shadow", "shadow grey", "shadow navy", "shadow red", "shimmer", "sienna", "smoke", "soft yellow", "strawberry cream", "sulfur", "summit white", "tan", "taupe", "taupe grey", "taupe haze", "timberwolf", "truffle grey", "vachetta tan", "velvet brown", "vintage coral", "vintage white", "warm vanilla", "wheat", "wild brown", "woodland"
    ],
    "grey": [
        "grey", "gray", "ash", "carbon", "cement", "cement grey", "charcoal", "cloud grey", "cool grey", "dark arctic grey", "dark ash", "dark grey", "dark loden", "dark pewter", "dark salt", "dark slate", "dark smoke grey", "deep grey", "diffused blue", "flint", "flint grey", "flint grey-black-varsity purple", "fog", "fossilized", "glacier grey", "glacier grey gravel", "graphite", "graphite grey", "grey five", "grey fog", "grey four", "grey mist", "grey one", "grey three", "grey two", "lead", "light grey", "light iron ore", "light smoke grey", "light steel grey", "marina", "medium ash", "medium grey", "medium grey-violet ore-white", "medium grey-white", "mercury grey", "mirage grey", "monument", "mx granite", "neutral grey", "neutral grey-sail-smoke grey", "night metallic", "night stadium", "nightfall", "ore", "pewter", "platinum", "platinum tint", "platinum violet", "putty grey", "quarry blue", "rain cloud", "rainbloud", "raincloud", "ridgerock", "shadow", "shadow grey", "shadow navy", "shadow red", "shimmer", "silver", "silver birch", "silver green", "silver metallic", "slate", "slate bone", "slate carbon", "slate grey", "slate marine", "slate onyx", "slate white", "smoke", "smoke grey", "soft yellow", "stadium grey", "stadium grey-metallic silver-tour yellow", "static", "stealth", "stealth-stealth", "steel grey", "steeple grey", "stone blue", "stone flax", "stone grey", "stone marine", "stone onyx", "stone sage", "stone salt", "stone taupe", "stone teal", "summit white", "timberwolf", "truffle grey", "vast grey", "wolf grey", "wolf grey-reflective silver", "wolf grey-white-wolf grey"
    ],
    "pink": [
        "pink", "barely rose", "blush", "bubblegum", "coral", "digital pink", "echo pink", "elemental pink", "fairy tale", "fierce pink", "fire pink", "flamingo", "hyper pink", "icey pink", "lotus", "lotus pink", "misty rose", "orchid", "pale magma", "pink blast", "pink foam", "pink punch", "pink spell", "pink velvet", "pinksicle", "plum dust", "polarized pink", "regal pink", "rose", "rose smoke", "rose tone", "rose whisper", "salmon pink", "sandy pink", "soft pink", "strawberry cream", "sweet pink", "vivid pink"
    ],
    "teal_aqua": [
        "aqua", "arctic", "celestine", "clear emerald", "clear jade", "denim turquoise", "fountain blue", "geode teal", "jade", "lagoon", "lagoon pulse", "mint", "mint candy", "mint foam", "mint melt", "paradise aqua", "spruce aura", "teal", "teal tint", "turquoise", "turquoise blue"
    ],
    "metallic": [
        "metallic", "champagne metallic", "chrome", "copper", "gold", "gold metallic", "hematite", "metallic blue", "metallic burgundy", "metallic copper", "metallic dark grey", "metallic gold", "metallic gold grain", "metallic gold-black", "metallic gold-black-sail", "metallic gold-obsidian", "metallic gold-phantom", "metallic grey", "metallic hematite", "metallic medium ash", "metallic pewter", "metallic platinum", "metallic red bronze", "metallic silver", "metallic silver-black-anthracite", "metallic silver-white", "metallic silver-black-pure platinum-white-pure platinum", "metallic silver-dark smoke grey-green strike-dusty sage-chrome", "metallic summit white", "metallic summit white-pure platinum-wolf grey-white"
    ],
    "multicolor": [
        "multi", "multi-color", "multi-color-multi-color", "multi-color-multi-color-crimson", "multi-color-total orange", "multi-color-white-multi-color", "multi-color-multi-color", "multicolor", "mutli-color", "rainbow", "tie-dye", "gradient", "mashup", "mix", "print", "color"
    ],
    "glow_neon": [
        "volt", "glow", "hyper", "neon", "glow blue", "glow green", "glow pink", "neon yellow", "solar flare", "solar green", "solar orange", "solar power", "solar red"
    ]
}

def parse_colorway(raw_value):
    if not raw_value:
        return []
    try:
        cleaned = re.sub(r'[\/\-]', ',', raw_value)
        parts = [part.strip().title() for part in cleaned.split(',') if part.strip()]
        return list(dict.fromkeys(parts))

    except Exception as e:
        print(f"Error parsing colorway: {e}")
        return []

def parse_normalized_colorway(raw_value):
    if not raw_value:
        return []
    try:
        cleaned = re.sub(r'[\/\-]', ',', raw_value)
        parts = [part.strip().lower() for part in cleaned.split(',') if part.strip()]
        found_colors = set()

        for part in parts:
            part = part.lower()
            for core_color, keywords in color_keywords.items():
                # Check if any keyword is in this part
                if any(keyword in part.lower() for keyword in keywords):
                    found_colors.add(core_color)
                    break  # stop checking other keywords for this part
        print(found_colors)
        return list(found_colors)
    except Exception as e:
        print(f"Error parsing normalized colorway: {e}")
        return []