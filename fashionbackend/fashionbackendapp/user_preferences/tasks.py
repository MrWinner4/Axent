from background_task import background
import subprocess

@background(schedule=60*60*24)  # every 24 hours
def run_fetch_shoe_data():
    subprocess.run(['python', 'manage.py', 'fetch_shoe_data'])