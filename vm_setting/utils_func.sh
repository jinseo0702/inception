#!/bin/bash


ENTER(){
    VBoxManage controlvm "$VM_NAME" keyboardputscancode 1c 9c
    sleep 0.5
}

#https://wikidocs.net/215602
progress_bar(){
    local duration=$1
    local width=80
    local char="#"
    local empty="-"
    local startTime=$(date +%s)
    local endTime=$((startTime + duration))
    local currentTime

    tput civis

    while [ "$(date +%s)" -lt "$endTime" ]; do
        currentTime=$(date +%s)
        local elapsedTime=$((currentTime - startTime))
        # proportion=$((duration / 100)) 이부분이 원래는 10 /100 = 100이 되어서 error가 발생했는데 고쳐습니다.
        local percent=$((elapsedTime * 100 / duration))
        local filledWidth=$((width * percent / 100))
        local emptyWidth=$((width - filledWidth))

        local progress_bar=""
        for ((i=0; i<filledWidth; i++)); do
            progress_bar+="$char"
        done
        for ((i=0; i<emptyWidth; i++)); do
            progress_bar+="$empty"
        done
        echo -ne "\r ["$progress_bar"] "$percent"% ("${elapsedTime}"s/"${duration}"s)"
        sleep 0.1
    done

    local fill_bar=""
    for ((i=0; i<width; i++)); do
        fill_bar+="$char"
    done
    echo -ne "\r ["$fill_bar"] 100% ("$elapsedTime"s/"$duration"s) \n"
    tput cnorm
}

vmpoweroff(){
    vboxmanage controlvm "$VM_NAME" keyboardputstring "poweroff"
    ENTER

    local VmState
    VmState=$(VBoxManage showvminfo "$VM_NAME" --machinereadable | grep "VMState=" | cut -d '='  -f2 | tr -d '\"')
    while [ "$VMState" = "running" ]; do
        VmState=$(VBoxManage showvminfo "$VM_NAME" --machinereadable | grep "VMState=" | cut -d '='  -f2 | tr -d '\"')
        sleep 0.1
    done
    #완전 종료를 위한 10초 대기
    progress_bar 10
    echo "VM "${VM_NMAE}"이 종료되었습니다."
}

# if [[ "$1" == "Sing_line_progressbar" ]]; then
#     echo "함수 호출됨: Sing_line_progressbar $2"
#     progress_bar "$2"
# fi