#!/bin/bash

# --- CONFIGURATION ---
# The script looks for a 'build' folder in the current directory.
# Inside 'build', it expects folders named: 'windows', 'linux', 'macos', 'web'
BUILD_DIR="$(pwd)/build"
DEST_DIR="$HOME/Downloads"

# ANSI Colors for terminal output
GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${CYAN}=== PROJECT GATEKEEPER PACKAGER ===${NC}"
echo -e "Source: $BUILD_DIR"
echo -e "Dest:   $DEST_DIR"
echo ""

# --- HELPER FUNCTION ---
package_platform() {
    FOLDER_NAME=$1
    # Optional: Allow the zip name to differ from the folder name
    # Usage: package_platform "folder_name" "zip_label"
    ZIP_LABEL=${2:-$FOLDER_NAME}

    SOURCE_PATH="$BUILD_DIR/$FOLDER_NAME"
    ZIP_FILE="$DEST_DIR/gatekeeper-$ZIP_LABEL.zip"

    if [ -d "$SOURCE_PATH" ]; then
        echo -e "Packaging ${CYAN}$FOLDER_NAME${NC}..."

        # 1. Enter the directory so we zip the *contents* (index.html, etc),
        #    not the folder itself. This is critical for itch.io web builds.
        pushd "$SOURCE_PATH" > /dev/null

        # 2. Delete existing zip to ensure a clean build
        if [ -f "$ZIP_FILE" ]; then
            rm "$ZIP_FILE"
        fi

        # 3. Zip recursively (-r) and quietly (-q)
        zip -q -r "$ZIP_FILE" .

        # 4. Return to original directory
        popd > /dev/null

        echo -e "${GREEN}✓ Created gatekeeper-$ZIP_LABEL.zip${NC}"
    else
        echo -e "${RED}x Error: Directory '$SOURCE_PATH' does not exist. Skipping.${NC}"
    fi
}

# --- EXECUTION ---

# 1. Windows Build
package_platform "windows"

# 2. Linux Build
package_platform "linux"

# 3. macOS Build
package_platform "macos"

# 4. Web Build (New!)
package_platform "web"

echo ""
echo -e "${GREEN}=== DEPLOYMENT READY ===${NC}"
# Opens the Downloads folder in Finder so you can see your files
open "$DEST_DIR"
