#!/bin/bash
############################
# @author Elias De Hondt   #
# @see https://eliasdh.com #
# @since 01/03/2024        #
############################
# FUNCTIE: This is de script to delete the GCloud infrastructure.
reset='\e[0m'
rood='\e[0;31m'
blauw='\e[0;34m'
groen='\e[0;32m'
line="*********************************************"

# Functie: Error afhandeling.
function error_exit() {
  echo -e "\n*\n* ${rood}$1${reset}\n*\n* Exiting script.\n${line}"
  exit 1
}

# Functie: Succes afhandeling.
function success_exit() {
  echo -e "*\n* ${groen}$1${reset}\n*\n${line}"
  exit 0
}

# Functie: Succes afhandeling.
function success() {
  echo -e "\n*\n* ${groen}$1${reset}\n*"
}

# Functie: Print the welcome message.
function welcome_message() {
  clear
  echo "$line"
  echo "*                                           *"
  echo -e "*     ${blauw}Running CodeForge delete script.${reset}      *"
  echo "*                                           *"
  echo "$line"
}

# Functie: Print the loading icon.
function loading_icon() {
    local load_interval="${1}"
    local loading_message="${2}"
    local elapsed=0
    local loading_animation=( '⠾' "⠷" '⠯' '⠟' '⠻' '⠽' )
    echo -n "${loading_message} "
    tput civis
    trap "tput cnorm" EXIT
    while [ "${load_interval}" -ne "${elapsed}" ]; do
        for frame in "${loading_animation[@]}" ; do
            printf "%s\b" "${frame}"
            sleep 0.25
        done
        elapsed=$(( elapsed + 1 ))
    done
    printf " \b"
    exit 1
}

# Functie: Bash validatie.
function bash_validation() {
  if [ -z "$BASH_VERSION" ]; then
    error_exit "This script must be run using Bash."
  fi

  [ "$EUID" -ne 0 ] && error_exit "Script must be run as root: sudo $0"

  if ! command -v gcloud &> /dev/null; then
    error_exit "Google Cloud CLI is not installed. Please install it before running this script."
  fi
}

# Functie: Delete the project.
function delete_project() {
  loading_icon 5 "* Step 1/1:" &
  gcloud projects delete $Projectid --quiet > ./Delete-Infrastructure-IaC.log 2>&1
  local delete_exit_code=$?
  wait

  if [ $delete_exit_code -eq 0 ]; then
    success "Project deleted successfully."
  else
    error_exit "Failed to delete the project."
  fi
}

touch ./Delete-Infrastructure-IaC.log
welcome_message
bash_validation           # Step 0

echo -n "* Delete the project id: "
read Projectid
echo -e "*"

delete_project            # Step 1
wait

success_exit "Infrastructure deleted successfully."