#!/bin/bash

set -e

cd /data

echo "Checking EULA..."
if ! [[ "$EULA" = "false" ]]; then
  echo "eula=true" > eula.txt
  echo "EULA accepted"
else
  echo "EULA not accepted"
  exit 1
fi

# Download and install ATM9, if not already installed
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

echo "Copying assets..."
cp -rn /assets/* .
echo "Assets copied"

echo "Running server..."
chmod 755 run.sh
./run.sh
