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
line="*********************************************"
global_staps=11

# Default GCloud variables.
region=us-central1
zone=us-central1-c
template_name=codeforge-template
network_name=codeforge-network
subnet_name=codeforge-subnet
projectid="codeforge-$(date +%Y%m%d%H%M%S)" # projectid="codeforge-projectid"
name_service_account="codeforge-service-account"
instance_group_name=codeforge-instance-group
bucket_name=codeforge-video-bucket


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
  echo "*                                           *"
  echo -e "*     ${blauw}Running CodeForge create script.${reset}      *"
  echo "*                                           *"
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
  local EXISTING_BUCKET=$(gsutil ls | grep -o "gs://${bucket_name}/")

  if [ -z "$EXISTING_BUCKET" ]; then
    loading_icon 10 "* Step 8/$global_staps:" &
    gcloud storage buckets create $bucket_name \
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

# Functie: Create a new network if it doesn't already exist.
function create_network() { # Step 11
  local EXISTING_NETWORK=$(gcloud compute networks list --format="value(NAME)" | grep -o "^$network_name")

  if [ -z "$EXISTING_NETWORK" ]; then
    loading_icon 10 "* Step 11/$global_staps:" &
    gcloud compute networks create $network_name \
      --subnet-mode=auto \
      --bgp-routing-mode=regional > ./Create-Infrastructure-IaC.log 2>&1
    wait

    if [ $? -eq 0 ]; then
      success "Network created successfully."
    else
      error_exit "Failed to create the network."
    fi
  else
    echo -n "* Step 11/$global_staps:"
    skip "Network already exists. Skipping creation."
  fi
}

# Functie: Create a new subnet if it doesn't already exist.
function create_network_subnet() { # Step 12
  local EXISTING_SUBNET=$(gcloud compute networks subnets list --network=$network_name --format="value(NAME)" | grep -o "^$SUBNET_NAME")

  if [ -z "$EXISTING_SUBNET" ]; then
    loading_icon 10 "* Step 12/$global_staps:" &
    gcloud compute networks subnets create $SUBNET_NAME \
      --network=$network_name \
      --region=$region \
      --range=10.0.0.0/24 > ./Create-Infrastructure-IaC.log 2>&1
    wait
  
  if [ $? -eq 0 ]; then
    success "Subnet created successfully."
  else
    error_exit "Failed to create the subnet."
  fi
  else
    echo -n "* Step 12/$global_staps:"
    skip "Subnet already exists. Skipping creation."
  fi
}

# Functie: Create a new firewall rule if it doesn't already exist.
function create_firewallrule() { # Step 13
  local FIREWALL_RULE_NAME=codeforge-firewall-rule
  local EXISTING_FIREWALL_RULE=$(gcloud compute firewall-rules list --format="value(NAME)" | grep -o "^$FIREWALL_RULE_NAME")

  if [ -z "$EXISTING_FIREWALL_RULE" ]; then
    loading_icon 10 "* Step 13/$global_staps:" &
    gcloud compute firewall-rules create $FIREWALL_RULE_NAME \
      --network=$network_name \
      --allow=tcp:80,tcp:443,tcp:22 \
      --source-ranges=0.0.0.0/0 > ./Create-Infrastructure-IaC.log 2>&1
    wait

    if [ $? -eq 0 ]; then
      success "Firewall rule created successfully."
    else
      error_exit "Failed to create the firewall rule."
    fi
  else
    echo -n "* Step 13/$global_staps:"
    skip "Firewall rule already exists. Skipping creation."
  fi
}

function set_metadata() { # Step 14
  local METADATA_KEY="SSH-keys-deployment"
  local METADATA_VALUE="-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
QyNTUxOQAAACCn12QTmZi7XPe9rVZm7g9I5b2Lf7tBCNxSa5on6eo/SAAAAKDaNOpZ2jTq
WQAAAAtzc2gtZWQyNTUxOQAAACCn12QTmZi7XPe9rVZm7g9I5b2Lf7tBCNxSa5on6eo/SA
AAAEB+ENgDO216QrnGM/RC0il4n7Nx00qCQxwA09vo8seZ7afXZBOZmLtc972tVmbuD0jl
vYt/u0EI3FJrmifp6j9IAAAAHGVsaWFzLmRlaG9uZHRAc3R1ZGVudC5rZGcuYmUB
-----END OPENSSH PRIVATE KEY-----"
  local EXISTING_METADATA=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[0].key)" | grep -o "^$METADATA_KEY")

  if [ -z "$EXISTING_METADATA" ]; then
    loading_icon 10 "* Step 14/$global_staps:" &
    gcloud compute project-info add-metadata --metadata=$METADATA_KEY="$METADATA_VALUE" > ./Create-Infrastructure-IaC.log 2>&1
    wait

    if [ $? -eq 0 ]; then
      success "Metadata set successfully."
    else
      error_exit "Failed to set the metadata."
    fi
  else
    echo -n "* Step 14/$global_staps:"
    skip "Metadata already exists. Skipping setting."
  fi
}

