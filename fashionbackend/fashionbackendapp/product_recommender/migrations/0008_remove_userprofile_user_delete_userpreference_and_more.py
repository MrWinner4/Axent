# Generated by Django 4.2.19 on 2025-04-05 19:09

from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ('product_recommender', '0007_remove_product_photo'),
    ]

    operations = [
        migrations.RemoveField(
            model_name='userprofile',
            name='user',
        ),
        migrations.DeleteModel(
            name='UserPreference',
        ),
        migrations.DeleteModel(
            name='UserProfile',
        ),
    ]
