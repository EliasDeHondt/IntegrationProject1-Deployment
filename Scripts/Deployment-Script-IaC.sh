#!/bin/bash
############################
# @author Elias De Hondt   #
# @see https://eliasdh.com #
# @since 01/03/2024        #
############################
# FUNCTIE: This script is used to deploy the infrastructure for the CodeForge project. Or delete the infrastructure.
reset='\e[0m'
rood='\e[0;31m'
blauw='\e[0;34m'
yellow='\e[0;33m'
groen='\e[0;32m'
global_staps=17

# Default GCloud variables.
projectid="codeforge-$(date +%Y%m%d%H%M%S)" # projectid="codeforge-projectid"
region=us-central1
zone=us-central1-c
template_name=codeforge-template
network_name=codeforge-network
subnet_name=codeforge-subnet
name_service_account="codeforge-service-account"
instance_group_name=codeforge-instance-group
user_email="${name_service_account}@${projectid}.iam.gserviceaccount.com"
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

# Functie: Banner message.
function banner_message() {
  clear
  local MESSAGE="$1"
  local LENGTH=$(( ${#MESSAGE} + 2 ))
  line="*$(printf "%${LENGTH}s" | tr ' ' '*')*"
  local LINE1="*$(printf "%${LENGTH}s" | tr ' ' ' ')*"
  echo "$line" && echo "$LINE1"
  echo -e "* ${blauw}$MESSAGE${reset} *"
  echo "$LINE1" && echo "$line"
}

# Functie: Bash validatie.
function bash_validation() {
  if [ -z "$BASH_VERSION" ]; then error_exit "This script must be run using Bash."; fi
  [ "$EUID" -ne 0 ] && error_exit "Script must be run as root: sudo $0"
  if ! command -v gcloud &> /dev/null; then error_exit "Google Cloud CLI is not installed. Please install it before running this script."; fi
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
  local CURRENT_BILLING_ACCOUNT=$(gcloud beta billing projects describe $(gcloud config get-value project) --format="value(billingAccountName)")

  if [ -z "$CURRENT_BILLING_ACCOUNT" ]; then
    loading_icon 10 "* Step 3/$global_staps:" &
    billing_account=$(gcloud beta billing accounts list --format="value(ACCOUNT_ID)" | head -n 1)
    gcloud beta billing projects link $(gcloud config get-value project) \
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
  local FIREWALL_RULE_NAME=codeforge-firewall-rule
  local EXISTING_FIREWALL_RULE=$(gcloud compute firewall-rules list --format="value(NAME)" | grep -o "^$FIREWALL_RULE_NAME")

  if [ -z "$EXISTING_FIREWALL_RULE" ]; then
    loading_icon 10 "* Step 7/$global_staps:" &
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

    if [ $EXIT_CODE -eq 0 ]; then success "Cloud SQL instance created successfully."; else error_exit "Failed to create the Cloud SQL instance."; fi
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

    if [ $EXIT_CODE -eq 0 ]; then success "Cloud SQL user created successfully."; else error_exit "Failed to create the Cloud SQL user."; fi
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

    if [ $EXIT_CODE -eq 0 ]; then success "Cloud SQL database created successfully."; else error_exit "Failed to create the Cloud SQL database."; fi
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

    if [ $EXIT_CODE -eq 0 ]; then success "Cloud Storage bucket created successfully."; else error_exit "Failed to create the Cloud Storage bucket."; fi
  else
    echo -n "* Step 11/$global_staps:"
    skip "Cloud Storage bucket already exists. Skipping creation."
  fi
}

# Functie: Create a new service account if it doesn't already exist.
function create_service_account() { # Step 12
  local EXISTING_ACCOUNT=$(gcloud iam service-accounts list | grep -o "${user_email}")

  if [ -z "$EXISTING_ACCOUNT" ]; then
    loading_icon 10 "* Step 12/$global_staps:" &
    gcloud iam service-accounts create $name_service_account \
      --display-name="CodeForge Service Account" \
      --description="Service account for CodeForge" > ./deployment-script.log 2>&1
    local EXIT_CODE=$?
    wait

    if [ $EXIT_CODE -eq 0 ]; then success "Service account created successfully."; else error_exit "Failed to create the service account."; fi
  else
    echo -n "* Step 12/$global_staps:"
    skip "Service account already exists. Skipping creation."
  fi
}

# Functie: Add permissions to the service account if it doesn't already have them.
function add_permissions_to_service_account() { # Step 13
  local ROLE="roles/storage.admin"
  local EXISTING_BINDINGS=$(gcloud projects get-iam-policy $projectid --flatten="bindings[].members" --format="value(bindings.members)" | grep -o "serviceAccount:${user_email}")

  if [ -z "$EXISTING_BINDINGS" ]; then
    loading_icon 10 "* Step 13/$global_staps:" &
    gcloud projects add-iam-policy-binding $projectid \
      --member=serviceAccount:$user_email \
      --role=$ROLE > ./deployment-script.log 2>&1
    local EXIT_CODE=$?
    wait

    if [ $EXIT_CODE -eq 0 ]; then success "Permissions added to the service account successfully."; else error_exit "Failed to add permissions to the service account."; fi
  else
    echo -n "* Step 13/$global_staps:"
    skip "Permissions for the service account already exist. Skipping addition."
  fi
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

  gcloud iam service-accounts keys create service-account-key.json --iam-account=$user_email > ./deployment-script.log 2>&1
  local EXIT_CODE=$?
  loading_icon 10 "* Step 14/$global_staps:" &
  gcloud compute project-info add-metadata --metadata="SSH-key-deployment=$METADATA_VALUE1,ASPNETCORE_ENVIRONMENT=$METADATA_VALUE2,ASPNETCORE_POSTGRES_HOST=$METADATA_VALUE3,ASPNETCORE_POSTGRES_PORT=$METADATA_VALUE4,ASPNETCORE_POSTGRES_DATABASE=$METADATA_VALUE5,ASPNETCORE_POSTGRES_USER=$METADATA_VALUE6,ASPNETCORE_POSTGRES_PASSWORD=$METADATA_VALUE7,ASPNETCORE_STORAGE_BUCKET=$bucket_name" > ./deployment-script.log 2>&1
  EXIT_CODE=$((EXIT_CODE + $?))
  gcloud compute project-info add-metadata --metadata=GOOGLE_APPLICATION_CREDENTIALS=service-account-key.json > ./deployment-script.log 2>&1
  EXIT_CODE=$((EXIT_CODE + $?))
  wait

  rm -f service-account-key.json
  if [ $EXIT_CODE -eq 0 ]; then success "Metadata set successfully."; else error_exit "Failed to set the metadata."; fi
}

# Functie: Create a new instance template if it doesn't already exist.
function create_instance_templates() { # Step 15
  local MACHINE_TYPE=n1-standard-2
  local IMAGE_PROJECT=ubuntu-os-cloud
  local IMAGE_FAMILY=ubuntu-2004-lts
  local STARTUP_SCRIPT='
  #!/bin/bash
  URL="http://metadata.google.internal/computeMetadata/v1/project/attributes"
  SSH_PRIVATE_KEY=$(curl -s "$URL/SSH-key-deployment" -H "Metadata-Flavor: Google")
  export ASPNETCORE_ENVIRONMENT=$(curl -s "$URL/ASPNETCORE_ENVIRONMENT" -H "Metadata-Flavor: Google")
  export ASPNETCORE_POSTGRES_HOST=$(curl -s "$URL/ASPNETCORE_POSTGRES_HOST" -H "Metadata-Flavor: Google")
  export ASPNETCORE_POSTGRES_PORT=$(curl -s "$URL/ASPNETCORE_POSTGRES_PORT" -H "Metadata-Flavor: Google")
  export ASPNETCORE_POSTGRES_DATABASE=$(curl -s "$URL/ASPNETCORE_POSTGRES_DATABASE" -H "Metadata-Flavor: Google")
  export ASPNETCORE_POSTGRES_USER=$(curl -s "$URL/ASPNETCORE_POSTGRES_USER" -H "Metadata-Flavor: Google")
  export ASPNETCORE_POSTGRES_PASSWORD=$(curl -s "$URL/ASPNETCORE_POSTGRES_PASSWORD" -H "Metadata-Flavor: Google")
  export ASPNETCORE_STORAGE_BUCKET=$(curl -s "$URL/ASPNETCORE_STORAGE_BUCKET" -H "Metadata-Flavor: Google")
  export GOOGLE_APPLICATION_CREDENTIALS=$(curl -s "$URL/GOOGLE_APPLICATION_CREDENTIALS" -H "Metadata-Flavor: Google")

  mkdir -p /root/.ssh
  echo "$SSH_PRIVATE_KEY" > /root/.ssh/id_ed25519
  chmod 600 /root/.ssh/id_ed25519
  ssh-keyscan gitlab.com >> /root/.ssh/known_hosts

  sudo apt-get update && sudo apt-get install -y wget apt-transport-https
  wget https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb -O /tmp/packages-microsoft-prod.deb
  sudo dpkg -i /tmp/packages-microsoft-prod.deb && sudo rm /tmp/packages-microsoft-prod.deb
  sudo apt-get update && sudo apt-get upgrade -y
  sudo apt-get install -y git dotnet-sdk-7.0

  # cd /root && GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=no" git clone --single-branch --branch MVP git@gitlab.com:kdg-ti/integratieproject-1/202324/23_codeforge/development.git
  cd /root && GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=no" git clone git@gitlab.com:kdg-ti/integratieproject-1/202324/23_codeforge/development.git

  wget -qO- https://raw.githubusercontent.com/creationix/nvm/v0.39.0/install.sh | bash
  . /.nvm/nvm.sh && nvm install 20.11.1

  export HOME=/root
  cd /root/development/MVC/ClientApp && . /.nvm/nvm.sh && npm rebuild && npm install && npm run build
  cd /root/development/MVC && dotnet publish /root/development/MVC/MVC.csproj -c Release -o /root/app && dotnet /root/app/MVC.dll --urls=http://0.0.0.0:5000
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

    if [ $EXIT_CODE -eq 0 ]; then success "Instance template created successfully."; else error_exit "Failed to create the instance template."; fi
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
  local TARGET_CPU_UTILIZATION=0.80   # 80%
  local COOL_DOWN_PERIOD=60           # 1 Minute
  local EXISTING_INSTANCE_GROUP=$(gcloud compute instance-groups list --format="value(NAME)" | grep -o "^$instance_group_name")

  if [ -z "$EXISTING_INSTANCE_GROUP" ]; then
    loading_icon 20 "* Step 16/$global_staps:" &
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
      --cool-down-period=$COOL_DOWN_PERIOD \
      --target-cpu-utilization=$TARGET_CPU_UTILIZATION > ./deployment-script.log 2>&1
    EXIT_CODE=$((EXIT_CODE + $?))
    wait

    if [ $EXIT_CODE -eq 0 ]; then success "Instance group created successfully."; else error_exit "Failed to create the instance group."; fi
  else
    echo -n "* Step 16/$global_staps:"
    skip "Instance group already exists. Skipping creation."
  fi
}

# Functie: Create a new load balancer if it doesn't already exist.
function create_load_balancer() {
  local LOAD_BALANCER_NAME=codeforge-load-balancer
  local BACKEND_SERVICE_NAME=codeforge-backend-service
  local HEALTH_CHECK_NAME=codeforge-health-check
  local URL_MAP_NAME=codeforge-url-map
  local TARGET_PROXY_NAME=codeforge-target-proxy
  local FORWARDING_RULE_NAME=codeforge-forwarding-rule
  local EXISTING_LOAD_BALANCER=$(gcloud compute forwarding-rules list --format="value(NAME)" | grep -o "^$FORWARDING_RULE_NAME")

  if [ -z "$EXISTING_LOAD_BALANCER" ]; then
    loading_icon 20 "* Step 17/$global_staps:" &
    # Create a health check
    gcloud compute health-checks create http $HEALTH_CHECK_NAME --port=5000 > ./deployment-script.log 2>&1
    local EXIT_CODE=$?
    
    # Create a backend service
    gcloud compute backend-services create $BACKEND_SERVICE_NAME --protocol=HTTP --health-checks=$HEALTH_CHECK_NAME --global > ./deployment-script.log 2>&1
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
    gcloud compute ssl-certificates create codeforge-ssl-certificate --domains=codeforge.eliasdh.com --global
    EXIT_CODE=$((EXIT_CODE + $?))

    # Create a target HTTPS proxy
    gcloud compute target-https-proxies create $TARGET_PROXY_NAME --url-map=$URL_MAP_NAME --ssl-certificates=codeforge-ssl-certificate > ./deployment-script.log 2>&1
    EXIT_CODE=$((EXIT_CODE + $?))
    
    # Create a forwarding rule
    gcloud compute forwarding-rules create $FORWARDING_RULE_NAME --global --target-https-proxy=$TARGET_PROXY_NAME --ports=443 > ./deployment-script.log 2>&1
    EXIT_CODE=$((EXIT_CODE + $?))
    wait

    if [ $EXIT_CODE -eq 0 ]; then 
      success "Load balancer created successfully."; 
    else 
      error_exit "Failed to create the load balancer."; 
    fi
  else
    echo -n "* Step 17/$global_staps:"
    skip "Load balancer already exists. Skipping creation."
  fi
}

# Functie: Create the infrastructure.
function create_infrastructure { # Choice 1 and 3
  echo -e "*"
  read -p "* Do you want to override the default variables? (Y/n): " configure
  if [ "$configure" == "Y" ] || [ "$configure" == "y" ] || [ -z "$configure" ]; then
    echo -e "*"
    echo -n "* Enter the region: "
    read region
    echo -n "* Enter the zone: "
    read zone
    if [ -z "$projectid" ] || [ -z "$region" ] || [ -z "$zone" ]; then error_exit "Please enter all the required variables."; fi
  elif [ "$configure" == "n" ]; then
    echo -e "*"
    echo -n "* Using the default variables."
  else
    error_exit "Invalid choice."
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
  create_postgres_instance; wait              # Step 8
  create_postgres_user; wait                  # Step 9
  create_postgres_database; wait              # Step 10
  create_storage_bucket; wait                 # Step 11
  create_service_account; wait                # Step 12
  add_permissions_to_service_account; wait    # Step 13
  set_metadata; wait                          # Step 14
  create_instance_templates; wait             # Step 15
  create_instance_group; wait                 # Step 16
  create_load_balancer; wait                  # Step 17
}

# Functie: Delete the project if it exists.
function delete_project() { # Choice 2
  local EXISTING_PROJECTS=$(gcloud projects list 2>/dev/null | grep -o "^$projectid")

  if [ -z "$EXISTING_PROJECTS" ]; then error_exit "Project does not exist."; fi

  loading_icon 10 "* Deleting project $projectid:" &
  gcloud projects delete $projectid --quiet > ./deployment-script.log 2>&1
  local EXIT_CODE=$?
  wait

  if [ $EXIT_CODE -eq 0 ]; then success "Project deleted successfully."; else error_exit "Failed to delete the project."; fi
}

# Functie: View the CodeForge dashboard.
function view_dashboard() { # Choice 4
  while true; do
    banner_message "Viewing the CodeForge dashboard."
    sleep 5
  done
}

# Function: Select a project and set it as the current project.
function select_project() {
  echo -e "*\n* Available projects:"
  gcloud projects list --format="value(projectId)" | nl -w 3 -s "] " | while read -r line; do echo -e "*   [$line"; done
  echo -e "*\n* Enter the project number or ID: \c"
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
  projectname=$(gcloud projects describe $projectid --format="value(name)")
  gcloud config set project $projectid > ./deployment-script.log 2>&1
  echo "* Selected project: $projectname" && projectid=$projectname
  sleep 4
}

# Functie: Main function.
function main {
  banner_message "Welcome to the CodeForge deployment script!"
  bash_validation
  touch ./deployment-script.log

  echo -e "*\n* ${blauw}[1]${reset} Create the infrastructure\n* ${blauw}[2]${reset} Update the infrastructure\n* ${blauw}[3]${reset} Delete the infrastructures\n* ${blauw}[4]${reset} View dashboard\n* ${blauw}[5]${reset} Exit"
  read -p "* Enter the number of your choice: " choice
  echo -e "*"
  if [ "$choice" == "1" ]; then
    banner_message "Creating the infrastructure."
    create_infrastructure 0
    success_exit "Infrastructure created successfully. Public IP address of the load balancer: $(gcloud compute forwarding-rules list --format="value(IPAddress)" | grep -o "^[0-9.]*")"
  elif [ "$choice" == "2" ]; then
    banner_message "Updating the infrastructure."
    create_infrastructure 1
    success_exit "Infrastructure updated successfully. Public IP address of the load balancer: $(gcloud compute forwarding-rules list --format="value(IPAddress)" | grep -o "^[0-9.]*")"
  elif [ "$choice" == "3" ]; then
    banner_message "Deleting the infrastructure."
    select_project
    delete_project; wait
    success_exit "Infrastructure deleted successfully."
  elif [ "$choice" == "4" ]; then
    banner_message "Viewing the CodeForge dashboard."
    select_project
    view_dashboard
  elif [ "$choice" == "5" ]; then
    success_exit "Exiting script."
  else
    error_exit "Invalid choice."
  fi
}

main # Start the script.