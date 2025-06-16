#!/bin/bash
# Bash FM - A simple, terminal-based file manager

# Find the script's own directory
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

# Source the configuration and function libraries
source "${SCRIPT_DIR}/config.sh"
source "${SCRIPT_DIR}/lib/ui.sh"
source "${SCRIPT_DIR}/lib/actions.sh"

# --- Main Application Loop ---
while true; do
    # 1. Populate the items array
    items=("..")
    for item in * .*; do
        [[ "$item" == "." || "$item" == ".." ]] && continue
        items+=("$item")
    done

    # 2. Display the UI
    display_ui

    # 3. Get user input
    echo -e "${COLOR_PROMPT}Actions: [num] to navigate, (v)iew, (e)dit, (c)opy, (m)ove, (d)elete, (h)elp, (q)uit${COLOR_RESET}"
    read -p "Your choice: " -r input

    # 4. Parse the input
    command=$(echo "$input" | cut -d' ' -f1)
    index=$(echo "$input" | cut -d' ' -f2)

    # 5. Process the command
    case "$command" in
        q|quit|exit)
            echo "Exiting File Manager. Goodbye!"
            break
            ;;
        h|help)
            display_help
            ;;
        *)
            # Handle commands that require an index (like 'v 5' or just '5')
            if [[ "$command" =~ ^[0-9]+$ ]]; then
                index="$command"
                command="nav" # Default action for a number is navigate
            fi

            # Validate index
            if ! [[ "$index" =~ ^[0-9]+$ && "$index" -lt "${#items[@]}" ]]; then
                echo -e "${COLOR_ERROR}Error: Invalid number.${COLOR_RESET}"
                sleep 1.5
                continue
            fi
            
            selected_item="${items[$index]}"

            case "$command" in
                nav) navigate_to "$selected_item" ;;
                v|view) view_item "$selected_item" ;;
                e|edit) edit_item "$selected_item" ;;
                d|delete) delete_item "$selected_item" ;;
                c|copy) copy_item "$selected_item" ;;
                m|move) move_item "$selected_item" ;;
                *)
                    echo -e "${COLOR_ERROR}Error: Unknown command '$command'. Type 'h' for help.${COLOR_RESET}"
                    sleep 1.5
                    ;;
            esac
            ;;
    esac
done
