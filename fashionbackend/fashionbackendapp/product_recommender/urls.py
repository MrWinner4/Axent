from django.urls import path
from . import views
from django.conf import settings

urlpatterns = [
    path('products/recommend/', views.recommend_product),
    path('products/search', views.search_products),
]