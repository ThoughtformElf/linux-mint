#!/bin/bash

# --- Configuration: Default Files/Directories to Exclude (Basenames) ---
# These use BASENAME matching and are skipped UNLESS overridden by --include
default_exclude_patterns=(
    ".git" "node_modules" ".DS_Store" ".gitignore" "package-lock.json"
    "yarn.lock" "dist" "build" "out" "target" ".vscode" ".idea" "*.pyc"
    "__pycache__"
)

# --- Define HEY for internal script calls ---
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# HEY is the parent directory of utils, typically where hey.sh resides
HEY=$(dirname "$SCRIPT_DIR") 

# Path to the parse.sh script
PARSE_SCRIPT="${HEY}/utils/parse.sh"

# Check if parse.sh exists and is executable
if [ ! -f "$PARSE_SCRIPT" ]; then
    echo "Error: Required parse script not found at '$PARSE_SCRIPT'. Please ensure it exists and \$HEY is set correctly." >&2
    exit 1
fi
if [ ! -x "$PARSE_SCRIPT" ]; then
    echo "Error: Required parse script '$PARSE_SCRIPT' is not executable. Please set executable permissions." >&2
    exit 1
fi

# --- Arrays for command-line options ---
custom_ignore_patterns=() # Patterns from --ignore (match FULL path)
custom_include_patterns=() # Patterns from --include (match FULL path, take precedence)
paths_to_process=()      # File/directory arguments from the command line

# --- Argument Parsing Loop ---
while [[ $# -gt 0 ]]; do
    case "$1" in
        --ignore)
            if [[ -z "$2" ]]; then
                echo "Error: --ignore requires a pattern argument." >&2
                exit 1
            fi
            # Store the pattern exactly as provided by the user
            custom_ignore_patterns+=("$2")
            shift 2 # Consume --ignore and its pattern
            ;;
        --include)
            if [[ -z "$2" ]]; then
                echo "Error: --include requires a pattern argument." >&2
                exit 1
            fi
            # Store the pattern exactly as provided by the user
            custom_include_patterns+=("$2")
            shift 2 # Consume --include and its pattern
            ;;
        --*) # Handle unknown options
           echo "Error: Unknown option '$1'" >&2
           exit 1
           ;;
        *) # Not an option, assume it's a file/directory path
            paths_to_process+=("$1")
            shift # Consume the path
            ;;
    esac
done

# --- Helper Function: Check if a path should be processed based on rules ---
# Returns 0 (true/success) if the item SHOULD be processed.
# Returns 1 (false/failure) if it should be SKIPPED.
should_process() {
    local item_path="$1" # The full path being checked (e.g., context/file.txt or ./subdir/another.log)
    local item_basename
    item_basename=$(basename -- "$item_path") # Used only for default excludes

    # === Priority 1: Custom INCLUDES (Full Path Match) ===
    # If a path matches an --include pattern, it's always processed.
    for pattern in "${custom_include_patterns[@]}"; do
        # Use [[ for reliable glob matching against the FULL path
        if [[ "$item_path" == $pattern ]]; then
            return 0 # Process it
        fi
    done

    # === Priority 2: Custom IGNORES (Full Path Match) ===
    # If it wasn't explicitly included, check if it matches an --ignore pattern.
    for pattern in "${custom_ignore_patterns[@]}"; do
        # Use [[ for reliable glob matching against the FULL path
        if [[ "$item_path" == $pattern ]]; then
            return 1 # Skip it
        fi
    done

    # === Priority 3: Default EXCLUDES (Basename Match) ===
    # This check is now mostly handled by 'find -prune' for directories,
    # but it's kept for files in the top-level directory and as a fallback.
    for pattern in "${default_exclude_patterns[@]}"; do
        # Use [[ for reliable glob matching against the BASENAME
        if [[ "$item_basename" == $pattern ]]; then
            return 1 # Skip it
        fi
    done

    # === Default: Process ===
    # If none of the above rules caused it to be skipped or explicitly included, process it.
    return 0 # Process it
}

# --- Helper Function: Process a single file ---
process_file() {
    local file_path="$1"
    if [ -f "$file_path" ] && [ -r "$file_path" ]; then
        echo "<file path=\"$file_path\">"
        cat -- "$file_path"
        echo # Ensure newline
        echo "</file>"
    else
         echo "<!-- Warning: Could not read file '$file_path', skipping processing. -->" >&2
    fi
}

# --- Main Script Logic ---
# Capture all context XML output and pipe it to parse.sh
{
    echo "<context>"

    # Process each path argument from the command line individually.
    for path_arg in "${paths_to_process[@]}"; do
        if [ ! -e "$path_arg" ]; then
            echo "<!-- Warning: Path '$path_arg' does not exist, skipping. -->" >&2
            continue
        fi

        # First, check the top-level path itself. If it's ignored, skip the whole thing.
        if ! should_process "$path_arg"; then
            continue
        fi

        # If the argument is a file, process it directly.
        if [ -f "$path_arg" ]; then
            process_file "$path_arg"
        # If the argument is a directory, find all files within it RECURSIVELY.
        elif [ -d "$path_arg" ]; then
            # Build the prune arguments for find to exclude default directories.
            # This prevents 'find' from ever descending into them.
            find_prune_args=()
            # Start with a condition that is always false to simplify the loop.
            find_prune_args+=(-false)
            for pattern in "${default_exclude_patterns[@]}"; do
                find_prune_args+=(-o -name "$pattern")
            done

            # Use -prune to skip descending into ignored directories.
            # Then, find all files (-type f) in the remaining paths.
            # The should_process check is still needed for custom --include/--ignore rules.
            find "$path_arg" \( "${find_prune_args[@]}" \) -prune -o -type f -print0 | while IFS= read -r -d $'\0' file_in_dir; do
                # Check every single file found against ALL rules.
                if should_process "$file_in_dir"; then
                    process_file "$file_in_dir"
                fi
            done
        fi
    done

    echo "</context>"
} | "$PARSE_SCRIPT" # Pipe the entire captured output to parse.sh
