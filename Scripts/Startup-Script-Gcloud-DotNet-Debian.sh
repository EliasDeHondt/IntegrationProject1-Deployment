#!/bin/bash
############################
# @author Elias De Hondt   #
# @see https://eliasdh.com #
# @since 01/03/2024        #
############################
# FUNCTIE: This script is used to start the application on a Google Cloud VM Debian instance.

# Get the environment variables from the metadata server
URL="http://metadata.google.internal/computeMetadata/v1/project/attributes"
export GITLAB_USERNAME=$(curl -s "$URL/GITLAB_USERNAME" -H "Metadata-Flavor: Google")
export GITLAB_TOKEN=$(curl -s "$URL/GITLAB_TOKEN" -H "Metadata-Flavor: Google")
export ASPNETCORE_ENVIRONMENT=$(curl -s "$URL/ASPNETCORE_ENVIRONMENT" -H "Metadata-Flavor: Google")
export ASPNETCORE_POSTGRES_HOST=$(curl -s "$URL/ASPNETCORE_POSTGRES_HOST" -H "Metadata-Flavor: Google")
export ASPNETCORE_POSTGRES_PORT=$(curl -s "$URL/ASPNETCORE_POSTGRES_PORT" -H "Metadata-Flavor: Google")
export ASPNETCORE_POSTGRES_DATABASE=$(curl -s "$URL/ASPNETCORE_POSTGRES_DATABASE" -H "Metadata-Flavor: Google")
export ASPNETCORE_POSTGRES_USER=$(curl -s "$URL/ASPNETCORE_POSTGRES_USER" -H "Metadata-Flavor: Google")
export ASPNETCORE_POSTGRES_PASSWORD=$(curl -s "$URL/ASPNETCORE_POSTGRES_PASSWORD" -H "Metadata-Flavor: Google")
export ASPNETCORE_STORAGE_BUCKET=$(curl -s "$URL/ASPNETCORE_STORAGE_BUCKET" -H "Metadata-Flavor: Google")
export ASPNETCORE_EMAIL=$(curl -s "$URL/ASPNETCORE_EMAIL" -H "Metadata-Flavor: Google")
export ASPNETCORE_EMAIL_PASSWORD=$(curl -s "$URL/ASPNETCORE_EMAIL_PASSWORD" -H "Metadata-Flavor: Google")
export GOOGLE_APPLICATION_CREDENTIALS=$(curl -s "$URL/GOOGLE_APPLICATION_CREDENTIALS" -H "Metadata-Flavor: Google")

# Install the necessary packages
sudo apt-get update && sudo apt-get install -y wget apt-transport-https
wget https://packages.microsoft.com/config/debian/10/packages-microsoft-prod.deb -O /tmp/packages-microsoft-prod.deb
sudo dpkg -i /tmp/packages-microsoft-prod.deb && sudo rm /tmp/packages-microsoft-prod.deb
sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install -y git dotnet-sdk-7.0

# Clone the repository and install the necessary packages
cd /root && git clone https://$GITLAB_USERNAME:$GITLAB_TOKEN@gitlab.com/kdg-ti/integratieproject-1/202324/23_codeforge/development.git

# Install Ops Agent
curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
sudo bash /root/add-google-cloud-ops-agent-repo.sh --also-install
sudo rm -rf /root/add-google-cloud-ops-agent-repo.sh

# Install Node.js and build the application
wget -qO- https://raw.githubusercontent.com/creationix/nvm/v0.39.0/install.sh | bash
. /.nvm/nvm.sh && nvm install 20.11.1

# Build the application
export HOME=/root
cd /root/development/MVC/ClientApp && . /.nvm/nvm.sh && npm rebuild && npm install && npm run build

# Start the application
cd /root/development/MVC && dotnet publish /root/development/MVC/MVC.csproj -c Release -o /root/app
cd /root/app && dotnet MVC.dll --urls=http://0.0.0.0:5000