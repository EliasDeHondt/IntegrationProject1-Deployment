#!/bin/bash
############################
# @author Elias De Hondt   #
# @see https://eliasdh.com #
# @since 01/03/2024        #
############################
# FUNCTIE: This is de script to create the GCloud infrastructure.
reset='\e[0m'
rood='\e[0;31m'
blauw='\e[0;34m'
groen='\e[0;32m'
PROJECTID='codeforge-$(date +%s)'
line="*********************************************"

# Functie: Error afhandeling.
function error_exit() {
  echo -e "* Error: ${rood}$1${reset}\n*\n* Exiting script."
  exit 1
}

function success_exit() {
  echo -e "* ${groen}$1${reset}\n*"
  exit 0
}

# Functie: Print the welcome message.
clear
echo "$line"
echo "*                                           *"
echo -e "*     ${blauw}Running CodeForge create script.${reset}      *"
echo "*                                           *"
echo "$line"

# Functie: Check of de script als root wordt uitgevoerd.
[ "$EUID" -ne 0 ] && error_exit "Script must be run as root: sudo $0"

# Functie: Check if the Google Cloud CLI is installed.
if [ ! command -v gcloud &> /dev/null ]; then
  error_exit "Google Cloud CLI is not installed. Please install it before running this script."
fi

# Start Deployment
echo -e "* ${groen}Starting deployment...${reset}\n*"

# Functie: Create a new project.
gcloud projects create $PROJECTID #&> /dev/null

if [ $? -eq 0 ]; then
  echo -e "* ${groen}Project creation successful.${reset}\n*"
else
  error_exit "Failed to create the project. Check the error message above for details."
fi

# Functie: Set the project.
gcloud config set project $PROJECTID #&> /dev/null

if [ $? -eq 0 ]; then
  echo -e "* ${groen}Project set successfully.${reset}\n*"
else
  error_exit "Failed to set the project. Check the error message above for details."
fi

# Functie: Link the billing account to the project.
gcloud beta billing projects link $(gcloud config get-value project) --billing-account=$(gcloud beta billing accounts list --format="value(ACCOUNT_ID)") #&> /dev/null

if [ $? -eq 0 ]; then
  echo -e "* ${groen}Billing account linked successfully.${reset}\n*"
else
  error_exit "Failed to link the billing account. Check the error message above for details."
fi