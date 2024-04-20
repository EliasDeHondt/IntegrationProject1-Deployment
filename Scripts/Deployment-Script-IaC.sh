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
line="***********************************************"
global_staps=17

# Default GCloud variables.
projectid="codeforge-$(date +%Y%m%d%H%M%S)" # projectid="codeforge-projectid"
region=us-central1
zone=us-central1-c
template_name=codeforge-template
network_name=codeforge-network
subnet_name=codeforge-subnet
name_service_account="codeforge-service-account"
json_key_file=codeforge-service-account-key.json
instance_group_name=codeforge-instance-group
bucket_name=gs://codeforge-video-bucket-$(date +%Y%m%d%H%M%S)/


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

# Functie: Skip afhandeling.
function skip() {
  echo -e "\n*\n* ${yellow}$1${reset}\n*"
}

# Functie: Print the welcome message.
function welcome_message() {
  clear
  echo "$line"
  echo "*                                             *"
  echo -e "* ${blauw}Welcome to the CodeForge deployment script!${reset} *"
  echo "*                                             *"
  echo "$line"
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
    gcloud projects create $projectid > ./deployment-script.log 2>&1
    local EXIT_CODE=$?
    wait

    if [ $EXIT_CODE -eq 0 ]; then
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
    gcloud config set project $projectid > ./deployment-script.log 2>&1
    local EXIT_CODE=$?
    wait

    if [ $EXIT_CODE -eq 0 ]; then
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
      --billing-account="$billing_account" > ./deployment-script.log 2>&1
    local EXIT_CODE=$?
    wait

    if [ $EXIT_CODE -eq 0 ]; then
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
  gcloud services enable sqladmin.googleapis.com > ./deployment-script.log 2>&1
  local EXIT_CODE=$?
  gcloud services enable cloudresourcemanager.googleapis.com > ./deployment-script.log 2>&1
  EXIT_CODE=$((EXIT_CODE + $?))
  gcloud services enable compute.googleapis.com > ./deployment-script.log 2>&1
  EXIT_CODE=$((EXIT_CODE + $?))
  gcloud services enable servicenetworking.googleapis.com > ./deployment-script.log 2>&1
  EXIT_CODE=$((EXIT_CODE + $?))
  gcloud services enable storage-component.googleapis.com > ./deployment-script.log 2>&1
  EXIT_CODE=$((EXIT_CODE + $?))
  wait

  if [ $EXIT_CODE -eq 0 ]; then
    success "APIs enabled successfully."
  else
    error_exit "Failed to enable the APIs."
  fi
}

# Functie: Create a new network if it doesn't already exist.
function create_network() { # Step 5
  local EXISTING_NETWORK=$(gcloud compute networks list --format="value(NAME)" | grep -o "^$network_name")

  if [ -z "$EXISTING_NETWORK" ]; then
    loading_icon 10 "* Step 5/$global_staps:" &
    gcloud compute networks create $network_name \
      --subnet-mode=auto \
      --bgp-routing-mode=regional > ./deployment-script.log 2>&1
    local EXIT_CODE=$?
    wait

    if [ $EXIT_CODE -eq 0 ]; then
      success "Network created successfully."
    else
      error_exit "Failed to create the network."
    fi
  else
    echo -n "* Step 5/$global_staps:"
    skip "Network already exists. Skipping creation."
  fi
}

# Functie: Create a new subnet if it doesn't already exist.
function create_network_subnet() { # Step 6
  local EXISTING_SUBNET=$(gcloud compute networks subnets list --network=$network_name --format="value(NAME)" | grep -o "^$subnet_name")

  if [ -z "$EXISTING_SUBNET" ]; then
    loading_icon 10 "* Step 6/$global_staps:" &
    gcloud compute networks subnets create $subnet_name \
      --network=$network_name \
      --region=$region \
      --range=10.0.0.0/24 \
      --enable-private-ip-google-access > ./deployment-script.log 2>&1
    wait

  if [ $? -eq 0 ]; then
    success "Subnet created successfully."
  else
    error_exit "Failed to create the subnet."
  fi
  else
    echo -n "* Step 6/$global_staps:"
    skip "Subnet already exists. Skipping creation."
  fi
}

