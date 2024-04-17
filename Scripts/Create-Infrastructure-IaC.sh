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
yellow='\e[0;33m'
groen='\e[0;32m'
projectid="codeforge-$(date +%Y%m%d%H%M%S)"
#projectid="codeforge-projectid"
name_service_account="codeforge-service-account"
line="*********************************************"
global_staps=11
region=europe-west1


# Functie: Error afhandeling.
function error_exit() {
  echo -e "*\n* ${rood}$1${reset}\n*\n* Exiting script.\n${line}"
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

function skip() {
  echo -e "\n*\n* ${yellow}$1${reset}\n*"
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

# Functie: Create a new project if it doesn't already exist.
function create_project() { # Step 1
  local EXISTING_PROJECTS=$(gcloud projects list 2>/dev/null | grep -o "^$projectid")

  if [ -z "$EXISTING_PROJECTS" ]; then
    loading_icon 10 "* Stap 1/$global_staps:" &
    gcloud projects create $projectid > ./Create-Infrastructure-IaC.log 2>&1
    wait

    if [ $? -eq 0 ]; then
      success "Project created successfully."
    else
      error_exit "Failed to create the project."
    fi
  else
    echo -n "* Stap 1/$global_staps:"
    skip "Project already exists. Skipping creation."
  fi
}

# Functie: Set the project if it's not already set.
function set_project() { # Step 2
  local CURRENT_PROJECT=$(gcloud config get-value project)

  if [ "$CURRENT_PROJECT" != "$projectid" ]; then
    loading_icon 5 "* Step 2/$global_staps:" &
    gcloud config set project $projectid > ./Create-Infrastructure-IaC.log 2>&1
    wait

    if [ $? -eq 0 ]; then
      success "Project set successfully."
    else
      error_exit "Failed to set the project."
    fi
  else
    echo -n "* Step 2/$global_staps:"
    skip "Project is already set to $projectid. Skipping setting."
  fi
}

# Functie: Link the billing account to the project if it's not already linked.
function link_billing_account() { # Step 3
  local CURRENT_BILLING_ACCOUNT=$(gcloud beta billing projects describe $(gcloud config get-value project) --format="value(billingAccountName)")

  if [ -z "$CURRENT_BILLING_ACCOUNT" ]; then
    loading_icon 10 "* Step 3/$global_staps:" &
    billing_account=$(gcloud beta billing accounts list --format="value(ACCOUNT_ID)" | head -n 1)
    gcloud beta billing projects link $(gcloud config get-value project) \
      --billing-account="$billing_account" > ./Create-Infrastructure-IaC.log 2>&1
    wait

    if [ $? -eq 0 ]; then
      success "Billing account linked successfully."
    else
      error_exit "Failed to link the billing account."
    fi
  else
    echo -n "* Step 3/$global_staps:"
    skip "Project is already linked to a billing account. Skipping linking."
  fi
}

# Functie: Enable the required APIs.
function enable_apis() { # Step 4
  loading_icon 10 "* Stap 4/$global_staps:" &
  gcloud services enable sqladmin.googleapis.com > ./Create-Infrastructure-IaC.log 2>&1
  gcloud services enable cloudresourcemanager.googleapis.com > ./Create-Infrastructure-IaC.log 2>&1
  gcloud services enable compute.googleapis.com > ./Create-Infrastructure-IaC.log 2>&1
  wait

  if [ $? -eq 0 ]; then
    success "APIs enabled successfully."
  else
    error_exit "Failed to enable the APIs."
  fi
}

# Functie: Create a new PostgreSQL instance if it doesn't already exist.
function create_postgres_instance() { # Step 5
  local INSTANCE_NAME=db1
  local DATABASE_VERSION=POSTGRES_15
  local MACHINE_TYPE=db-f1-micro
  local EXISTING_INSTANCE=$(gcloud sql instances list --filter="name=$INSTANCE_NAME" --format="value(NAME)" 2>/dev/null)

  if [ -z "$EXISTING_INSTANCE" ]; then
    loading_icon 500 "* Stap 5/$global_staps:" &
    gcloud sql instances create $INSTANCE_NAME \
      --database-version=$DATABASE_VERSION \
      --tier=$MACHINE_TYPE \
      --region=$region \
      --authorized-networks=0.0.0.0/0 > ./Create-Infrastructure-IaC.log 2>&1
    wait

    if [ $? -eq 0 ]; then
      success "Cloud SQL instance created successfully."
    else
      error_exit "Failed to create the Cloud SQL instance."
    fi
  else
    echo -n "* Stap 5/$global_staps:"
    skip "Cloud SQL instance already exists. Skipping creation."
  fi
}

# Functie: Create a new PostgreSQL user if it doesn't already exist.
function create_postgres_user() { # Step 6
  local INSTANCE_NAME=db1
  local DATABASE_USER=admin
  local EXISTING_USER=$(gcloud sql users list --instance=$INSTANCE_NAME | grep -o "^$DATABASE_USER")

  if [ -z "$EXISTING_USER" ]; then
    loading_icon 10 "* Stap 6/$global_staps:" &
    gcloud sql users create $DATABASE_USER \
      --instance=$INSTANCE_NAME \
      --password=123 > ./Create-Infrastructure-IaC.log 2>&1
    gcloud sql users delete postgres \
      --instance=$INSTANCE_NAME --quiet > ./Create-Infrastructure-IaC.log 2>&1
    wait

    if [ $? -eq 0 ]; then
      success "Cloud SQL user created successfully."
    else
      error_exit "Failed to create the Cloud SQL user."
    fi
  else
    echo -n "* Stap 6/$global_staps:"
    skip "Cloud SQL user already exists. Skipping creation."
  fi
}

# Functie: Create a new PostgreSQL database if it doesn't already exist.
function create_postgres_database() { # Step 7
  local INSTANCE_NAME=db1
  local DATABASE_NAME=codeforge
  local EXISTING_DATABASE=$(gcloud sql databases list --instance=$INSTANCE_NAME --format="value(NAME)" | grep -o "^$DATABASE_NAME")

  if [ -z "$EXISTING_DATABASE" ]; then
    loading_icon 10 "* Stap 7/$global_staps:" &
    gcloud sql databases create $DATABASE_NAME \
      --instance=$INSTANCE_NAME > ./Create-Infrastructure-IaC.log 2>&1
    wait

    if [ $? -eq 0 ]; then
      success "Cloud SQL database created successfully."
    else
      error_exit "Failed to create the Cloud SQL database."
    fi
  else
    echo -n "* Stap 7/$global_staps:"
    skip "Cloud SQL database already exists. Skipping creation."
  fi
}

# Functie: Create a new GCloud Storage bucket if it doesn't already exist.
function create_storage_bucket() { # Step 8
  local BUCKET_NAME=codeforge-video-bucket
  local EXISTING_BUCKET=$(gsutil ls | grep -o "gs://${BUCKET_NAME}/")

  if [ -z "$EXISTING_BUCKET" ]; then
    loading_icon 10 "* Step 8/$global_staps:" &
    gcloud storage buckets create $BUCKET_NAME \
      --location=$region > ./Create-Infrastructure-IaC.log 2>&1
    wait

    if [ $? -eq 0 ]; then
      success "Cloud Storage bucket created successfully."
    else
      error_exit "Failed to create the Cloud Storage bucket."
    fi
  else
    echo -n "* Step 8/$global_staps:"
    skip "Cloud Storage bucket already exists. Skipping creation."
  fi
}

# Functie: Create a new service account if it doesn't already exist.
function create_service_account() { # Step 9
  local EXISTING_ACCOUNT=$(gcloud iam service-accounts list | grep -o "${name_service_account}@${projectid}.iam.gserviceaccount.com")

  if [ -z "$EXISTING_ACCOUNT" ]; then
    loading_icon 10 "* Step 9/$global_staps:" &
    gcloud iam service-accounts create $name_service_account \
      --display-name="CodeForge Service Account" \
      --description="Service account for CodeForge" > ./Create-Infrastructure-IaC.log 2>&1
    wait

    if [ $? -eq 0 ]; then
      success "Service account created successfully."
    else
      error_exit "Failed to create the service account."
    fi
  else
    echo -n "* Step 9/$global_staps:"
    skip "Service account already exists. Skipping creation."
  fi
}

# Functie: Add permissions to the service account if it doesn't already have them.
function add_permissions_to_service_account() { # Step 10
  local USER_EMAIL="${name_service_account}@${projectid}.iam.gserviceaccount.com"
  local ROLE="roles/storage.admin"
  local EXISTING_BINDINGS=$(gcloud projects get-iam-policy $projectid --flatten="bindings[].members" --format="value(bindings.members)" | grep -o "serviceAccount:${USER_EMAIL}")

  if [ -z "$EXISTING_BINDINGS" ]; then
    loading_icon 10 "* Step 10/$global_staps:" &
    gcloud projects add-iam-policy-binding $projectid \
      --member=serviceAccount:$USER_EMAIL \
      --role=$ROLE > ./Create-Infrastructure-IaC.log 2>&1
    wait

    if [ $? -eq 0 ]; then
      success "Permissions added to the service account successfully."
    else
      error_exit "Failed to add permissions to the service account."
    fi
  else
    echo -n "* Step 10/$global_staps:"
    skip "Permissions for the service account already exist. Skipping addition."
  fi

  # Export the service account key to a JSON file.
  gcloud iam service-accounts keys create $json_key_file \
    --iam-account=$USER_EMAIL > ./Create-Infrastructure-IaC.log 2>&1
}

# Functie: Create a new VM instance.
function create_vm_instance() { # Step 11
  local INSTANCE_NAME=codeforge-vm
  local MACHINE_TYPE=f1-micro
  local IMAGE_PROJECT=ubuntu-os-cloud
  local IMAGE_FAMILY=ubuntu-2004-lts
  local ZONE=europe-west1-c
  local STARTUP_SCRIPT='
  sudo apt-get update -y && sudo apt-get upgrade -y
  '

  loading_icon 10 "* Stap 11/$global_staps:" &
  gcloud compute instances create $INSTANCE_NAME \
    --machine-type=$MACHINE_TYPE \
    --image-project=$IMAGE_PROJECT \
    --image-family=$IMAGE_FAMILY \
    --zone=$ZONE \
    --metadata=startup-script=\"$STARTUP_SCRIPT\"
  wait

  if [ $? -eq 0 ]; then
    success "VM instance created successfully."
  else
    error_exit "Failed to create the VM instance."
  fi
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

#create_vm_instance        # Step 11
#wait

success_exit "Infrastructure created successfully."