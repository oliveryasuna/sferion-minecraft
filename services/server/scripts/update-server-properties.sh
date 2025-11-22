#!/bin/bash

set -e

usage() {
  cat >&2 <<EOF
Usage: $0 [OPTIONS] [key=value ...]

Update or create server properties, output to stdout.

OPTIONS:
  -i, --input PATH     Input server.properties file (optional)
  -h, --help          Show this help message

EXAMPLES:
  # Create new file with properties
  $0 motd="My Server" max-players=20 > server.properties

  # Update existing file
  $0 -i server.properties difficulty=hard > server.properties.new

  # Read from stdin
  echo -e "motd=Server\nmax-players=10" | $0 > server.properties
EOF
  exit 1
}

INPUT_FILE=""
PROPERTIES=()

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -i|--input)
      INPUT_FILE="$2"
      shift 2
      ;;
    -h|--help)
      usage
      ;;
    *=*)
      PROPERTIES+=("$1")
      shift
      ;;
    *)
      echo "Error: Unknown argument: $1" >&2
      usage
      ;;
  esac
done

# Create temporary file for processing
TEMP_FILE=$(mktemp)
trap "rm -f $TEMP_FILE" EXIT

# Copy input file if it exists, otherwise start with empty file
if [[ -n "$INPUT_FILE" && -f "$INPUT_FILE" ]]; then
  cp "$INPUT_FILE" "$TEMP_FILE"
fi

# Function to set or update a property
set_property() {
  local key="$1"
  local value="$2"

  # Escape special characters for sed
  local escaped_key=$(echo "$key" | sed 's/[.[\*^$()+?{|]/\\&/g')
  local escaped_value=$(echo "$value" | sed 's/[&/\]/\\&/g')

  if [[ -f "$TEMP_FILE" ]] && grep -q "^${escaped_key}=" "$TEMP_FILE" 2>/dev/null; then
    # Property exists, update it
    sed -i.bak "s|^${escaped_key}=.*|${key}=${value}|" "$TEMP_FILE"
    rm -f "${TEMP_FILE}.bak"
  else
    # Property doesn't exist, append it
    echo "${key}=${value}" >> "$TEMP_FILE"
  fi
}

# Process properties from arguments
for prop in "${PROPERTIES[@]}"; do
  if [[ "$prop" =~ ^([^=]+)=(.*)$ ]]; then
    key="${BASH_REMATCH[1]}"
    value="${BASH_REMATCH[2]}"
    set_property "$key" "$value"
  else
    echo "Warning: Skipping invalid property format: $prop" >&2
  fi
done

# Process properties from stdin if available
if [[ ! -t 0 ]]; then
  while IFS= read -r line; do
    # Skip empty lines and comments
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

    if [[ "$line" =~ ^([^=]+)=(.*)$ ]]; then
      key="${BASH_REMATCH[1]}"
      value="${BASH_REMATCH[2]}"
      set_property "$key" "$value"
    else
      echo "Warning: Skipping invalid property format: $line" >&2
    fi
  done
fi

# Output to stdout
cat "$TEMP_FILE"
