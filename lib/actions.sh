# lib/actions.sh
# Action handler functions for Bash FM

function navigate_to() {
    local item="$1"
    if [[ -d "$item" ]]; then
        cd "$item" || echo -e "${COLOR_ERROR}Error: Could not enter directory.${COLOR_RESET}"
    else
        echo -e "${COLOR_ERROR}Error: '$item' is not a directory. Use 'v' to view or 'e' to edit.${COLOR_RESET}"
        sleep 2
    fi
}

function view_item() {
    local item="$1"
    if [[ -f "$item" ]]; then
        "$PAGER" "$item"
    else
        echo -e "${COLOR_ERROR}Error: Cannot view a directory.${COLOR_RESET}"
        sleep 1.5
    fi
}

function edit_item() {
    local item="$1"
    if [[ -f "$item" ]]; then
        "$EDITOR" "$item"
    else
        echo -e "${COLOR_ERROR}Error: Cannot edit a directory.${COLOR_RESET}"
        sleep 1.5
    fi
}

function delete_item() {
    local item="$1"
    read -p "Are you sure you want to delete '$item'? [y/N]: " -r confirm
    if [[ "$confirm" =~ ^[yY](es)?$ ]]; then
        rm -rf "$item" && echo "Deleted '$item'." || echo -e "${COLOR_ERROR}Error deleting item.${COLOR_RESET}"
    else
        echo "Deletion cancelled."
    fi
    sleep 1.5
}

function copy_item() {
    local item="$1"
    read -p "Enter destination path for copy: " -r dest
    # The -i flag prompts for overwrite, -r is recursive for directories
    cp -irv "$item" "$dest" && echo "Copied '$item' to '$dest'." || echo -e "${COLOR_ERROR}Error copying item.${COLOR_RESET}"
    sleep 2
}

function move_item() {
    local item="$1"
    read -p "Enter new path/name for '$item': " -r dest
    mv -iv "$item" "$dest" && echo "Moved/Renamed '$item' to '$dest'." || echo -e "${COLOR_ERROR}Error moving item.${COLOR_RESET}"
    sleep 2
}
