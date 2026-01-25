#!/bin/bash

# Script to apply patches to Flutter plugins with namespace issues
# This script should be run before building the app

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Starting Flutter plugin patches...${NC}"

# Find the flutter_barcode_scanner plugin location
PLUGIN_LOCATIONS=(
  "$HOME/.pub-cache/hosted/pub.dev/flutter_barcode_scanner-2.0.0/android"
  "$HOME/.pub-cache/git/flutter_barcode_scanner/android"
  "$HOME/.flutter-plugins/flutter_barcode_scanner/android"
)

# Keep track of whether we patched successfully
PATCHED=false

# Function to patch a plugin's build.gradle
patch_plugin() {
  local PLUGIN_DIR=$1
  local PATCH_FILE=$2
  local PLUGIN_NAME=$3

  if [ -d "$PLUGIN_DIR" ]; then
    echo -e "${GREEN}Found $PLUGIN_NAME at: $PLUGIN_DIR${NC}"

    # Check if build.gradle exists
    if [ -f "$PLUGIN_DIR/build.gradle" ]; then
      # Backup the original file if not already backed up
      if [ ! -f "$PLUGIN_DIR/build.gradle.orig" ]; then
        cp "$PLUGIN_DIR/build.gradle" "$PLUGIN_DIR/build.gradle.orig"
        echo -e "${GREEN}Created backup at: $PLUGIN_DIR/build.gradle.orig${NC}"
      fi

      # Apply the patch
      cp "$PATCH_FILE" "$PLUGIN_DIR/build.gradle"
      echo -e "${GREEN}Successfully patched $PLUGIN_NAME with namespace configuration!${NC}"
      PATCHED=true
    else
      echo -e "${RED}Error: build.gradle not found in $PLUGIN_DIR${NC}"
    fi
  fi
}

# Try to patch flutter_barcode_scanner
for LOCATION in "${PLUGIN_LOCATIONS[@]}"; do
  patch_plugin "$LOCATION" "./plugin-patches/flutter_barcode_scanner/build.gradle" "flutter_barcode_scanner"
  if [ "$PATCHED" = true ]; then
    break
  fi
done

# If we haven't patched anything yet, search more locations
if [ "$PATCHED" = false ]; then
  echo -e "${YELLOW}Searching for flutter_barcode_scanner in other locations...${NC}"

  # Look for the plugin in the Flutter SDK directory
  if [ -d "$FLUTTER_ROOT" ]; then
    FLUTTER_PLUGIN_PATH="$FLUTTER_ROOT/.pub-cache/hosted/pub.dev/flutter_barcode_scanner-2.0.0/android"
    patch_plugin "$FLUTTER_PLUGIN_PATH" "./plugin-patches/flutter_barcode_scanner/build.gradle" "flutter_barcode_scanner"
  fi

  # Search in the local project directory
  PROJECT_PLUGIN_PATH=$(find .. -path "*/flutter_barcode_scanner-*/android" -type d | head -1)
  if [ -n "$PROJECT_PLUGIN_PATH" ]; then
    patch_plugin "$PROJECT_PLUGIN_PATH" "./plugin-patches/flutter_barcode_scanner/build.gradle" "flutter_barcode_scanner"
  fi
fi

if [ "$PATCHED" = false ]; then
  echo -e "${RED}Warning: Could not find flutter_barcode_scanner plugin to patch${NC}"
  echo -e "${YELLOW}You may need to manually add 'namespace \"com.amolg.flutterbarcodescanner\"' to the plugin's build.gradle${NC}"
fi

echo -e "${GREEN}Plugin patching process complete.${NC}"