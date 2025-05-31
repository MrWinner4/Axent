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
    def recommend(self, request):
        """
        Get a recommended product for the authenticated user
        """


        token = request.headers.get('Authorization', '').replace('Token ', '').strip()
        if not token:
            return Response({"error": "No token provided"}, status=401)
        
        try:
            user_profile = get_user_from_token(token)
            if not user_profile:
                return Response({"error": "Invalid or expired token"}, status=401)
        except Exception as e:
            return Response({"error": "Error verifying token"}, status=401)

        #WHICH PRODUCTS TO PULL - USE FILTERS
        products= Product.objects.all()

        if not products.exists():
            return Response(
                {"error": "No products available."},
                status=status.HTTP_404_NOT_FOUND
            )
        #RECOMMENDATION LOGIC HERE
        recommended_product = recommendation_algorithm(user_profile)
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
    

from user_preferences.models import UserPreference
from .models import Product
import numpy as np
def recommendation_algorithm(current_user_profile):
    # Load fresh data
    prefs = UserPreference.objects.all()
    users = list(UserProfile.objects.all())
    products = list(Product.objects.all())

    user_ids = {user.id: idx for idx, user in enumerate(users)}
    product_ids = {product.id: idx for idx, product in enumerate(products)}

    # Build preference matrix
    data = [[0] * len(products) for _ in range(len(users))]
    for pref in prefs:
        u_idx = user_ids.get(pref.user_id)
        p_idx = product_ids.get(pref.product_id)
        if u_idx is not None and p_idx is not None:
            data[u_idx][p_idx] = pref.preference

    data_np = np.array(data)

    # Current user preferences vector
    current_user_idx = user_ids.get(current_user_profile.id)
    if current_user_idx is None:
        return None  # User not found in preferences

    current_user_responses = data_np[current_user_idx]

    # Run clustering
    num_clusters = 10
    if len(users) < num_clusters or len(products) < num_clusters:
        num_clusters = min(len(users), len(products), 2)

    model = SpectralBiclustering(n_clusters=num_clusters, random_state=0)
    model.fit(data_np)

    liked_products = np.where(current_user_responses == 1)[0]

    # If no liked products, recommend random unreviewed product
    if len(liked_products) == 0:
        unreviewed = np.where(current_user_responses == 0)[0]
        if len(unreviewed) == 0:
            return None
        random_idx = random.choice(unreviewed)
        product_id = list(product_ids.keys())[list(product_ids.values()).index(random_idx)]
        return Product.objects.get(id=product_id)

    # Count liked clusters
    product_cluster_counts = {}
    for p_idx in liked_products:
        cluster = model.column_labels_[p_idx]
        product_cluster_counts[cluster] = product_cluster_counts.get(cluster, 0) + 1

    best_cluster = max(product_cluster_counts, key=product_cluster_counts.get)

    # Find products in best cluster
    cluster_product_indices = np.where(model.column_labels_ == best_cluster)[0]

    # Count likes in cluster by similar users (in same row cluster)
    cluster_likes = {idx: 0 for idx in cluster_product_indices}
    current_user_row_cluster = model.row_labels_[current_user_idx]

    for u_idx, row_cluster in enumerate(model.row_labels_):
        if row_cluster == current_user_row_cluster:
            for p_idx in cluster_product_indices:
                if data_np[u_idx, p_idx] == 1:
                    cluster_likes[p_idx] += 1

    # Find unreviewed products in cluster
    unreviewed_in_cluster = [idx for idx in cluster_product_indices if current_user_responses[idx] == 0]

    if unreviewed_in_cluster:
        # Recommend the most liked unreviewed product in cluster
        best_product_idx = max(unreviewed_in_cluster, key=lambda idx: cluster_likes.get(idx, 0))
        product_id = list(product_ids.keys())[list(product_ids.values()).index(best_product_idx)]
        return Product.objects.get(id=product_id)
    else:
        return None
