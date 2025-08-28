#!/bin/bash

ENVIRONMENT=$(grep '^environment' terraform.tfvars | awk -F '"' '{print $2}')
LAKE_FOLDERS=$(grep '^lake_folders' terraform.tfvars | sed 's/.*=\s*\[\(.*\)\]/\1/' | tr -d '"' | tr ',' '\n')

echo "ENVIRONMENT = $ENVIRONMENT"
echo "LAKE_FOLDERS = $LAKE_FOLDERS"

# Paths
REGO_PATH="policies/opa/naming_conventions.rego"
PYTHON_SCRIPT="policies/opa/scripts/convert_yaml_to_json.py"

VIOLATIONS=""

for LAKE in $LAKE_FOLDERS; do
  YAML_PATH="configs/${ENVIRONMENT}/${LAKE}/lake-mapping.yaml"
  JSON_PATH="policies/opa/input/${LAKE}-mapping.json"

  echo "Converting $YAML_PATH to JSON..."
  python "$PYTHON_SCRIPT" "$YAML_PATH" "$JSON_PATH"

  echo "Running OPA validation for $LAKE..."
  RESULT=$("/c/Program Files/OpenPolicyAgent/opa.exe" eval --input "$JSON_PATH" --data "$REGO_PATH" "data.naming.deny" --format=json | jq -r '.result[0].expressions[0].value[]?')

  if [ -n "$RESULT" ]; then
    VIOLATIONS+="
Violations in $LAKE:
$RESULT
"
  fi

done

if [ -n "$VIOLATIONS" ]; then
  echo -e "Naming convention violations found:$VIOLATIONS"
  exit 1
else
  echo "✅ All naming conventions passed."
  exit 0
fi
