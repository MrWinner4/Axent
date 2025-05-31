from django.apps import AppConfig


class ProductRecommenderConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'product_recommender'

    def ready(self):
        from django_q.models import Schedule
        if not Schedule.objects.filter(name="Retrain ALS model").exists():
            Schedule.objects.create(
                name="Retrain ALS model",
                func='django.core.management.call_command',
                args='train_recommender',
                schedule_type=Schedule.HOURLY,
                repeats=-1
            )