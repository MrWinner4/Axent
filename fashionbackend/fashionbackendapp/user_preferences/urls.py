from django.urls import path
from . import views

urlpatterns = [
    # Health check
    path('health/', views.health_check, name='health_check'),
    
    # Handle swipes
    path('handle_swipe/', views.UserPreferenceViewSet.as_view({'post': 'handle_swipe'}), name='handle-swipe'),
    
    # Get liked products
    path('liked_products/', views.UserPreferenceViewSet.as_view({'get': 'liked_products'}), name='liked-products'),
    
    # Product details
    path('product_detail/<uuid:product_id>/', views.UserPreferenceViewSet.as_view({'get': 'product_detail'}), name='product_detail'),

    #Update Bought Products
    path('update_bought_products/', views.UserPreferenceViewSet.as_view({'post': 'update_bought_products'}), name='update_bought_products'),
    
    # User creation
    path('create_user/', views.UserPreferenceViewSet.as_view({'post': 'create_user'}), name='create_user'),

    # Email Update
    path('update_email/', views.UserPreferenceViewSet.as_view({'post': 'update_email'}), name='update_email'),

    #Post Detail View
    path('post_detail_view/', views.UserPreferenceViewSet.as_view({'post': 'post_detail_view'}), name='post_detail_view'),

    #Buy Product
    path('buy_product/', views.UserPreferenceViewSet.as_view({'post': 'buy_product'}), name='buy_product'),
]
