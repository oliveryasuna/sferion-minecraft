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
  if ! [[ -f "Server-Files-1.1.1.zip" ]]; then
    echo "Downloading ATM9..."
    curl -Lo "Server-Files-1.1.1.zip" "https://edge.forgecdn.net/files/7097/957/Server-Files-1.1.1.zip" || exit 2
    echo "ATM9 downloaded"

    echo "Unzipping ATM9..."
    unzip -u -o "Server-Files-1.1.1.zip" -d /data
    if [[ -d "Server-Files-1.1.1" ]]; then
      mv Server-Files-1.1.1/* .
    fi
    echo "ATM9 unzipped"

    echo "Finding Forge installer..."
    FORGE_INSTALLER=$(find . -maxdepth 1 -name "forge-*-installer.jar" -type f | head -n 1)
    if [[ -z "$FORGE_INSTALLER" ]]; then
      echo "Forge installer not found"
      exit 1
    fi
    echo "Forge installer found"

    echo "Installing Forge..."
    java -jar "$FORGE_INSTALLER" --installServer
    echo "Forge installed"
  else
    echo "ATM9 already installed"
  fi
}

copy_assets() {
  echo "Copying assets..."
  cp -rn /assets/* .
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

setup_memory() {
  echo "Setting memory..."
  sed -i "s/^-Xmx.*/-Xmx${MEMORY_MAX}/" user_jvm_args.txt
  sed -i "s/^-Xms.*/-Xms${MEMORY_MIN}/" user_jvm_args.txt
  echo "Memory set"
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
  [[ -n "$ENABLE_RCON" ]] && set_property "enable-rcon" "$ENABLE_RCON"
  [[ -n "$RCON_PASSWORD" ]] && set_property "rcon.password" "$RCON_PASSWORD"
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
setup_memory
set_server_properties
run_server

