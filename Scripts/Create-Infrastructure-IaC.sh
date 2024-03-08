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
  echo -e "* Error: ${rood}$1${reset}\n*\n* Exiting script."
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

welcome_message

# Functie: Check of de script als root wordt uitgevoerd.
[ "$EUID" -ne 0 ] && error_exit "Script must be run as root: sudo $0"

# Functie: Check if the Google Cloud CLI is installed.
if [ ! command -v gcloud &> /dev/null ]; then
  error_exit "Google Cloud CLI is not installed. Please install it before running this script."
fi

# Start Deployment
success "Starting deployment..."

# Functie: Create a new project.
gcloud projects create $Projectid &> /dev/null

if [ $? -eq 0 ]; then
  success "Project created successfully."
else
  error_exit "Failed to create the project. Check the error message above for details."
fi

# Functie: Set the project.
gcloud config set project $Projectid &> /dev/null

if [ $? -eq 0 ]; then
  success "Project set successfully."
else
  error_exit "Failed to set the project. Check the error message above for details."
fi

# Functie: Link the billing account to the project.
billing_account=$(gcloud beta billing accounts list --format="value(ACCOUNT_ID)" | head -n 1)
gcloud beta billing projects link $(gcloud config get-value project) --billing-account=$(gcloud beta billing accounts list --format="value(ACCOUNT_ID)") &> /dev/null

if [ -n "$billing_account" ]; then
  gcloud beta billing projects link $(gcloud config get-value project) --billing-account="$billing_account" &> /dev/null

  if [ $? -eq 0 ]; then
    success "Billing account linked successfully."
  else
    error_exit "Failed to link the billing account."
  fi
else
  error_exit "No billing accounts found. Please make sure you have a billing account set up for your Google Cloud project."
fi

# Functie: Create a new PostgreSQL instance.
gcloud sql instances create db1 \
  --database-version=POSTGRES_15 \
  --tier=db-f1-micro \
  --region=europe-west1 \
  --authorized-networks=0.0.0.0/0 &> /dev/null

if [ $? -eq 0 ]; then
  success "Cloud SQL instance created successfully."
else
  error_exit "Failed to create the Cloud SQL instance."
fi

# Functie: Create a new PostgreSQL user and delete the default user.
gcloud sql users create admin --instance=db1 --password=123
gcloud sql users delete postgres --instance=db1 --quiet

if [ $? -eq 0 ]; then
  success "Cloud SQL user created successfully."
else
  error_exit "Failed to create the Cloud SQL user."
fi










#success_exit "Infrastructure created successfully."