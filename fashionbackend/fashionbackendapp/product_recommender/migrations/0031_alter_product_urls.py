# Generated by Django 4.2.19 on 2025-04-28 22:40

from django.db import migrations, models
import product_recommender.models


class Migration(migrations.Migration):

    dependencies = [
        ('product_recommender', '0030_remove_product_store_links'),
    ]

    operations = [
        migrations.AddField(
            model_name='product',
            name='urls',
            field=models.JSONField(blank=True, default=dict, help_text='Dictionary of store URLs with platform as key'),
        ),
    ]
