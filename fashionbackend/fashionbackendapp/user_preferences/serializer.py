from fashionbackend.fashionbackendapp.product_recommender.models import Product, ProductImage, ProductImage360, ProductVariant
from rest_framework import serializers


        
class ProductImage360Serializer(serializers.ModelSerializer):
    class Meta:
        model = ProductImage360
        fields = ['image_url', 'order']

class ProductSerializer(serializers.ModelSerializer):
    images = ProductImageSerializer(many=True, read_only=True)

    class Meta:
        model = Product
        fields = [
            'id',
            'title',
            'brand',
            'model',
            'description',
            'sku',
            'slug',
            'category',
            'secondary_category',
            'upcoming',
            'updated_at',
            'link',
            'colorway',
            'trait',
            'release_date',
            'retailprice',
        ]
