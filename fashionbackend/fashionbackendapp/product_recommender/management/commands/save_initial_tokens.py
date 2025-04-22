import os
import json
import requests
from django.core.management.base import BaseCommand
from django.utils import timezone
from product_recommender.models import StockXSecret

class Command(BaseCommand):
    help = 'Exchange authorization code for StockX access and refresh tokens'

    def add_arguments(self, parser):
        parser.add_argument('--code', type=str, help='Authorization code from StockX redirect')

    def handle(self, *args, **options):
        code = options['code']
        if not code:
            self.stderr.write("Authorization code is required.")
            return

        # Get credentials from environment
        STOCKX_CLIENT_ID = os.getenv('STOCKX_CLIENT_ID')
        STOCKX_CLIENT_SECRET = os.getenv('STOCKX_CLIENT_SECRET')
        REDIRECT_URI = os.getenv('STOCKX_REDIRECT_URI')  # This should be defined in your environment variables

        if not REDIRECT_URI:
            self.stderr.write("Redirect URI is not defined.")
            return

        # Prepare request payload to exchange code for tokens
        payload = {
            "grant_type": "authorization_code",
            "code": code,
            "client_id": STOCKX_CLIENT_ID,
            "client_secret": STOCKX_CLIENT_SECRET,
            "redirect_uri": REDIRECT_URI  # Make sure this is included
        }

        headers = {
            "Content-Type": "application/x-www-form-urlencoded"
        }

        # Send the POST request
        token_url = "https://accounts.stockx.com/oauth/token"
        response = requests.post(token_url, data=payload, headers=headers)

        if response.status_code == 200:
            token_data = response.json()
            access_token = token_data.get("access_token")
            refresh_token = token_data.get("refresh_token")
            expires_in = token_data.get("expires_in")

            # Save tokens to the database
            StockXSecret.objects.create(
                access_token=access_token,
                refresh_token=refresh_token,
                expires_in=expires_in,
                created_at=timezone.now()
            )

            self.stdout.write(self.style.SUCCESS("Tokens successfully saved in database!"))
        else:
            self.stderr.write(f"Failed to exchange token: {response.status_code}")
            self.stderr.write(response.text)
