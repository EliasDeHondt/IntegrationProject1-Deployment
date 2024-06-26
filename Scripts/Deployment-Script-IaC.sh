#!/bin/bash
############################
# @author Elias De Hondt   #
# @see https://eliasdh.com #
# @since 01/03/2024        #
############################
# FUNCTIE: This script is used to deploy the infrastructure for the CodeForge project. Or delete the infrastructure.

# Get all the variables from the config file.
source ./Variables.conf

# Functie: Error afhandeling.
function error_exit() {
  echo -e "\n*\n* ${red}$1${reset}\n*\n* Exiting script.\n${line}"
  exit 1
}

# Functie: Succes afhandeling.
function success_exit() {
  echo -e "*\n* ${green}$1${reset}\n*\n${line}"
  exit 0
}

# Functie: Succes afhandeling.
function success() {
  echo -e "\n*\n* ${green}$1${reset}\n*"
}

# Functie: Skip afhandeling.
function skip() {
  echo -e "\n*\n* ${yellow}$1${reset}\n*"
}

# Functie: Banner message.
function banner_message() {
  clear
  local MESSAGE="$1"
  local LENGTH=$(( ${#MESSAGE} + 2 ))
  line="*$(printf "%${LENGTH}s" | tr ' ' '*')*"
  local LINE1="*$(printf "%${LENGTH}s" | tr ' ' ' ')*"
  echo "$line" && echo "$LINE1"
  echo -e "* ${blue}$MESSAGE${reset} *"
  echo "$LINE1" && echo "$line"
}

# Functie: Checks if there were any options given to the script.
function options_check() {
  case "$1" in
    --create) create_infrastructure 0;;
    -c) create_infrastructure 0;;
    --update) create_infrastructure 1;;
    -u) create_infrastructure 1;;
    --delete) delete_infrastructure;;
    -d) delete_infrastructure;;
    --help) echo -e "*\n* ${yellow}Usage:${reset}\n*   ./Deployment-Script-IaC.sh [OPTION]\n*\n* ${yellow}Options:${reset}\n*   --create, -c    Create the infrastructure.\n*   --update, -u    Update the infrastructure.\n*   --delete, -d    Delete the infrastructure.\n*   --help, -h      Display this help message.\n*"
    success_exit;;
    -h) echo -e "*\n* ${yellow}Usage:${reset}\n*   ./Deployment-Script-IaC.sh [OPTION]\n*\n* ${yellow}Options:${reset}\n*   --create, -c    Create the infrastructure.\n*   --update, -u    Update the infrastructure.\n*   --delete, -d    Delete the infrastructure.\n*   --help, -h      Display this help message.\n*"
    success_exit;;
  esac
}

