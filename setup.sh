#!/bin/bash

# Set the PATH for the functions file
FUNCTIONS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Delimiters to encapsulate the code injected into the respective shell profiles
START_MARKER="# Start of functions file loading into shell"
END_MARKER="# End of functions file loading into shell"

# Detect macOS or Linux using uname command, Darwin vs Linux return, to use proper flags of stat
if [[ "$(uname)" == "Darwin" ]]; then
    OS="macOS"
    STAT_CMD="stat -f %m"  # macOS uses 'stat -f %m' instead of 'stat -c %Y'
else
    OS="Linux"
    STAT_CMD="stat -c %Y"  # Linux uses 'stat -c %Y'
fi

# Detect the shell and set the correct profile file
if [[ "$SHELL" == "/bin/zsh" ]]; then
    PROFILE_FILE="$HOME/.zshrc"
    FUNCTIONS_FILE="$FUNCTIONS_DIR/zsh"
elif [[ "$SHELL" == "/bin/bash" ]]; then
    PROFILE_FILE="$HOME/.bashrc"
    FUNCTIONS_FILE="$FUNCTIONS_DIR/bash"
else
    echo "Unsupported shell: $SHELL"
    exit 1
fi

# Output for debugging & user verification
echo -e "\n**********************************"
echo "Detected OS: $OS"
echo "Using Profile: $PROFILE_FILE"
echo "Using Functions File: $FUNCTIONS_FILE"
echo -e "**********************************\n"

# Run remove.sh before adding a new snippet
bash "$FUNCTIONS_DIR/remove.sh"

# Define the snippet to insert between markers into shell profile
FUNCTIONS_SNIPPET="$START_MARKER
FUNCTIONS_FILE=\"$FUNCTIONS_FILE\"

if [ -f \"\$FUNCTIONS_FILE\" ]; then
    source \"\$FUNCTIONS_FILE\"

    # Store the last modified time of the functions file
    export BASH_FUNCTIONS_TIMESTAMP=\$($STAT_CMD \"\$FUNCTIONS_FILE\")

    # Function to check for updates and reload automatically by checking the timestamp on the functions file
    check_reload_functions() {
        local new_timestamp=\$($STAT_CMD \"\$FUNCTIONS_FILE\")
        if [[ \"\$new_timestamp\" -ne \"\$BASH_FUNCTIONS_TIMESTAMP\" ]]; then
            source \"\$FUNCTIONS_FILE\"
            export BASH_FUNCTIONS_TIMESTAMP=\$new_timestamp
            echo \"Reloaded \$FUNCTIONS_FILE due to updates.\"
        fi
    }

    # Ensure PROMPT_COMMAND is set correctly
    if [[ -z \"\$PROMPT_COMMAND\" ]]; then
        PROMPT_COMMAND=\"check_reload_functions\"
    else
        PROMPT_COMMAND=\"check_reload_functions; \$PROMPT_COMMAND\"
    fi
fi
$END_MARKER"

# Check if the snippet already exists in the profile file
if ! grep -q "if [ -f \"$FUNCTIONS_FILE\" ]; then" "$PROFILE_FILE"; then
    echo -e "\n$FUNCTIONS_SNIPPET" >> "$PROFILE_FILE"
    echo "Added custom functions file to load in $PROFILE_FILE"
else
    echo "Custom functions loading is already present in $PROFILE_FILE"
fi

# Ensure the functions directory exists
if [ ! -d "$FUNCTIONS_DIR" ]; then
    mkdir -p "$FUNCTIONS_DIR"
    echo "Created directory: $FUNCTIONS_DIR"
fi

# Ensure the functions file exists
if [ ! -f "$FUNCTIONS_FILE" ]; then
    touch "$FUNCTIONS_FILE"
    echo "# Custom shell functions file" > "$FUNCTIONS_FILE"
    echo "Created $FUNCTIONS_FILE"
fi

# Check if DIR= is already defined to avoid duplicates
if ! grep -q '^DIR=' "$FUNCTIONS_FILE"; then
    echo "Prepending DIR to $FUNCTIONS_FILE"

    if [[ "$OS" == "macOS" ]]; then
        sed -i '' '1s|^|DIR="'"$FUNCTIONS_DIR"'"\
        \n|' "$FUNCTIONS_FILE"
    else
        sed -i '1s|^|DIR="'"$FUNCTIONS_DIR"'"\
        \n|' "$FUNCTIONS_FILE"
    fi
fi

# Apply changes immediately
source "$PROFILE_FILE"

echo "Setup complete! Your shell functions will now auto-reload in $PROFILE_FILE."