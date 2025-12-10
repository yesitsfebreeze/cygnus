#!/bin/bash
# Build script for Cygnus ZMK firmware using Docker

set -e

echo "Building Cygnus firmware with Docker..."

# Create bin directory if it doesn't exist
mkdir -p bin


git pull

# Build and run the Docker container
docker-compose up --build

echo ""
echo "✓ Build complete!"
echo "Firmware files are available in bin/"
echo ""
echo "To flash:"
echo "1. Put keyboard half into bootloader mode (double-tap reset)"
echo "2. Copy the appropriate .uf2 file to the keyboard drive"
echo "   - Left half: bin/cygnus_left.uf2"
echo "   - Right half: bin/cygnus_right.uf2"
echo "   - Settings reset: bin/settings_reset.uf2"
