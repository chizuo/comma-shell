#!/bin/bash

# Detect the shell profile file
if [[ "$SHELL" == "/bin/zsh" ]]; then
    PROFILE_FILE="$HOME/.zshrc"
elif [[ "$SHELL" == "/bin/bash" ]]; then
    PROFILE_FILE="$HOME/.bashrc"
else
    echo "Unsupported shell: $SHELL"
    exit 1
fi

# Define start and end markers
START_MARKER="# Start of functions file loading into shell"
END_MARKER="# End of functions file loading into shell"

# Check if the snippet exists
if grep -q "$START_MARKER" "$PROFILE_FILE"; then
    # Delete everything between start and end markers
    sed -i.bak "/$START_MARKER/,/$END_MARKER/d" "$PROFILE_FILE"
    echo "Removed function snippet from $PROFILE_FILE"
else
    echo "No function snippet found in $PROFILE_FILE"
fi