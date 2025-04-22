import requests
from models import StockXSecret
import os

def get_latest_token():
    """Get the most recently saved access token from the DB."""
    try:
        return StockXSecret.objects.latest("updated_at").access_token
    except StockXSecret.DoesNotExist:
        raise Exception("No access token found in the database.")

def stockx_api_request(endpoint: str, method: str = "GET", data=None, params=None):
    base_url = "https://api.stockx.com"
    url = f"{base_url}{endpoint}"
    access_token = get_latest_token()
    api_key = os.getenv("STOCKX_API_KEY")

    headers = {
        "Authorization": f"Bearer {access_token}",
        "x-api-key": api_key,
        "Content-Type": "application/json",
        "Accept": "application/json",
    }

    response = requests.request(method, url, headers=headers, json=data, params=params)

    if response.status_code == 401:
        raise Exception("⚠️ Unauthorized. Access token may have expired.")
    elif not response.ok:
        raise Exception(f"StockX API error: {response.status_code} - {response.text}")

    return response.json()

#What i'm working on: have some functions that authenticate me, have to setup refreshing every so often. Also, need to flesh out actually putting stuff in db.