from django.db import models
from django.contrib.auth.models import User
import uuid

#Just got token refreshing working, now need to work on getting actual products from stockx into db

class Product(models.Model):
    uuid = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    brand = models.CharField(max_length=100, default="")
    product_type = models.CharField(max_length=100)
    style_id = models.CharField(max_length=100, default="")
    url_key = models.SlugField(unique=True, default="")
    title = models.CharField(max_length=100)
    color = models.CharField(max_length=100, null=True, blank=True)
    colorway = models.CharField(max_length=255, null=True, blank=True)
    gender = models.CharField(max_length=50, null=True, blank=True)
    release_date = models.DateField(null=True, blank=True)
    retail_price = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    lowest_ask = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    highest_bid = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    currency = models.CharField(max_length=5, default='USD')

    season = models.CharField(max_length=100, null=True, blank=True)

    def __str__(self):
        return self.title
    
class ProductImage(models.Model):
    product = models.ForeignKey(Product, related_name="images", on_delete=models.CASCADE)
    image_url = models.URLField()

    def __str__(self):
        return f"{self.product.title} - Image"
    
from django.db import models

class StockXSecret(models.Model):
    access_token = models.TextField()
    refresh_token = models.TextField()
    id_token = models.TextField(blank=True, null=True)
    expires_in = models.IntegerField()
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"StockX Token (last updated: {self.updated_at})"




