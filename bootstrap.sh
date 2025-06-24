#!/usr/bin/env bash
set -e

TEMP_SCRIPT="code-quality.sh"

# Download
curl -sSfL https://raw.githubusercontent.com/ahsant4riq/code-quality-setup/main/code-quality.sh -o "$TEMP_SCRIPT"

# Make executable
chmod +x "$TEMP_SCRIPT"

# Run
./"$TEMP_SCRIPT"

# Cleanup after successful run
rm "$TEMP_SCRIPT"
