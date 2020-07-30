#!/bin/bash
# Bash shell script to fix chrome on debian and ubuntu based distros
# Author : David Kariuki

noSandBoxFlag="--no-sandbox"
incognitoFlag="--incognito"
path=/usr/share/applications/google-chrome.desktop

# Function to check if user is running as root
function checkIfUserIsRoot(){
    declare -l -r user=$USER # Declare user variable as lowercase
    if [ "$user" != 'root' ]; then
        printf "\nThis script only works with root.\n Please switch to root and retry.\n"
        exit # Exit script
    fi;
}

# Function to find and replace using sed
function findReplace(){
  sed -i -e "s@$1@$2@g" $3
}

# Check for root priviledges (Exits if otherwise)
checkIfUserIsRoot

# Find and replace execNoUrl
# All instances of execNoUrl(Exec=/usr/bin/google-chrome-stable)
#   will be replaced by Exec=/usr/bin/google-chrome-stable --no-sandbox.
# This will tamper with execWithUrl and incognito option.
execNoUrl="Exec=/usr/bin/google-chrome-stable" # sandboxed execNoUrl
execNoUrlNoSandbox="$execNoUrl $noSandBoxFlag" # unSandboxed execNoUrl
$(findReplace "$execNoUrl" "$execNoUrlNoSandbox" "$path")

# Fix execWithUrl exec (tampered earlier)
# Take the tampered execWithUrl generated above and update it correcty.
#   (Exec=/usr/bin/google-chrome-stable --no-sandbox %U) becomes
#   (Exec=/usr/bin/google-chrome-stable %U --no-sandbox)
execWithUrl="$execNoUrl $noSandBoxFlag %U" # sandboxed execWithUrl
execWithUrlNoSandbox="$execNoUrl %U $noSandBoxFlag" # unSandboxed execWithUrl
$(findReplace "$execWithUrl" "$execWithUrlNoSandbox" "$path")

# Fix execIncognito (tampered earlier)
# Take the tampered execIncognito generated above and update it correcty.
#   (Exec=/usr/bin/google-chrome-stable --no-sandbox --incognito) becomes
#   (Exec=/usr/bin/google-chrome-stable --incognito --no-sandbox)
execIncognito="$execNoUrl $noSandBoxFlag $incognitoFlag"  # sandboxed execIncognito
execIncognitoNoSandbox="$execNoUrl $incognitoFlag $noSandBoxFlag" # unSandboxed execIncognito
$(findReplace "$execIncognito" "$execIncognitoNoSandbox" "$path")

# Remove duplicate --no-sandbox commands incase of multiple script re-run
repeatedExecNoUrl="$execNoUrl $noSandBoxFlag $noSandBoxFlag"
$(findReplace "$repeatedExecNoUrl" "$execNoUrlNoSandbox" "$path")
repeatedExecWithUrl="$execNoUrl %U $noSandBoxFlag $noSandBoxFlag"
execWithUrlNoSandbox="$execNoUrl %U $noSandBoxFlag"
$(findReplace "$repeatedExecWithUrl" "$execWithUrlNoSandbox" "$path")
repeatedExecIncognito="$execNoUrl $incognitoFlag $noSandBoxFlag $noSandBoxFlag"
execIncognitoNoSandbox="$execNoUrl $incognitoFlag $noSandBoxFlag"
$(findReplace "$repeatedExecIncognito" "$execIncognitoNoSandbox" "$path")

printf "\n\n Chrome will now run as root.\n"
exit # Exit script
