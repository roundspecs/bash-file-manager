#!/bin/bash

# Configuration
EDITOR=${EDITOR:-nano}
PAGER=${PAGER:-less}

COLOR_RESET='\033[0m'
COLOR_DIR='\033[1;34m'
COLOR_FILE='\033[0m'
COLOR_HEADER='\033[1;32m'
COLOR_PROMPT='\033[1;36m'
COLOR_ERROR='\033[1;31m'

# UI Functions
function display_ui() {
    clear
    echo -e "${COLOR_HEADER}--- Bash File Manager ---${COLOR_RESET}"
    echo -e "Current Directory: ${COLOR_HEADER}$(pwd)${COLOR_RESET}"
    echo

    for i in "${!items[@]}"; do
        item_path="${items[$i]}"

        if [[ -d "$item_path" ]]; then
            echo -e "  $i\t${COLOR_DIR}${item_path}/${COLOR_RESET}"
        elif [[ -f "$item_path" ]]; then
            # Get file size in human readable format
            if command -v stat >/dev/null 2>&1; then
                # Use stat for better cross-platform compatibility
                if [[ "$OSTYPE" == "darwin"* ]]; then
                    # macOS stat format
                    file_size=$(stat -f%z "$item_path" 2>/dev/null | numfmt --to=iec-i --suffix=B 2>/dev/null || stat -f%z "$item_path" 2>/dev/null || echo "0")
                    # Get modification date for macOS
                    file_date=$(stat -f%Sm -t "%Y-%m-%d %H:%M" "$item_path" 2>/dev/null || echo "Unknown")
                else
                    # Linux stat format
                    file_size=$(stat -c%s "$item_path" 2>/dev/null | numfmt --to=iec-i --suffix=B 2>/dev/null || stat -c%s "$item_path" 2>/dev/null || echo "0")
                    # Get modification date for Linux
                    file_date=$(stat -c%y "$item_path" 2>/dev/null | cut -d'.' -f1 | sed 's/\([0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}\) \([0-9]\{2\}:[0-9]\{2\}\).*/\1 \2/' || echo "Unknown")
                fi
            else
                # Fallback using ls
                file_size=$(ls -lh "$item_path" 2>/dev/null | awk '{print $5}' || echo "0")
                file_date=$(ls -l "$item_path" 2>/dev/null | awk '{print $6, $7, $8}' || echo "Unknown")
            fi
            
            # Format the display with size and date
            printf "  %s\t${COLOR_FILE}%-25s${COLOR_RESET} %8s  %s\n" "$i" "$item_path" "$file_size" "$file_date"
        else
            # Special files (links, etc.)
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
    echo "  s           - Search items (by name, content, or type)."
    echo "  o           - Sort items (by name, size, date, type). Use 'o 0' to reset."
    echo "  t           - Manage trash (restore/empty)."
    echo "  h           - Show this help menu."
    echo "  q           - Quit the file manager."
    echo
    read -n 1 -s -r -p "Press any key to continue..."
}

# Action Functions
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
    read -p "Select search type (1-4): " search_type

    read -p "Enter search term: " search_term

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
    echo -e "  0. Reset to default"
    read -p "Select sort type (0-7): " sort_type

    case "$sort_type" in
    0)
        # Reset sorting
        export SORT_MODE=""
        echo -e "${COLOR_HEADER}Sort reset to default.${COLOR_RESET}"
        ;;
    1)
        # Sort by name A-Z
        export SORT_MODE="name_asc"
        echo -e "${COLOR_HEADER}Items will be sorted by name (A-Z).${COLOR_RESET}"
        ;;
    2)
        # Sort by name Z-A
        export SORT_MODE="name_desc"
        echo -e "${COLOR_HEADER}Items will be sorted by name (Z-A).${COLOR_RESET}"
        ;;
    3)
        # Sort by size (smallest first)
        export SORT_MODE="size_asc"
        echo -e "${COLOR_HEADER}Items will be sorted by size (smallest first).${COLOR_RESET}"
        ;;
    4)
        # Sort by size (largest first)
        export SORT_MODE="size_desc"
        echo -e "${COLOR_HEADER}Items will be sorted by size (largest first).${COLOR_RESET}"
        ;;
    5)
        # Sort by date modified (oldest first)
        export SORT_MODE="date_asc"
        echo -e "${COLOR_HEADER}Items will be sorted by date (oldest first).${COLOR_RESET}"
        ;;
    6)
        # Sort by date modified (newest first)
        export SORT_MODE="date_desc"
        echo -e "${COLOR_HEADER}Items will be sorted by date (newest first).${COLOR_RESET}"
        ;;
    7)
        # Sort by type (directories first)
        export SORT_MODE="type"
        echo -e "${COLOR_HEADER}Items will be sorted by type (directories first).${COLOR_RESET}"
        ;;
    *)
        echo -e "${COLOR_ERROR}Invalid sort option.${COLOR_RESET}"
        sleep 1.5
        return
        ;;
    esac
    
    sleep 1.5
}

