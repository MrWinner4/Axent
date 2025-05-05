from rest_framework import viewsets, permissions, status
from rest_framework.response import Response
from django.shortcuts import get_object_or_404
from .models import Wardrobe, WardrobeItem
from .serializers import WardrobeSerializer, WardrobeItemSerializer
from rest_framework.decorators import action
from rest_framework.decorators import api_view

class WardrobeViewSet(viewsets.ModelViewSet):
    queryset = Wardrobe.objects.all()
    serializer_class = WardrobeSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return self.queryset.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

    @api_view(['POST'])
    def add_item(self, request):
        wardrobe = self.get_object()
        serializer = WardrobeItemSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save(wardrobe=wardrobe)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    @api_view(['POST'])
    def remove_item(self, request):
        wardrobe = self.get_object()
        product_id = request.data.get('product_id')
        if not product_id:
            return Response({'error': 'product_id is required'}, status=status.HTTP_400_BAD_REQUEST)
        
        item = get_object_or_404(WardrobeItem, wardrobe=wardrobe, product_id=product_id)
        item.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)