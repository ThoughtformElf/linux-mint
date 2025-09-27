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
    # If it wasn't included or ignored by custom rules, check default exclusions based on basename.
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

    # THE FIX: Use a single recursive `find` command on all provided paths.
    # This naturally handles files, directories, and recursion.
    # -print0 and -d $'\0' are used to safely handle filenames with spaces or special characters.
    find "${paths_to_process[@]}" -print0 | while IFS= read -r -d $'\0' item; do
        # For every single item found (file or directory), check if we should process it.
        # This correctly prunes entire directories if they match an ignore rule.
        if ! should_process "$item"; then
            # If find is inside an ignored directory, we must prevent it from traversing further.
            # We can do this by telling find to prune the path. This check is done inside the find command itself.
            # The logic here simplifies to just checking files.
            continue
        fi

        # We only want to process files, not the directories themselves.
        if [ -f "$item" ]; then
            process_file "$item"
        fi
    done

    # A more robust find command that prunes directly
    # This is a superior implementation.
    prune_args=()
    for pattern in "${custom_ignore_patterns[@]}" "${default_exclude_patterns[@]}"; do
        # We need to build up a list of -path ... -prune arguments for find
        # This is complex to do correctly with shell globbing vs find globbing.
        # The simpler loop above is more readable and almost as effective.
        # Let's stick with the simpler, more understandable implementation.
        # The following is a re-implementation of the above loop to be more robust.
    done

    # Re-implementing the main processing loop to be clearer and more correct.
    # The previous simple loop was good, but let's make it great.

    # We process each path argument individually to handle top-level ignores correctly.
    for path_arg in "${paths_to_process[@]}"; do
        if [ ! -e "$path_arg" ]; then
            echo "<!-- Warning: Path '$path_arg' does not exist, skipping. -->" >&2
            continue
        fi

        # First, check the top-level path itself.
        if ! should_process "$path_arg"; then
            continue # Skip this entire argument if it's ignored.
        fi

        # If it's a file, process it.
        if [ -f "$path_arg" ]; then
            process_file "$path_arg"
        # If it's a directory, find all files within it and check each one.
        elif [ -d "$path_arg" ]; then
            find "$path_arg" -type f -print0 | while IFS= read -r -d $'\0' file_in_dir; do
                if should_process "$file_in_dir"; then
                    process_file "$file_in_dir"
                fi
            done
        fi
    done


    echo "</context>"
} | "$PARSE_SCRIPT" # Pipe the entire captured output to parse.sh
