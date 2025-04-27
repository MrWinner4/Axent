from .models import Product, ProductImage
from rest_framework import serializers

class ProductImageSerializer(serializers.ModelSerializer):
    class Meta:
        model = ProductImage
        fields = ['image_url']

class ProductSerializer(serializers.ModelSerializer):
    images = ProductImageSerializer(many=True, read_only=True)

    class Meta:
        model = Product
        fields = [
            'id',
            'title',
            'brand',
            'colorway',
            'gender',
            'silhouette',
            'release_date',
            'retailprice',
            'estimatedMarketValue',
            'story',
            'images'
        ]
