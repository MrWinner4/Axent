from django.shortcuts import render
from .models import Product, User
from rest_framework.response import Response
from rest_framework.decorators import api_view
import numpy as np
import random
from sklearn.cluster import SpectralBiclustering
from .serializer import ProductSerializer, ProductImageSerializer

@api_view (['POST'])
def postData(request):
     serializer = ProductSerializer(data = request.data)
     if(serializer.is_valid):
          serializer.save()
          return Response(serializer.data)

# Function to run recommendation
@api_view(['GET'])
def recommend_product(request):
    print("Recommending product...")
    #Recommending random product for now
    products = Product.objects.all()
    if not products.exists():
        return Response({"error": "No products available."}, status=404)
    # Pick a random product
    recommended_product = random.choice(products)
    serializer = ProductSerializer(recommended_product)
    print(serializer.data)
    return Response(serializer.data)
    
def update_response(self, product_index, response):
        self.responses[product_index] = response

# View to handle product recommendation
def recommend_view(request):
    user_id = request.GET.get('user_id', None)
    if not user_id:
        return render(request, 'error.html', {'message': 'User ID is required.'})

    recommended_product = recommend_product(user_id)
    return render(request, 'recommendation.html', {'recommended_product': recommended_product})
