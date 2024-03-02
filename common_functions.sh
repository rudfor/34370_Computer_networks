#!/usr/bin/env bash

# Set default verbosity level
verbosity=0
# Counter variable
counter=0

# Function to increment the counter
increment_counter() {
    counter=$((counter + 1))
}
# Function to print messages based on verbosity level
print_message() {
    local message="$1"
    local level="$2"
    local run_increment="${3:-true}"  # Use true as default if the third argument is not provided

    # Check if verbosity is greater than or equal to the specified level
    if [ "$verbosity" -ge "$level" ]; then
        echo "$message"
        # Check if the third argument is set to true, then run the function
        if [ "$run_increment" = true ]; then
            # Replace the following line with the actual function you want to run
            increment_counter
        fi
    fi
}

# Parse command-line arguments for verbosity
while getopts ":v" opt; do
    case $opt in
        v)  verbosity=$((verbosity + 1))
            ;;
        \?) echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
    esac
done

# Example messages at different verbosity levels
print_message "This is a low verbosity message" 1 false
print_message "This is a medium verbosity message" 2 false
print_message "This is a high verbosity message" 3 false