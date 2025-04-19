from django.urls import path
from . import views

urlpatterns = [
    path('liked_products/', views.liked_products, name='liked_products'),
    path('product_detail/<int:product_id>/', views.product_detail, name='product_detail'),
    path('create_user/', views.create_user, name='create_user'),
    path('handle_swipe/', views.handle_swipe, name='handle_swipe'),
]