# Functie: Bash validatie.
function bash_validation() {
  # Check if the script is run using Bash.
  if [ -z "$BASH_VERSION" ]; then error_exit "This script must be run using Bash."; fi

  # Check if the script is not run as root.
  if [ "$EUID" -eq 0 ]; then error_exit "This script must not be run as root."; fi

  # Check if the Google Cloud CLI is installed.
  if ! command -v gcloud &> /dev/null; then error_exit "Google Cloud CLI is not installed. Please install it before running this script."; fi

  # Check if the startup script exists.
  if [ ! -f "./deployment-script.log" ]; then touch ./deployment-script.log; fi
  if [ ! -f "./Variables.conf" ]; then error_exit "Variables file not found."; fi
  if [ ! -f "./Startup-Script-Gcloud-DotNet-Ubuntu.sh" ]; then error_exit "Startup script for Ubuntu not found."; fi
  if [ ! -f "./Startup-Script-Gcloud-DotNet-Debian.sh" ]; then error_exit "Startup script for Debian not found."; fi
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

# Functie: Select a backup of the SQL instance.
function backup_configuration_select() {
  echo -e "*\n* Available Backups:"
  local backups=$(gcloud sql backups list --instance=$sql_instance_name --format="value(ID,startTime)")
  local backup_count=$(echo "$backups" | wc -l)
  if [ $backup_count -eq 0 ]; then error_exit "No backups found."; fi
    echo "$backups" | nl -w 3 -s "]${reset} " | while read -r line; do
    echo -e "*   ${blue}[$line"
  done
  echo -e "*\n* Enter the number of the backup you want to select: \c"
  read backup_number
  if [[ "$backup_number" =~ ^[0-9]+$ ]]; then
    if [ $backup_number -gt 0 ] && [ $backup_number -le $backup_count ]; then
      backup_id=$(echo "$backups" | sed -n "${backup_number}p" | awk '{print $1}')
    else
      error_exit "Invalid backup number."
    fi
  else
    error_exit "Invalid backup number."
  fi
}

# Function: Select a project and set it as the current project.
function select_project() {
  banner_message "Selecting a project."

  local current_project=$(gcloud config get-value project 2>/dev/null)
  if [ -n "$current_project" ]; then
    local current_project_name=$(gcloud projects describe $current_project --format="value(name)" 2>/dev/null)
    echo -e "*\n* Current project Name and ID: ${green}$current_project_name${reset} (${green}$current_project${reset})"
  else
    echo -e "*\n* No project currently set."
  fi

  echo -e "*\n* Available projects:"
  gcloud projects list --format="value(projectId)" | nl -w 3 -s "]${reset} " | while read -r line; do echo -e "*   ${blue}[$line"; done
  echo -e "*\n* Enter the project ID: \c"
  read project_input

  if [[ "$project_input" =~ ^[0-9]+$ ]]; then
    num_projects=$(gcloud projects list --format="value(projectId)" | wc -l)
    if (( project_input <= num_projects )); then
      projectid=$(gcloud projects list --format="value(projectId)" | sed -n "${project_input}p")
    else
      error_exit "Invalid project number. Please enter a valid project number."
    fi
  else
    error_exit "Invalid input. Please enter a valid project number."
  fi

  if [ "$current_project" == "$projectid" ]; then
    echo -e "*\n* Project is already set to ${green}$current_project_name${reset} (${green}$current_project${reset}). No changes made."
  else
    projectname=$(gcloud projects describe $projectid --format="value(name)" 2>/dev/null)
    gcloud config set project $projectid > ./deployment-script.log 2>&1
    echo -e "*\n* Selected project: ${green}$projectname${reset} (${green}$projectid${reset})"
  fi

  sleep 4
}

# Functie: Undo the project deletion.
function undo_project_deletion() {
  echo -e "*"
  read -p "* Do you want to undo the deletion? (Y/n): " undo
  if [ "$undo" == "Y" ] || [ "$undo" == "y" ] || [ -z "$undo" ]; then
    loading_icon 10 "* Restoring project $projectid:" &
    gcloud projects undelete $projectid --quiet > ./deployment-script.log 2>&1
    local EXIT_CODE=$?
    wait

    if [ $EXIT_CODE -eq 0 ]; then success "Project restored successfully."; else error_exit "Failed to restore the project."; fi
  elif [ "$undo" == "n" ]; then
    echo -e "*"
    echo "* Project deletion not undone."
  else
    error_exit "Invalid choice."
  fi
}

# Functie: Create a new project if it doesn't already exist.
function create_project() { # Step 1
  local EXISTING_PROJECTS=$(gcloud projects list 2>/dev/null | grep -o "^$projectid")

  if [ -z "$EXISTING_PROJECTS" ]; then
    loading_icon 10 "* Stap 1/$global_staps:" &
    gcloud projects create $projectid > ./deployment-script.log 2>&1
    local EXIT_CODE=$?
    wait

    if [ $EXIT_CODE -eq 0 ]; then success "Project created successfully."; else error_exit "Failed to create the project."; fi
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

    if [ $EXIT_CODE -eq 0 ]; then success "Project set successfully."; else error_exit "Failed to set the project."; fi
  else
    echo -n "* Step 2/$global_staps:"
    skip "Project is already set to $projectid. Skipping setting."
  fi
}

# Functie: Link the billing account to the project if it's not already linked.
function link_billing_account() { # Step 3
  local CURRENT_BILLING_ACCOUNT=$(gcloud billing projects describe $(gcloud config get-value project) --format="value(billingAccountName)")

  if [ -z "$CURRENT_BILLING_ACCOUNT" ]; then
    loading_icon 10 "* Step 3/$global_staps:" &
    billing_account=$(gcloud billing accounts list --format="value(ACCOUNT_ID)" | head -n 1)
    gcloud billing projects link $(gcloud config get-value project) \
      --billing-account="$billing_account" > ./deployment-script.log 2>&1
    local EXIT_CODE=$?
    wait

    if [ $EXIT_CODE -eq 0 ]; then success "Billing account linked successfully."; else error_exit "Failed to link the billing account."; fi
  else
    echo -n "* Step 3/$global_staps:"
    skip "Project is already linked to a billing account. Skipping linking."
  fi
}

# Functie: Enable the required APIs.
function enable_apis() { # Step 4
  loading_icon 15 "* Stap 4/$global_staps:" &
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
  gcloud services enable gmail.googleapis.com > ./deployment-script.log 2>&1
  EXIT_CODE=$((EXIT_CODE + $?))
  wait

  if [ $EXIT_CODE -eq 0 ]; then success "APIs enabled successfully."; else error_exit "Failed to enable the APIs."; fi
}

# Functie: Create a new network if it doesn't already exist.
function create_network() { # Step 5
  local EXISTING_NETWORK=$(gcloud compute networks list --format="value(NAME)" | grep -o "^$network_name")

  if [ -z "$EXISTING_NETWORK" ]; then
    loading_icon 15 "* Step 5/$global_staps:" &
    gcloud compute networks create $network_name \
      --subnet-mode=auto \
      --bgp-routing-mode=regional > ./deployment-script.log 2>&1
    local EXIT_CODE=$?
    wait

    if [ $EXIT_CODE -eq 0 ]; then success "Network created successfully."; else error_exit "Failed to create the network."; fi
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

  if [ $? -eq 0 ]; then success "Subnet created successfully.";  else error_exit "Failed to create the subnet."; fi
  else
    echo -n "* Step 6/$global_staps:"
    skip "Subnet already exists. Skipping creation."
  fi
}

# Functie: Create a new firewall rule if it doesn't already exist.
function create_firewallrule() { # Step 7
  local FIREWALL_RULE_NAME="codeforge-firewall-rule"
  local EXISTING_FIREWALL_RULE=$(gcloud compute firewall-rules list --format="value(NAME)" | grep -o "^$FIREWALL_RULE_NAME")

  if [ -z "$EXISTING_FIREWALL_RULE" ]; then
    loading_icon 20 "* Step 7/$global_staps:" &
    gcloud compute firewall-rules create $FIREWALL_RULE_NAME \
      --network=$network_name \
      --allow=tcp:5000,tcp:22 \
      --source-ranges=0.0.0.0/0 > ./deployment-script.log 2>&1
    local EXIT_CODE=$?
    wait

    if [ $EXIT_CODE -eq 0 ]; then success "Firewall rule created successfully."; else error_exit "Failed to create the firewall rule."; fi
  else
    echo -n "* Step 7/$global_staps:"
    skip "Firewall rule already exists. Skipping creation."
  fi
}

# Functie: Create a new router if it doesn't already exist.
function create_router() { # Step 8
  local EXISTING_ROUTER=$(gcloud compute routers list --format="value(NAME)" | grep -o "^$router_name")

  if [ -z "$EXISTING_ROUTER" ]; then
    loading_icon 10 "* Step 8/$global_staps:" &
    gcloud compute routers create $router_name \
      --network=$network_name \
      --region=$region > ./deployment-script.log 2>&1
    local EXIT_CODE=$?
    wait

    if [ $EXIT_CODE -eq 0 ]; then success "Router created successfully."; else error_exit "Failed to create the router."; fi
  else
    echo -n "* Step 8/$global_staps:"
    skip "Router already exists. Skipping creation."
  fi
}

# Functie: Create a new Cloud NAT for all instances in the subnet if it doesn't already exist.
function create_nat() { # Stap 9
  local NAT_NAME="nat1"
  local EXISTING_NAT=$(gcloud compute routers nats list --router=$router_name --router-region=$region --format="value(NAME)" | grep -o "^$NAT_NAME")

  if [ -z "$EXISTING_NAT" ]; then
    loading_icon 10 "* Stap 9/$global_staps:" &
    gcloud compute routers nats create $NAT_NAME \
      --router=$router_name \
      --nat-all-subnet-ip-ranges \
      --router-region=$region \
      --auto-allocate-nat-external-ips > ./deployment-script.log 2>&1
    local EXIT_CODE=$?
    wait

    if [ $EXIT_CODE -eq 0 ]; then success "Cloud NAT created successfully."; else error_exit "Failed to create the Cloud NAT."; fi
  else
    echo -n "* Stap 9/$global_staps:"
    skip "Cloud NAT already exists. Skipping creation."
  fi
}

# Functie: Create a new VPC network peering if it doesn't already exist.
function create_vpc_network_peering() { # Step 10
  local EXISTING_PEERING=$(gcloud compute addresses list --global --format="value(NAME)" | grep -o "^$peering_name")

  if [ -z "$EXISTING_PEERING" ]; then
    loading_icon 10 "* Step 10/$global_staps:" &
    gcloud compute addresses create $peering_name \
      --global \
      --purpose=VPC_PEERING \
      --prefix-length=24 \
      --network=$network_name > ./deployment-script.log 2>&1
    local EXIT_CODE=$?
    wait

    if [ $EXIT_CODE -eq 0 ]; then success "VPC network peering created successfully."; else error_exit "Failed to create the VPC network peering."; fi
  else
    echo -n "* Step 10/$global_staps:"
    skip "VPC network peering already exists. Skipping creation."
  fi
}

# Functie: Add the VPC network peering to the Google Cloud Services.
function add_vpc_network_peering() { # Step 11
  local EXISTING_PEERING=$(gcloud services vpc-peerings list --network=$network_name --format="value(NAME)" | grep -o "^$peering_name")

  if [ -z "$EXISTING_PEERING" ]; then
    loading_icon 10 "* Step 11/$global_staps:" &
    gcloud services vpc-peerings connect \
      --service=servicenetworking.googleapis.com \
      --ranges=$peering_name \
      --network=$network_name > ./deployment-script.log 2>&1
    local EXIT_CODE=$?
    wait

    if [ $EXIT_CODE -eq 0 ]; then success "VPC network peering added successfully."; else error_exit "Failed to add the VPC network peering."; fi
  else
    echo -n "* Step 11/$global_staps:"
    skip "VPC network peering already exists. Skipping addition."
  fi
}

# Functie: Create a new PostgreSQL instance if it doesn't already exist.
function create_postgres_instance() { # Step 12
  local DATABASE_VERSION="POSTGRES_15"
  local EXISTING_INSTANCE=$(gcloud sql instances list --filter="name=$sql_instance_name" --format="value(NAME)" 2>/dev/null)

  if [ -z "$EXISTING_INSTANCE" ]; then
    loading_icon 500 "* Stap 12/$global_staps:" &
    gcloud sql instances create $sql_instance_name \
      --database-version=$DATABASE_VERSION \
      --tier=$machine_type_db \
      --region=$region \
      --network=$network_name \
      --no-assign-ip \
      --enable-google-private-path \
      --authorized-networks=0.0.0.0/0 > ./deployment-script.log 2>&1
    local EXIT_CODE=$?
    wait

    if [ $EXIT_CODE -eq 0 ]; then success "Cloud SQL instance created successfully."; else error_exit "Failed to create the Cloud SQL instance."; fi
  else
    echo -n "* Stap 12/$global_staps:"
    skip "Cloud SQL instance already exists. Skipping creation."
  fi
}

# Functie: Create a new PostgreSQL user if it doesn't already exist.
function create_postgres_user() { # Step 13
  local DATABASE_USER="admin"
  local EXISTING_USER=$(gcloud sql users list --instance=$sql_instance_name | grep -o "^$DATABASE_USER")

  if [ -z "$EXISTING_USER" ]; then
    loading_icon 10 "* Stap 13/$global_staps:" &
    gcloud sql users create $DATABASE_USER \
      --instance=$sql_instance_name \
      --password=$db_password > ./deployment-script.log 2>&1
    local EXIT_CODE=$?
    gcloud sql users delete postgres \
      --instance=$sql_instance_name --quiet > ./deployment-script.log 2>&1
    EXIT_CODE=$((EXIT_CODE + $?))
    wait

    if [ $EXIT_CODE -eq 0 ]; then success "Cloud SQL user created successfully."; else error_exit "Failed to create the Cloud SQL user."; fi
  else
    echo -n "* Stap 13/$global_staps:"
    skip "Cloud SQL user already exists. Skipping creation."
  fi
}

# Functie: Create a new PostgreSQL database if it doesn't already exist.
function create_postgres_database() { # Step 14
  local DATABASE_NAME="codeforge"
  local EXISTING_DATABASE=$(gcloud sql databases list --instance=$sql_instance_name --format="value(NAME)" | grep -o "^$DATABASE_NAME")

  if [ -z "$EXISTING_DATABASE" ]; then
    loading_icon 10 "* Stap 14/$global_staps:" &
    gcloud sql databases create $DATABASE_NAME \
      --instance=$sql_instance_name > ./deployment-script.log 2>&1
    local EXIT_CODE=$?
    wait

    if [ $EXIT_CODE -eq 0 ]; then success "Cloud SQL database created successfully."; else error_exit "Failed to create the Cloud SQL database."; fi
  else
    echo -n "* Stap 14/$global_staps:"
    skip "Cloud SQL database already exists. Skipping creation."
  fi
}

# Functie: Create a new GCloud Storage bucket if it doesn't already exist.
function create_storage_bucket() { # Step 15
  local EXISTING_BUCKET=$(gsutil ls | awk -F'/' '{print $3}')

  if [ -z "$EXISTING_BUCKET" ]; then
    loading_icon 10 "* Step 15/$global_staps:" &
    gcloud storage buckets create gs://$bucket_name \
      --location=$region > ./deployment-script.log 2>&1
    local EXIT_CODE=$?
    wait

    if [ $EXIT_CODE -eq 0 ]; then success "Cloud Storage bucket created successfully."; else error_exit "Failed to create the Cloud Storage bucket."; fi
  else
    echo -n "* Step 15/$global_staps:"
    skip "Cloud Storage bucket already exists. Skipping creation."
  fi
}

# Functie: Create a new service account if it doesn't already exist.
function create_service_account() { # Step 16
  local EXISTING_ACCOUNT=$(gcloud iam service-accounts list | grep -o "${user_email}")

  if [ -z "$EXISTING_ACCOUNT" ]; then
    loading_icon 10 "* Step 16/$global_staps:" &
    gcloud iam service-accounts create $name_service_account \
      --display-name="CodeForge Service Account" \
      --description="Service account for CodeForge" > ./deployment-script.log 2>&1
    local EXIT_CODE=$?
    wait

    if [ $EXIT_CODE -eq 0 ]; then success "Service account created successfully."; else error_exit "Failed to create the service account."; fi
  else
    echo -n "* Step 16/$global_staps:"
    skip "Service account already exists. Skipping creation."
  fi
}

# Functie: Add permissions to the service account if it doesn't already have them.
function add_permissions_to_service_account() { # Step 17
  local ROLE="roles/storage.admin"
  local EXISTING_BINDINGS=$(gcloud projects get-iam-policy $projectid --flatten="bindings[].members" --format="value(bindings.members)" | grep -o "serviceAccount:${user_email}")

  if [ -z "$EXISTING_BINDINGS" ]; then
    loading_icon 10 "* Step 17/$global_staps:" &
    # Add storage permissions
    gcloud projects add-iam-policy-binding $projectid \
      --member=serviceAccount:$user_email \
      --role=$ROLE > ./deployment-script.log 2>&1
    local EXIT_CODE=$?
    wait

    if [ $EXIT_CODE -eq 0 ]; then success "Permissions added to the service account successfully."; else error_exit "Failed to add permissions to the service account."; fi
  else
    echo -n "* Step 17/$global_staps:"
    skip "Permissions for the service account already exist. Skipping addition."
  fi
}

# Functie: Set the metadata if it doesn't already exist.
function set_metadata() { # Step 17
  local ASPNETCORE_ENVIRONMENT="Production"
  local ASPNETCORE_POSTGRES_HOST=$(gcloud sql instances describe $sql_instance_name --format="value(ipAddresses.ipAddress)" | cut -d ';' -f 1)
  local ASPNETCORE_POSTGRES_PORT="5432"
  local ASPNETCORE_POSTGRES_DATABASE="codeforge"
  local ASPNETCORE_POSTGRES_USER="admin"
  local ASPNETCORE_EMAIL="codeforge.noreply@gmail.com"
  local ASPNETCORE_EMAIL_PASSWORD="evqb lztz oqvu kgwc"
  local GROQ_API_KEY="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"
  local GOOGLE_APPLICATION_CREDENTIALS="/var/www/dotnet/service-account-key.json"

  gcloud iam service-accounts keys create service-account-key.json --iam-account=$user_email > ./deployment-script.log 2>&1
  local EXIT_CODE=$?

  loading_icon 10 "* Step 18/$global_staps:" &
  gcloud compute project-info add-metadata --metadata="GITLAB_USERNAME=$gitlab_username,GITLAB_TOKEN=$gitlab_token,ASPNETCORE_ENVIRONMENT=$ASPNETCORE_ENVIRONMENT,ASPNETCORE_POSTGRES_HOST=$ASPNETCORE_POSTGRES_HOST,ASPNETCORE_POSTGRES_PORT=$ASPNETCORE_POSTGRES_PORT,ASPNETCORE_POSTGRES_DATABASE=$ASPNETCORE_POSTGRES_DATABASE,ASPNETCORE_POSTGRES_USER=$ASPNETCORE_POSTGRES_USER,ASPNETCORE_POSTGRES_PASSWORD=$db_password,ASPNETCORE_STORAGE_BUCKET=$bucket_name,ASPNETCORE_EMAIL=$ASPNETCORE_EMAIL,ASPNETCORE_EMAIL_PASSWORD=$ASPNETCORE_EMAIL_PASSWORD,GROQ_API_KEY=$GROQ_API_KEY" > ./deployment-script.log 2>&1
  EXIT_CODE=$((EXIT_CODE + $?))
  gcloud compute project-info add-metadata --metadata-from-file GOOGLE_APPLICATION_CREDENTIALS_JSON=service-account-key.json > ./deployment-script.log 2>&1
  EXIT_CODE=$((EXIT_CODE + $?))
  wait

  rm -f service-account-key.json
  if [ $EXIT_CODE -eq 0 ]; then success "Metadata set successfully."; else error_exit "Failed to set the metadata."; fi
}

# Functie: Create a new instance template if it doesn't already exist.
function create_instance_templates() { # Step 19
  local EXISTING_TEMPLATE=$(gcloud compute instance-templates list --format="value(NAME)" | grep -o "^$template_name")

  if [ -z "$EXISTING_TEMPLATE" ]; then
    loading_icon 10 "* Stap 19/$global_staps:" &
    gcloud compute instance-templates create $template_name \
      --machine-type=$machine_type_vm \
      --image-project=$image_project \
      --image-family=$image_family \
      --no-address \
      --subnet=projects/$projectid/regions/$region/subnetworks/$subnet_name \
      --metadata-from-file=startup-script=$startup_script > ./deployment-script.log 2>&1
    local EXIT_CODE=$?
    wait  

    if [ $EXIT_CODE -eq 0 ]; then success "Instance template created successfully."; else error_exit "Failed to create the instance template."; fi
  else
    echo -n "* Step 19/$global_staps:"
    skip "Instance template already exists. Skipping creation."
  fi
}

# Functie: Create a new instance group if it doesn't already exist.
function create_instance_group() { # Step 20
  local EXISTING_INSTANCE_GROUP=$(gcloud compute instance-groups list --format="value(NAME)" | grep -o "^$instance_group_name")

  if [ -z "$EXISTING_INSTANCE_GROUP" ]; then
    loading_icon 20 "* Step 20/$global_staps:" &
    gcloud compute instance-groups managed create $instance_group_name \
      --base-instance-name=$instance_group_name \
      --size=$instance_group_size \
      --template=$template_name \
      --zone=$zone > ./deployment-script.log 2>&1
    local EXIT_CODE=$?
    gcloud compute instance-groups managed set-autoscaling $instance_group_name \
      --zone=$zone \
      --min-num-replicas=$min_replicas \
      --max-num-replicas=$max_replicas \
      --cool-down-period=$cool_down_period \
      --target-cpu-utilization=$target_cpu_utilization > ./deployment-script.log 2>&1
    EXIT_CODE=$((EXIT_CODE + $?))
    wait

    if [ $EXIT_CODE -eq 0 ]; then success "Instance group created successfully."; else error_exit "Failed to create the instance group."; fi
  else
    echo -n "* Step 20/$global_staps:"
    skip "Instance group already exists. Skipping creation."
  fi
}

# Functie: Create a new load balancer if it doesn't already exist.
function create_load_balancer() { # Step 21
  local BACKEND_SERVICE_NAME="codeforge-backend-service"
  local HEALTH_CHECK_NAME="codeforge-health-check"
  local URL_MAP_NAME="codeforge-url-map"
  local TARGET_PROXY_NAME="codeforge-target-proxy"
  local FORWARDING_RULE_NAME="codeforge-forwarding-rule"
  local EXISTING_LOAD_BALANCER=$(gcloud compute forwarding-rules list --format="value(NAME)" | grep -o "^$FORWARDING_RULE_NAME")

  if [ -z "$EXISTING_LOAD_BALANCER" ]; then
    loading_icon 20 "* Step 21/$global_staps:" &
    # Create a health check
    gcloud compute health-checks create http $HEALTH_CHECK_NAME --port=5000 > ./deployment-script.log 2>&1
    local EXIT_CODE=$?

    # Create a backend service
    gcloud compute backend-services create $BACKEND_SERVICE_NAME --protocol=HTTP --health-checks=$HEALTH_CHECK_NAME --session-affinity=CLIENT_IP --global > ./deployment-script.log 2>&1
    EXIT_CODE=$((EXIT_CODE + $?))

    # Add backend instance group to backend service
    gcloud compute backend-services add-backend $BACKEND_SERVICE_NAME --instance-group=$instance_group_name --instance-group-zone=$zone --global > ./deployment-script.log 2>&1
    EXIT_CODE=$((EXIT_CODE + $?))

    # Set named ports
    gcloud compute instance-groups set-named-ports $instance_group_name --named-ports=http:5000 --zone=$zone > ./deployment-script.log 2>&1
    EXIT_CODE=$((EXIT_CODE + $?))

    # Create a URL map
    gcloud compute url-maps create $URL_MAP_NAME --default-service=$BACKEND_SERVICE_NAME > ./deployment-script.log 2>&1
    EXIT_CODE=$((EXIT_CODE + $?))

    # Create a SSL certificate
    gcloud compute ssl-certificates create $ssl_certificate_name --domains=$domain_name --global > ./deployment-script.log 2>&1
    EXIT_CODE=$((EXIT_CODE + $?))

    # Create a target HTTPS proxy
    gcloud compute target-https-proxies create $TARGET_PROXY_NAME --url-map=$URL_MAP_NAME --ssl-certificates=$ssl_certificate_name > ./deployment-script.log 2>&1
    EXIT_CODE=$((EXIT_CODE + $?))

    # Create a forwarding rule for HTTPS
    gcloud compute forwarding-rules create $FORWARDING_RULE_NAME --global --target-https-proxy=$TARGET_PROXY_NAME --ports=443 > ./deployment-script.log 2>&1
    EXIT_CODE=$((EXIT_CODE + $?))
    wait

    if [ $EXIT_CODE -eq 0 ]; then success "Load balancer created successfully."; else error_exit "Failed to create the load balancer."; fi
  else
    echo -n "* Step 21/$global_staps:"
    skip "Load balancer already exists. Skipping creation."
  fi
}

# Functie: Create the infrastructure.
function create_infrastructure { # Choice 1 and 3
  if [ $2 -eq 0 ]; then
    # Asking for the choice of overriding the default variables.
    echo -e "*"
    echo -e "* ${yellow}Note: Default = Variables.conf${reset}"
    read -p "* Do you want to override the default variables? (Y/n): " var_choice
    if [ "$var_choice" == "Y" ] || [ "$var_choice" == "y" ] || [ -z "$var_choice" ]; then
      echo -e "*"
      echo -n "* Enter the domain name: "
      read domain_name
      echo -n "* Enter the region: "
      read region
      echo -n "* Enter the zone: "
      read zone
      if [ -z "$domain_name" ] || [ -z "$region" ] || [ -z "$zone" ]; then error_exit "Please enter all the required variables."; fi
    elif [ "$var_choice" == "n" ]; then
      echo -e "*"
      echo -en "* ${geel}Using the default variables.${reset}"
    else
      error_exit "Invalid choice."
    fi

    # Asking for the choice of Debian or Ubuntu for VMs.
    banner_message "Creating the infrastructure."
    echo -e "*"
    echo -e "* Which OS do you want to use for the VMs? (Default: Ubuntu):\n* ${blue}[1]${reset} Ubuntu\n* ${blue}[2]${reset} Debian\n*"
    read -p "* Enter your choice: " os_choice
    if [ "$os_choice" == "1" ] || [ -z "$os_choice" ]; then
      image_project=ubuntu-os-cloud
      image_family=ubuntu-2004-lts
      startup_script=Startup-Script-Gcloud-DotNet-Ubuntu.sh
    elif [ "$os_choice" == "2" ]; then
      image_project=debian-cloud
      image_family=debian-10
      startup_script=Startup-Script-Gcloud-DotNet-Debian.sh
    else
      error_exit "Invalid choice."
    fi

    # Asking for database password.
    banner_message "Creating the infrastructure."
    echo -e "*"
    read -p "* Enter the database password: " db_password
    if [ -z "$db_password" ]; then error_exit "Please enter the database password."; fi
  fi

  if [ $1 -eq 0 ]; then
    banner_message "Creating the infrastructure."
    create_project; wait                        # Step 1
    set_project; wait                           # Step 2
  elif [ $1 -eq 1 ]; then
    banner_message "Updating the infrastructure."
    select_project
    banner_message "Updating the infrastructure."
    echo -e "*\n* ${yellow}Skipping steps 1 and 2.${reset}\n*"
  fi

  link_billing_account; wait                  # Step 3
  enable_apis; wait                           # Step 4
  create_network; wait                        # Step 5
  create_network_subnet; wait                 # Step 6
  create_firewallrule; wait                   # Step 7
  create_router; wait                         # Step 8
  create_nat; wait                            # Step 9
  create_vpc_network_peering; wait            # Step 10
  add_vpc_network_peering; wait               # Step 11
  echo -e "* ${yellow}We will wait for 5 minutes so that the network can migrate before we go to the next steps.${reset}\n*"
  sleep 300                                   # Wait for 5 minutes
  create_postgres_instance; wait              # Step 12
  create_postgres_user; wait                  # Step 13
  create_postgres_database; wait              # Step 14
  create_storage_bucket; wait                 # Step 15
  create_service_account; wait                # Step 16
  add_permissions_to_service_account; wait    # Step 17
  set_metadata; wait                          # Step 18
  create_instance_templates; wait             # Step 19
  create_instance_group; wait                 # Step 20
  create_load_balancer; wait                  # Step 21
}

# Functie: Delete the project if it exists.
function delete_project() { # Choice 2
  local EXISTING_PROJECTS=$(gcloud projects list 2>/dev/null | grep -o "^$projectid")

  if [ -z "$EXISTING_PROJECTS" ]; then error_exit "Project does not exist."; fi
  banner_message "Deleting the infrastructure."
  loading_icon 10 "* Deleting project $projectid:" &
  gcloud projects delete $projectid --quiet > ./deployment-script.log 2>&1
  local EXIT_CODE=$?
  wait

  if [ $EXIT_CODE -eq 0 ]; then success "Project deleted successfully."; else error_exit "Failed to delete the project."; fi
}

# Functie: Backup configuration of the SQL instance.
function backup_configuration() { # Choice 4
  banner_message "Backup configuration of the SQL instance."
  # This is a small sub menu for backup configuration of the SQL instance.
  echo -e "*\n* ${blue}[1]${reset} Create a backup of the SQL instance\n* ${blue}[2]${reset} Delete the SQL instance\n* ${blue}[3]${reset} Restore the SQL instance from the backup\n* ${blue}[4]${reset} List the backups of the SQL instance\n*"
  read -p "* Enter your choice: " backup_choice
  echo -e "*"
  case "$backup_choice" in
    1) backup_configuration_create;;
    2) backup_configuration_delete;;
    3) backup_configuration_restore;;
    4) backup_configuration_list;;
    *) error_exit "Invalid choice.";;
  esac
}

