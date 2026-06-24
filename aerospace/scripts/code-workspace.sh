#!/bin/bash

WORKSPACE="terminal"

# Application 1 Configuration
APP1_NAME="Microsoft Edge"
APP1_ID="com.microsoft.edgemac"

# Application 2 Configuration
APP2_NAME="Ghostty"
APP2_ID="com.mitchellh.ghostty"

while true; do
  # 1. Check if the "Code" workspace currently has focus
  CURRENT_WORKSPACE=$(aerospace list-workspaces --focused)

  if [ "$CURRENT_WORKSPACE" = "$WORKSPACE" ]; then

    # 2. Check and restore Chrome
    CHROME_COUNT=$(aerospace list-windows --workspace "$WORKSPACE" --format "%{app-id}" | grep -c "$APP1_ID")
    if [ "$CHROME_COUNT" -eq 0 ]; then
      open -na "$APP1_NAME"
    fi

    # 3. Check and restore Ghostty
    GHOSTTY_COUNT=$(aerospace list-windows --workspace "$WORKSPACE" --format "%{app-id}" | grep -c "$APP2_ID")
    if [ "$GHOSTTY_COUNT" -eq 0 ]; then
      open -na "$APP2_NAME"
    fi

  fi

  # Interval check frequency (in seconds)
  sleep 2
done
