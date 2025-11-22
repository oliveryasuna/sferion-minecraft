#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GET_UUID_SCRIPT="${SCRIPT_DIR}/get-player-uuid.sh"

if [ ! -f "$GET_UUID_SCRIPT" ]; then
  echo "Error: get-player-uuid.sh not found at ${GET_UUID_SCRIPT}" >&2
  exit 1
fi

if [ $# -eq 0 ]; then
  echo "Usage: $0 <username1> [username2] [username3] ..." >&2
  echo "Example: $0 top_tier_couch Notch jeb_" >&2
  exit 1
fi

echo "["

FIRST=true
for USERNAME in "$@"; do
  echo "Fetching UUID for ${USERNAME}..." >&2

  UUID=$("$GET_UUID_SCRIPT" "$USERNAME")

  if [ $? -ne 0 ]; then
    echo "Error: Failed to get UUID for ${USERNAME}" >&2
    exit 1
  fi

  if [ "$FIRST" = false ]; then
    echo "  },"
  fi

  cat <<EOF
  {
    "uuid": "${UUID}",
    "name": "${USERNAME}",
    "level": 4,
    "bypassesPlayerLimit": true
EOF

  FIRST=false
done

echo "  }"
echo "]"
