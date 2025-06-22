# UI and display functions for Bash FM

# This function expects a global array named 'items' to be set.
function display_ui() {
    clear
    echo -e "${COLOR_HEADER}--- Bash File Manager ---${COLOR_RESET}"
    echo -e "Current Directory: ${COLOR_HEADER}$(pwd)${COLOR_RESET}"
    echo

    # Display the items with numbers
    for i in "${!items[@]}"; do
        item_path="${items[$i]}"
        # Check if it's a directory or file to apply color
        if [[ -d "$item_path" ]]; then
            echo -e "  $i\t${COLOR_DIR}${item_path}/${COLOR_RESET}"
        else
            echo -e "  $i\t${COLOR_FILE}${item_path}${COLOR_RESET}"
        fi
    done
    echo
}

function display_help() {
    clear
    echo -e "${COLOR_HEADER}--- Help Menu ---${COLOR_RESET}"
    echo "Enter a command followed by a number from the list."
    echo
    echo "  [num]       - Navigate into the directory with that number."
    echo "  v [num]     - View the selected file using '$PAGER'."
    echo "  e [num]     - Edit the selected file using '$EDITOR'."
    echo "  c [num]     - Copy the selected file/directory."
    echo "  m [num]     - Move/Rename the selected file/directory."
    echo "  d [num]     - Delete the selected file/directory."
    echo "  n           - Create new file/directory."
    echo "  r [num]     - Rename file/directory."
    echo "  h           - Show this help menu."
    echo "  q           - Quit the file manager."
    echo
    read -n 1 -s -r -p "Press any key to continue..."
}