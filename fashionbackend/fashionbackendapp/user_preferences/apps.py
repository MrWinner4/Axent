from django.apps import AppConfig


class UserPreferencesConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'user_preferences'

def ready(self):
    import user_preferences.signals  

# In views.py or apps.py
from .firebase import initialize_firebase

# Call initialize_firebase() at the start of your app or view
initialize_firebase()