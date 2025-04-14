#!/bin/bash
# Requires curl or npm to check for latest version online. 
# Enter SMTP recipient or discord webhook in the second field below. Leave blank to disable.
declare -a smtpSettings=("msmtp" "") # requires package msmtp
declare -a discordSettings=("Captain Hook" "")

func_echo () {
	if [[ "$1" == "info" ]]; then
		echo -e "\033[0;32m[INFO] $2\033[0m"
	elif [[ "$1" == "error" ]]; then
		echo -e "\033[0;31m[ERROR] $2\033[0m"
	elif [[ "$1" == "alert" ]]; then
		echo -e "\033[0;33m[ALERT] $2\033[0m"
	elif [[ "$1" == "debug" ]]; then
		echo -e "\033[0;95m[DEBUG] $2\033[0m"
	fi
}

func_alert () {
    if [[ "${discordSettings[1]}" != "" ]] ; then
        func_echo alert "Discord settings not empty, using discord alert."
        curl -H "Content-Type: application/json" -d '{"username": "'"${discordSettings[0]}"'", "content": "'"$1"'"}' ${discordSettings[1]}
    else
        func_echo alert "Discord settings empty. Not using Discord alert."
    fi
    if [[ "${smtpSettings[1]}" != "" ]] ; then
        func_echo alert "SMTP settings not empty, using SMTP alert."
        printf "Subject: Auki version mismatch\n\n$1" | ${smtpSettings[0]} -a default ${smtpSettings[1]}
    else
        func_echo alert "SMTP settings empty. Not using SMTP alert."
    fi
}

# Get latest version by curl or npm
if [ -x "$(command -v npm)" ]; then
	remoteVersion=$(npm view @streamr/node version)
	func_echo info "Npm found. Remote version is: '$remoteVersion'"
elif [ -x "$(command -v curl)" ]; then
	remoteVersion=$(curl -s https://www.npmjs.com/package/@streamr/node | grep -oP 'Latest version: \K\d+\.\d+\.\d+' | head -n 1)
    func_echo info "Npm not found. Using curl. Remote version is: '$remoteVersion'"
else
	func_echo error "Could not find curl or npm. Exiting."
	exit 1
fi

# Get local version
if [ -x "$(command -v docker)" ] || [ -x "$(command -v streamr-node)" ]; then
    func_echo info "Docker or streamr-node found."
	if docker ps | grep -q 'streamr' ; then
		localVersion=$(docker logs streamr  | grep version | awk '{print $9}')
		func_echo info "Assuming docker installation"
		if [[ "$localVersion" == "$remoteVersion" ]]; then
			func_echo info "Installed docker version '$localVersion' and remote version '$remoteVersion' match. Exiting."
			exit 0
        elif [[ "$localVersion" != "$remoteVersion" ]]; then
            func_echo alert "Installed docker version '$localVersion' and remote version '$remoteVersion' mismatch. Alerting."
            func_alert "Streamr version mismatch."
		fi
	elif [ -x "$(command -v streamr-node)" ]; then
  		func_echo info "Assuming Npm installation"
		localVersion=$(streamr-node --version)
		if [[ "$localVersion" == "$remoteVersion" ]]; then
			func_echo info "Installed npm version '$localVersion' and remote version '$remoteVersion' match. Exiting."
			exit 0
		elif [[ "$localVersion" != "$remoteVersion" ]]; then
			func_echo alert "Installed npm version '$localVersion' and remote version '$remoteVersion' mismatch. Alerting."
            func_alert "Streamr version mismatch."
		fi
	else
    	func_echo error "Cannot get version info."
		exit 1
	fi
else
	func_echo error "Cannot find installation method"
	exit 1
fi