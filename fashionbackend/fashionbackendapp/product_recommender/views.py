from .models import Product, User
from rest_framework.decorators import action, authentication_classes
from rest_framework.response import Response
from rest_framework import viewsets, status
from .serializer import ProductSerializer, ProductImageSerializer
from firebase_admin import auth as firebase_auth
from user_preferences.models import UserProfile
from user_preferences.recombee import client
from recombee_api_client.api_requests import RecommendItemsToUser

# In user_preferences/utils.py or at the top of views.py
from firebase_admin import auth as firebase_auth

def get_user_from_token(token):
    try:
        decoded_token = firebase_auth.verify_id_token(token)
        print("decoded_token")
        print(decoded_token)
        firebase_uid = decoded_token['uid']
        print("firebase_uid")
        print(firebase_uid)
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
        print("recommend")
        """Get product recommendations for a user"""
        auth_header = request.headers.get('Authorization', '')
        if not auth_header.startswith('Bearer '):
            return Response({"error": "Invalid authorization header"}, status=401)

        token = auth_header.split(' ').pop()
        user_profile = get_user_from_token(token)
        print("user profile?")
        print(user_profile)
        if not user_profile:
            return Response({"error": "Invalid or expired token"}, status=401)

        try:
            filters = request.query_params.get('filters', {})
        except KeyError:
            return Response({"error": "Filters not provided"}, status=400)

        try:
            recommendations = client.send(RecommendItemsToUser(user_profile.firebase_uid, 10, filter=filters))
            product_ids = [rec['id'] for rec in recommendations.recomms ]
            products = Product.objects.filter(id__in=product_ids)
            serializer = ProductSerializer(products, many=True)
            return Response(serializer.data)
        except Exception as e:
            print(f"Error getting recommendations: {e}")
            return Response([], status=status.HTTP_500_INTERNAL_SERVER_ERROR)