# Functie: Create a new firewall rule if it doesn't already exist.
function create_firewallrule() { # Step 7
  local FIREWALL_RULE_NAME=codeforge-firewall-rule
  local EXISTING_FIREWALL_RULE=$(gcloud compute firewall-rules list --format="value(NAME)" | grep -o "^$FIREWALL_RULE_NAME")

  if [ -z "$EXISTING_FIREWALL_RULE" ]; then
    loading_icon 10 "* Step 7/$global_staps:" &
    gcloud compute firewall-rules create $FIREWALL_RULE_NAME \
      --network=$network_name \
      --allow=tcp:80,tcp:443 \
      --source-ranges=0.0.0.0/0 > ./deployment-script.log 2>&1
    local EXIT_CODE=$?
    wait

    if [ $EXIT_CODE -eq 0 ]; then
      success "Firewall rule created successfully."
    else
      error_exit "Failed to create the firewall rule."
    fi
  else
    echo -n "* Step 7/$global_staps:"
    skip "Firewall rule already exists. Skipping creation."
  fi
}

# Functie: Create a new PostgreSQL instance if it doesn't already exist.
function create_postgres_instance() { # Step 8
  local INSTANCE_NAME=db1
  local DATABASE_VERSION=POSTGRES_15
  local MACHINE_TYPE=db-f1-micro
  local EXISTING_INSTANCE=$(gcloud sql instances list --filter="name=$INSTANCE_NAME" --format="value(NAME)" 2>/dev/null)

  if [ -z "$EXISTING_INSTANCE" ]; then
    loading_icon 500 "* Stap 8/$global_staps:" &
    gcloud sql instances create $INSTANCE_NAME \
      --database-version=$DATABASE_VERSION \
      --tier=$MACHINE_TYPE \
      --region=$region \
      --authorized-networks=0.0.0.0/0 > ./deployment-script.log 2>&1
    local EXIT_CODE=$?
    wait

    if [ $EXIT_CODE -eq 0 ]; then
      success "Cloud SQL instance created successfully."
    else
      error_exit "Failed to create the Cloud SQL instance."
    fi
  else
    echo -n "* Stap 8/$global_staps:"
    skip "Cloud SQL instance already exists. Skipping creation."
  fi
}

# Functie: Create a new PostgreSQL user if it doesn't already exist.
function create_postgres_user() { # Step 9
  local INSTANCE_NAME=db1
  local DATABASE_USER=admin
  local EXISTING_USER=$(gcloud sql users list --instance=$INSTANCE_NAME | grep -o "^$DATABASE_USER")

  if [ -z "$EXISTING_USER" ]; then
    loading_icon 10 "* Stap 9/$global_staps:" &
    gcloud sql users create $DATABASE_USER \
      --instance=$INSTANCE_NAME \
      --password=123 > ./deployment-script.log 2>&1
    local EXIT_CODE=$?
    gcloud sql users delete postgres \
      --instance=$INSTANCE_NAME --quiet > ./deployment-script.log 2>&1
    EXIT_CODE=$((EXIT_CODE + $?))
    wait

    if [ $EXIT_CODE -eq 0 ]; then
      success "Cloud SQL user created successfully."
    else
      error_exit "Failed to create the Cloud SQL user."
    fi
  else
    echo -n "* Stap 9/$global_staps:"
    skip "Cloud SQL user already exists. Skipping creation."
  fi
}

# Functie: Create a new PostgreSQL database if it doesn't already exist.
function create_postgres_database() { # Step 10
  local INSTANCE_NAME=db1
  local DATABASE_NAME=codeforge
  local EXISTING_DATABASE=$(gcloud sql databases list --instance=$INSTANCE_NAME --format="value(NAME)" | grep -o "^$DATABASE_NAME")

  if [ -z "$EXISTING_DATABASE" ]; then
    loading_icon 10 "* Stap 10/$global_staps:" &
    gcloud sql databases create $DATABASE_NAME \
      --instance=$INSTANCE_NAME > ./deployment-script.log 2>&1
    local EXIT_CODE=$?
    wait

    if [ $EXIT_CODE -eq 0 ]; then
      success "Cloud SQL database created successfully."
    else
      error_exit "Failed to create the Cloud SQL database."
    fi
  else
    echo -n "* Stap 10/$global_staps:"
    skip "Cloud SQL database already exists. Skipping creation."
  fi
}

