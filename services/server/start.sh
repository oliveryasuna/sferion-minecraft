#!/bin/bash

set -e

cd /data

check_eula() {
  echo "Checking EULA..."

  if [[ "$MC_EULA" = "true" ]]; then
    echo "eula=true" > eula.txt

    echo "EULA accepted"
  else
    echo "EULA not accepted"
    exit 1
  fi
}

copy_atm9() {
  echo "Copying ATM9..."

  if ! [[ -f "run.sh" ]]; then
    cp -r /tmp/server-files/* /data/

    echo "ATM9 copied"
  else
    echo "ATM9 already copied"
  fi
}

copy_assets() {
  echo "Copying assets..."

  # Copy assets, but force overwrite specific config files
  cp -r --update=none /tmp/assets/* .

  # Force overwrite JVM args to use our custom settings
  if [ -f "/tmp/assets/user_jvm_args.txt" ]; then
    cp -f /tmp/assets/user_jvm_args.txt .
    echo "Overwrote user_jvm_args.txt with custom settings"
  fi

  echo "Assets copied"
}

generate_whitelist() {
  echo "Generating whitelist..."

  if [[ -z "$MC_WHITELIST" ]]; then
    echo "MC_WHITELIST not set, skipping whitelist generation"
    return
  fi

  IFS=',' read -ra USERNAMES <<< "$MC_WHITELIST"
  /tmp/scripts/generate-whitelist.sh "${USERNAMES[@]}" > whitelist.json

  echo "Whitelist generated"
  cat whitelist.json
}

generate_ops() {
  echo "Generating ops..."

  if [[ -z "$MC_OPS" ]]; then
    echo "MC_OPS not set, skipping ops generation"
    return
  fi

  IFS=',' read -ra USERNAMES <<< "$MC_OPS"
  /tmp/scripts/generate-ops.sh "${USERNAMES[@]}" > ops.json

  echo "Ops generated"
  echo ops.json
}

update_server_properties() {
  echo "Updating server properties..."

  # Collect all MC_SERVER_PROP__* environment variables
  PROPS=()
  while IFS='=' read -r name value; do
    if [[ "$name" =~ ^MC_SERVER_PROP__(.+)$ ]]; then
      # Extract key and convert:
      # - Double underscores (__) to dots (.)
      # - Single underscores (_) to dashes (-)
      key="${BASH_REMATCH[1]}"
      # First replace __ with a placeholder to preserve them
      key="${key//__/<<<DOT>>>}"
      # Replace single _ with -
      key="${key//_/-}"
      # Replace placeholder with .
      key="${key//<<<DOT>>>/.}"
      PROPS+=("${key}=${value}")
    fi
  done < <(env)

  if [[ ${#PROPS[@]} -eq 0 ]]; then
    echo "No MC_SERVER_PROP__* variables set, using default server.properties"
    return
  fi

  /tmp/scripts/update-server-properties.sh -i server.properties "${PROPS[@]}" > server.properties.tmp
  mv server.properties.tmp server.properties

  echo "Server properties updated"
  cat server.properties
}

update_jvm_args() {
  echo "Updating JVM args..."

  # Collect all MC_JVM_ARG__* environment variables
  ARGS=()
  while IFS='=' read -r name value; do
    if [[ "$name" =~ ^MC_JVM_ARG__(.+)$ ]]; then
      # Extract key and use value as the full arg
      ARGS+=("$value")
    fi
  done < <(env)

  if [[ ${#ARGS[@]} -eq 0 ]]; then
    echo "No MC_JVM_ARG__* variables set, using default user_jvm_args.txt"
    return
  fi

  /tmp/scripts/update-jvm-args.sh -i user_jvm_args.txt "${ARGS[@]}" > user_jvm_args.txt.tmp
  mv user_jvm_args.txt.tmp user_jvm_args.txt

  echo "JVM args updated"
  cat user_jvm_args.txt
}

run_server() {
  echo "Running server..."

  chmod 755 run.sh

  # Start server in background
  ./run.sh &
  SERVER_PID=$!

  # Function to gracefully shutdown using RCON
  shutdown() {
    echo "Received shutdown signal, saving world via RCON..."

    # Wait a moment for RCON to be available
    sleep 2

    # Send save-all command via RCON
    mcrcon -H localhost -P 25575 -p "${MC_SERVER_PROP__rcon_password}" "save-all flush" 2>/dev/null || true
    sleep 5

    # Send stop command via RCON
    mcrcon -H localhost -P 25575 -p "${MC_SERVER_PROP__rcon_password}" "stop" 2>/dev/null || true

    # Wait up to 120 seconds for graceful shutdown
    timeout=120
    while kill -0 $SERVER_PID 2>/dev/null && [ $timeout -gt 0 ]; do
      sleep 1
      timeout=$((timeout - 1))
    done

    if kill -0 $SERVER_PID 2>/dev/null; then
      echo "Server didn't stop gracefully, forcing shutdown..."
      kill -KILL $SERVER_PID
    else
      echo "Server stopped gracefully"
    fi

    exit 0
  }

  # Trap SIGTERM and SIGINT
  trap shutdown SIGTERM SIGINT

  echo "Server started with PID $SERVER_PID"
  echo "Waiting for signals..."

  # Wait for server process
  wait $SERVER_PID
}


check_eula
copy_atm9
copy_assets
generate_whitelist
generate_ops
update_server_properties
update_jvm_args
run_server

