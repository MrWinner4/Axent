from .models import Product, User
from rest_framework.decorators import action, authentication_classes
from rest_framework.response import Response
from rest_framework.authentication import TokenAuthentication, SessionAuthentication
from rest_framework.permissions import IsAuthenticated
import numpy as np
import random
from sklearn.cluster import SpectralBiclustering
from .serializer import ProductSerializer, ProductImageSerializer
from firebase_admin import auth as firebase_auth


class ProductViewSet(viewsets.ViewSet):
    authentication_classes = [TokenAuthentication, SessionAuthentication]
    permission_classes = [IsAuthenticated]

    @action(detail=False, methods=['get'])
    def recommend(self, request):
        """
        Get a recommended product for the authenticated user
        """

        user = request.user
        #WHICH PRODUCTS TO PULL - USE FILTERS
        products= Product.objects.all

        if not products.exists():
            return Response(
                {"error": "No products available."},
                status=status.HTTP_404_NOT_Found
            )
        #RECOMMENDATION LOGIC HERE
        recommended_product = random.choice(products)
        serializer = ProductSerializer(recommended_product)
        return Response(serializaer.data)

    @action(detail=False, methods=['get'])
    def search(self, request):
        """
        Search for products by name
        """
        query = request.query_params.get('q', '')
        if not query:
            return Response([], status=status.HTTP_200_OK)
        
        results = Product.objects.filter(name_icontains=query)[:10]
        serializaer = ProductSerializer(results, many=True)
        return Response(serializer.data)
    

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