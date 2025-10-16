#!/usr/bin/env bash
set -e

# Move to project root (if not already there)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Create and enter build directory
mkdir -p build
cd build

# Run cmake on the parent folder
cmake ..

# Build the firmware
make

echo "✅ Build output:"
shopt -s nullglob
files=( *.elf *.bin )
if [ ${#files[@]} -eq 0 ]; then
  echo "No .elf/.bin produced."
else
  ls -lh "${files[@]}"
fi
