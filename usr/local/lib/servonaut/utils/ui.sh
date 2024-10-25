#!/bin/bash

select_option() {
    # Arguments: title, description, array of options
    local title="$1"
    local description="$2"
    shift 2
    local options=("$@")

    # Helper functions for terminal control
    ESC=$(printf "\033")
    cursor_blink_on() { printf "$ESC[?25h"; }
    cursor_blink_off() { printf "$ESC[?25l"; }
    cursor_to() { printf "$ESC[$1;${2:-1}H"; }
    print_option() { printf "   $1"; }
    print_selected() { printf "\033[36m ❯ $1\033[0m"; }
    get_cursor_row() {
        IFS=';' read -sdR -p $'\E[6n' ROW COL
        echo ${ROW#*[}
    }

    # Clear screen and print header
    clear
    echo "$title"
    echo "$description"
    echo ""

    # Print initial empty lines
    for opt in "${options[@]}"; do printf "\n"; done

    # Get cursor position
    lastrow=$(get_cursor_row)
    startrow=$((lastrow - ${#options[@]}))

    # Ensure cursor is restored on ctrl+c
    trap "cursor_blink_on; stty echo; printf '\n'; exit" 2
    cursor_blink_off

    local selected=0
    while true; do
        # Print options
        local idx=0
        for opt in "${options[@]}"; do
            cursor_to $((startrow + idx))
            if [ $idx -eq $selected ]; then
                print_selected "$opt"
            else
                print_option "$opt"
            fi
            ((idx++))
        done

        # Read key input
        read -sn1 key
        case $key in
        $'\x1B')
            read -sn1 -t1 key
            if [ "$key" = "[" ]; then
                read -sn1 -t1 key
                case $key in
                A) # Up arrow
                    ((selected--))
                    [ $selected -lt 0 ] && selected=$((${#options[@]} - 1))
                    ;;
                B) # Down arrow
                    ((selected++))
                    [ $selected -ge ${#options[@]} ] && selected=0
                    ;;
                esac
            fi
            ;;
        "") # Enter
            break
            ;;
        esac
    done

    # Restore cursor
    cursor_to $lastrow
    printf "\n"
    cursor_blink_on

    # Return selected index
    return $selected
}
