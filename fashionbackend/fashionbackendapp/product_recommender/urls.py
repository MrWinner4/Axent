from django.urls import path
from . import views
from django.conf import settings

urlpatterns = [
    path('post/', views.postData),
    path('products/recommend/', views.recommend_product),
]