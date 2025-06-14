#Converts HTTP Request data to Python data types and vice versa, basically just making the requests something django can understand
from .models import Product, ProductImage, ProductVariant, ProductImage360
from rest_framework import serializers

class ProductImageSerializer(serializers.ModelSerializer):
    class Meta:
        model = ProductImage
        fields = ['image_url', 'image_type']

class ProductImage360Serializer(serializers.ModelSerializer):
    class Meta:
        model = ProductImage360
        fields = ['image_url', 'order']
class ProductVariantSerializer(serializers.ModelSerializer):
    class Meta:
        model = ProductVariant
        fields = ['size', 'sizeMen', 'sizeYouth', 'sizeKids', 'lowest_ask', 'total_asks', 'previous_lowest_ask', 'subtotal', 'updated_at']

class ProductSerializer(serializers.ModelSerializer):
    images = ProductImageSerializer(many=True, read_only=True)  # Nested serializer
    images360 = ProductImage360Serializer(many=True, read_only=True)
    variants = ProductVariantSerializer(many=True, read_only=True)

    class Meta:
        model = Product
        fields = ['id','title','brand','model','description','sku','slug','category','secondary_category','upcoming','updated_at','link','colorway','trait','release_date','retailprice', 'images', 'images360', 'variants']