import yaml
import json
import sys
import os

print("Conversion initiated")

if len(sys.argv) != 3:
    print("Usage: python convert_yaml_to_json.py <input_yaml> <output_json>")
    sys.exit(1)

input_yaml = sys.argv[1]
output_json = sys.argv[2]


if not os.path.exists(input_yaml):
    print(f"Input file '{input_yaml}' does not exist.")


with open(input_yaml, 'r') as f:
    yaml_data = yaml.safe_load(f)

with open(output_json, 'w') as f:
    json.dump(yaml_data, f, indent=2)

print(f"Successfully converted '{input_yaml}' to '{output_json}'.")
