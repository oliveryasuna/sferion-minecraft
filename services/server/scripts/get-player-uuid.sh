#!/bin/bash

set -e

if [ -z "$1" ]; then
  echo "Usage: $0 <username>" >&2
  exit 1
fi

USERNAME="$1"

# Fetch player data from Mojang API
RESPONSE=$(curl -sf "https://api.mojang.com/users/profiles/minecraft/${USERNAME}")

if [ -z "$RESPONSE" ]; then
  echo "Error: Player not found or API request failed" >&2
  exit 1
fi

# Extract ID and add dashes to format as UUID
ID=$(echo "$RESPONSE" | grep -o '"id"[[:space:]]*:[[:space:]]*"[^"]*"' | grep -o '"[a-f0-9]*"' | tr -d '"')

if [ -z "$ID" ]; then
  echo "Error: Failed to extract UUID from API response" >&2
  exit 1
fi

# Format as UUID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
UUID="${ID:0:8}-${ID:8:4}-${ID:12:4}-${ID:16:4}-${ID:20:12}"

echo "$UUID"