# Functie: Create a new instance template.
function create_instance_templates() { # Step 15
  local MACHINE_TYPE=n1-standard-4
  local IMAGE_PROJECT=ubuntu-os-cloud
  local IMAGE_FAMILY=ubuntu-2004-lts
  local STARTUP_SCRIPT='
  #!/bin/bash
  # Create a new user and add it to the sudo group and home directory and login using the user:
  sudo useradd -m -s /bin/bash codeforge
  echo "codeforge:123" | sudo chpasswd
  sudo usermod -aG sudo codeforge
  sudo su - codeforge
  cd /home/codeforge
  
  
  # Update and install dependencies:
  sudo wget https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb -O /home/codeforge/packages-microsoft-prod.deb 
  sudo dpkg -i /home/codeforge/packages-microsoft-prod.deb
  sudo apt-get update -y && sudo apt-get upgrade -y
  sudo apt-get install -yq git apt-transport-https dotnet-sdk-7.0
  
  
  # Add SSH key & clone the repository from GitLab:
  mkdir /home/codeforge/.ssh
  SSH_PRIVATE_KEY=$(curl -s "http://metadata.google.internal/computeMetadata/v1/project/attributes/SSH-keys-deployment" -H "Metadata-Flavor: Google")
  sudo echo "$SSH_PRIVATE_KEY" >> /home/codeforge/.ssh/id_ed25519
  sudo chmod 700 /home/codeforge/.ssh
  sudo chmod 600 /home/codeforge/.ssh/id_ed25519
  ssh-keyscan gitlab.com >> /home/codeforge/.ssh/known_hosts
  GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=no" git clone git@gitlab.com:kdg-ti/integratieproject-1/202324/23_codeforge/development.git
  

  # Install dependencies and build the project:
  sudo wget -qO- https://raw.githubusercontent.com/creationix/nvm/v0.39.0/install.sh -d /home/codeforge | bash
  . /home/codeforge/.nvm/nvm.sh && nvm install 20.11.1
  cd /home/codeforge/development/MVC/ClientApp
  . /home/codeforge/.nvm/nvm.sh && npm rebuild && npm install && npm run build
  dotnet build
  mkdir /home/codeforge/app
  dotnet publish "MVC.csproj" -c Release -o /home/codeforge/app
  dotnet /home/codeforge/app/MVC.dll 2>> /home/codeforge/progress.txt
  '
  gcloud compute instances create codeforge-vm --source-instance-template=$template_name --zone=us-central1-c
  gcloud compute instances delete codeforge-vm --zone=us-central1-c --quiet
  gcloud compute instance-templates delete codeforge-template --quiet


  loading_icon 10 "* Stap 15/$global_staps:" &
  gcloud compute instance-templates create $template_name \
    --machine-type=$MACHINE_TYPE \
    --image-project=$IMAGE_PROJECT \
    --image-family=$IMAGE_FAMILY \
    --subnet=projects/$projectid/regions/$region/subnetworks/$subnet_name \
    --metadata=startup-script="$STARTUP_SCRIPT" > ./Create-Infrastructure-IaC.log 2>&1
  wait

  if [ $? -eq 0 ]; then
    success "Instance template created successfully."
  else
    error_exit "Failed to create the instance template."
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
      --zone=$zone > ./Create-Infrastructure-IaC.log 2>&1

    gcloud compute instance-groups managed set-autoscaling $instance_group_name \
      --zone=$zone \
      --min-num-replicas=$MIN_REPLICAS \
      --max-num-replicas=$MAX_REPLICAS \
      --target-cpu-utilization=$TARGET_CPU_UTILIZATION > ./Create-Infrastructure-IaC.log 2>&1
    wait

    if [ $? -eq 0 ]; then
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
      --port=80 > ./Create-Infrastructure-IaC.log 2>&1

    gcloud compute backend-services create $BACKEND_SERVICE_NAME \
      --protocol=HTTP \
      --health-checks=$HEALTH_CHECK_NAME \
      --global > ./Create-Infrastructure-IaC.log 2>&1

    gcloud compute backend-services add-backend $BACKEND_SERVICE_NAME \
      --instance-group=$instance_group_name \
      --instance-group-zone=$zone \
      --global > ./Create-Infrastructure-IaC.log 2>&1

    gcloud compute url-maps create $URL_MAP_NAME \
      --default-service=$BACKEND_SERVICE_NAME > ./Create-Infrastructure-IaC.log 2>&1

    gcloud compute target-http-proxies create $TARGET_PROXY_NAME \
      --url-map=$URL_MAP_NAME > ./Create-Infrastructure-IaC.log 2>&1

    gcloud compute forwarding-rules create $FORWARDING_RULE_NAME \
      --global \
      --target-http-proxy=$TARGET_PROXY_NAME \
      --ports=80 > ./Create-Infrastructure-IaC.log 2>&1
    wait

    if [ $? -eq 0 ]; then
      success "Load balancer created successfully."
    else
      error_exit "Failed to create the load balancer."
    fi
  else
    echo -n "* Step 17/$global_staps:"
    skip "Load balancer already exists. Skipping creation."
  fi
}


welcome_message           # Welcome message
bash_validation           # Step 0
touch ./Create-Infrastructure-IaC.log
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


create_network            # Step 11
wait
create_network_subnet     # Step 12
wait
create_firewallrule       # Step 13
wait

set_metadata              # Step 14
wait
create_instance_templates  # Step 15
wait
create_instance_group     # Step 16
wait
create_load_balancer      # Step 17
wait
success_exit "Infrastructure created successfully."



# gcloud compute instances create codeforge-vm --source-instance-template=$template_name --zone=us-central1-c

# gcloud compute instances delete codeforge-vm --zone=us-central1-c --quiet

# gcloud sql instances delete db1 --quiet


# gcloud compute forwarding-rules delete codeforge-forwarding-rule --global --quiet
# gcloud compute target-http-proxies delete codeforge-target-proxy --quiet
# gcloud compute url-maps delete codeforge-url-map --quiet
# gcloud compute backend-services delete codeforge-backend-service --global --quiet
# gcloud compute health-checks delete codeforge-health-check --quiet

# gcloud compute instance-groups managed delete codeforge-instance-group --zone=us-central1-c --quiet

# gcloud compute instance-templates delete codeforge-template --quiet
