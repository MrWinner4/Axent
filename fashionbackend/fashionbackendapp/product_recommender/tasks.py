from django.core.management import call_command
print("tasks.py loaded")

def run_train_recommender():
    print("run train recommender called")
    call_command('train_recommender')