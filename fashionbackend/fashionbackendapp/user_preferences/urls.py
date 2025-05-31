from django.urls import path
from . import views

urlpatterns = [
    # Handle swipes
    path('handle_swipe/', views.UserPreferenceViewSet.as_view({'post': 'handle_swipe'}), name='handle-swipe'),
    
    # Get liked products
    path('liked_products/', views.UserPreferenceViewSet.as_view({'get': 'liked_products'}), name='liked-products'),
    
    # Product details
    path('product_detail/<int:product_id>/', views.product_detail, name='product_detail'),
    
    # User creation
    path('create_user/', views.UserPreferenceViewSet.as_view({'post': 'create_user'}), name='create_user'),
]
