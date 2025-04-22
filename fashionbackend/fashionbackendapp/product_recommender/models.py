from django.db import models
from django.contrib.auth.models import User
import uuid

#Just got token refreshing working, now need to work on getting actual products from stockx into db

class Product(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    brand = models.CharField(max_length=100, default="")
    title = models.CharField(max_length=100)
    colorway = models.CharField(max_length=255, null=True, blank=True)
    gender = models.CharField(max_length=50, null=True, blank=True)
    silhouette = models.CharField(max_length=100, null=True, blank=True)
    release_date = models.DateField(null=True, blank=True)
    retailprice = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    estimatedMarketValue = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    story = models.TextField(null=True, blank=True)

    def __str__(self):
        return self.title
    
class ProductImage(models.Model):
    product = models.ForeignKey(
        'Product',
        related_name="images",
        on_delete=models.CASCADE,
        default=None,
    )

    image_url = models.URLField()
    def __str__(self):
        return f"{self.product.title} - Image"

