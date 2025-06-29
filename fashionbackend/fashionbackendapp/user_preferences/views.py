from django.shortcuts import get_object_or_404
from rest_framework import viewsets, status
from rest_framework.response import Response
from rest_framework.decorators import api_view, action
from firebase_admin import auth
from .models import Product, UserPreference, UserProfile
from product_recommender.serializer import ProductSerializer
from django_q.tasks import async_task
from .recombee import client
from recombee_api_client.api_requests import AddUser, AddRating, AddDetailView
import os


def get_user_profile_from_token(token):
    """Helper function to get user profile from Firebase token"""
    try:
        decoded_token = auth.verify_id_token(token)
        firebase_uid = decoded_token['uid']
        return UserProfile.objects.get(firebase_uid=firebase_uid)
    except Exception as e:
        print(f"Error getting user from token: {e}")
        return None


class UserPreferenceViewSet(viewsets.ViewSet):
    authentication_classes = []
    permission_classes = []

    def get_user_from_request(self, request):
        """Helper method to get user from request token"""
        auth_header = request.headers.get('Authorization', '')
        if not auth_header.startswith('Bearer '):
            return None
        
        token = auth_header.split(' ').pop()
        return get_user_profile_from_token(token)


    @action(detail=False, methods=['post'])
    def handle_swipe(self, request):
        user_profile = self.get_user_from_request(request)
        if not user_profile:
            return Response({"error": "Invalid or expired token"}, status=401)

        try:
            product_id = request.data.get('product_id')
            preference_value = int(request.data.get('preference', 0))
            
            product = get_object_or_404(Product, id=product_id)
            
            UserPreference.objects.update_or_create(
                user=user_profile,
                product=product,
                defaults={'preference': preference_value}
            )

            if preference_value == 1:
                user_profile.liked_products.add(product)
            
            user_profile.save()

            try:
                client.send(AddRating(user_profile.firebase_uid, product_id, preference_value))
            except Exception as recombee_error:
                print(f"Recombee error: {recombee_error}")
            

            return Response({'message': 'Preference updated successfully'})

        except Exception as e:
            print(f"Error in handle_swipe: {str(e)}")
            return Response({'error': 'Server error occurred'}, status=500)

    @action(detail=False, methods=['get'])
    def liked_products(self, request):
        try:
            auth_header = request.headers.get('Authorization', '')
            if not auth_header.startswith('Bearer '):
                return Response({"error": "Invalid authorization header"}, status=401)

            token = auth_header.split(' ').pop()
            user_profile = get_user_profile_from_token(token)
            if not user_profile:
                return Response({"error": "Invalid or expired token"}, status=401)
            
            # Get liked products with error handling
            try:
                products = user_profile.liked_products.all()
                print(f"Found {products.count()} liked products for user {user_profile.firebase_uid}")
                
                # Serialize with error handling
                serializer = ProductSerializer(products, many=True)
                return Response(serializer.data)
                
            except Exception as e:
                print(f"Error serializing liked products: {e}")
                # Return empty list if serialization fails
                return Response([])
                
        except Exception as e:
            print(f"Error in liked_products endpoint: {e}")
            return Response({"error": "Server error occurred"}, status=500)

    @action(detail=False, methods=['get'])
    def bought_products(self, request):
        auth_header = request.headers.get('Authorization', '')
        if not auth_header.startswith('Bearer '):
            return Response({"error": "Invalid authorization header"}, status=401)

        token = auth_header.split(' ').pop()
        user_profile = get_user_profile_from_token(token)
        if not user_profile:
            return Response({"error": "Invalid or expired token"}, status=401)
        
        products = user_profile.bought_products.all()
        serializer = ProductSerializer(products, many=True)
        return Response(serializer.data)


    @action(detail=False, methods=['post'])
    def update_bought_product(self, request):
        auth_header = request.headers.get('Authorization', '')
        if not auth_header.startswith('Bearer '):
            return Response({"error": "Invalid authorization header"}, status=401)

        token = auth_header.split(' ').pop()
        user_profile = get_user_profile_from_token(token)
        
        if not user_profile:
            return Response({"error": "Invalid or expired token"}, status=401)

        try:
            product_ids = request.data.get('product_ids', [])
            user_profile.bought_products.add(*product_ids)
            return Response({"message": "Bought products updated successfully"})
        except Exception as e:
            print(f"Error updating bought products: {e}")
            return Response({"error": "Failed to update bought products"}, status=500)

    @action(detail=False, methods=['post'])
    def create_user(self, request):
        print('Creating user')
        auth_header = request.headers.get('Authorization', '')
        if not auth_header.startswith('Bearer '):
            return Response({"error": "Invalid authorization header"}, status=401)
        
        token = auth_header.split(' ').pop()
        
        try:
            decoded_token = auth.verify_id_token(token)
            uid = decoded_token['uid']
            email = decoded_token.get('email')
            name = request.data.get('name', '')

            # Create or update the UserProfile with Firebase UID + name
            profile, profile_created = UserProfile.objects.get_or_create(
                firebase_uid=uid,
                defaults={
                    'username': name,
                    'email': email,
                }
            )

            if not profile_created:
                # If profile already exists, update it
                profile.firebase_uid = uid
                profile.name = name
                profile.save()
            # Create Recombee user
            print("lebronza")
            
            print("RECOMBEE_DATABASE_ID:", os.getenv('RECOMBEE_DATABASE_ID'))
            print("RECOMBEE_PRIVATE_TOKEN:", os.getenv('RECOMBEE_PRIVATE_TOKEN'))
            try:
                client.send(AddUser(uid))
            except Exception as e:
                print(f"Error creating user: {e}")

            return Response({
                'message': 'User and profile created successfully' if profile_created else 'User already exists'
            })

        except auth.InvalidIdTokenError:
            return Response({'error': 'Invalid ID token'}, status=400)
        except Exception as e:
            print(f"Error creating user: {e}")
            return Response({'error': 'Server error'}, status=500)

    @action(detail=False, methods=['get'])
    def get_detail_view(self, request):
        auth_header = request.headers.get('Authorization', '')
        if not auth_header.startswith('Bearer '):
            return Response({"error": "Invalid authorization header"}, status=401)

        token = auth_header.split(' ').pop()
        user_profile = get_user_profile_from_token(token)
        if not user_profile:
            return Response({"error": "Invalid or expired token"}, status=401)
        
        product_id = request.data.get('product_id')
        if not product_id:
            return Response({"error": "Product ID is required"}, status=400)

        try:
            client.send(AddDetailView(user_profile.firebase_uid, product_id))
            return Response({"message": "Detail view recorded successfully"})
        except Exception as e:
            print(f"Error sending detail view: {e}")
            return Response({"error": "Failed to record detail view"}, status=500)





@api_view(['GET'])
def product_detail(request, product_id):
    try:
        product = Product.objects.get(id=product_id)
        serializer = ProductSerializer(product)
        client.send(AddDetailView())
        return Response(serializer.data)
    except Product.DoesNotExist:
        return Response({"error": "Product not found"}, status=404)
