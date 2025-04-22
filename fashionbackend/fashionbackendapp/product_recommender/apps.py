from django.apps import AppConfig


class ProductRecommenderConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'product_recommender'

    def ready(self):
        from django_q.models import Schedule
        if not Schedule.objects.filter(name="Refresh StockX Token").exists():
            Schedule.objects.create(
                func='product_recommender.tasks.refresh_stockx_token_command',
                name='Refresh StockX Token Cmd',
                schedule_type=Schedule.MINUTES,
                minutes=360,  # Every 6 hours
            )
