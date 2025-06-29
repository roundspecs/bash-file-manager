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
    local trash_dir="${HOME}/.bashfm_trash"
    local file_store="${trash_dir}/files"
    local meta_store="${trash_dir}/meta"

    mkdir -p "$file_store" "$meta_store"

    if [[ ! -e "$item" ]]; then
        echo -e "${COLOR_ERROR}Error: '$item' does not exist.${COLOR_RESET}"
        sleep 1.5
        return
    fi

    read -p "Move '$item' to Trash? [y/N]: " -r confirm
    if [[ "$confirm" =~ ^[yY](es)?$ ]]; then
        local timestamp=$(date +%s)
        local base=$(basename "$item")
        local trash_name="${base}_${timestamp}"
        local meta_file="${meta_store}/${trash_name}.info"

        mv "$item" "${file_store}/${trash_name}" && \
        echo "$(realpath "$item")" > "$meta_file" && \
        echo -e "Moved '${COLOR_FILE}$item${COLOR_RESET}' to Trash." || \
        echo -e "${COLOR_ERROR}Error moving item to Trash.${COLOR_RESET}"
    else
        echo "Deletion cancelled."
    fi
    sleep 1.5
}

function restore_from_trash() {
    local trash_dir="${HOME}/.bashfm_trash"
    local file_store="${trash_dir}/files"
    local meta_store="${trash_dir}/meta"

    mapfile -t items < <(ls "$file_store" 2>/dev/null)

    if [[ ${#items[@]} -eq 0 ]]; then
        echo "Trash is empty."
        sleep 1.5
        return
    fi

    echo -e "${COLOR_HEADER}--- Trash Contents ---${COLOR_RESET}"
    for i in "${!items[@]}"; do
        original_path=$(cat "${meta_store}/${items[$i]}.info" 2>/dev/null)
        echo -e "  $i\t${COLOR_FILE}${items[$i]}${COLOR_RESET} → ${original_path}"
    done

    echo
    read -p "Enter item number to restore: " -r index

    if ! [[ "$index" =~ ^[0-9]+$ && "$index" -lt "${#items[@]}" ]]; then
        echo -e "${COLOR_ERROR}Invalid selection.${COLOR_RESET}"
        sleep 1.5
        return
    fi

    local selected="${items[$index]}"
    local original_path
    original_path=$(cat "${meta_store}/${selected}.info" 2>/dev/null)

    read -p "Restore '${selected}' to '${original_path}'? [y/N]: " -r confirm
    if [[ "$confirm" =~ ^[yY](es)?$ ]]; then
        mkdir -p "$(dirname "$original_path")"
        mv "${file_store}/${selected}" "$original_path" && \
        rm "${meta_store}/${selected}.info" && \
        echo "Restored to $original_path"
    else
        echo "Restore cancelled."
    fi
    sleep 1.5
}

function empty_trash() {
    local trash_dir="${HOME}/.bashfm_trash"
    local file_store="${trash_dir}/files"
    local meta_store="${trash_dir}/meta"

    if [[ ! -d "$file_store" || -z "$(ls -A "$file_store")" ]]; then
        echo "Trash is already empty."
        sleep 1.5
        return
    fi

    read -p "Permanently delete all trash items? [y/N]: " -r confirm
    if [[ "$confirm" =~ ^[yY](es)?$ ]]; then
        rm -rf "$file_store"/* "$meta_store"/*
        echo "Trash emptied."
    else
        echo "Trash not emptied."
    fi
    sleep 1.5
}


function move_item() {
    local item="$1"
    read -p "Enter new path/name for '$item': " -r dest
    mv -iv "$item" "$dest" && echo "Moved/Renamed '$item' to '$dest'." || echo -e "${COLOR_ERROR}Error moving item.${COLOR_RESET}"
    sleep 2
}

function copy_item() {
    local item="$1"
    read -p "Enter destination path for '$item': " -r dest
    
    if [[ -d "$item" ]]; then
        cp -riv "$item" "$dest" && echo "Copied directory '$item' to '$dest'." || echo -e "${COLOR_ERROR}Error copying directory.${COLOR_RESET}"
    elif [[ -f "$item" ]]; then
        cp -iv "$item" "$dest" && echo "Copied file '$item' to '$dest'." || echo -e "${COLOR_ERROR}Error copying file.${COLOR_RESET}"
    else
        echo -e "${COLOR_ERROR}Error: '$item' does not exist.${COLOR_RESET}"
    fi
    sleep 2
}

function create_item() {
    echo -e "${COLOR_PROMPT}Create:${COLOR_RESET}"
    echo -e "  1. File"
    echo -e "  2. Directory"
    read -p "Select type (1-2): " type_choice

    read -p "Enter name/path: " path

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

function search_items() {
    echo -e "${COLOR_PROMPT}Search Options:${COLOR_RESET}"
    echo -e "  1. Search by name (current directory)"
    echo -e "  2. Search by name (recursive)"
    echo -e "  3. Search by content (files only)"
    echo -e "  4. Search by file type/extension"
    read -p "Select search type (1-4): " search_type    read -p "Enter search term: " search_term

    if [[ -z "$search_term" ]]; then
        echo -e "${COLOR_ERROR}Error: Search term cannot be empty.${COLOR_RESET}"
        sleep 1.5
        return
    fi

    echo -e "${COLOR_HEADER}--- Search Results ---${COLOR_RESET}"
    
    case "$search_type" in
    1)
        # Search by name in current directory only
        find . -maxdepth 1 -iname "*${search_term}*" -not -path "." | while read -r item; do
            if [[ -d "$item" ]]; then
                echo -e "  ${COLOR_DIR}${item}/${COLOR_RESET}"
            else
                echo -e "  ${COLOR_FILE}${item}${COLOR_RESET}"
            fi
        done
        ;;
    2)
        # Search by name recursively
        find . -iname "*${search_term}*" -not -path "." | while read -r item; do
            if [[ -d "$item" ]]; then
                echo -e "  ${COLOR_DIR}${item}/${COLOR_RESET}"
            else
                echo -e "  ${COLOR_FILE}${item}${COLOR_RESET}"
            fi
        done
        ;;
    3)
        # Search by content in files
        echo "Searching file contents..."
        grep -r -l -i "$search_term" . 2>/dev/null | while read -r item; do
            echo -e "  ${COLOR_FILE}${item}${COLOR_RESET}"
        done
        ;;
    4)
        # Search by file type/extension
        echo "Searching by file type/extension..."
        # Add dot if not present for extension search
        if [[ ! "$search_term" =~ ^\. ]]; then
            search_pattern="*.${search_term}"
        else
            search_pattern="*${search_term}"
        fi
        
        find . -type f -iname "$search_pattern" | while read -r item; do
            echo -e "  ${COLOR_FILE}${item}${COLOR_RESET}"
        done
        
        # Also show common file type examples if no results
        if [[ ! $(find . -type f -iname "$search_pattern" | head -1) ]]; then
            echo -e "${COLOR_ERROR}No files found with extension '${search_term}'.${COLOR_RESET}"
            echo -e "${COLOR_PROMPT}Examples: txt, pdf, jpg, mp3, sh, py, etc.${COLOR_RESET}"
        fi
        ;;
    *)
        echo -e "${COLOR_ERROR}Invalid search type.${COLOR_RESET}"
        sleep 1.5
        return
        ;;
    esac
    
    echo
    read -n 1 -s -r -p "Press any key to continue..."
}

function sort_items() {
    echo -e "${COLOR_PROMPT}Sort Options:${COLOR_RESET}"
    echo -e "  1. Sort by name (A-Z)"
    echo -e "  2. Sort by name (Z-A)"
    echo -e "  3. Sort by size (smallest first)"
    echo -e "  4. Sort by size (largest first)"
    echo -e "  5. Sort by date modified (oldest first)"
    echo -e "  6. Sort by date modified (newest first)"
    echo -e "  7. Sort by type (directories first)"
    read -p "Select sort type (1-7): " sort_type

    case "$sort_type" in
    1)
        # Sort by name A-Z
        mapfile -t items < <(ls -1 | sort)
        ;;
    2)
        # Sort by name Z-A
        mapfile -t items < <(ls -1 | sort -r)
        ;;
    3)
        # Sort by size (smallest first)
        mapfile -t items < <(ls -1S -r)
        ;;
    4)
        # Sort by size (largest first)
        mapfile -t items < <(ls -1S)
        ;;
    5)
        # Sort by date modified (oldest first)
        mapfile -t items < <(ls -1t -r)
        ;;
    6)
        # Sort by date modified (newest first)
        mapfile -t items < <(ls -1t)
        ;;
    7)
        # Sort by type (directories first)
        mapfile -t items < <(ls -1 --group-directories-first 2>/dev/null || (ls -1 | grep '/$'; ls -1 | grep -v '/$'))
        ;;
    *)
        echo -e "${COLOR_ERROR}Invalid sort option.${COLOR_RESET}"
        sleep 1.5
        return
        ;;
    esac
    
    echo -e "${COLOR_HEADER}Items sorted successfully.${COLOR_RESET}"
    sleep 1
}
