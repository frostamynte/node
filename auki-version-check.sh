#!/bin/bash
# Check for updates via GitHub API and alert via Discord or email if version mismatch
# Domain server binary lacks version functionality like hagall, using docker logs to grab version information instead of "docker exec -it sh ./ds version"
# Tested on domain-server all in one.
# Leave SMTP recipient or webhook URL blank to disable alert method.

declare -a smtpSettings=("msmtp" "") # Requires package msmtp. Enter email recipient in the second field to enable alert.
declare -a discordSettings=("Captain Hook" "") # Enter discord webhook URL in the second field to enable alert.
declare -A ds
declare -A hagall

# Echo content of array for debugging
func_arrayEcho () {
    local -n arr=$1
    echo -e "local arr=$arr\n"
    length=${#arr[@]}
    echo -e "//Func arrayEcho\n Bash array '\${arr}' has total ${length} element(s) (length)\n"
    for (( j=0; j<${length}; j++ )) ; do
        printf "Current index %d with value %s\n" $j ${arr[$j]}
    done
}

# Call to print line number for debugging
func_log() {
    echo "LINENO: ${LINENO}"
    echo "BASH_LINENO: ${BASH_LINENO[0]}"
}

func_alert () {
    if [[ "${discordSettings[1]}" != "" ]] ; then
        echo -e "Discord settings not empty, using discord alert.\n"
        curl -H "Content-Type: application/json" -d '{"username": "'"${discordSettings[0]}"'", "content": "'"$1"'"}' ${discordSettings[1]}
    else
        echo -e "Discord settings empty. Not using Discord alert.\n"
    fi
    if [[ "${smtpSettings[1]}" != "" ]] ; then
        echo -e "SMTP settings not empty, using SMTP alert.\n"
        printf "Subject: Auki version mismatch\n\n$1" | ${smtpSettings[0]} -a default ${smtpSettings[1]}
    else
        echo -e "SMTP settings empty. Not using SMTP alert.\n"
    fi
}

dockerRunning=$(docker ps | grep aukilabs | awk '{print $2}' | cut -d '/' -f2 | cut -d ':' -f1)
echo -e "\nRunning containers: \n$dockerRunning\n"
readarray -t array <<< $dockerRunning

# Get local DS version from logs and compare to github 
if [[ "${array[0]}" == "domain-server" ]] || [[ "${array[1]}" == "domain-server" ]]; then
    echo -e "The key domain-server is found in the array. Executing check.\n"
    dockerID=$(docker ps | grep aukilabs/domain-server | awk '{print $1}') ; echo -e "$dockerID\n"
    localCurrent=$(docker logs $dockerID | awk -F "version" '/version/{print $2}' | tail -n 1 | cut -d '"' -f 3| tr -s "[:space:]" | cut -d ' ' -f2)
    ds[lver]="$localCurrent"
    gitVersion=$(curl -s https://api.github.com/repos/aukilabs/domain-server/releases/latest | grep -oP '(?<="tag_name":).*' | tr -d '",' | tr -s "[:space:]" | cut -d ' ' -f2)
    ds[gver]="$gitVersion"
    if [[ "${ds[lver]}" == "${ds[gver]}" ]]; then
        echo -e "DS local version is equal to Github version.\n"
    elif [[ "${ds[lver]}" != "${ds[gver]}" ]]; then
        echo -e "DS local version "${ds[lver]}" differs from Github version "${ds[gver]}" Alerting.\n"
        func_alert "Auki domain-server version mismatch"
    fi
else
    echo -e "Key domain-server is not found in the array.\n"
fi

# Get local Hagall version from logs and compare to github 
if [[ "${array[0]}" == "hagall" ]] || [[ "${array[1]}" == "hagall" ]]; then
    echo -e "The key hagall is found in the array. Executing check.\n"
    dockerID=$(docker ps | grep aukilabs/hagall | awk '{print $1}') ; echo -e "$dockerID\n"
    hagall[id]="$dockerID"
    localCurrent=$(docker logs $dockerID | awk -F "version" '/version/{print $2}' | tail -n 1 | cut -d '"' -f 3 | tr -s "[:space:]" | cut -d ' ' -f2)
    hagall[lver]="$localCurrent"
    gitVersion=$(curl -s https://api.github.com/repos/aukilabs/hagall/releases/latest | grep -oP '(?<="tag_name":).*' | tr -d '",' | tr -s "[:space:]" | cut -d ' ' -f2)
    hagall[gver]="$gitVersion"
    if [[ "${hagall[lver]}" == "${hagall[gver]}" ]]; then
        echo -e "Hagall local version is equal to Github version.\n"
        exit 0
    elif [[ "${hagall[lver]}" != "${hagall[gver]}" ]]; then
        echo -e "Hagall local version differs from Github version. Alerting.\n"
        echo -e func_alert "Auki hagall version mismatch"
    fi
else
    echo -e "Key hagall is not found in the array.\n"
fi

exit 0
