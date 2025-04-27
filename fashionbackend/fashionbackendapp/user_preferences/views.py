# views.py
from django.shortcuts import render
from .models import Product, UserPreference, UserProfile
from rest_framework.response import Response
from rest_framework.decorators import api_view
from .serializer import ProductSerializer
from firebase_admin import auth as firebase_auth
from django_q.tasks import async_task



def verify_firebase_token(id_token):
    try:
        decoded_token = firebase_auth.verify_id_token(id_token)
        return decoded_token
    except Exception as e:
        print(f"Error verifying token: {e}")
        return None
    
@api_view(['POST'])
def handle_swipe(request):
    try:
        token = request.headers.get('Authorization', '').replace('Bearer ', '').strip()
        print(f"Token: {token}")
        decoded_token = verify_firebase_token(token)
        print(f"Decoded Token: {decoded_token}")

        if not decoded_token:
            return Response({'error': 'Invalid token'}, status=401)

        firebase_uid = decoded_token['uid']
        print(f"Firebase UID: {firebase_uid}")

        try:
            user = UserProfile.objects.get(firebase_uid=firebase_uid)
            print(f"User found: {user}")
        except UserProfile.DoesNotExist:
            return Response({'error': 'User not found'}, status=404)

        product_id = request.data.get('product_id')
        preference_value = int(request.data.get('preference'))  # check this key name!
        print(f"Product ID: {product_id}, Preference: {preference_value}")

        try:
            product = Product.objects.get(id=product_id)
        except Product.DoesNotExist:
            return Response({'error': 'Product not found'}, status=404)

        UserPreference.objects.update_or_create(
            user=user,
            product=product,
            defaults={'preference': preference_value}
        )

        if preference_value == 1:
            user.liked_products.add(product)

        user.save()

        async_task('yourapp.tasks.background_update_preferences', user.id)

        return Response({'message': 'Preference updated successfully'})

    except Exception as e:
        print(f"🔥 Error in handle_swipe: {str(e)}")
        return Response({'error': 'Server error occurred'}, status=500)






@api_view(['POST'])
def create_user(request):
    print('creating user')
    token = request.headers.get('Authorization', '').replace('Bearer ', '').strip()

    try:
        decoded_token = firebase_auth.verify_id_token(token)
        uid = decoded_token['uid']
        email = decoded_token.get('email')
        name = request.data.get('name', '')

        # Step 2: Create or update the UserProfile with Firebase UID + name
        profile, profile_created = UserProfile.objects.get_or_create(
            firebase_uid=uid,
            defaults={
                'username': name,
                'email': email,
            }
        )

        if not profile_created:
            # If profile already exists, you might want to update it
            profile.firebase_uid = uid
            profile.name = name
            profile.save()

        return Response({
            'message': 'User and profile created successfully' if profile_created else 'User already exists'
        })

    except firebase_auth.InvalidIdTokenError:
        return Response({'error': 'Invalid ID token'}, status=400)
    except Exception as e:
        print(f"Error creating user: {e}")
        return Response({'error': 'Server error'}, status=500)

@api_view(['GET'])
def liked_products(request):
    print("liked products")
    # Get the Firebase ID token from the request's Authorization header
    id_token = request.headers.get('Authorization', '').replace('Bearer ', '').strip()

    
    try:
    # Verify the token using Firebase Admin SDK
        decoded_token = firebase_auth.verify_id_token(id_token)
        uid = decoded_token['uid']
        print(f"Token verified, user ID: {uid}")
    except firebase_auth.InvalidIdTokenError as e:
        return Response({'error': f'Invalid token: {str(e)}'}, status=400)
    except firebase_auth.ExpiredIdTokenError as e:
        return Response({'error': f'Token expired: {str(e)}'}, status=400)
    except Exception as e:
        return Response({'error': f'Error verifying token: {str(e)}'}, status=400)
    
    if decoded_token is None:
        return Response({"error": "Invalid token or user not authenticated"}, status=401)

    # Firebase UID is decoded from the ID token
    firebase_uid = decoded_token['uid']
    print('hi?')

    try:
        # Retrieve the User based on Firebase UID
        user = UserProfile.objects.get(firebase_uid=firebase_uid)
    except UserProfile.DoesNotExist:
        print("nouser")
        return Response({"error": "User not found."}, status=404)
    except Exception as e:
        print(f"Error retrieving user: {e}")
        return Response({"error": "Server error."}, status=500)

    products = user.liked_products.all()
    serializer = ProductSerializer(products, many=True)
    return Response(serializer.data)


@api_view(['GET'])
def product_detail(request, product_id):
    try:
        product = Product.objects.get(id=product_id)
    except Product.DoesNotExist:
        return Response({"error": "Product not found."}, status=404)

    serializer = ProductSerializer(product)
    return Response(serializer.data)
