from celery import shared_task
from .models import UserProfile, UserPreference

@shared_task
def update_all_user_profiles():
    """Batch updates all user preference JSONFields"""
    users = UserProfile.objects.all()
    for profile in users:
        profile.update_preferences()
    return f"Updated {users.count()} user profiles"
