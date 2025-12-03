#!/bin/bash
# Example script to generate a simple splash screen
# Usage: ./EXAMPLE-splash.sh "Your Text" output.tga

set -e

if [ $# -lt 2 ]; then
    echo "Usage: $0 <text> <output.tga>"
    echo "Example: $0 'Welcome to My Pi' splash.tga"
    exit 1
fi

TEXT="$1"
OUTPUT="$2"

# Check if ImageMagick is installed
if ! command -v convert &> /dev/null; then
    echo "Error: ImageMagick is required but not installed"
    echo "Install it with: sudo apt install imagemagick"
    exit 1
fi

echo "Creating splash screen with text: $TEXT"

# Create a simple splash screen with centred text
convert \
    -size 1920x1080 \
    xc:black \
    -font DejaVu-Sans-Bold \
    -pointsize 72 \
    -fill white \
    -gravity center \
    -annotate 0 "$TEXT" \
    -depth 8 \
    -colors 224 \
    -type truecolor \
    -flip \
    "$OUTPUT"

echo "Splash screen created: $OUTPUT"

# Show file information
file "$OUTPUT"
identify "$OUTPUT"

echo ""
echo "To use this splash screen, update your config file:"
echo ""
echo "splash:"
echo "  image_path: $(realpath "$OUTPUT")"

