#!/bin/bash
# Bash shell script to fix chrome on debian and ubuntu based distros
# Author : David Kariuki
1="" # Empty any parameter passed by user
declare -r targetLinux="Debian Linux"
declare -r scriptVersion="1.0" # Stores scripts version
declare -l -r scriptName="linux-unsandbox-browser" # Script file name (Set to lowers and read-only)
declare -l -r networkTestUrl="www.google.com" # NetworkTestUrl (Set to lowers and read-only)
declare -l startTime="" # Stores start time of execution
declare -l totalExecutionTime="" # Total execution time in days:hours:minutes:seconds
declare listOfInstalledBrowsers="" # List of all installed browsers
declare -i totalNoOfInstalledBrowsers=0 # Total number of supported installed browsers
declare -i foundOpera=0; foundChrome=0; foundFirefoxEsr=0; foundChromium=0;
declare operaDesktopBrowser="Opera Desktop Browser"
declare googleChromeBrowser="Google Chrome Browser"
declare firefoxEsrBrowser="Firefox ESR Browser"
declare chromiumWebBrowser="Chromium Web Browser"
declare -r numberExpression='^[0-9]+$' # Number expression
declare noSandBoxFlag="--no-sandbox"; incognitoFlag="--incognito"
clear=clear # Command to clear terminal

# Paths to browsers' desktop files
operaDesktopPath=/usr/share/applications/opera.desktop
googleChromePath=/usr/share/applications/google-chrome.desktop
firefoxESRPath=/usr/share/applications/firefox-esr.desktop
chromiumWebPath=/usr/share/applications/chromium.desktop

#operaDesktopPath=browser/opera.desktop
#googleChromePath=browser/google-chrome.desktop
#firefoxESRPath=browser/firefox-esr.desktop
#chromiumWebPath=browser/chromium.desktop

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
    declare -l -r user=$USER # Declare user variable as lowercase
    if [ "$user" != 'root' ]; then
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
  cPrint "GREEN" "$1 un-sandboxed. $1 will now run as root.\n"
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

# Function to get a list of all installed browser
function getAllInstalledBrowsers(){
    local -i listCount=0 # Numbers the list of installed browser

    # Unset variables
    unset installedBrowsers listOfInstalledBrowsers

    # Get all installed browsers
    installedBrowsers=$(ls -l /usr/share/applications/)

    # Checking for Opera UnSanboxing
    if [[ $installedBrowsers == *"opera"* ]]
    then
        listCount=$[listCount+1] # Update list count
        foundOpera=$[foundOpera + 1] # Set found Opera to 1

        # Adding Opera browser to the list of installed browsers
        listOfInstalledBrowsers="${listOfInstalledBrowsers} \n\t$listCount. Opera Desktop Browser."
    fi

    # Checking for Chrome UnSanboxing
    if [[ $installedBrowsers == *"google-chrome"* ]]
    then
        listCount=$[listCount+1] # Update list count
        foundChrome=$[foundChrome + 1] # Set found Chrome to 1

        # Adding Chrome browser to the list of installed browsers
        listOfInstalledBrowsers="${listOfInstalledBrowsers} \n\t$listCount. Google Chrome Browser."
    fi

    # Checking for Firefox UnSanboxing
    if [[ $installedBrowsers == *"firefox-esr"* ]]
    then
        listCount=$[listCount+1] # Update list count
        foundFirefoxEsr=$[foundFirefoxEsr + 1] # Set found Firefox to 1

        # Adding Firefox ESR browser to list of installed browsers
        listOfInstalledBrowsers="${listOfInstalledBrowsers} \n\t$listCount. Firefox ESR Browser."
    fi

    # Checking for Chromium UnSanboxing
    if [[ $installedBrowsers == *"chromium"* ]]
    then
        listCount=$[listCount+1] # Update list count
        foundChromium=$[foundChromium + 1] # Set found opera to 1

        # Adding Chromium browser to list of installed browsers
        listOfInstalledBrowsers="${listOfInstalledBrowsers} \n\t$listCount. Chromium Web Browser."

        # Get total number of installed and supported browsers
        totalNoOfInstalledBrowsers=$((foundOpera+foundChrome+foundFirefoxEsr+foundChromium))
    fi

    if [ "$listCount" -gt 1 ]
    then # More that one browser installed
        listCount=$[listCount+1] # Update list count
        # Add option to unSandbox all at once
        listOfInstalledBrowsers="${listOfInstalledBrowsers} \n\t$listCount. unSandbox all browsers."
    fi

    # Add option to cancel unSandboxation
    listCount=$[listCount+1] # Update list count
    listOfInstalledBrowsers="${listOfInstalledBrowsers} \n\t$listCount. Exit."
    # Adding line break after list
    listOfInstalledBrowsers="${listOfInstalledBrowsers} \n"

    if [ "$1" == "--list" ]
    then
      # Display list of installed browsers
      cPrint "YELLOW" "$listOfInstalledBrowsers"
    fi
}

# Function to remove repeated --no-sandbox flags
function removeRepeatedNoSandBoxFlag(){
  # unSandboxed execWithUrl (Exec=opera %U)
  local doubleNoSandbox="$noSandBoxFlag $noSandBoxFlag"
  $(findReplace "$doubleNoSandbox" "$noSandBoxFlag" "$1")
}

# Function to unSandbox Opera Desktop Browser
function unSandboxOperaDesktopBrowser(){
    cPrint "YELLOW" "UnSandboxing Opera Desktop Browser."
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
    cPrint "YELLOW" "UnSandboxing Google Chrome Browser."
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
    cPrint "YELLOW" "Unsandboxing Firefox ESR Browser."
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
    successMessage "$firefoxESRPath"
}

# Function to unSandbox Chromium Web Browser
function unSandboxChromiumWebBrowser(){
  cPrint "YELLOW" "Unsandboxing Chromium Web Browser."
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

# Function to unSandbox all suported browsers
function unSandboxAllBrowsers(){
    cPrint "GREEN" "UnSandboxing all $totalNoOfInstalledBrowsers browsers.\n"
    holdTerminal 2 # Hold
    unSandboxOperaDesktopBrowser # unSandbox Opera Browser
    unSandboxGoogleChromeBrowser # unSandbox Google Chrome Browser
    unSandboxFirefoxESRBrowser # unSandbox Firefox ESR Browser
    unSandboxChromiumWebBrowser # unSandbox Chromium Browser
}

# Function to switch selected choice and unSandbox
function switchSelectedChoice(){
    choice=$1
    # Check chosen option and unsandbox the respective browser
    if  [[ "$choice" == 'opera desktop' ]]
    then # Option : Opera browser
        unSandboxOperaDesktopBrowser # unSandbox OPera Desktop Browser

    elif  [[ "$choice" == 'google chrome' ]]
    then # Option : Google Chrome Browser
        unSandboxGoogleChromeBrowser; choice="" # unSandbox chrome

    elif  [[ "$choice" == 'firefox esr' ]]
    then # Option : Firefox ESR Browser
        unSandboxFirefoxESRBrowser # unSandbox Firefox ESR Browser

    elif  [[ "$choice" == 'chromium web' ]]
    then # Option : Chromium Web Browser
        unSandboxChromiumWebBrowser # unSandbox Chromium Web Browser

    elif  [[ "$choice" == 'unsandbox all' ]]
    then # Option : Unsandbox all browsers
        unSandboxAllBrowsers

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

                else # Get option to unSandbox all browsers
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
            switchSelectedChoice "$choice"
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