# Functie: Create a backup of the SQL instance.
function backup_configuration_create() { # Choice 4.1
  banner_message "Creating a backup of the SQL instance."
  local DESCRIPTION="CodeForge Backup $(date +'%Y-%m-%d %H:%M:%S')"
  local BACKUP_LOCATION="us-central1"

  loading_icon 40 "* Creating backup of the SQL instance:" &
  gcloud sql backups create \
    --instance=$sql_instance_name \
    --description="$DESCRIPTION" \
    --location=$BACKUP_LOCATION > ./deployment-script.log 2>&1
  local EXIT_CODE=$?
  wait

  if [ $EXIT_CODE -eq 0 ]; then success "Backup created successfully."; else error_exit "Failed to create the backup."; fi
  echo -e "${line}"
  sleep 10
  main
}

# Functie: Delete a backup of the SQL instance.
function backup_configuration_delete() { # Choice 4.2
  banner_message "Deleting the backup of the SQL instance."
  backup_configuration_select

  loading_icon 40 "* Deleting backup of the SQL instance:" &
  gcloud sql backups delete $backup_id --instance=$sql_instance_name --quiet > ./deployment-script.log 2>&1
  local EXIT_CODE=$?
  wait

  if [ $EXIT_CODE -eq 0 ]; then success "Backup deleted successfully."; else error_exit "Failed to delete the backup."; fi
  echo -e "${line}"
  sleep 10
  main
}

