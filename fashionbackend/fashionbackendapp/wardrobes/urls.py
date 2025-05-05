from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import WardrobeViewSet

router = DefaultRouter()
router.register(r'', WardrobeViewSet, basename='wardrobe')

urlpatterns = [
    path('', include(router.urls)),
]