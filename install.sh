#!/bin/sh
set -eu

url="https://github.com/ridafkih/brighter/releases/latest/download/Brighter.zip"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

echo "Downloading Brighter..."
curl -fsSL "$url" -o "$tmp/Brighter.zip"
ditto -x -k "$tmp/Brighter.zip" "$tmp"

if pgrep -x Brighter >/dev/null; then
  pkill -x Brighter
  while pgrep -x Brighter >/dev/null; do sleep 0.1; done
fi

rm -rf /Applications/Brighter.app
mv "$tmp/Brighter.app" /Applications/
open /Applications/Brighter.app

echo "Brighter is installed. Look for the sun in your menu bar."
