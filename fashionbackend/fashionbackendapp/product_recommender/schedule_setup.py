from django_q.models import Schedule

def setup_fetch_shoe_data_schedule():
    Schedule.objects.update_or_create(
        name='fetch_shoe_data_daily',
        defaults={
            'func': 'django.core.management.call_command',
            'args': 'fetch_shoe_data',
            'schedule_type': Schedule.DAILY,
            'repeats': -1,  # Repeat forever
            'next_run': None,  # Will run 24 hours after creation, or set a datetime for first run
        }
    )