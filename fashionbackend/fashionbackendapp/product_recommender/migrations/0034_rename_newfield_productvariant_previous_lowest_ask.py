# Generated by Django 4.2.19 on 2025-06-05 17:53

from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ('product_recommender', '0033_productvariant_newfield'),
    ]

    operations = [
        migrations.RenameField(
            model_name='productvariant',
            old_name='newField',
            new_name='previous_lowest_ask',
        ),
    ]
