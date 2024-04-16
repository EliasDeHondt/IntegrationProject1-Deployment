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
projectid="codeforge-$(date +%Y%m%d%H%M%S)"
#projectid="codeforge-projectid"
name_service_account="codeforge-service-account"
line="*********************************************"
global_staps=10

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
  echo -e "*     ${blauw}Running CodeForge create script.${reset}      *"
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

# Functie: Create a new project.
function create_project() { # Step 1
  loading_icon 10 "* Stap 1/$global_staps:" &
  gcloud projects create $projectid > ./Create-Infrastructure-IaC.log 2>&1
  wait

  if [ $? -eq 0 ]; then
    success "Project created successfully."
  else
    error_exit "Failed to create the project."
  fi
}

# Functie: Set the project.
function set_project() { # Step 2
  loading_icon 10 "* Stap 2/$global_staps:" &
  gcloud config set project $projectid > ./Create-Infrastructure-IaC.log 2>&1
  wait

  if [ $? -eq 0 ]; then
    success "Project set successfully."
  else
    error_exit "Failed to set the project."
  fi
}

# Functie: Link the billing account to the project.
function link_billing_account() { # Step 3
  loading_icon 10 "* Stap 3/$global_staps:" &
  billing_account=$(gcloud beta billing accounts list \
    --format="value(ACCOUNT_ID)" | head -n 1)
  gcloud beta billing projects link $(gcloud config get-value project) \
    --billing-account="$billing_account" > ./Create-Infrastructure-IaC.log 2>&1
  wait

  if [ $? -eq 0 ]; then
    success "Billing account linked successfully."
  else
    error_exit "Failed to link the billing account."
  fi
}

# Functie: Enable the required APIs.
function enable_apis() { # Step 4
  loading_icon 10 "* Stap 4/$global_staps:" &
  gcloud services enable sqladmin.googleapis.com > ./Create-Infrastructure-IaC.log 2>&1
  gcloud services enable cloudresourcemanager.googleapis.com > ./Create-Infrastructure-IaC.log 2>&1
  wait

  if [ $? -eq 0 ]; then
    success "APIs enabled successfully."
  else
    error_exit "Failed to enable the APIs."
  fi
}

# Functie: Create a new PostgreSQL instance.
function create_postgres_instance() { # Step 5
  loading_icon 600 "* Stap 5/$global_staps:" &
  gcloud sql instances create db1 \
    --database-version=POSTGRES_15 \
    --tier=db-f1-micro \
    --region=europe-west1 \
    --authorized-networks=0.0.0.0/0 > ./Create-Infrastructure-IaC.log 2>&1
  wait

  if [ $? -eq 0 ]; then
    success "Cloud SQL instance created successfully."
  else
    error_exit "Failed to create the Cloud SQL instance."
  fi
}

# Functie: Create a new PostgreSQL user.
function create_postgres_user() { # Step 6
  loading_icon 10 "* Stap 6/$global_staps:" &
  gcloud sql users create admin \
    --instance=db1 \
    --password=123 > ./Create-Infrastructure-IaC.log 2>&1
  gcloud sql users delete postgres \
    --instance=db1 --quiet > ./Create-Infrastructure-IaC.log 2>&1
  wait

  if [ $? -eq 0 ]; then
    success "Cloud SQL user created successfully."
  else
    error_exit "Failed to create the Cloud SQL user."
  fi
}

# Functie: Create a new PostgreSQL database.
function create_postgres_database() { # Step 7
  loading_icon 10 "* Stap 7/$global_staps:" &
  gcloud sql databases create codeforge \
    --instance=db1 > ./Create-Infrastructure-IaC.log 2>&1
  wait

  if [ $? -eq 0 ]; then
    success "Cloud SQL database created successfully."
  else
    error_exit "Failed to create the Cloud SQL database."
  fi
}

# Functie: Create a new GCloud Storage bucket.
function create_storage_bucket() { # Step 8
  loading_icon 10 "* Stap 8/$global_staps:" &
  gcloud storage buckets create gs://codeforge-video-bucket \
    --location=europe-west1 > ./Create-Infrastructure-IaC.log 2>&1
  wait

  if [ $? -eq 0 ]; then
    success "Cloud Storage bucket created successfully."
  else
    error_exit "Failed to create the Cloud Storage bucket."
  fi
}

# Functie: Create a new service account and add permissions
function create_service_account() { # Step 9
  loading_icon 10 "* Stap 9/$global_staps:" &
  gcloud iam service-accounts create $name_service_account \
    --display-name="CodeForge Service Account" \
    --description="Service account for CodeForge" > ./Create-Infrastructure-IaC.log 2>&1
  wait

  if [ $? -eq 0 ]; then
    success "Service account created successfully."
  else
    error_exit "Failed to create the service account."
  fi
}

# Functie: Add permissions to the service account.
function add_permissions_to_service_account() { # Step 10
  local user_email="${name_service_account}@${projectid}.iam.gserviceaccount.com"
  local role="roles/storage.admin"
  local json_key_file="./service-account-key.json"
  
  loading_icon 10 "* Stap 10/$global_staps:" &
  gcloud projects add-iam-policy-binding $projectid \
    --member=serviceAccount:$user_email \
    --role=$role > ./Create-Infrastructure-IaC.log 2>&1
  wait

  if [ $? -eq 0 ]; then
    success "Permissions added to the service account successfully."
  else
    error_exit "Failed to add permissions to the service account."
  fi
  # Export the service account key to a JSON file.
  gcloud iam service-accounts keys create $json_key_file \
    --iam-account=$user_email > ./Create-Infrastructure-IaC.log 2>&1
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

touch ./Create-Infrastructure-IaC.log
welcome_message
bash_validation           # Step 0

create_project            # Step 1
wait

set_project               # Step 2
wait

link_billing_account      # Step 3
wait

enable_apis               # Step 4
wait

create_postgres_instance  # Step 5
wait

create_postgres_user      # Step 6
wait

create_postgres_database  # Step 7
wait

create_storage_bucket     # Step 8
wait

create_service_account    # Step 9
wait

add_permissions_to_service_account # Step 10
wait

success_exit "Infrastructure created successfully."