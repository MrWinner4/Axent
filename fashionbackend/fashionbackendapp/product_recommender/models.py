from django.db import models
from django.contrib.auth.models import User

class Product(models.Model):
    """Stores product info"""
    name = models.CharField(max_length=255)
    category = models.CharField(max_length=100)
    features = models.JSONField(default=dict)  # Storing feature vectors for ML (optional)
    price = models.DecimalField(max_digits=10, decimal_places=2, default = 0.00)
    url = models.URLField(max_length=500, default="")
    id = models.IntegerField(primary_key=True)
    brand = models.CharField(max_length=100, blank=True, null=True)

    def __str__(self):
        return self.name
    
class ProductImage(models.Model):
    product = models.ForeignKey(Product, related_name="images", on_delete=models.CASCADE)
    image_url = models.URLField()

    def __str__(self):
        return f"{self.product.name} - Image"
    



