# Generated by Django 4.2.19 on 2025-04-22 22:19

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('product_recommender', '0023_productimage_product'),
    ]

    operations = [
        migrations.AddField(
            model_name='product',
            name='url',
            field=models.URLField(blank=True, null=True),
        ),
    ]
