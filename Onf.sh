#!/bin/sh
set -e

reset="\033[0m"
cyan="\033[36m"
green="\033[32m"
red="\033[31m"
VERSION="0.4.2"

# Check if OS is Linux
if [ "$(uname -s)" = "Linux" ]; then
  LOCATION="onf"
  URL="https://github.com/OnFinality-io/onf-cli/releases/download/v$VERSION/onf-linux-amd64-v$VERSION"
  SYSTEM="LINUX"

  # Create the directory if it doesn't exist
  mkdir -p "$LOCATION"

  # Download binary
  printf %s"$cyan> Downloading ...$reset\n"
  cd "$LOCATION"
  if curl -L "$URL" --output onf; then
    chmod 773 onf
    printf %s"$green > onf command v$VERSION is ready. $reset\n"
  else
    printf %s"$red> Failed to download $URL.$reset\n"
    exit 1
  fi
else
  printf %s"$red> This script only supports Linux.$reset\n"
  exit 1
fi
