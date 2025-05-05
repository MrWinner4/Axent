from django.urls import path
from . import views
from django.conf import settings

urlpatterns = [
    path('recommend/', views.recommend_product),
    path('search', views.search_products),
]