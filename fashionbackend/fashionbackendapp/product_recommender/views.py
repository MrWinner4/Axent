from django.shortcuts import render
from .models import Product, User
from rest_framework.response import Response
from rest_framework.decorators import api_view
import numpy as np
import random
from sklearn.cluster import SpectralBiclustering
from .serializer import ProductSerializer, ProductImageSerializer
from firebase_admin import auth as firebase_auth

# Function to run recommendation
@api_view(['GET'])
def recommend_product(request):
    user_id = request.query_params.get('user_id')
    print(f"Recommending product for user {user_id}...")

    if not user_id:
        return Response({"error": "Missing user_id"}, status=400)
    #Recommending random product for now
    products = Product.objects.all()
    if not products.exists():
        return Response({"error": "No products available."}, status=404)
    # Pick a random product
    recommended_product = random.choice(products)
    serializer = ProductSerializer(recommended_product)
    print(serializer.data)
    return Response(serializer.data)


# fashionbackendapp/product_recommender/views.py
@api_view(['GET'])
def search_products(request):
    query = request.GET.get('q', '')
    if not query:
        return Response([])

    results = Product.objects.filter(name__icontains=query)[:10]
    data = [{'name': p.name, 'brand': p.brand} for p in results]
    return Response(data)