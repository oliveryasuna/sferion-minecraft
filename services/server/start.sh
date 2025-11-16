#!/bin/bash

set -e

cd /data

check_eula() {
  echo "Checking EULA..."
  if [[ "$EULA" = "true" ]]; then
    echo "eula=true" > eula.txt
    echo "EULA accepted"
  else
    echo "EULA not accepted"
    exit 1
  fi
}

install_atm9() {
  echo "Checking for ATM9..."
  if ! [[ -f "run.sh" ]]; then
    echo "Copying server files from image..."
    cp -r /server-files/* /data/
    echo "Server files copied"
  else
    echo "ATM9 already installed"
  fi
}

copy_assets() {
  echo "Copying assets..."
  cp -r --update=none /assets/* .
  echo "Assets copied"
}

setup_log4j() {
  echo "Setting log4j configuration..."
  if ! grep -q "log4j.configurationFile" user_jvm_args.txt 2>/dev/null; then
    sed -i -e '$a\' user_jvm_args.txt 2>/dev/null || true
    echo "-Dlog4j.configurationFile=log4j2.xml" >> user_jvm_args.txt
    echo "Added log4j config to user_jvm_args.txt"
  else
    echo "Log4j configuration already set"
  fi
}

setup_jvm_args() {
  echo "Setting JVM args..."

  sed -i "s/^-Xmx.*/-Xmx${MEMORY_MAX}/" user_jvm_args.txt
  sed -i "s/^-Xms.*/-Xms${MEMORY_MIN}/" user_jvm_args.txt

  sed -i '/^-XX:+ExitOnOutOfMemoryError$/d' user_jvm_args.txt
  [ "$EXIT_ON_OOM" = "true" ] && echo "-XX:+ExitOnOutOfMemoryError" >> user_jvm_args.txt

  if ! grep -q "jdk.incubator.vector" user_jvm_args.txt 2>/dev/null; then
    sed -i -e '$a\' user_jvm_args.txt 2>/dev/null || true
    echo "--add-modules=jdk.incubator.vector" >> user_jvm_args.txt
  fi

  echo "JVM args set"
  cat user_jvm_args.txt
}

set_server_properties() {
  set_property() {
    local key="$1"
    local value="$2"
    local file="${3:-server.properties}"

    if grep -q "^${key}=" "$file" 2>/dev/null; then
      # Property exists, replace it
      sed -i "s|^${key}=.*|${key}=${value}|" "$file"
    else
      # Property doesn't exist, append it
      echo "${key}=${value}" >> "$file"
    fi
  }

  echo "Setting server properties..."
  [[ -n "$LEVEL_SEED" ]] && set_property "level-seed" "$LEVEL_SEED"
  [[ -n "$MOTD" ]] && set_property "motd" "$MOTD"
  [[ -n "$DIFFICULTY" ]] && set_property "difficulty" "$DIFFICULTY"
  [[ -n "$MAX_PLAYERS" ]] && set_property "max-players" "$MAX_PLAYERS"
  [[ -n "$VIEW_DISTANCE" ]] && set_property "view-distance" "$VIEW_DISTANCE"
  set_property "white-list" "true"
  echo "Server properties set"
}

run_server() {
  echo "Running server..."
  chmod 755 run.sh
  ./run.sh
}

check_eula
install_atm9
copy_assets
setup_log4j
setup_jvm_args
set_server_properties
run_server

