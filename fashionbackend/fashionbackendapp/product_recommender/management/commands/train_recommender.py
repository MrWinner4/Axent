
from django.core.management.base import BaseCommand
from product_recommender.training import train_als_model

class Command(BaseCommand):
    help = "Train ALS recommendation model"

    def handle(self, *args, **kwargs):
        train_als_model()
        self.stdout.write(self.style.SUCCESS("ALS model retrained."))
