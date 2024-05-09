import json
import sys

def get_echo_time(json_file):
    with open(json_file, 'r') as f:
        data = json.load(f)
        echo_time = data.get('EchoTime', None)
        return echo_time

# Example usage:
json_file = sys.argv[1]  # replace 'data.json' with the path to your JSON file
echo_time = get_echo_time(json_file)
if echo_time is not None:
    print(echo_time)
else:
    print("EchoTime field not found in the JSON file.")
