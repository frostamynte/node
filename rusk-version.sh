#!/bin/bash
# Fill in email address or webhook URL in the second field of smtp or discord settings. Leave blank ("") to disable.
declare -a smtpSettings=("msmtp" "")
declare -a discordSettings=("Captain Hook" "")
repo="https://api.github.com/repos/dusk-network/rusk/releases/latest"

gitVersion=$(curl -s $repo | grep -oP '(?<="tag_name":).*' | tr -d '",' | sed 's/.*rusk-\([0-9]\+\.[0-9]\+\.[0-9]\+\).*/\1/')
localVersion=$($(which rusk) --version | awk '{print $2}')

bgreen () { printf "\e[1m\e[32m" ; $@ ; printf "\e[0m"; }
red    () { printf      "\e[31m" ; $@ ; printf "\e[0m"; }

func_discordHook () {
    curl -H "Content-Type: application/json" -d '{"username": "'"${discordSettings[0]}"'", "content": "'"$1"'"}' ${discordSettings[1]}
}

func_smtpAlert () {
    printf "Subject: Rusk version mismatch\n\n$1" | ${smtpSettings[0]} -a default ${smtpSettings[1]}
}

if [[ "$localVersion" != "$gitVersion" ]]; then
    red echo -e "Rusk version mismatch. Sending alert."
    red echo -e "Local version is: $localVersion"
    red echo -e "Github version is: $gitVersion\n"
    if [ "${smtpSettings[1]}" != "" ]; then
        echo -e "SMTP settings string is not empty. Using email alert.\n"
        func_smtpAlert "Rusk version mismatch. New version available."
    else
        echo -e "SMTP settings string is empty. Skipping email alert.\n"
    fi
    if [ "${discordSettings[1]}" != "" ]; then
        echo -e "Discord settings string is not empty. Using Discord alert.\n"
        func_discordHook "Rusk server mismatch. New version available."
    else
        echo -e "Discord settings string is empty. Skipping Discord alert.\n"
    fi
elif [[ "$localVersion" == "$gitVersion" ]]; then
    bgreen echo -e "Rusk version is current."
    bgreen echo -e "Local version is: $localVersion"
    bgreen echo -e "Github version is: $gitVersion\n"
    exit 0
else
    echo "Something went wrong."
    exit 1
fi