# Functie: Restore the SQL instance from the backup.
function backup_configuration_restore() { # Choice 4.3
  banner_message "Restoring the SQL instance from the backup."
  backup_configuration_select

  loading_icon 40 "* Restoring the SQL instance from the backup:" &
  gcloud sql backups restore $backup_id --restore-instance=$sql_instance_name --quiet > ./deployment-script.log 2>&1
  local EXIT_CODE=$?
  wait

  if [ $EXIT_CODE -eq 0 ]; then success "SQL instance restored successfully."; else error_exit "Failed to restore the SQL instance."; fi
  echo -e "${line}"
  sleep 10
  main
}

# Functie: List the backups of the SQL instance.
function backup_configuration_list() { # Choice 4.4
  banner_message "Listing the backups of the SQL instance."
  echo -e "* List of Backups:"
  gcloud sql backups list --instance=$sql_instance_name --format="value(name,description)" | while read -r line; do echo -e "*   $line"; done
  echo -e "*\n* ${yellow}To exit the dashboard, press CTRL + C or wait for 1 minute.${reset}\n*"
  echo -e "${line}"
  sleep 60
  main
}

# Functie: View the CodeForge dashboard.
function view_dashboard() { # Choice 5
  local red='\033[0;31m'
  local green='\033[0;32m'
  local yellow='\033[1;33m'
  local reset='\033[0m'

  # Onderdruk foutmeldingen en haal waarden op
  local IP_ADDRESS=$(gcloud compute forwarding-rules list --format="value(IPAddress)" 2>/dev/null | grep -o "^[0-9.]*")
  local NAME=$(gcloud compute forwarding-rules list --format="value(NAME)" 2>/dev/null)
  local URL="https://$domain_name"
  local INSTANCE_GROUP_SIZE=$(gcloud compute instance-groups list --format="value(SIZE)" 2>/dev/null | grep -o "^[0-9]*")
  local INSTANCE_GROUP_IPS=$(gcloud compute instances list --format="value(networkInterfaces[0].networkIP)" 2>/dev/null | tr '\n' ' ')
  local SQL_IP=$(gcloud sql instances describe $sql_instance_name --format="value(ipAddresses.ipAddress)" 2>/dev/null | cut -d ';' -f 1)
  local BUCKET_NAME=$(gsutil ls | awk -F'/' '{print $3}')
  local MIN_REPLICAS=$(gcloud compute instance-groups managed describe $instance_group_name --zone=$zone --format="value(autoscaler.autoscalingPolicy.minNumReplicas)" 2>/dev/null)
  local MAX_REPLICAS=$(gcloud compute instance-groups managed describe $instance_group_name --zone=$zone --format="value(autoscaler.autoscalingPolicy.maxNumReplicas)" 2>/dev/null)
  local COOL_DOWN_PERIOD=$(gcloud compute instance-groups managed describe $instance_group_name --zone=$zone --format="value(autoscaler.autoscalingPolicy.coolDownPeriodSec)" 2>/dev/null)
  local TARGET_CPU_UTILIZATION=$(gcloud compute instance-groups managed describe $instance_group_name --zone=$zone --format="value(autoscaler.autoscalingPolicy.cpuUtilization.utilizationTarget)" 2>/dev/null)

  # Functie om standaardwaarden in te stellen en in rood af te drukken
  function check_and_set_default() {
    local var_value="$1"
    local default_value="$2"

    if [ -z "$var_value" ]; then echo -e "${red}$default_value${reset}"
    else echo -e "${green}$var_value${reset}"; fi
  }

  IP_ADDRESS=$(check_and_set_default "$IP_ADDRESS" "0.0.0.0")
  NAME=$(check_and_set_default "$NAME" "Unknown")
  URL=$(check_and_set_default "$URL" "https://example.com")
  INSTANCE_GROUP_SIZE=$(check_and_set_default "$INSTANCE_GROUP_SIZE" "0")
  INSTANCE_GROUP_IPS=$(check_and_set_default "$INSTANCE_GROUP_IPS" "No IPs")
  SQL_IP=$(check_and_set_default "$SQL_IP" "0.0.0.0")
  BUCKET_NAME=$(check_and_set_default "$BUCKET_NAME" "No Bucket")
  MIN_REPLICAS=$(check_and_set_default "$MIN_REPLICAS" "0")
  MAX_REPLICAS=$(check_and_set_default "$MAX_REPLICAS" "0")
  COOL_DOWN_PERIOD=$(check_and_set_default "$COOL_DOWN_PERIOD" "0 sececonds")
  TARGET_CPU_UTILIZATION=$(check_and_set_default "$TARGET_CPU_UTILIZATION" "0.0%")

  banner_message "Viewing the CodeForge dashboard."
  echo -e "*\n* Load Balancer Information:"
  echo -e "*   | Name: $NAME"
  echo -e "*   | URL: $URL"
  echo -e "*   | IP Address: $IP_ADDRESS"
  echo -e "*\n* Instance Group Information:"
  echo -e "*   | Number of Instances: $INSTANCE_GROUP_SIZE"
  echo -e "*   | IP Addresses: $INSTANCE_GROUP_IPS"
  echo -e "*\n* SQL Instance Information:"
  echo -e "*   | IP Address: $SQL_IP"
  echo -e "*\n* Storage Bucket Information:"
  echo -e "*   | Name: $BUCKET_NAME"
  echo -e "*\n* Horizontal Scaling Information:"
  echo -e "*   | Minimum Replicas: $MIN_REPLICAS"
  echo -e "*   | Maximum Replicas: $MAX_REPLICAS"
  echo -e "*   | Cool Down Period: $COOL_DOWN_PERIOD sececonds"
  echo -e "*   | Target CPU Utilization: $TARGET_CPU_UTILIZATION%\n*"

  read -p "* Do you want to update the autoscaling settings? (Y/N): " update_autoscaling
  if [[ "$update_autoscaling" == "Y" || "$update_autoscaling" == "y" ]]; then
    read -p "* Enter the minimum number of replicas (current: $MIN_REPLICAS): " new_min_replicas
    read -p "* Enter the maximum number of replicas (current: $MAX_REPLICAS): " new_max_replicas
    read -p "* Enter the cool down period (current: $COOL_DOWN_PERIOD sececonds): " new_cool_down_period
    read -p "* Enter the target CPU utilization (current: $TARGET_CPU_UTILIZATION%): " new_target_cpu_utilization
    echo -n "*"

    gcloud compute instance-groups managed set-autoscaling $instance_group_name \
      --zone=$zone \
      --min-num-replicas=${new_min_replicas:-$MIN_REPLICAS} \
      --max-num-replicas=${new_max_replicas:-$MAX_REPLICAS} \
      --cool-down-period=${new_cool_down_period:-$COOL_DOWN_PERIOD} \
      --target-cpu-utilization=${new_target_cpu_utilization:-$TARGET_CPU_UTILIZATION} > ./deployment-script.log 2>&1
    if [ $? -eq 0 ]; then success "Autoscaling settings updated successfully."; else error_exit "Failed to update the autoscaling settings."; fi
  else
    echo -e "* ${yellow}Autoscaling settings not updated.${reset}"
  fi
  echo -e "*\n* ${yellow}To exit the dashboard, press CTRL + C or wait for 1 minute.${reset}\n*"
  echo -e "${line}"
  sleep 60
  main
}

