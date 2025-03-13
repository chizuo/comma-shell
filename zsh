
# functions used by the functions in this file, must be declared before use by other functions
describe() {
    local explain="$1"
    local description="$2"

    if [[ "$explain" == "true" ]]; then
        echo "$description"
        return 0
    fi

    return 1
}

,() {
    printf "%-20s | %s\n" "Function Name" "Description"
    printf "%-20s | %s\n" "--------------------" "--------------------"
    print -l ${(k)functions} | grep -oE '^,[a-zA-Z_][a-zA-Z0-9_]*' | while read -r func; do
        desc=$("$func" "true" 2>/dev/null)  # Call each function with "true" and suppress errors
        if [[ -n "$desc" ]]; then
            printf "%-20s | %s\n" "$func" "$desc"
        fi
    done
}

# Opens the functions file via VS CODE
,functions() {
    local description="Opens functions file on VS Code"
    if describe "$1" "$description"; then
        return 0
    fi
   code "$DIR/zsh"