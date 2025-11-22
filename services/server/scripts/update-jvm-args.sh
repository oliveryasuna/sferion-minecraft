#!/bin/bash

set -e

usage() {
  cat >&2 <<EOF
Usage: $0 [OPTIONS] [arg1] [arg2] ...

Update or create JVM arguments, output to stdout.

OPTIONS:
  -i, --input PATH     Input user_jvm_args.txt file (optional)
  -h, --help          Show this help message

EXAMPLES:
  # Create new args
  $0 -Xms8G -Xmx16G > user_jvm_args.txt

  # Update existing file (replaces matching args, preserves others)
  $0 -i user_jvm_args.txt -Xmx32G > user_jvm_args.txt.new

  # Read from stdin
  echo -e "-Xms8G\n-Xmx16G" | $0 > user_jvm_args.txt

NOTES:
  - Args starting with -Xms or -Xmx replace existing memory settings
  - Other -XX: args replace matching args by name
  - -D args replace matching args by property name
  - Args are matched by prefix/name, not full string
EOF
  exit 1
}

INPUT_FILE=""
ARGS=()

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
    -*)
      ARGS+=("$1")
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
  # Ensure file ends with newline to prevent args from concatenating
  if [[ -s "$TEMP_FILE" ]]; then
    tail -c1 "$TEMP_FILE" | read -r _ || echo >> "$TEMP_FILE"
  fi
fi

# Function to extract the "key" part of a JVM arg for matching
get_arg_key() {
  local arg="$1"

  if [[ "$arg" =~ ^-Xms ]]; then
    echo "-Xms"
  elif [[ "$arg" =~ ^-Xmx ]]; then
    echo "-Xmx"
  elif [[ "$arg" =~ ^-D([^=]+) ]]; then
    echo "-D${BASH_REMATCH[1]}"
  elif [[ "$arg" =~ ^-XX:(\+|-)([^=]+) ]]; then
    echo "-XX:${BASH_REMATCH[1]}${BASH_REMATCH[2]}"
  elif [[ "$arg" =~ ^-XX:([^=]+) ]]; then
    echo "-XX:${BASH_REMATCH[1]}"
  else
    echo "$arg"
  fi
}

# Function to set or update a JVM arg
set_arg() {
  local new_arg="$1"
  local key=$(get_arg_key "$new_arg")

  # Escape special characters for sed
  local escaped_key=$(echo "$key" | sed 's/[.[\*^$()+?{|]/\\&/g')

  if [[ -f "$TEMP_FILE" ]] && grep -q "^${escaped_key}" "$TEMP_FILE" 2>/dev/null; then
    # Arg exists, replace it
    sed -i.bak "/^${escaped_key}/c\\
${new_arg}" "$TEMP_FILE"
    rm -f "${TEMP_FILE}.bak"
  else
    # Arg doesn't exist, append it
    echo "$new_arg" >> "$TEMP_FILE"
  fi
}

# Process args from command line
for arg in "${ARGS[@]}"; do
  set_arg "$arg"
done

# Process args from stdin if available
if [[ ! -t 0 ]]; then
  while IFS= read -r line; do
    # Skip empty lines and comments
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

    set_arg "$line"
  done
fi

# Output to stdout
cat "$TEMP_FILE"
