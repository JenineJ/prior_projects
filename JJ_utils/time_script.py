"""
Times entire script if imported. The time is printed at the end.
"""

import atexit
from datetime import datetime


def elapsed_time(start_time):
    print(f'Time taken: {datetime.now() - start_time}')


try:
    start_time = datetime.now()
    print(f'Start time: {start_time}')

    atexit.register(elapsed_time, start_time)

except Exception:
    print('Could not time script')
