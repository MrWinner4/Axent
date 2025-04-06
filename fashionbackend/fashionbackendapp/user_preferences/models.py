from django.db import models
from django.contrib.auth.models import User
from product_recommender.models import Product

class UserPreference(models.Model):
    """Stores individual user-product interactions"""
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    product = models.ForeignKey(Product, on_delete=models.CASCADE)
    preference = models.IntegerField(choices=[(-1, "Dislike"), (0, "Neutral"), (1, "Like")])
    timestamp = models.DateTimeField(auto_now=True)
    class Meta:
        unique_together = ('user', 'product')  # Ensures one preference per product per user

    def __str__(self):
        return f"{self.user.username} - {self.product.name}: {self.preference}"

class UserProfile(models.Model):
    """Stores aggregated preferences for fast ML access"""
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    preferences = models.JSONField(default=dict)  # Stores {product_id: preference}

    def update_preferences(self):
        """Recalculates and stores user preferences from UserPreference"""
        user_prefs = UserPreference.objects.filter(user=self.user).values("product_id", "preference")
        self.preferences = {str(p["product_id"]): p["preference"] for p in user_prefs}
        self.save()

    def __str__(self):
        return f"Profile for {self.user.username}"