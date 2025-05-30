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

prefs = UserPreference.objects.all() # Gets all user preferences

user_ids = {user.id: idx for idx, user in enumerate(UserProfile.objects.all())} # Maps over all ids from the profiles and assigns them an index for the matrix
product_ids = {product.id: idx for idx, product in enumerate(Product.objects.all())} # Maps over all products and assigns them an index for the matrix

data = [[0] * len(product_ids) for _ in range(len(user_ids))] # Creates a 2d Matrix with all products and users

for pref in prefs: # Populates the matrix with user preferences that you just made
    u_idx = user_ids[pref.user_id]
    p_idx = product_ids[pref.product_id]
    data[u_idx][p_idx] = pref.preference

num_users = len(user_ids)
num_products = len(product_ids)

users = [
    {"user_id": user_id, "responses": data[user_ids[user_id]]}
    for user_id in user_ids
]

from .models import Product
import numpy as np
def recommendation_algorithm(current_user):
    global num_clusters

    # Run biclustering
    model = SpectralBiclustering(n_clusters=num_clusters, random_state=0)
    model.fit(data)

    # Reorder the matrix based on biclustering
    row_order = np.argsort(model.row_labels_)
    col_order = np.argsort(model.column_labels_)
    reordered_data = data[row_order][:, col_order]

        # Determine products user likes
    liked_products = np.where(np.array(current_user["responses"]) == 1)[0]
    if len(liked_products) == 0: # If they havent liked any products yet
        if num_clusters > 2:
            num_clusters -= 1

        # Find indices of products the user hasn't reviewed yet
        unreviewed_indices = [i for i, resp in enumerate(current_user["responses"]) if resp == 0]

        if not unreviewed_indices:
            return None  # Or some fallback if no products left

        # Pick a random product index from unreviewed
        random_idx = random.choice(unreviewed_indices)

        # Reverse lookup to get product_id from product index
        reverse_product_ids = {v: k for k, v in product_ids.items()}
        product_id = reverse_product_ids[random_idx]

        # Return the Product instance from DB
        return Product.objects.get(id=product_id)

    # Count how many times each product cluster is liked
    product_cluster_counts = {}
    for product in liked_products:
        cluster = model.column_labels_[product]
        product_cluster_counts[cluster] = product_cluster_counts.get(cluster, 0) + 1

        product_cluster_counts = {}
        for product in liked_products:
            cluster = model.column_labels_[product]
            if cluster in product_cluster_counts:
                product_cluster_counts[cluster] += 1
            else:
                product_cluster_counts[cluster] = 1

    # Find the most relevant product cluster
    best_product_cluster = max(product_cluster_counts, key=product_cluster_counts.get)

    # Find products in the best cluster that the majority of users liked
    product_cluster_indices = np.where(model.column_labels_ == best_product_cluster)[0]
    cluster_likes = {product_idx: 0 for product_idx in product_cluster_indices}

    current_user_row = user_ids[current_user["user_id"]]  # Index of current_user in data

    for user_idx, user_label in enumerate(model.row_labels_):
        if user_label == model.row_labels_[current_user_row]:
            for product_idx in product_cluster_indices:
                if users[user_idx]["responses"][product_idx] == 1:
                    cluster_likes[product_idx] += 1

    # Recommend the most liked product in the cluster that the user has not reviewed
    unreviewed_indices = [
    idx for idx, response in enumerate(current_user["responses"]) if response == 0
    ]

    if unreviewed_indices:
        # Pick a random index from the unreviewed ones
        random_index = random.choice(unreviewed_indices)

        # Get the actual product ID using reverse lookup
        reverse_product_ids = {v: k for k, v in product_ids.items()}
        product_id = reverse_product_ids[random_index]

        # Fetch the Product object from DB
        return Product.objects.get(id=product_id)
    else:
        return None  # or fallback