# Functie: Create a new GCloud Storage bucket if it doesn't already exist.
function create_storage_bucket() { # Step 11
  local EXISTING_BUCKET=$(gsutil ls | grep -o "${bucket_name}")

  if [ -z "$EXISTING_BUCKET" ]; then
    loading_icon 10 "* Step 11/$global_staps:" &
    gcloud storage buckets create $bucket_name \
      --location=$region > ./deployment-script.log 2>&1
    local EXIT_CODE=$?
    wait

    if [ $EXIT_CODE -eq 0 ]; then
      success "Cloud Storage bucket created successfully."
    else
      error_exit "Failed to create the Cloud Storage bucket."
    fi
  else
    echo -n "* Step 11/$global_staps:"
    skip "Cloud Storage bucket already exists. Skipping creation."
  fi
}

# Functie: Create a new service account if it doesn't already exist.
function create_service_account() { # Step 12
  local EXISTING_ACCOUNT=$(gcloud iam service-accounts list | grep -o "${name_service_account}@${projectid}.iam.gserviceaccount.com")

  if [ -z "$EXISTING_ACCOUNT" ]; then
    loading_icon 10 "* Step 12/$global_staps:" &
    gcloud iam service-accounts create $name_service_account \
      --display-name="CodeForge Service Account" \
      --description="Service account for CodeForge" > ./deployment-script.log 2>&1
    local EXIT_CODE=$?
    wait

    if [ $EXIT_CODE -eq 0 ]; then
      success "Service account created successfully."
    else
      error_exit "Failed to create the service account."
    fi
  else
    echo -n "* Step 12/$global_staps:"
    skip "Service account already exists. Skipping creation."
  fi
}

# Functie: Add permissions to the service account if it doesn't already have them.
function add_permissions_to_service_account() { # Step 13
  local USER_EMAIL="${name_service_account}@${projectid}.iam.gserviceaccount.com"
  local ROLE="roles/storage.admin"
  local EXISTING_BINDINGS=$(gcloud projects get-iam-policy $projectid --flatten="bindings[].members" --format="value(bindings.members)" | grep -o "serviceAccount:${USER_EMAIL}")

  if [ -z "$EXISTING_BINDINGS" ]; then
    loading_icon 10 "* Step 13/$global_staps:" &
    gcloud projects add-iam-policy-binding $projectid \
      --member=serviceAccount:$USER_EMAIL \
      --role=$ROLE > ./deployment-script.log 2>&1
    local EXIT_CODE=$?
    wait

    if [ $EXIT_CODE -eq 0 ]; then
      success "Permissions added to the service account successfully."
    else
      error_exit "Failed to add permissions to the service account."
    fi
  else
    echo -n "* Step 13/$global_staps:"
    skip "Permissions for the service account already exist. Skipping addition."
  fi

  # Export the service account key to a JSON file.
  gcloud iam service-accounts keys create $json_key_file \
    --iam-account=$USER_EMAIL > ./deployment-script.log 2>&1
}

# Functie: Set the metadata if it doesn't already exist.
function set_metadata() { # Step 14
  local METADATA_VALUE1="-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
QyNTUxOQAAACCn12QTmZi7XPe9rVZm7g9I5b2Lf7tBCNxSa5on6eo/SAAAAKDaNOpZ2jTq
WQAAAAtzc2gtZWQyNTUxOQAAACCn12QTmZi7XPe9rVZm7g9I5b2Lf7tBCNxSa5on6eo/SA
AAAEB+ENgDO216QrnGM/RC0il4n7Nx00qCQxwA09vo8seZ7afXZBOZmLtc972tVmbuD0jl
vYt/u0EI3FJrmifp6j9IAAAAHGVsaWFzLmRlaG9uZHRAc3R1ZGVudC5rZGcuYmUB
-----END OPENSSH PRIVATE KEY-----"
  local METADATA_VALUE2="Production"
  local METADATA_VALUE3=$(gcloud sql instances describe db1 --format="value(ipAddresses.ipAddress)" | cut -d ';' -f 1)
  local METADATA_VALUE4="5432"
  local METADATA_VALUE5="codeforge"
  local METADATA_VALUE6="admin"
  local METADATA_VALUE7="123"

  loading_icon 10 "* Step 14/$global_staps:" &
  gcloud compute project-info add-metadata --metadata="\
SSH-key-deployment=$METADATA_VALUE1,\
ASPNETCORE_ENVIRONMENT=$METADATA_VALUE2,\
ASPNETCORE_POSTGRES_HOST=$METADATA_VALUE3,\
ASPNETCORE_POSTGRES_PORT=$METADATA_VALUE4,\
ASPNETCORE_POSTGRES_DATABASE=$METADATA_VALUE5,\
ASPNETCORE_POSTGRES_USER=$METADATA_VALUE6,\
ASPNETCORE_POSTGRES_PASSWORD=$METADATA_VALUE7,\
ASPNETCORE_STORAGE_BUCKET=$bucket_name,\
GOOGLE_APPLICATION_CREDENTIALS=$json_key_file" > ./deployment-script.log 2>&1
  local EXIT_CODE=$?
  wait

  if [ $EXIT_CODE -eq 0 ]; then
    success "Metadata set successfully."
  else
    error_exit "Failed to set the metadata."
  fi
}

