from rest_framework import serializers
from .models import Wardrobe, WardrobeItem
from product_recommender.models import Product
from product_recommender.serializer import ProductSerializer

class WardrobeItemSerializer(serializers.ModelSerializer):
    product = ProductSerializer(read_only=True)
    product_id = serializers.UUIDField(write_only=True)

    class Meta:
        model = WardrobeItem
        fields = ('id', 'wardrobe', 'product', 'product_id', 'created_at', 'updated_at')
        read_only_fields = ('id', 'wardrobe', 'added_at')

    def create(self, validated_data):
        product_id = validated_data.pop('product_id')
        try:
            product = Product.objects.get(id=product_id)
        except Product.DoesNotExist:
            raise serializers.ValidationError(f"Product with id {product_id} does not exist")
        

class WardrobeSerializer(serializers.ModelSerializer):
    items = WardrobeItemSerializer(many=True, read_only=True)

    class Meta:
        model = Wardrobe
        fields = ('id', 'user', 'name', 'created_at', 'updated_at', 'items', 'product_ids')
        read_only_fields = ('id', 'user', 'created_at', 'updated_at')