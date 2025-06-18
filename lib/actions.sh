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

function create_item() {
    echo -e "${COLOR_PROMPT}Create:${COLOR_RESET}"
    echo -e "  1. File"
    echo -e "  2. Directory"
    read -p "Select type (1-2): " type_choice

    read -p "Enter name/path: " path

    # Handle WSL Windows paths warning
    if [[ "$path" == /mnt/[a-z]* ]]; then
        echo -e "${COLOR_ERROR}Warning: Modifying Windows files from WSL.${COLOR_RESET}"
    fi

    case "$type_choice" in
        1)
            if [ -e "$path" ]; then
                echo -e "${COLOR_ERROR}Error: '$path' already exists.${COLOR_RESET}"
            else
                touch "$path" && echo -e "Created file: ${COLOR_FILE}$path${COLOR_RESET}"
            fi
            ;;
        2)
            if [ -d "$path" ]; then
                echo -e "${COLOR_ERROR}Error: Directory '$path' already exists.${COLOR_RESET}"
            else
                mkdir -p "$path" && echo -e "Created directory: ${COLOR_DIR}$path${COLOR_RESET}/"
            fi
            ;;
        *)
            echo -e "${COLOR_ERROR}Invalid choice.${COLOR_RESET}"
            ;;
    esac
    sleep 1.5
}

function rename_item() {
    local old_path="$1"
    if [ ! -e "$old_path" ]; then
        echo -e "${COLOR_ERROR}Error: '$old_path' does not exist.${COLOR_RESET}"
        sleep 1.5
        return
    fi

    read -p "Enter new name/path: " new_path

    # WSL path warning
    if [[ "$old_path" == /mnt/[a-z]* || "$new_path" == /mnt/[a-z]* ]]; then
        echo -e "${COLOR_ERROR}Warning: Modifying Windows files from WSL.${COLOR_RESET}"
    fi

    mv -i "$old_path" "$new_path" 2>/dev/null
    if [ $? -eq 0 ]; then
        echo -e "Renamed: ${COLOR_FILE}$old_path${COLOR_RESET} → ${COLOR_FILE}$new_path${COLOR_RESET}"
    else
        echo -e "${COLOR_ERROR}Error: Failed to rename. Check permissions.${COLOR_RESET}"
    fi
    sleep 1.5
}