from django.core.management import call_command

def run_train_recommender():
    call_command('train_recommender')