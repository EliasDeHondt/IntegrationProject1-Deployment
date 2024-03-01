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

# Functie: Error afhandeling.
function error_exit() {
  echo -e "Error: ${rood}$1${reset}"
  exit 1
}

# Functie: Check of de script als root wordt uitgevoerd.
[ "$EUID" -ne 0 ] && error_exit "Script must be run as root: sudo $0"

# Functie: Check if the Google Cloud CLI is installed.
[ ! command -v gcloud &> /dev/null ] then
  error_exit "Google Cloud CLI is not installed. Please install it before running this script."
fi

# Functie: Print the welcome message.
clear
echo -e "${blauw}*********************************************"
echo "*                                           *"
echo "*     Running CodeForge delete script.      *"
echo "*                                           *"
echo -e "*********************************************${reset}"