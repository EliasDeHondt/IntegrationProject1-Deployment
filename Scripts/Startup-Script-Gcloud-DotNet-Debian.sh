#!/bin/bash
############################
# @author Elias De Hondt   #
# @see https://eliasdh.com #
# @since 01/03/2024        #
############################
# FUNCTIE: This script is used to start the application on a Google Cloud VM Debian instance.

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
export GOOGLE_APPLICATION_CREDENTIALS=$(curl -s "$URL/GOOGLE_APPLICATION_CREDENTIALS" -H "Metadata-Flavor: Google")

sudo apt-get update && sudo apt-get install -y wget apt-transport-https
wget https://packages.microsoft.com/config/debian/10/packages-microsoft-prod.deb -O /tmp/packages-microsoft-prod.deb
sudo dpkg -i /tmp/packages-microsoft-prod.deb && sudo rm /tmp/packages-microsoft-prod.deb
sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install -y git dotnet-sdk-7.0

cd /root && git clone https://$GITLAB_USERNAME:$GITLAB_TOKEN@gitlab.com/kdg-ti/integratieproject-1/202324/23_codeforge/development.git

wget -qO- https://raw.githubusercontent.com/creationix/nvm/v0.39.0/install.sh | bash
. /.nvm/nvm.sh && nvm install 20.11.1

export HOME=/root
cd /root/development/MVC/ClientApp && . /.nvm/nvm.sh && npm rebuild && npm install && npm run build
cd /root/development/MVC && dotnet publish /root/development/MVC/MVC.csproj -c Release -o /root/app && dotnet /root/app/MVC.dll -urls=http://0.0.0.0:5000