# Functie: Create a new instance template if it doesn't already exist.
function create_instance_templates() { # Step 15
  local MACHINE_TYPE=n1-standard-4
  local IMAGE_PROJECT=ubuntu-os-cloud
  local IMAGE_FAMILY=ubuntu-2004-lts
  local STARTUP_SCRIPT='
  #!/bin/bash

  sudo apt-get update && sudo apt-get install -y apache2
  sudo systemctl start apache2
  sudo systemctl enable apache2

  echo "Testpagina van Apache" | sudo tee /var/www/html/index.html > /dev/null
  sudo chmod 644 /var/www/html/index.html
  '

  local EXISTING_TEMPLATE=$(gcloud compute instance-templates list --format="value(NAME)" | grep -o "^$template_name")

  if [ -z "$EXISTING_TEMPLATE" ]; then
    loading_icon 10 "* Stap 15/$global_staps:" &
    gcloud compute instance-templates create $template_name \
      --machine-type=$MACHINE_TYPE \
      --image-project=$IMAGE_PROJECT \
      --image-family=$IMAGE_FAMILY \
      --subnet=projects/$projectid/regions/$region/subnetworks/$subnet_name \
      --metadata=startup-script="$STARTUP_SCRIPT" > ./deployment-script.log 2>&1
    local EXIT_CODE=$?
    wait

    if [ $EXIT_CODE -eq 0 ]; then
      success "Instance template created successfully."
    else
      error_exit "Failed to create the instance template."
    fi
  else
    echo -n "* Step 15/$global_staps:"
    skip "Instance template already exists. Skipping creation."
  fi
}

# Functie: Create a new instance group if it doesn't already exist.
function create_instance_group() { # Step 16
  local INSTANCE_GROUP_SIZE=1
  local MIN_REPLICAS=1
  local MAX_REPLICAS=5
  local TARGET_CPU_UTILIZATION=0.75

  local EXISTING_INSTANCE_GROUP=$(gcloud compute instance-groups list --format="value(NAME)" | grep -o "^$instance_group_name")

  if [ -z "$EXISTING_INSTANCE_GROUP" ]; then
    loading_icon 10 "* Step 16/$global_staps:" &
    gcloud compute instance-groups managed create $instance_group_name \
      --base-instance-name=$instance_group_name \
      --size=$INSTANCE_GROUP_SIZE \
      --template=$template_name \
      --zone=$zone > ./deployment-script.log 2>&1
    local EXIT_CODE=$?
    gcloud compute instance-groups managed set-autoscaling $instance_group_name \
      --zone=$zone \
      --min-num-replicas=$MIN_REPLICAS \
      --max-num-replicas=$MAX_REPLICAS \
      --target-cpu-utilization=$TARGET_CPU_UTILIZATION > ./deployment-script.log 2>&1
    EXIT_CODE=$((EXIT_CODE + $?))
    wait

    if [ $EXIT_CODE -eq 0 ]; then
      success "Instance group created successfully."
    else
      error_exit "Failed to create the instance group."
    fi
  else
    echo -n "* Step 16/$global_staps:"
    skip "Instance group already exists. Skipping creation."
  fi
}

