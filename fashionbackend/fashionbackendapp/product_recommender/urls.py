from django.urls import path
from . import views

urlpatterns = [
    path('test/', views.test_view, name='test-view'),  # Add this line
    path('recommend/', views.ProductViewSet.as_view({'get': 'recommend'}), name='product-recommend'),
    path('search/', views.ProductViewSet.as_view({'get': 'search'}), name='product-search'),
]