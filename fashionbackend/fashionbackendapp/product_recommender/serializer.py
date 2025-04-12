#Converts HTTP Request data to Python data types and vice versa, basically just making the requests something django can understand
from .models import Product, ProductImage
from rest_framework import serializers
class ProductImageSerializer(serializers.ModelSerializer):
    
    class Meta:
        model = ProductImage
        fields = ['image_url']

class ProductSerializer(serializers.ModelSerializer):
    images = ProductImageSerializer(many=True, read_only=True)  # Nested serializer

    class Meta:
        model = Product
        fields = ['name', 'category', 'features', 'images', 'price', 'id']