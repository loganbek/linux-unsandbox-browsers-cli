#!/bin/bash
# Bash shell script to fix chrome on debian and ubuntu based distros
# Author : David Kariuki
1="" # Empty any parameter passed by user during script exercution
declare -r targetLinux="Debian Linux"
declare -r scriptVersion="2.0" # Stores scripts version
declare -l -r scriptName="linux-unsandbox-browsers" # Script file name (Set to lowers and read-only)
declare -l -r networkTestUrl="www.google.com" # NetworkTestUrl (Set to lowers and read-only)
declare -l startTime="" # Stores start time of execution
declare -l totalExecutionTime="" # Total execution time in days:hours:minutes:seconds
declare listOfInstalledBrowsers="" # List of all installed browsers
declare unSandboxSandboxMenu="" # List of unsandbox and sandbox options
declare -i totalNoOfInstalledBrowsers=0 # Total number of supported installed browsers
declare -i foundOpera=0 foundChrome=0 foundFirefoxEsr=0 foundChromium=0
declare operaDesktopBrowser="Opera Desktop Browser"
declare googleChromeBrowser="Google Chrome Browser"
declare firefoxEsrBrowser="Firefox ESR Browser"
declare chromiumWebBrowser="Chromium Web Browser"
declare -r numberExpression='^[0-9]+$' # Number expression
declare -r noSandBoxFlag="--no-sandbox" incognitoFlag="--incognito"
declare -r disableSandbox="Disable/Sandbox"
declare -r enableUnsandbox="Enable/Unsandbox"

# Variables to store un-sandbox states
declare -i operaFullyUnSandboxed=0 operaPartiallyUnSandboxed=0
declare -i googleChromeUnSandboxed=0 googleChromePartiallyUnSandboxed=0
declare -i firefoxESRUnSandboxed=0 chromiumWebUnSandboxed=0
clear=clear # Command to clear terminal

# Paths to browsers' desktop files
operaDesktopPath=/usr/share/applications/opera.desktop
googleChromePath=/usr/share/applications/google-chrome.desktop
firefoxESRPath=/usr/share/applications/firefox-esr.desktop
chromiumWebPath=/usr/share/applications/chromium.desktop

# Function to create a custom coloured print
function cPrint(){
    RED="\033[0;31m"    # 31 - red    : "\e[1;31m$1\e[0m"
    GREEN="\033[0;32m"  # 32 - green  : "\e[1;32m$1\e[0m"
    YELLOW="\033[1;33m" # 33 - yellow : "\e[1;33m$1\e[0m"
    BLUE="\033[1;34m"   # 34 - blue   : "\e[1;34m$1\e[0m"
    PURPLE="\033[1;35m" # 35 - purple : "\e[1;35m$1\e[0m"
    NC="\033[0m"        # No Color    : "\e[0m$1\e[0m"
    # Display coloured text setting its background color to black
    printf "\e[48;5;0m${!1}\n ${2} ${NC}\n" || exit
}

# Function to space out different sections
function sectionBreak(){
    cPrint "NC" "\n" # Print without color
}

# Function to display script information
function displayScriptInfo(){
    cPrint "NC" "About\n   Script       : $scriptName.\n   Target Linux : $targetLinux.\n   Version      : $scriptVersion\n   License      : MIT Licence.\n   Developer    : David Kariuki (dk)\n" |& tee -a $logFileName
}