# Functie: View the log file.
function view_log_file() { # Choice 6
  banner_message "          Log File          "
  echo -e "*"
  sed 's/^/* /g' ./deployment-script.log
  echo -e "*"
  echo -e "${line}"
  sleep 30
  main
}

# Functie: Send support message via Discord.
function send_support_message() { # Choice 7
  local WEBHOOK_URL="https://discord.com/api/webhooks/1234178845838413864/R8MEa3bwW91csJ_z1m5N4BG28BZmnBhvqakwI9V6QwufUflfF6fHR3l9RjNYq0ZO779F"
  local MESSAGE="Support message from the CodeForge deployment script. Please help me with the following issue:"
  banner_message "          Support          "
  echo -e "*"
  read -p "* Enter your first name: " first_name
  read -p "* Enter your last name: " last_name
  read -p "* Enter your email address: " email
  read -p "* Enter your message: " message

  curl -X POST -H "Content-Type: application/json" -d "{\"content\": \"$MESSAGE\n\n**Name:** $first_name $last_name\n**Email:** $email\n**Message:** $message\"}" $WEBHOOK_URL > ./deployment-script.log 2>&1
  echo -e "*n"
  if [ $? -eq 0 ]; then success "Support message sent successfully."; else error_exit "Failed to send the support message."; fi

  echo -e "${line}"
  sleep 30
  main
}

