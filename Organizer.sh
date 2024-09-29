#!/bin/bash 
# This Script Was Built by Essam Qsous 
# This script helps organize and filter outputs from large files based on specific patterns like domains, subdomains, or paths.

# Function to show usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -f                Read: One or more files that you want to read from, separated by spaces"
    echo "  -g                Grep: What do you want to filter on, example: api or multiple examples: 'api aspx'"
    echo "  -u                Unique: Remove duplicates"
    echo "  -o                Output: Add the result into a new file"
    echo "  -d                Filter domains"
    echo "  -s                Filter subdomains"
    echo "  -p                Filter paths" 
    echo "  -x                Exclude results containing a specific word or multiple examples: 'js url'"
}

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -f) files="$2"; shift ;;
        -g) grep="$2"; shift ;;
        -u) unique=true ;;
        -o) output="$2"; shift ;;
        -d) filter_type="domains" ;;
        -s) filter_type="subdomains" ;;
        -p) filter_type="paths" ;;
        -x) exclude="$2"; shift ;;
        *) echo "Unknown parameter: $1"; usage; exit 1 ;;
    esac
    shift
done 

# Function to read multiple files from the command line 
read_cat() { 
    if [[ -z "$files" ]]; then
        echo "Error: No files specified."
        usage
        exit 1
    fi
    
    echo "Reading the files now..."
    # Initialize cat_file as an empty string
    cat_file=""
    
    # Read content from each file and append to cat_file
    for file in $files; do
        if [[ -f "$file" ]]; then
            echo "Reading from file: $file"
            cat_file+=$(cat "$file")
            cat_file+=$'\n'  # Add a newline between file contents
        else
            echo "File not found: $file"
        fi
    done
}

# Function to filter content based on domain, subdomain, or path
filter_by_type() {
    case $filter_type in
        domains)
            echo "Filtering domains..."
            filtered_content=$(echo "$cat_file" | grep --color=always -oP '(https?://)([a-zA-Z0-9-]+\.)*[a-zA-Z0-9-]+\.[a-z]{2,}')
            filtered_content=$(echo "$filtered_content" | sed -E 's|(https?://)([a-zA-Z0-9-]+\.)*([a-zA-Z0-9-]+\.[a-z]{2,})|\1\3|')
            ;;
        subdomains)
            echo "Filtering subdomains..."
            filtered_content=$(echo "$cat_file" | grep --color=always -oP '(https?://[a-zA-Z0-9.-]+\.[a-z]{2,})')
            ;;
        paths)
            echo "Filtering paths..."
            filtered_content=$(echo "$cat_file" | grep --color=always -oP 'https?://[a-zA-Z0-9.-]+/\K.*')
            ;;
        *)
            filtered_content="$cat_file"
            ;;
    esac
}

# Function to filter the file content using grep if a search term is provided
filter_grep() {
    if [[ -n "$grep" ]]; then
        echo "Filtering content by: $grep..."
        echo "========================================"
        
        # Combine the keywords into a single pattern separated by '|'
        grep_pattern=$(echo "$grep" | sed 's/ /|/g')
        
        # Use sed with the combined pattern
        filtered_content=$(echo "$filtered_content" | grep --color=always -Ei "$grep_pattern")
    fi
}

# Function to remove duplicates if the unique flag is set
remove_duplicates() {
    if [[ "$unique" == true ]]; then
        echo "Removing duplicates..."
        filtered_content=$(echo "$filtered_content" | sort | uniq)
    fi
}

# Function to exclude results based on a specific word
exclude_word() {
    if [[ -n "$exclude" ]]; then
        echo "Excluding lines that contain any of: '$exclude'..."
        echo "=============================="
        # Split the 'exclude' variable into an array of keywords
        IFS=', ' read -r -a exclude_keywords <<< "$exclude"
        
        # Loop through each keyword and exclude lines containing it
        for keyword in "${exclude_keywords[@]}"; do
            filtered_content=$(echo "$filtered_content" | grep -v "$keyword")
        done
    fi
}

# Function to save output to a file if specified
save_output() {
    if [[ -n "$output" ]]; then
        echo "Saving output to $output..."
        echo "$filtered_content" > "$output"
    else
        echo "$filtered_content"
    fi
}

# Main function execution
if [[ -n "$files" ]]; then
    read_cat
    filter_by_type
    exclude_word
    filter_grep
    remove_duplicates
    save_output
else
    echo "Error: Missing required parameters."
    usage
    exit 1
fi
