#!/bin/bash

STATE_RUNNING="running"
STATE_OFF="poweroff"

machineId=0
isProvision=0

read_data() {
    isProvision=0
    count=0
    while IFS= read -r line; do
        if [[ "$line" != *[![:space:]]* ]]; then
            break
        fi
        count=$((count + 1))
        eval "id$count=$(echo $line | awk '{print $1}')"
        eval "status$count=$(echo $line | awk '{print $4}')"
#        eval "location$count=$(echo $line | awk '{$1=$2=$3=$4=""; print $0}')"
#        location="$("$line" | awk '{$1=$2=$3=$4=""; print $0}')"
        eval "location$count=$(echo "$line" | awk '{print $NF}')"
#        eval "location$count=${location}"
    done < <(vagrant global-status | tail -n +3)
    main_menu
}

main_menu() {
    echo
    echo "There are $count machines"
    for ((i=1; i<=count; i++)); do
        eval echo "$i. \${id$i} \${status$i} \${location$i}"
    done
    echo
    echo "1. Choice Machine"
    echo "2. Refresh"
    echo "3. Halt all"
    echo "4. Halt all and shutdown"
    echo "5. Terminate"
    first_choice
}

first_choice() {
    read -p "Command: " choice
    case $choice in
        1) choice_machine ;;
        2) refresh_all ;;
        3) shutdown_all ;;
        4) shutdown_computer ;;
        5) end ;;
        *) first_choice ;;
    esac
}

refresh_all() {
    for ((i=1; i<=count; i++)); do
        eval vagrant status \${id$i}
    done
    read_data
}

shutdown_all() {
    for ((i=1; i<=count; i++)); do
        eval vagrant halt \${id$i}
    done
    read_data
}

shutdown_computer() {
    for ((i=1; i<=count; i++)); do
        eval vagrant halt \${id$i}
    done
    echo
    echo "DANGER, PREPARE TO SHUTDOWN"
    read -t 10 -p "Press any key except [1] to cancel: " -n 1 -r
    if [[ $REPLY != 1 ]]; then
        echo "Shutdown canceled."
        read_data
    else
        shutdown -h +20s
    fi
}

end() {
    exit 0
}

choice_machine() {
    read -p "Machine: " choice
    eval machineId=\${id$choice}
    if [[ -z $machineId ]]; then
        choice_machine
    else
        echo
        eval echo "Machine \${id$choice} \${status$choice} \${location$choice}"
        echo "1. Start machine"
        echo "2. SSH machine"
        echo "3. Restart machine"
        echo "4. Refresh"
        echo "5. Halt machine"
        echo "0. Back"
        choice_command
    fi
}

choice_command() {
    read -p "Your choice: " choice
    case $choice in
        1) provision; start_machine ;;
        2) ssh_machine ;;
        3) provision; restart_machine ;;
        4) refresh_machine ;;
        5) halt_machine ;;
        0) main_menu ;;
        *) choice_command ;;
    esac
}

provision() {
    echo
    echo "1. Normal boot"
    echo "2. Provision"
    read -p "Your choice: " provision
    case $provision in
        1) isProvision=0 ;;
        2) isProvision=1 ;;
        *) provision ;;
    esac
}

refresh_machine() {
    refresh_command $machineId
    read_data
}

start_machine() {
    start_command $machineId
    read_data
}

halt_machine() {
    halt_command $machineId
    read_data
}

ssh_machine() {
    get_machine_state $machineId
    if [[ $machineState == $STATE_RUNNING ]]; then
        ssh_command $machineId
    elif [[ $machineState == $STATE_OFF ]]; then
        echo "Try to start machine before ssh"
        start_command $machineId
        ssh_command $machineId
    else
        echo "Machine state is not valid: $machineState"
    fi
    read_data
}

restart_machine() {
    reload_command $machineId
    read_data
}

get_machine_state() {
    while IFS= read -r line; do
        if [[ "$line" != *[![:space:]]* ]]; then
            break
        fi
        machineState=$(echo "$line" | awk '{print $2}')
    done < <(vagrant status "$1" | tail -n +3)
}

refresh_command() {
    vagrant status "$1"
}

start_command() {
    if [[ $isProvision -eq 1 ]]; then
        vagrant up "$1" --provision
    else
        vagrant up "$1"
    fi
}

reload_command() {
    if [[ $isProvision -eq 1 ]]; then
        vagrant reload "$1" --provision
    else
        vagrant reload "$1"
    fi
}

ssh_command() {
    vagrant ssh "$1"
}

halt_command() {
    vagrant halt "$1"
}

read_data
