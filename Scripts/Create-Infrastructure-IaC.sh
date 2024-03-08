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
Projectid="codeforge-$(date +%Y%m%d%H%M%S)"
line="*********************************************"

# Functie: Error afhandeling.
function error_exit() {
  echo -e "* ${rood}$1${reset}\n*\n* Exiting script."
  exit 1
}

# Functie: Succes afhandeling.
function success_exit() {
  echo -e "* ${groen}$1${reset}\n*\n${line}"
  exit 0
}

function success() {
  echo -e "* ${groen}$1${reset}\n*"
}

# Functie: Print the welcome message.
function welcome_message() {
  clear
  echo "$line"
  echo "*                                           *"
  echo -e "*     ${blauw}Running CodeForge create script.${reset}      *"
  echo "*                                           *"
  echo "$line"
}

# Functie: Print the loading icon.
function loading_icon() {
    local load_interval="${1}"
    local loading_message="${2}"
    local elapsed=0
    local loading_animation=( '—' "\\" '|' '/' )
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
    printf " \b\n"
}

# Functie: Create a new project.
function create_project() {
  gcloud projects create $Projectid &> /dev/null
}

# Functie: Set the project.
function set_project() {
  gcloud config set project $Projectid &> /dev/null
}

# Functie: Link the billing account to the project.
function link_billing_account() {
  billing_account=$(gcloud beta billing accounts list --format="value(ACCOUNT_ID)" | head -n 1)
  gcloud beta billing projects link $(gcloud config get-value project) --billing-account="$billing_account" &> /dev/null
}

# Functie: Create a new PostgreSQL instance.
function create_postgres_instance() {
  gcloud sql instances create db1 \
    --database-version=POSTGRES_15 \
    --tier=db-f1-micro \
    --region=europe-west1 \
    --authorized-networks=0.0.0.0/0 &> /dev/null
}

# Functie: Create a new PostgreSQL user.
function create_postgres_user() {
  gcloud sql users create admin --instance=db1 --password=123
  gcloud sql users delete postgres --instance=db1 --quiet
}

function bash_validation() {
  if [ -z "$BASH_VERSION" ]; then error_exit "This script must be run using Bash."; fi
  [ "$EUID" -ne 0 ] && error_exit "Script must be run as root: sudo $0"
  if [ ! command -v gcloud &> /dev/null ]; then error_exit "Google Cloud CLI is not installed. Please install it before running this script."; fi
}

welcome_message
bash_validation

success "Starting deployment..."

create_project &
loading_icon 10 "* "
if [ $? -eq 0 ]; then
  success "Project created successfully."
else
  error_exit "Failed to create the project."
fi

set_project &
loading_icon 10 "* "
if [ $? -eq 0 ]; then
  success "Project set successfully."
else
  error_exit "Failed to set the project."
fi

link_billing_account &
loading_icon 10 "* "
if [ $? -eq 0 ]; then
  success "Billing account linked successfully."
else
  error_exit "Failed to link the billing account."
fi

create_postgres_instance &
loading_icon 300 "* "
if [ $? -eq 0 ]; then
  success "Cloud SQL instance created successfully."
else
  error_exit "Failed to create the Cloud SQL instance."
fi

create_postgres_user &
loading_icon 10 "* "
if [ $? -eq 0 ]; then
  success "Cloud SQL user created successfully."
else
  error_exit "Failed to create the Cloud SQL user."
fi


#success_exit "Infrastructure created successfully."