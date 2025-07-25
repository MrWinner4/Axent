# Generated by Django 4.2.19 on 2025-04-22 22:21

import django.contrib.postgres.fields
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('product_recommender', '0024_product_url'),
    ]

    operations = [
        migrations.RemoveField(
            model_name='product',
            name='url',
        ),
        migrations.AddField(
            model_name='product',
            name='urls',
            field=django.contrib.postgres.fields.ArrayField(base_field=models.URLField(), blank=True, default=list, help_text='List of image URLs', size=None),
        ),
    ]
