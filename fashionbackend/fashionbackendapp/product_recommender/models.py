from django.db import models
from django.contrib.auth.models import User
import uuid
from django.contrib.postgres.fields import ArrayField
from jsonschema import validate, ValidationError


#Just got token refreshing working, now need to work on getting actual products from stockx into db

def validate_urls(urls):
    schema = {
        'type': 'object',
        'properties': {
            'stockx': {'type': 'string', 'format': 'uri'},
            'goat': {'type': 'string', 'format': 'uri'},
            'flightclub': {'type': 'string', 'format': 'uri'},
            'stadiumgoods': {'type': 'string', 'format': 'uri'},
        },
        'additionalProperties': False
    }
    try:
        validate(instance=urls, schema=schema)
    except ValidationError as e:
        raise ValueError(f"Invalid URL format: {e.message}")


class Product(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    title = models.CharField(max_length=100)
    brand = models.CharField(max_length=100, default="")
    model = models.CharField(max_length=100, null=True, blank=True)
    description = models.TextField(null=True, blank=True)
    sku = models.CharField(max_length=100, unique=True, null=True, blank=True)
    slug = models.SlugField(unique=True, null=True, blank=True)
    category = models.CharField(max_length=100, null=True, blank=True)
    secondary_category = models.CharField(max_length=100, null=True, blank=True)
    #Would be gallery - I think this is like a gallery of photos and i'll just use product Image for that
    upcoming = models.BooleanField(default=False, help_text="Indicates if the product is upcoming")
    #Again with gallery 360 - i might check for this later tho, maybe not a day 1 feature
    updated_at = models.DateTimeField(auto_now=False)
    link = models.URLField()
    colorway = models.JSONField(default=list)
    trait = models.BooleanField(default=False)
    release_date = models.DateField(null=True, blank=True)
    retailprice = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)

    def __str__(self):
        return self.title
    
class ProductImage(models.Model): #Future versions, would like to utilize all images recieved
    product = models.ForeignKey(Product, related_name="images", on_delete=models.CASCADE)
    image_url = models.URLField() #Make arrayField if want > 1 image
    image_type = models.CharField(max_length=20, default="original")  # optional


    def __str__(self):
        return f"{self.product.title} - Image"

class ProductVariant(models.Model): #This is for the variants recieved from the API
    product = models.ForeignKey(Product, related_name="variants", on_delete=models.CASCADE)
    size = models.DecimalField(max_digits=3, decimal_places=1)
    sizeMen = models.BooleanField(default=True) #True = men, False = women
    lowest_ask = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    total_asks = models.IntegerField(default=0)
    previous_lowest_ask: models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    subtotal = models.JSONField(
        default=dict,
        help_text="Dictionary of shipping options and their prices"
    )
    updated_at = models.DateTimeField(auto_now=False)
    