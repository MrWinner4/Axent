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
from user_preferences.models import UserProfile

# In user_preferences/utils.py or at the top of views.py
from firebase_admin import auth as firebase_auth

def get_user_from_token(token):
    try:
        decoded_token = firebase_auth.verify_id_token(token)
        firebase_uid = decoded_token['uid']
        return UserProfile.objects.get(firebase_uid=firebase_uid)
    except Exception as e:
        print(f"Error getting user from token: {e}")
        return None

class ProductViewSet(viewsets.ViewSet):
    authentication_classes = []
    permission_classes = []
    
    def get_queryset(self):
        return Product.objects.all()


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

    @action(detail=False, methods=['get'])
    def recommend(self, request):
        token = request.headers.get('Authorization', '').replace('Token', '').strip()
        if not token:
            return Response({"error": "No token provided"}, status=status.HTTP_401_UNAUTHORIZED)

        user_profile = get_user_from_token(token)
        if not user_profile:
            return Response({"error": "Invalid or expired token"}, status=status.HTTP_401_UNAUTHORIZED)
        
        model, user_id_map, product_id_map, users, products, user_product_csr = train_als_model()
        recommendations = recommend_product_for_user(model, user_profile.id, user_id_map, product_id_map, products, user_product_csr)
        
        if not recommendations:
            return Response({"error": "No recommendations available"}, status=status.HTTP_404_NOT_FOUND)

        serializer = ProductSerializer(recommendations, many=True)
        return Response(serializer.data)