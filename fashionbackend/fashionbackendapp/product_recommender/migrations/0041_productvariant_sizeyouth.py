# Generated by Django 4.2.19 on 2025-06-07 19:34

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('product_recommender', '0040_alter_productimage_image_url_and_more'),
    ]

    operations = [
        migrations.AddField(
            model_name='productvariant',
            name='sizeYouth',
            field=models.BooleanField(default=False),
        ),
    ]
