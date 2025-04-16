#!/bin/bash
# Enter email recipient and/or discord webhook in the second field of settings array.
declare -a smtpSettings=("msmtp" "") # requires package msmtp
declare -a discordSettings=("Captain Hook" "")
today=$(date +'%d-%m-%Y %T')
logging="yes"
gitUrl="https://api.github.com/repos/SiaFoundation/hostd/releases/latest"

# Colors and logging
func_echo () {
	if [[ "$logging" == "yes" ]]; then
		logFile="$0.log"
		if [[ "$1" == "info" ]]; then
			echo -e "\033[0;32m[INFO]  $today $2\033[0m" 2>&1 | tee -a $logFile
		elif [[ "$1" == "error" ]]; then
			echo -e "\033[0;31m[ERROR] $today $2\033[0m" 2>&1 | tee -a $logFile
		elif [[ "$1" == "alert" ]]; then
			echo -e "\033[0;33m[ALERT] $today $2\033[0m" 2>&1 | tee -a $logFile
		elif [[ "$1" == "debug" ]]; then
			echo -e "\033[0;95m[DEBUG] $today $2\033[0m" 2>&1 | tee -a $logFile
		fi
	elif [[ "$logging" != "yes" ]]; then
		if [[ "$1" == "info" ]]; then
			echo -e "\033[0;32m[INFO]  $today $2\033[0m"
		elif [[ "$1" == "error" ]]; then
			echo -e "\033[0;31m[ERROR] $today $2\033[0m"
		elif [[ "$1" == "alert" ]]; then
			echo -e "\033[0;33m[ALERT] $today $2\033[0m"
		elif [[ "$1" == "debug" ]]; then
			echo -e "\033[0;95m[DEBUG] $today $2\033[0m"
		fi
	fi
}

# Logging check
if [[ "$logging" == "yes" ]]; then
    func_echo info "Logging enabled"
    if [ -f $0.log ]; then
	    func_echo info "Log file exists. $0.log"
    else
	    func_echo info "Log file does not exist. Creating $0.log"
        touch $0.log
    fi
fi

# Alert function
func_alert () {
    if [[ "${discordSettings[1]}" != "" ]] ; then
        func_echo alert "Discord settings not empty, using discord alert."
        curl -H "Content-Type: application/json" -d '{"username": "'"${discordSettings[0]}"'", "content": "'"$1"'"}' ${discordSettings[1]}
    else
        func_echo alert "Discord settings empty. Not using Discord alert."
    fi
    if [[ "${smtpSettings[1]}" != "" ]] ; then
        func_echo alert "SMTP settings not empty, using SMTP alert."
        printf "Subject: Sia version mismatch\n\n$1" | ${smtpSettings[0]} -a default ${smtpSettings[1]}
    else
        func_echo alert "SMTP settings empty. Not using SMTP alert."
    fi
}

# check installed and github version
if [ -x "$(command -v hostd version)" ]; then
    localVersion=$(hostd version | grep hostd | tail -n 1 | awk '{print $2}')
    gitVersion=$(curl -s $gitUrl | grep -oP '(?<="tag_name":).*'| tr -d '",' | tr -s "[:space:]" | cut -d ' ' -f2)
    func_echo info "Installed version is: $localVersion"
    func_echo info "Github version is: $gitVersion"
    if [[ "$localVersion" == "$gitVersion" ]]; then
        func_echo info "Local and github version matches. Exiting."
        exit 0
    elif [[ "$localVersion" != "$gitVersion" ]]; then
        func_echo alert "Local version and github version mismatch. Alerting."
        func_alert "Sia hostd version mismatch"
        exit 0
    else
        func_echo error "Version check: something went wrong."
        exit 1
    fi
elif [ ! "$(command -v hostd version)" ]; then
    func_echo error "Cannot find hostd binary. Exiting."
    exit 1
else
    func_echo error "Something went wrong. Exiting"
    exit 1
fi
exit 0