# Function to hold terminal with simple terminal animation
function holdTerminal(){
  local -r initialTime=`date +%s` # Get start time
  local -r characters=" //--\\|| "
  while :
  do
      local currentTime=`date +%s`
      for (( i=0; i<${#characters}; i++ ))
      do
          sleep .1
          echo -en "  ${characters:$i:1}" "\r"
      done
      difference=$((currentTime-initialTime))
      if [[ "$difference" -eq $1 ]]
      then
          break
      fi
  done
}

# Function to format time from seconds to days:hours:minutes:seconds
function formatTime() {
    local inputSeconds=$1; local minutes=0
    local hour=0; local day=0
    if((inputSeconds>59))
    then
        ((seconds=inputSeconds%60))
        ((inputSeconds=inputSeconds/60))
        if((inputSeconds>59))
        then
            ((minutes=inputSeconds%60))
            ((inputSeconds=inputSeconds/60))
            if((inputSeconds>23))
            then
                ((hour=inputSeconds%24))
                ((day=inputSeconds/24))
            else ((hour=inputSeconds))
            fi
        else ((minutes=inputSeconds))
        fi
    else ((seconds=inputSeconds))
    fi
    unset totalExecutionTime
    totalExecutionTime="${totalExecutionTime}$day"
    totalExecutionTime="${totalExecutionTime}d "
    totalExecutionTime="${totalExecutionTime}$hour"
    totalExecutionTime="${totalExecutionTime}h "
    totalExecutionTime="${totalExecutionTime}$minutes"
    totalExecutionTime="${totalExecutionTime}m "
    totalExecutionTime="${totalExecutionTime}$seconds"
    totalExecutionTime="${totalExecutionTime}s "
}

# Function to check if user is running as root
function isUserRoot(){
    local -l -r user=$USER # Set user variable as lowercase
    if [ "$user" != 'root' ]
    then
        cPrint "RED" "This script works fully when run as root.\n Please run it as root to avoid issues/errors.\n"
        holdTerminal 4 # Hold for user to read
        exitScript --end
    else return $(true)
    fi
}

# Function to find and replace using sed
function findReplace(){
  sed -i -e "s@$1@$2@g" $3
}

# Function to display success message once a browser is unsandboxed
function successMessage(){
  cPrint "GREEN" "$1 un-sandboxed successfuly. $1 will now run as root.\n"
  holdTerminal 3 # Hold
  sectionBreak
}

# Function to exit script with custom coloured message
function exitScript(){
    cPrint "RED" "Exiting script...." # Display exit message
    holdTerminal 2 # Hold for user to read

    ${clear} # Clear terminal
    cd ~ || exit # Change to home directory
    displayScriptInfo # Display script information

    # Get script execution time
    endTime=`date +%s` # Get start time
    executionTimeInSeconds=$((endTime-startTime))
    # Calculate time in days:hours:minutes:seconds
    formatTime $executionTimeInSeconds

    # Draw logo
    printf "\n\n       __   __\n      |  | |  |  ___\n      |  | |  | /  /\n    __|  | |  |/  /\n  /  _   | |     <\n |  (_|  | |  |\  \ \n  \______| |__| \__\ \n\n "
    cPrint "YELLOW" "Script execution time : $totalExecutionTime \n"
    cPrint "RED" "Exited script...\n\n" # Display exit message
    cd ~ || exit # Change to home directory
    exit 0 # Exit script
}

# Function to remove repeated --no-sandbox flags
function removeRepeatedNoSandBoxFlag(){
    # unSandboxed execWithUrl (Exec=opera %U)
    local doubleNoSandbox="$noSandBoxFlag $noSandBoxFlag"
    $(findReplace "$doubleNoSandbox" "$noSandBoxFlag" "$1")
}

# Function to check if Opera Desktop Browser is aleady un-sandboxed
function checkForUnSandBoxedOpera(){
    # Get contents of desktop file
    local operaDesktopFileContent=$(cat $operaDesktopPath)
    # Check for un-sandboxed flag from Exec line
    if [[ $operaDesktopFileContent == *"Exec=opera %U --no-sandbox"*
        && $operaDesktopFileContent == *"Exec=opera --new-window --no-sandbox"*
        && $operaDesktopFileContent == *"Exec=opera --private --no-sandbox"* ]]
    then
      operaFullyUnSandboxed=1 # Set fully un-sandboxed to True
      operaPartiallyUnSandboxed=0 # Set partially un-sandboxed to False

    # Check for un-sandboxed flag from Exec line
    elif [[ $operaDesktopFileContent == *"Exec=opera %U --no-sandbox"*
        || $operaDesktopFileContent == *"Exec=opera --new-window --no-sandbox"*
        || $operaDesktopFileContent == *"Exec=opera --private --no-sandbox"* ]]
    then
      operaFullyUnSandboxed=0 # Set fully un-sandboxed to False
      operaPartiallyUnSandboxed=1 # Set partially un-sandboxed to True
    else
      operaFullyUnSandboxed=0 # Set fully un-sandboxed to False
      operaPartiallyUnSandboxed=0 # Set partially un-sandboxed to False
    fi
}

# Function to check if Google Chrome Browser is aleady un-sandboxed
function checkForUnSandBoxedGoogleChrome(){
    # Get contents of desktop file
    local googleChromeFileContent=$(cat $googleChromePath)
    # Check for un-sandboxed flag from Exec line
    if [[ $googleChromeFileContent == *"Exec=/usr/bin/google-chrome-stable %U --no-sandbox"*
        && $googleChromeFileContent == *"Exec=/usr/bin/google-chrome-stable --no-sandbox"*
        && $googleChromeFileContent == *"Exec=/usr/bin/google-chrome-stable --incognito --no-sandbox"* ]]
    then
      googleChromeFullyUnSandboxed=1 # Set fully un-sandboxed to True
      googleChromePartiallyUnSandboxed=0 # Set partially un-sandboxed to False

      # Check for un-sandboxed flag from Exec line
    elif [[ $googleChromeFileContent == *"Exec=/usr/bin/google-chrome-stable %U --no-sandbox"*
        || $googleChromeFileContent == *"Exec=/usr/bin/google-chrome-stable --no-sandbox"*
        || $googleChromeFileContent == *"Exec=/usr/bin/google-chrome-stable --incognito --no-sandbox"* ]]
    then
      googleChromeFullyUnSandboxed=0 # Set fully un-sandboxed to False
      googleChromePartiallyUnSandboxed=1 # Set partially un-sandboxed to True
    else
      googleChromeFullyUnSandboxed=0 # Set fully un-sandboxed to False
      googleChromePartiallyUnSandboxed=0 # Set partially un-sandboxed to False
    fi
}

# Function to check if Firefox ESR Browser is aleady un-sandboxed
function checkForUnSandBoxedFirefoxESR(){
    # Get contents of desktop file
    local firefoxESRFileContent=$(cat $firefoxESRPath)
    # Check for un-sandboxed flag from Exec line
    if [[ $firefoxESRFileContent == *"Exec=/usr/lib/firefox-esr/firefox-esr %u --no-sandbox"* ]]
    then
        firefoxESRUnSandboxed=1 # Set fully un-sandboxed to True
    else
        firefoxESRUnSandboxed=0 # Set fully un-sandboxed to False
    fi
}

# Function to check if Chromium Web Browser is aleady un-sandboxed
function checkForUnSandBoxedChromiumWeb(){
    # Get contents of desktop file
    local chromiumWebFileContent=$(cat $chromiumWebPath)
    # Check for un-sandboxed flag from Exec line
    if [[ $chromiumWebFileContent == *"Exec=/usr/bin/chromium %U --no-sandbox"* ]]
    then
        chromiumWebUnSandboxed=1 # Set fully un-sandboxed to True
    else
        chromiumWebUnSandboxed=0 # Set fully un-sandboxed to False
    fi
}

# Function to get a list of all installed browser
function getAllInstalledBrowsers(){
    local -i listCount=0 # Numbers the list of installed browser
    local browserUnSandboxedLabel="";
    local -r partiallyUnSandboxedLabel="\e[1;33mPartially Un-Sandboxed.\e[0m"
    local -r unSandboxedLabel="\e[1;33mUn-Sandboxed.\e[0m"
    local -r willRunAsRoot="(Will run as root)"
    local -r canPartiallyRunAsRoot="\e[1;31m(Can partially run as root)\e[0m"
    local -r cantRunAsRoot="\e[1;31m(Cannot run as root)\e[0m"

    # Unset variables
    unset installedBrowsers listOfInstalledBrowsers
    unset foundOpera foundChrome foundFirefoxEsr foundChromium

    # Get all installed browsers
    installedBrowsers=$(ls -l /usr/share/applications/)

    # Set found Opera to 1 if installed
    if [[ $installedBrowsers == *"opera"* ]];
    then foundOpera=$[foundOpera + 1]; fi
    # Set found Chrome to 1 if installed
    if [[ $installedBrowsers == *"google-chrome"* ]];
    then foundChrome=$[foundChrome + 1]; fi
    # Set found Firefox to 1 if installed
    if [[ $installedBrowsers == *"firefox-esr"* ]];
    then foundFirefoxEsr=$[foundFirefoxEsr + 1]; fi
    # Set found opera to 1 if installed
    if [[ $installedBrowsers == *"chromium"* ]];
    then foundChromium=$[foundChromium + 1]; fi

    # Get total number of installed and supported browsers
    totalNoOfInstalledBrowsers=$((foundOpera+foundChrome+foundFirefoxEsr+foundChromium))
    listOfInstalledBrowsers="\n Found a total of $totalNoOfInstalledBrowsers browsers.\n"

    # Checking for Opera UnSanboxing
    if [[ $installedBrowsers == *"opera"* ]]
    then
        listCount=$[listCount+1] # Update list count

        # Check if Opera Desktop Browser is already un-sandboxed
        checkForUnSandBoxedOpera

        if [ "$operaFullyUnSandboxed" -eq 1 ]
        then
            browserUnSandboxedLabel="$unSandboxedLabel $willRunAsRoot)"
        elif [ "$operaPartiallyUnSandboxed" -eq 1 ]
        then
            browserUnSandboxedLabel="$partiallyUnSandboxedLabel $canPartiallyRunAsRoot)"
        else
            browserUnSandboxedLabel="$cantRunAsRoot"
        fi

        # Adding Opera browser to the list of installed browsers
        listOfInstalledBrowsers="${listOfInstalledBrowsers} \n\t\e[1;32m$listCount. Opera Desktop Browser. \e[0m $browserUnSandboxedLabel"
        browserUnSandboxedLabel=""
    fi

    # Checking for Chrome UnSanboxing
    if [[ $installedBrowsers == *"google-chrome"* ]]
    then
        listCount=$[listCount+1] # Update list count

        # Check if Google Chrome Browser is already un-sandboxed
        checkForUnSandBoxedGoogleChrome

        if [ "$googleChromeFullyUnSandboxed" -eq 1 ]
        then
            browserUnSandboxedLabel="$unSandboxedLabel $willRunAsRoot)"
        elif [ "$googleChromePartiallyUnSandboxed" -eq 1 ]
        then
            browserUnSandboxedLabel="$partiallyUnSandboxedLabel $canPartiallyRunAsRoot)"
        else
            browserUnSandboxedLabel="$cantRunAsRoot"
        fi

        # Adding Chrome browser to the list of installed browsers
        listOfInstalledBrowsers="${listOfInstalledBrowsers} \n\t\e[1;32m$listCount. Google Chrome Browser. \e[0m $browserUnSandboxedLabel"
        browserUnSandboxedLabel=""
    fi

    # Checking for Firefox UnSanboxing
    if [[ $installedBrowsers == *"firefox-esr"* ]]
    then
        listCount=$[listCount+1] # Update list count

        # Check if Firefox ESR Browser is already un-sandboxed
        checkForUnSandBoxedFirefoxESR

        if [ "$firefoxESRUnSandboxed" -eq 1 ]
        then
            browserUnSandboxedLabel="$unSandboxedLabel $willRunAsRoot"
        else
            browserUnSandboxedLabel="$cantRunAsRoot"
        fi

        # Adding Firefox ESR browser to list of installed browsers
        listOfInstalledBrowsers="${listOfInstalledBrowsers} \n\t\e[1;32m$listCount. Firefox ESR Browser. \e[0m $browserUnSandboxedLabel"
        browserUnSandboxedLabel=""
    fi

    # Checking for Chromium UnSanboxing
    if [[ $installedBrowsers == *"chromium"* ]]
    then
        listCount=$[listCount+1] # Update list count

        #  Check if Chroimum Web Browser is already un-sandboxed
        checkForUnSandBoxedChromiumWeb

        if [ "$chromiumWebUnSandboxed" -eq 1 ]
        then
            browserUnSandboxedLabel="$unSandboxedLabel $willRunAsRoot"
        else
            browserUnSandboxedLabel="$cantRunAsRoot"
        fi

        # Adding Chromium browser to list of installed browsers
        listOfInstalledBrowsers="${listOfInstalledBrowsers} \n\t\e[1;32m$listCount. Chromium Web Browser. \e[0m $browserUnSandboxedLabel"
        browserUnSandboxedLabel=""
    fi

    # Add option to cancel unSandboxation
    listCount=$[listCount+1] # Update list count
    listOfInstalledBrowsers="${listOfInstalledBrowsers} \n\t\e[1;32m$listCount. Exit."
    # Adding line break after list
    listOfInstalledBrowsers="${listOfInstalledBrowsers} \n"

    if [ "$1" == "--list" ]
    then
      # Display list of installed browsers
      cPrint "YELLOW" "$listOfInstalledBrowsers"
    fi
}

# Function to unSandbox Opera Desktop Browser
function unSandboxOperaDesktopBrowser(){
    cPrint "YELLOW" "Enabling/UnSandboxing $operaDesktopBrowser."
    holdTerminal 2 # Hold

    # Find and replace (Exec=opera --new-window) with
    # (Exec=opera --new-window --no-sandbox)
    local execNewWindow="Exec=opera --new-window"
    # Replace (Exec=opera %U) with (Exec=opera %U --no-sandbox)
    local execWithUrl="Exec=opera %U"
    # Replace (Exec=opera --private) with (Exec=opera --private --no-sandbox)
    local execPrivate="Exec=opera --private"

    # unSandboxed execNewWindow (Exec=opera --new-window)
    local execNewWindowNoSandbox="$execNewWindow $noSandBoxFlag"
    $(findReplace "$execNewWindow" "$execNewWindowNoSandbox" "$operaDesktopPath")

    # unSandboxed execWithUrl (Exec=opera %U)
    local execWithUrlNoSandbox="$execWithUrl $noSandBoxFlag"
    $(findReplace "$execWithUrl" "$execWithUrlNoSandbox" "$operaDesktopPath")

    # unSandboxed execPrivate (Exec=opera --private)
    local execPrivateNoSandbox="$execPrivate $noSandBoxFlag"
    $(findReplace "$execPrivate" "$execPrivateNoSandbox" "$operaDesktopPath")

    # Remove duplicate --no-sandbox commands incase of multiple script re-run
    repeatedExecNewWindow="$execNewWindow $noSandBoxFlag $noSandBoxFlag"
    $(findReplace "$repeatedExecNewWindow" "$execNewWindowNoSandbox" "$operaDesktopPath")
    repeatedExecWithUrl="$execWithUrl $noSandBoxFlag $noSandBoxFlag"
    $(findReplace "$repeatedExecWithUrl" "$execWithUrlNoSandbox" "$operaDesktopPath")
    repeatedExecPrivate="$execPrivate $noSandBoxFlag $noSandBoxFlag"
    $(findReplace "$repeatedExecPrivate" "$execPrivateNoSandbox" "$operaDesktopPath")
    removeRepeatedNoSandBoxFlag "$operaDesktopPath"

    # Display Opera Desktop Browser unsandboxed message
    successMessage "$operaDesktopBrowser"
}

# Function to unSandbox Google Chrome Browser
function unSandboxGoogleChromeBrowser(){
    cPrint "YELLOW" "Enabling/UnSandboxing $googleChromeBrowser."
    holdTerminal 2 # Hold

    # Find and replace (Exec=/usr/bin/google-chrome-stable) with
    # (Exec=/usr/bin/google-chrome-stable --no-sandbox) This will tamper with
    # incognito option and execNoUrl
    local execNoUrl="Exec=/usr/bin/google-chrome-stable"
    local execNoUrlNoSandbox="$execNoUrl $noSandBoxFlag" # unSandboxed execNoUrl
    $(findReplace "$execNoUrl" "$execNoUrlNoSandbox" "$googleChromePath")

    # Fix execWithUrl exec (tampered earlier)
    # Correct tampered execWithUrl generated above.
    # (Exec=/usr/bin/google-chrome-stable --no-sandbox %U) is replaced by
    # (Exec=/usr/bin/google-chrome-stable %U --no-sandbox)
    execWithUrl="$execNoUrl $noSandBoxFlag %U" # sandboxed execWithUrl
    execWithUrlNoSandbox="$execNoUrl %U $noSandBoxFlag" # unSandboxed execWithUrl
    $(findReplace "$execWithUrl" "$execWithUrlNoSandbox" "$googleChromePath")

    # Fix execIncognito (tampered earlier)
    # Take the tampered execIncognito generated above and update it correcty.
    #   (Exec=/usr/bin/google-chrome-stable --no-sandbox --incognito) becomes
    #   (Exec=/usr/bin/google-chrome-stable --incognito --no-sandbox)
    # sandboxed execIncognito
    execIncognito="$execNoUrl $noSandBoxFlag $incognitoFlag"
    # unSandboxed execIncognito
    execIncognitoNoSandbox="$execNoUrl $incognitoFlag $noSandBoxFlag"
    $(findReplace "$execIncognito" "$execIncognitoNoSandbox" "$googleChromePath")

    # Remove duplicate --no-sandbox commands incase of multiple script re-run
    repeatedExecNoUrl="$execNoUrl $noSandBoxFlag $noSandBoxFlag"
    $(findReplace "$repeatedExecNoUrl" "$execNoUrlNoSandbox" "$googleChromePath")
    repeatedExecWithUrl="$execNoUrl %U $noSandBoxFlag $noSandBoxFlag"
    execWithUrlNoSandbox="$execNoUrl %U $noSandBoxFlag"
    $(findReplace "$repeatedExecWithUrl" "$execWithUrlNoSandbox" "$googleChromePath")
    repeatedExecIncognito="$execNoUrl $incognitoFlag $noSandBoxFlag $noSandBoxFlag"
    execIncognitoNoSandbox="$execNoUrl $incognitoFlag $noSandBoxFlag"
    $(findReplace "$repeatedExecIncognito" "$execIncognitoNoSandbox" "$googleChromePath")
    removeRepeatedNoSandBoxFlag "$googleChromePath"

    # Display Chrome Browser unsandboxed message
    successMessage "$googleChromeBrowser"
}

# Function to unSandbox Firefox ESR Browser
function unSandboxFirefoxESRBrowser(){
    cPrint "YELLOW" "Enabling/UnSandboxing $firefoxEsrBrowser."
    holdTerminal 2 # Hold

    # Find and replace (Exec=/usr/lib/firefox-esr/firefox-esr %u) with
    # (Exec=/usr/lib/firefox-esr/firefox-esr %u --no-sandbox)
    local execWithUrl="Exec=/usr/lib/firefox-esr/firefox-esr %u"

    # unSandboxed execWithUrl (Exec=/usr/lib/firefox-esr/firefox-esr %u)
    local execWithUrlNoSandbox="$execWithUrl $noSandBoxFlag"
    $(findReplace "$execWithUrl" "$execWithUrlNoSandbox" "$firefoxESRPath")

    # Remove duplicate --no-sandbox commands incase of multiple script re-run
    repeatedexecWithUrl="$execWithUrl $noSandBoxFlag $noSandBoxFlag"
    $(findReplace "$repeatedexecWithUrl" "$execWithUrlNoSandbox" "$firefoxESRPath")
    removeRepeatedNoSandBoxFlag "$firefoxESRPath"

    # Display Firefox ESR Browser unsandboxed message
    successMessage "$firefoxEsrBrowser"
}

# Function to unSandbox Chromium Web Browser
function unSandboxChromiumWebBrowser(){
  cPrint "YELLOW" "Enabling/UnSandboxing $chromiumWebBrowser."
  holdTerminal 2 # Hold

  # Find and replace (Exec=/usr/bin/chromium %U) with
  # (Exec=/usr/bin/chromium %U --no-sandbox)
  local execWithUrl="Exec=/usr/bin/chromium %U"

  # unSandboxed execWithUrl (Exec=/usr/bin/chromium %U)
  local execWithUrlNoSandbox="$execWithUrl $noSandBoxFlag"
  $(findReplace "$execWithUrl" "$execWithUrlNoSandbox" "$chromiumWebPath")

  # Remove duplicate --no-sandbox commands incase of multiple script re-run
  repeatedexecWithUrl="$execWithUrl $noSandBoxFlag $noSandBoxFlag"
  $(findReplace "$repeatedexecWithUrl" "$execWithUrlNoSandbox" "$chromiumWebPath")
  removeRepeatedNoSandBoxFlag "$chromiumWebPath"

  # Display Chromium Web Browser unsandboxed message
  successMessage "$chromiumWebBrowser"
}

# Function to sandbox all browsers
function sandboxBrowser(){
    ${clear} # Clear terminal

    cPrint "YELLOW" "Disabling/Sandboxing $firefoxEsrBrowser."
    local path=""

    # Check for browser and set browser desktop file path
    if [ "$1" == "$operaDesktopBrowser" ]
    then
        path="$operaDesktopPath"
    elif [ "$1" == "$googleChromeBrowser" ]
    then
        path="$googleChromePath"
    elif [ "$1" == "$firefoxEsrBrowser" ]
    then
        path="$firefoxESRPath"
    elif [ "$1" == "$chromiumWebBrowser" ]
    then
        path="$chromiumWebPath"
    fi

    # Remove unSandbox flag from Exec lines
    $(findReplace " $noSandBoxFlag" "" "$path")
}

# Function to switch Sandbox-UnSandbox menu selected choice
function switchSandboxUnSandboxMenuChoice(){
    choice=$1

    # Check if entered choice is a number
    if [[ $choice =~ $numberExpression ]]
    then # Choice is a number
        unset list # Unset List
        # Get list of all installed browsers
        list="$unSandboxSandboxMenu"
        unset filterParam # Unset filter parameter
        # Get text between list number and 'Browser' word
        filterParam="$choice. \K.*?(?= Browser.)"
        unset option # Unset option
        # Grep string to get option
        option=$(grep -oP "$filterParam" <<< "$list")

        # Check if option is empty or not
        if [ ! -z "$option" ]
        then # Option is not empty
            unset choice # Unset choice
            choice="$option Browser" # Set option to choice
        else # Get cancel option
            unset filterParam2 # Unset filter parameter
            # Get text between list number and period
            filterParam2="$choice. \K.*?(?= .)"
            unset option # Unset option
            # Grep string to get option
            option=$(grep -oP "$filterParam2" <<< "$list")
            option=${option//.} # Strip period from option
            option=${option,,} # Convert to lowercase
            unset choice # Unset choice
            choice="$option" # Set option to choice
        fi
    fi

    # Check chosen option and unsandbox the respective browser
    # Opera Desktop Browser
    if  [[ "$choice" == "$enableUnsandbox $operaDesktopBrowser" ]]
    then # Option : Opera browser
        unSandboxOperaDesktopBrowser # unSandbox Opera Desktop Browser
    elif  [[ "$choice" == "$disableSandbox $operaDesktopBrowser" ]]
    then
        sandboxBrowser "$operaDesktopBrowser" # sandbox Opera Desktop Browser
    # Google Chrome Browser
    elif  [[ "$choice" == "$enableUnsandbox $googleChromeBrowser" ]]
    then # Option : Chrome browser
        unSandboxGoogleChromeBrowser # unSandbox Google Chrome Browser
    elif  [[ "$choice" == "$disableSandbox $googleChromeBrowser" ]]
    then
        sandboxBrowser "$googleChromeBrowser" # sandbox Google Chrome Browser
    # Firefox ESR Browser
    elif  [[ "$choice" == "$enableUnsandbox $firefoxEsrBrowser" ]]
    then # Option : Firefox ESR browser
        unSandboxFirefoxESRBrowser # unSandbox Firefox ESR Browser
    elif  [[ "$choice" == "$disableSandbox $firefoxEsrBrowser" ]]
    then
        sandboxBrowser "$firefoxEsrBrowser" # sandbox Firefox ESR Browser
    # Chromium Web Browser
    elif  [[ "$choice" == "$enableUnsandbox $chromiumWebBrowser" ]]
    then # Option : Chromium Web
        unSandboxChromiumWebBrowser # unSandbox Chromium Web Browser
    elif  [[ "$choice" == "$disableSandbox $chromiumWebBrowser" ]]
    then
        sandboxBrowser "$chromiumWebBrowser" # sandbox Chromium Web Browser
    # Back
    elif  [[ "$choice" == 'back' ]]
    then # Option : Exit script
        ${clear} # Clear terminal
    fi
  sleep 1 # Hold loop
}

# Function to select sandbox or unsandbox options
function sandboxUnSandboxMenu(){
  while true
  do # Start infinite loop
      ${clear} # Clear terminal

      getAllInstalledBrowsers # Get all installed browsers

      # Unset required variables to prevent duplicates during loop
      unset unSandboxSandboxMenu listCount

      # Prompt user to select sandbox or unsandbox
      local unSandboxSandboxMenu="Select an option below to proceed."
      local -i listcount=0 # Menu list count

      # Opera Desktop Browser
      if [ "$1" == "$operaDesktopBrowser" ]
      then
          listCount=$[listCount+1]
          if [ "$operaFullyUnSandboxed" -eq 1 ]
          then # Sandbox
              unSandboxSandboxMenu="$unSandboxSandboxMenu\n\t$listCount. $disableSandbox $1."
          elif [ "$operaPartiallyUnSandboxed" -eq 1 ]
          then # Partial Un-Sandbox (unSandbox fully(--no-sandbox) or Sandbox)
              unSandboxSandboxMenu="$unSandboxSandboxMenu\n\t$listCount. $enableUnsandbox $1."
              unSandboxSandboxMenu="$unSandboxSandboxMenu\n\t$listCount. $disableSandbox $1."
          else # None UnSandboxed
              unSandboxSandboxMenu="$unSandboxSandboxMenu\n\t$listCount. $enableUnsandbox $1."
          fi
      # Google Chrome Browser
      elif [ "$1" == "$googleChromeBrowser" ]
      then
          listCount=$[listCount+1]
          if [ "$googleChromeFullyUnSandboxed" -eq 1 ]
          then # Sandbox
              unSandboxSandboxMenu="$unSandboxSandboxMenu\n\t$listCount. $disableSandbox $1."
          elif [ "$googleChromePartiallyUnSandboxed" -eq 1 ]
          then # Partial Un-Sandbox (unSandbox fully(--no-sandbox) or Sandbox)
              unSandboxSandboxMenu="$unSandboxSandboxMenu\n\t$listCount. $enableUnsandbox $1."
              unSandboxSandboxMenu="$unSandboxSandboxMenu\n\t$listCount. $disableSandbox $1."
          else # None UnSandboxed
              unSandboxSandboxMenu="$unSandboxSandboxMenu\n\t$listCount. $enableUnsandbox $1."
          fi
      # Firefox ESR Browser
      elif [ "$1" == "$firefoxEsrBrowser" ]
      then
          listCount=$[listCount+1]
          if [ "$firefoxESRUnSandboxed" -eq 1 ]
          then
              unSandboxSandboxMenu="$unSandboxSandboxMenu\n\t$listCount. $disableSandbox $1."
          else
              unSandboxSandboxMenu="$unSandboxSandboxMenu\n\t$listCount. $enableUnsandbox $1."
          fi
      # Chromium Web Browser
      elif [ "$1" == "$chromiumWebBrowser" ]
      then
          listCount=$[listCount+1]
          if [ "$chromiumWebUnSandboxed" -eq 1 ]
          then
              unSandboxSandboxMenu="$unSandboxSandboxMenu\n\t$listCount. $disableSandbox $1."
          else
              unSandboxSandboxMenu="$unSandboxSandboxMenu\n\t$listCount. $enableUnsandbox $1."
          fi
      fi

      listCount=$[listCount+1]
      unSandboxSandboxMenu="$unSandboxSandboxMenu\n\t$listCount. Back"

      cPrint "YELLOW" "$unSandboxSandboxMenu"
      read -p ' option: ' sandboxChoice
      sandboxChoice=${sandboxChoice,,} # Convert to lowercase
      # Display choice
      cPrint "GREEN" " You chose : $sandboxChoice\n" |& tee -a $logFileName

      switchSandboxUnSandboxMenuChoice "$sandboxChoice" "$1"
      break
  done
}

# Function to switch main menu selected choice
function switchMainMenuChoice(){
    choice=$1
    # Check chosen option and unsandbox the respective browser
    if  [[ "$choice" == 'opera desktop' ]]
    then # Option : Opera browser
        # unSandbox/sandbox Opera Desktop Browser
        sandboxUnSandboxMenu "$operaDesktopBrowser"; choice=""

    elif  [[ "$choice" == 'google chrome' ]]
    then # Option : Google Chrome Browser
        # unSandbox/sandbox Google Chrome Browser
        sandboxUnSandboxMenu "$googleChromeBrowser"; choice=""

    elif  [[ "$choice" == 'firefox esr' ]]
    then # Option : Firefox ESR Browser
        # unSandbox/sandbox Firefox ESR Browser
        sandboxUnSandboxMenu "$firefoxEsrBrowser"; choice=""

    elif  [[ "$choice" == 'chromium web' ]]
    then # Option : Chromium Web Browser
        # unSandbox/sandbox Chromium Web Browser
        sandboxUnSandboxMenu "$chromiumWebBrowser"; choice=""

    elif  [[ "$choice" == 'exit' ]]
    then # Option : Exit script
        ${clear} # Clear terminal
        exitScript # ExitScript
    fi
    sleep 1 # Hold loop
}


# Function to select and unSandbox a browser
function displayInstalledBrowsersMenu(){
    ${clear} # Clear terminal

    # Get number of installed browsers
    getAllInstalledBrowsers

    while true
    do # Start infinite loop
        ${clear} # Clear terminal

        if [ "$totalNoOfInstalledBrowsers" -gt 0 ]
        then # 1 or more browser installed

            # Get all installed browsers and display them
            getAllInstalledBrowsers --list

            cPrint "YELLOW" "Please select a browser to unSandbox from the list above!"
            read -p ' option: ' choice
            choice=${choice,,} # Convert to lowercase
            cPrint "GREEN" " You chose : $choice" # Display choice

            # Check if entered choice is a number
            if [[ $choice =~ $numberExpression ]]
            then # Choice is a number

                unset list # Unset List
                # Get list of all installed browsers
                list="$listOfInstalledBrowsers"
                unset filterParam # Unset filter parameter
                # Get text between list number and 'Browser' word
                filterParam="$choice. \K.*?(?= Browser.)"
                unset option # Unset option
                # Grep string to get option
                option=$(grep -oP "$filterParam" <<< "$list")

                # Check if option is empty or not
                if [ ! -z "$option" ]
                then # Option is not empty
                    option=${option,,} # Convert to lowercase
                    unset choice # Unset choice
                    choice="$option" # Set option to choice

                else # Get option to unSandbox all listed browsers
                    unset filterParam2 # Unset filter parameter
                    # Get text between list number and 'browsers' words
                    filterParam2="$choice. \K.*?(?= browsers.)"
                    unset option # Unset option
                    # Grep string to get option
                    option=$(grep -oP "$filterParam2" <<< "$list")

                    # Check if option is empty or not
                    if [ ! -z "$option" ]
                    then # Option is not empty
                        option=${option,,} # Convert to lowercase
                        unset choice # Unset choice
                        choice="$option" # Set option to choice

                    else # Get cancel option
                        unset filterParam3 # Unset filter parameter
                        # Get text between list number and period
                        filterParam3="$choice. \K.*?(?= .)"
                        unset option # Unset option
                        # Grep string to get option
                        option=$(grep -oP "$filterParam3" <<< "$list")
                        option=${option//.} # Strip period from option
                        option=${option,,} # Convert to lowercase
                        unset choice # Unset choice
                        choice="$option" # Set option to choice
                    fi
                fi
            fi

            # Switch selected choice and unSandbox
            switchMainMenuChoice "$choice"
        else
          cPrint "RED" "You have not installed any supported browsers. This script works with:\n\t1. $operaDesktopBrowser.\n\t2. $googleChromeBrowser.\n\t3. $firefoxEsrBrowser.\n\t4. $chromiumWebBrowser."
          holdTerminal 15 # Hold for user to read
          exitScript # Exit script
        fi
    done
}

function displayMainMenu(){
    startTime=`date +%s` # Get start time
    ${clear} # Clear terminal

    echo ""; cPrint "RED" "Hello $USER!!"
    cPrint "YELLOW"	"This script will help you enable different browsers to run as root on your $targetLinux."
    holdTerminal 7 # Hold for user to read

    # Check if user is running as root
    if isUserRoot
    then
        displayInstalledBrowsersMenu # Display installed browsers menu
    fi
    sectionBreak
    displayScriptInfo # Display Script Information
}

displayMainMenu # Display browser selection menu
exitScript # Exit script
