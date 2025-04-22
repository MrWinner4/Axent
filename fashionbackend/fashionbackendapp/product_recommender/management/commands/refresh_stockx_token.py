import os
import requests
from django.core.management.base import BaseCommand
from product_recommender.models import StockXSecret

class Command(BaseCommand):
    help = "Refresh the StockX access token using the refresh token"

    def handle(self, *args, **options):
        try:
            secrets = StockXSecret.objects.latest("updated_at")
        except StockXSecret.DoesNotExist:
            self.stderr.write("No existing StockX tokens found in database.")
            return

        client_id = os.getenv("STOCKX_CLIENT_ID")
        client_secret = os.getenv("STOCKX_CLIENT_SECRET")

        url = "https://accounts.stockx.com/oauth/token"
        headers = {
            "Content-Type": "application/x-www-form-urlencoded"
        }
        data = {
            "grant_type": "refresh_token",
            "client_id": client_id,
            "client_secret": client_secret,
            "refresh_token": secrets.refresh_token,
            "audience": "gateway.stockx.com"
        }

        response = requests.post(url, data=data, headers=headers)

        if response.status_code == 200:
            token_data = response.json()
            new_secret = StockXSecret.objects.create(
                access_token=token_data["access_token"],
                refresh_token=token_data.get("refresh_token", secrets.refresh_token),
                id_token=token_data.get("id_token"),
                expires_in=token_data["expires_in"]
            )
            self.stdout.write(self.style.SUCCESS("✅ Access token refreshed and saved to DB."))
        else:
            self.stderr.write("❌ Failed to refresh token:")
            self.stderr.write(str(response.status_code))
            self.stderr.write(response.text)
