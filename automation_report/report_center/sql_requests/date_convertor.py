from sys import argv
from pytz import timezone
import pandas as pd

environment = argv[6]

def convert_timezone(date: str, default_timezone: str, target_timezone:str) -> int:
    start = timezone(default_timezone)
    end = timezone(target_timezone)
    date = pd.to_datetime(date)
    diff = int((start.localize(date) - end.localize(date).astimezone(start)).seconds/3600)
    if diff > 12:
        time_diff = 24 - diff
    else:
        time_diff = diff
    if environment == "PA" or environment == "MI":
        env_time_diff = time_diff + 6
    else:
        env_time_diff = time_diff
    return env_time_diff
