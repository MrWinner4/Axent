
import numpy as np
from scipy.sparse import csr_matrix
from implicit.als import AlternatingLeastSquares
from user_preferences.models import UserPreference, UserProfile
from .models import Product

def train_als_model():
    prefs = UserPreference.objects.filter(preference=1)
    users = list(UserProfile.objects.all())
    products = list(Product.objects.all())

    user_id_map = {user.id: idx for idx, user in enumerate(users)}
    product_id_map = {product.id: idx for idx, product in enumerate(products)}

    matrix = np.zeros((len(users), len(products)))
    for pref in prefs:
        u_idx = user_id_map.get(pref.user.id)
        p_idx = product_id_map.get(pref.product.id)
        if u_idx is not None and p_idx is not None:
            matrix[u_idx, p_idx] = 1

    csr_data = csr_matrix(matrix)
    model = AlternatingLeastSquares(factors=50, regularization=0.1, iterations=20)
    model.fit(csr_data)

    # Optionally: save the model or relevant data to cache or file
    print("✅ ALS model trained.")

    return model