# Functie: Credits of the developers.
function credits() { # Choice 8
  local COLOR_ELIAS_DE_HONDT="\033[96m"             # Light cyan
  local COLOR_VINCENT_VERBOVEN="\e[91m"             # Light red
  local COLOR_VERA_WISE="\e[95m"                    # Light magenta
  local COLOR_MATTHIAS_HENDRICKX="\e[92m"           # Light green
  local COLOR_JANA_YANG="\e[93m"                    # Light yellow
  local GITGUB_URL_ELIAS_DE_HONDT="https://github.com/EliasDeHondt"
  local GITGUB_URL_VINCENT_VERBOVEN="https://github.com/Meastro85"
  local GITGUB_URL_VERA_WISE="https://github.com/VW03"
  local GITGUB_URL_MATTHIAS_HENDRICKX="https://github.com/MatthiasHendrickx"
  local GITGUB_URL_JANA_YANG="https://github.com/janayang"
  banner_message "          Credits          "
  echo -e "*\n* ${COLOR_ELIAS_DE_HONDT}Elias De Hondt${reset}"
  echo -e "*   | ${COLOR_ELIAS_DE_HONDT}GitHub: ${GITGUB_URL_ELIAS_DE_HONDT}${reset}"
  echo -e "*\n* ${COLOR_VINCENT_VERBOVEN}Vincent Verboven${reset}"
  echo -e "*   | ${COLOR_VINCENT_VERBOVEN}GitHub: ${GITGUB_URL_VINCENT_VERBOVEN}${reset}"
  echo -e "*\n* ${COLOR_VERA_WISE}Vera Wise${reset}"
  echo -e "*   | ${COLOR_VERA_WISE}GitHub: ${GITGUB_URL_VERA_WISE}${reset}"
  echo -e "*\n* ${COLOR_MATTHIAS_HENDRICKX}Matthias Hendrickx${reset}"
  echo -e "*   | ${COLOR_MATTHIAS_HENDRICKX}GitHub: ${GITGUB_URL_MATTHIAS_HENDRICKX}${reset}"
  echo -e "*\n* ${COLOR_JANA_YANG}Jana Yang${reset}"
  echo -e "*   | ${COLOR_JANA_YANG}GitHub: ${GITGUB_URL_JANA_YANG}${reset}\n*"
  echo -e "${line}"
  sleep 10
  main
}

