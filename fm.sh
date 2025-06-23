#!/bin/bash

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

source "${SCRIPT_DIR}/config.sh"
source "${SCRIPT_DIR}/lib/ui.sh"
source "${SCRIPT_DIR}/lib/actions.sh"

while true; do

    items=("..")
    for item in * .*; do
        [[ "$item" == "." || "$item" == ".." ]] && continue
        items+=("$item")
    done

    display_ui

    echo
    echo -e "${COLOR_PROMPT}Available Actions:${COLOR_RESET}"
    echo -e "  [num]   - Navigate into item"
    echo -e "  v [num] - View item"
    echo -e "  e [num] - Edit item"
    echo -e "  c [num] - Copy item"
    echo -e "  m [num] - Move item"
    echo -e "  d [num] - Delete item"
    echo "  n          - Create new file/directory."
    echo "  r [num]    - Rename file/directory."
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
        ;;
    n | new)
        create_item
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