# Functie: Create a new load balancer if it doesn't already exist.
function create_load_balancer() { # Step 17
  local LOAD_BALANCER_NAME=codeforge-load-balancer
  local BACKEND_SERVICE_NAME=codeforge-backend-service
  local HEALTH_CHECK_NAME=codeforge-health-check
  local URL_MAP_NAME=codeforge-url-map
  local TARGET_PROXY_NAME=codeforge-target-proxy
  local FORWARDING_RULE_NAME=codeforge-forwarding-rule
  local EXISTING_LOAD_BALANCER=$(gcloud compute forwarding-rules list --format="value(NAME)" | grep -o "^$FORWARDING_RULE_NAME")

  if [ -z "$EXISTING_LOAD_BALANCER" ]; then
    loading_icon 10 "* Step 17/$global_staps:" &
    gcloud compute health-checks create http $HEALTH_CHECK_NAME \
      --port=80 > ./deployment-script.log 2>&1
    local EXIT_CODE=$?
    gcloud compute backend-services create $BACKEND_SERVICE_NAME \
      --protocol=HTTP \
      --health-checks=$HEALTH_CHECK_NAME \
      --global > ./deployment-script.log 2>&1
    EXIT_CODE=$((EXIT_CODE + $?))
    gcloud compute backend-services add-backend $BACKEND_SERVICE_NAME \
      --instance-group=$instance_group_name \
      --instance-group-zone=$zone \
      --global > ./deployment-script.log 2>&1
    EXIT_CODE=$((EXIT_CODE + $?))
    gcloud compute url-maps create $URL_MAP_NAME \
      --default-service=$BACKEND_SERVICE_NAME > ./deployment-script.log 2>&1
    EXIT_CODE=$((EXIT_CODE + $?))
    gcloud compute target-http-proxies create $TARGET_PROXY_NAME \
      --url-map=$URL_MAP_NAME > ./deployment-script.log 2>&1
    EXIT_CODE=$((EXIT_CODE + $?))
    gcloud compute forwarding-rules create $FORWARDING_RULE_NAME \
      --global \
      --target-http-proxy=$TARGET_PROXY_NAME \
      --ports=80 > ./deployment-script.log 2>&1
    EXIT_CODE=$((EXIT_CODE + $?))
    wait

    if [ $EXIT_CODE -eq 0 ]; then
      success "Load balancer created successfully."
    else
      error_exit "Failed to create the load balancer."
    fi
  else
    echo -n "* Step 17/$global_staps:"
    skip "Load balancer already exists. Skipping creation."
  fi
}

# Functie: Delete the project if it exists.
function delete_project() {
  local EXISTING_PROJECTS=$(gcloud projects list 2>/dev/null | grep -o "^$Projectid")

  if [ -z "$EXISTING_PROJECTS" ]; then
    error_exit "Project does not exist."
  fi
  
  loading_icon 10 "* Deleting project $Projectid:" &
  gcloud projects delete $Projectid --quiet > ./deployment-script.log 2>&1
  local EXIT_CODE=$?
  wait

  if [ $EXIT_CODE -eq 0 ]; then
    success "Project deleted successfully."
  else
    error_exit "Failed to delete the project."
  fi
}

welcome_message
bash_validation
touch ./deployment-script.log

# Ask the user what they want to do. Do they want to create the infrastructure or delete?
echo -e "*"
echo -e "* [1] Create the infrastructure\n* [2] Delete the infrastructure"
read -p "* Enter the number of your choice: " choice
echo -e "*"
if [ "$choice" == "1" ]; then
  welcome_message
  echo -e "*"
  create_project          # Step 1
  wait
  set_project             # Step 2
  wait
  link_billing_account    # Step 3
  wait
  enable_apis             # Step 4
  wait
  create_network          # Step 5
  wait
  create_network_subnet   # Step 6
  wait
  create_firewallrule     # Step 7
  wait
  create_postgres_instance # Step 8
  wait
  create_postgres_user    # Step 9
  wait
  create_postgres_database # Step 10
  wait
  create_storage_bucket   # Step 11
  wait
  create_service_account  # Step 12
  wait
  add_permissions_to_service_account # Step 13
  wait
  set_metadata            # Step 14
  wait
  create_instance_templates # Step 15
  wait
  create_instance_group   # Step 16
  wait
  create_load_balancer    # Step 17
  wait
  success_exit "Infrastructure created successfully."
elif [ "$choice" == "2" ]; then
  welcome_message
  echo -e "*"
  echo -n "* Delete project (id): "
  read Projectid
  delete_project
  wait
  success_exit "Infrastructure deleted successfully."
else
  error_exit "Invalid choice."
fi