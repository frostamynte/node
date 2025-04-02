#!/bin/bash
# Check for updates via Githup API and alert via Discord or email if version mismatch
# Domain server binary lacks version functionality like hagall, using docker logs to grab version information instead of "docker exec -it sh ./ds version"
# Tested on domain-server all in one.
# Leave recipient or webhook URL blank to disable alert method
declare -a gitRepo=("domain-server" "hagall") # which containers to check, takes one or two arguments
declare -a localDocker
declare -a smtpSettings=("msmtp" "") # Add recipient as second value, requires msmtp
declare -a discordSettings=("Captain Hook" "") # Add webhook URL as second value

func_installedVersion () {
    dockerID=$(docker ps | grep aukilabs/$1 | awk '{print $1}')
    echo -e "Container ID for $1 is: $dockerID\n"
    localDocker+=($1)
    localDocker+=($dockerID)
    localCurrent=$(docker logs $dockerID | awk -F "version" '/version/{print $2}' | tail -n 1 | cut -d '"' -f 3)
    localDocker+=($localCurrent)
    echo -e "Running version for $1 is: $localCurrent\n"
}

func_gitCheck () {
    gitVersion=$(curl -s https://api.github.com/repos/aukilabs/$1/releases/latest | grep -oP '(?<="tag_name":).*' | tr -d '",')
    gitRepo+=($gitVersion)
}

func_discordHook () {
    curl -H "Content-Type: application/json" -d '{"username": "'"${discordSettings[0]}"'", "content": "'"$1"'"}' ${discordSettings[1]}
}

func_smtpAlert () {
    printf "Subject: Auki version mismatch\n\n$1" | ${smtpSettings[0]} -a default ${smtpSettings[1]}
}

for item in "${gitRepo[@]}" ; do
    func_installedVersion $item
    func_gitCheck $item
done

# Check Domain server version
if [[ "${localDocker[2]}" != "${gitRepo[2]}" ]]; then
    # Check if the SMTP setting string is not empty 
    if [ "${smtpSettings[1]}" != "" ]; then
        echo -e "DS SMTP settings string is not empty. Using email alert.\n"
        func_smtpAlert "Auki domain server mismatch. New version available."
    else
        echo -e "DS SMTP settings string is empty. Skipping email alert.\n"
    fi
    # Check if the Discord setting string is not empty
    if [ "${discordSettings[1]}" != "" ]; then
        echo -e "DS Discord settings string is not empty. Using Discord alert.\n"
        func_discordHook "Auki domain server mismatch. New version available."
    else
        echo -e "DS Discord settings string is empty. Skipping Discord alert.\n"
    fi
fi

# Check Hagall server version
if [[ "${localDocker[5]}" != "${gitRepo[3]}" ]]; then
    # Check if the SMTP setting string is not empty 
    if [ "${smtpSettings[1]}" != "" ]; then
        echo -e "Hagall SMTP settings string is not empty. Using email alert.\n"
        func_smtpAlert "Auki hagall server mismatch. New version available."
    else
        echo -e "Hagall SMTP settings string is empty. Skipping email alert.\n"
    fi
    # Check if the Discord setting string is not empty
    if [ "${discordSettings[1]}" != "" ]; then
        echo -e "Hagall Discord settings string is not empty. Using Discord alert.\n"
        func_discordHook "Auki hagall server mismatch. New version available."
    else
        echo -e "Hagall Discord settings string is empty. Skipping Discord alert.\n"
    fi
fi