# Functie: Main function.
function main { # Start the script.
  banner_message "Welcome to the CodeForge deployment script!"
  bash_validation
  options_check "$1"

  echo -e "*\n* ${blue}[1]${reset} Create the infrastructure\n* ${blue}[2]${reset} Update the infrastructure\n* ${blue}[3]${reset} Delete the infrastructures\n* ${blue}[4]${reset} Backup Configuration\n* ${blue}[5]${reset} View dashboard\n* ${blue}[6]${reset} View Log File\n* ${blue}[7]${reset} Support\n* ${blue}[8]${reset} Credits\n* ${blue}[9]${reset} Exit"
  read -p "* Enter the number of your choice: " choice
  echo -e "*"
  case "$choice" in
    1)
      banner_message "Creating the infrastructure."
      create_infrastructure 0 0
      success_exit "Infrastructure created successfully. Public IP address of the load balancer: $(gcloud compute forwarding-rules list --format="value(IPAddress)" | grep -o "^[0-9.]*") (https://$domain_name) $projectid"
      ;;
    2)
      banner_message "Updating the infrastructure."
      create_infrastructure 1 0
      success_exit "Infrastructure updated successfully. Public IP address of the load balancer: $(gcloud compute forwarding-rules list --format="value(IPAddress)" | grep -o "^[0-9.]*") (https://$domain_name) $projectid"
      ;;
    3)
      select_project
      delete_project; wait
      undo_project_deletion; wait
      success_exit "Infrastructure deleted successfully."
      ;;
    4)
      select_project
      backup_configuration
      ;;
    5)
      select_project
      view_dashboard
      ;;
    6) view_log_file;;
    7) send_support_message;;
    8) credits;;
    9) success_exit "Exiting script.";;
    *) error_exit "Invalid choice.";;
  esac
}

main "$1" # Start the script.