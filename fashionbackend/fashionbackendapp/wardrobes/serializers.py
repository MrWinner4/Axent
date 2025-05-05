from rest_framework import serializers
from .models import Wardrobe, WardrobeItem
from product_recommender.models import Product
from product_recommender.serializer import ProductSerializer

class WardrobeItemSerializer(serializers.ModelSerializer):
    product = ProductSerializer(read_only=True)
    product_id = serializers.UUIDField(write_only=True)

    class Meta:
        model = WardrobeItem
        fields = ('id', 'wardrobe', 'product', 'product_id', 'notes', 'added_at', 'image_url')
        read_only_fields = ('id', 'wardrobe', 'added_at')

class WardrobeSerializer(serializers.ModelSerializer):
    items = WardrobeItemSerializer(many=True, read_only=True)

    class Meta:
        model = Wardrobe
        fields = ('id', 'user', 'name', 'description', 'created_at', 'updated_at', 'items')
        read_only_fields = ('id', 'user', 'created_at', 'updated_at')