function apply_sort() {
    local sort_mode="$1"
    
    if [[ -z "$sort_mode" ]]; then
        return 0
    fi
    
    case "$sort_mode" in
    "name_asc")
        mapfile -t sorted_items < <(printf '%s\n' "${items[@]:1}" | sort)
        ;;
    "name_desc")
        mapfile -t sorted_items < <(printf '%s\n' "${items[@]:1}" | sort -r)
        ;;
    "size_asc")
        mapfile -t sorted_items < <(ls -1Sr 2>/dev/null | grep -v '^total$' || printf '%s\n' "${items[@]:1}")
        ;;
    "size_desc")
        mapfile -t sorted_items < <(ls -1S 2>/dev/null | grep -v '^total$' || printf '%s\n' "${items[@]:1}")
        ;;
    "date_asc")
        mapfile -t sorted_items < <(ls -1tr 2>/dev/null | grep -v '^total$' || printf '%s\n' "${items[@]:1}")
        ;;
    "date_desc")
        mapfile -t sorted_items < <(ls -1t 2>/dev/null | grep -v '^total$' || printf '%s\n' "${items[@]:1}")
        ;;
    "type")
        if command -v ls --group-directories-first >/dev/null 2>&1; then
            mapfile -t sorted_items < <(ls -1 --group-directories-first 2>/dev/null | grep -v '^total$')
        else
            # Fallback for systems without --group-directories-first
            mapfile -t dirs < <(printf '%s\n' "${items[@]:1}" | while read -r item; do [[ -d "$item" ]] && echo "$item"; done | sort)
            mapfile -t files < <(printf '%s\n' "${items[@]:1}" | while read -r item; do [[ -f "$item" ]] && echo "$item"; done | sort)
            sorted_items=("${dirs[@]}" "${files[@]}")
        fi
        ;;
    *)
        return 1
        ;;
    esac
    
    # Rebuild items array with ".." at the beginning
    items=(".." "${sorted_items[@]}")
}

while true; do

    items=("..")
    for item in * .*; do
        [[ "$item" == "." || "$item" == ".." ]] && continue
        items+=("$item")
    done

    # Apply sorting if a sort mode is set
    if [[ -n "$SORT_MODE" ]]; then
        apply_sort "$SORT_MODE"
    fi

    display_ui

    #echo    echo -e "${COLOR_PROMPT}Available Actions:${COLOR_RESET}"
    echo -e "  [num]   - Navigate into item"
    echo -e "  v [num] - View item"
    echo -e "  e [num] - Edit item"
    echo -e "  c [num] - Copy item"
    echo -e "  m [num] - Move item"
    echo -e "  d [num] - Delete item"
    echo "  n       - Create new file/directory."
    echo "  r [num] - Rename file/directory."
    echo "  s       - Search items (by name, content, or type)."
    echo "  o       - Sort items (by name, size, date, type). Use 'o 0' to reset."
    echo "  t       - Manage trash (restore/empty)"
    echo -e "  h       - Help"
    echo -e "  q       - Quit"
    echo
    read -e -p "$(echo -e "${COLOR_PROMPT}Enter command or number: ${COLOR_RESET}")" -r input
    input="${input//[$'\t\r\n']/}"

    command=$(echo "$input" | cut -d' ' -f1)
    index=$(echo "$input" | cut -d' ' -f2)

    case "$command" in
    q | quit | exit)
        echo "Exiting File Manager. Goodbye!"
        break
        ;;
    h | help)
        display_help
        ;;    n | new)
        create_item
        ;;
    s | search)
        search_items
        ;;
    o | sort)
        sort_items
        ;;
    t | trash)
        echo -e "${COLOR_PROMPT}Trash Management:${COLOR_RESET}"
        echo -e "  1. Restore items from trash"
        echo -e "  2. Empty trash"
        read -p "Select option (1-2): " trash_choice
        case "$trash_choice" in
        1) restore_from_trash ;;
        2) empty_trash ;;
        *) echo -e "${COLOR_ERROR}Invalid choice.${COLOR_RESET}"; sleep 1.5 ;;
        esac
        ;;
    *)
        if [[ "$command" =~ ^[0-9]+$ ]]; then
            index="$command"
            command="nav"
        fi

        if ! [[ "$index" =~ ^[0-9]+$ && "$index" -lt "${#items[@]}" ]]; then
            echo -e "${COLOR_ERROR}Error: Invalid number.${COLOR_RESET}"
            sleep 1.5
            continue
        fi

        selected_item="${items[$index]}"

        case "$command" in
        nav) navigate_to "$selected_item" ;;
        v | view) view_item "$selected_item" ;;
        e | edit) edit_item "$selected_item" ;;
        d | delete) delete_item "$selected_item" ;;
        r | rename)
            if [[ "$index" =~ ^[0-9]+$ && "$index" -lt "${#items[@]}" ]]; then
                rename_item "${items[$index]}"
            else
                echo -e "${COLOR_ERROR}Error: Invalid selection for rename.${COLOR_RESET}"
                sleep 1.5
            fi
            ;;
        c | copy) copy_item "$selected_item" ;;
        m | move) move_item "$selected_item" ;;
        *)
            echo -e "${COLOR_ERROR}Error: Unknown command '$command'. Type 'h' for help.${COLOR_RESET}"
            sleep 1.5
            ;;
        esac
        ;;
    esac
done
