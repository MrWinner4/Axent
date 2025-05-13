from django.http import JsonResponse
from .models import Product, User
from rest_framework.decorators import action, authentication_classes
from rest_framework.response import Response
from rest_framework import viewsets, status
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

    def get_queryset(self):
        return Product.objects.all()


    def test_view(request):
        print("test works")
        return JsonResponse({"message": "Test successful"})
    @action(detail=False, methods=['get'])
    def recommend(self, request):
        """
        Get a recommended product for the authenticated user
        """

        print("Auth headers:", request.META.get('HTTP_AUTHORIZATION'))
        print("User:", request.user)


        user = request.user
        #WHICH PRODUCTS TO PULL - USE FILTERS
        products= Product.objects.all()

        if not products.exists():
            return Response(
                {"error": "No products available."},
                status=status.HTTP_404_NOT_FOUND
            )
        #RECOMMENDATION LOGIC HERE
        recommended_product = random.choice(products)
        serializer = ProductSerializer(recommended_product)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def search(self, request):
        """
        Search for products by name
        """
        query = request.query_params.get('q', '')
        if not query:
            return Response([], status=status.HTTP_200_OK)
        
        results = Product.objects.filter(name__icontains=query)[:10]
        serializer = ProductSerializer(results, many=True)
        return Response(serializer.data)