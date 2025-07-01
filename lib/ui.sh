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
