#!/bin/bash
############################
# @author Elias De Hondt   #
# @see https://eliasdh.com #
# @since 01/03/2024        #
############################
# FUNCTIE: This script is used to start the application on a Google Cloud VM Ubuntu instance.

# Set the environment variables
URL="http://metadata.google.internal/computeMetadata/v1/project/attributes"
ENV_FILE="/etc/environmentvariables.conf"

export GITLAB_USERNAME=$(curl -s "$URL/GITLAB_USERNAME" -H "Metadata-Flavor: Google")
export GITLAB_TOKEN=$(curl -s "$URL/GITLAB_TOKEN" -H "Metadata-Flavor: Google")
export GOOGLE_APPLICATION_CREDENTIALS=$(curl -s "$URL/GOOGLE_APPLICATION_CREDENTIALS" -H "Metadata-Flavor: Google")
export GOOGLE_APPLICATION_CREDENTIALS_JSON=$(curl -s "$URL/GOOGLE_APPLICATION_CREDENTIALS_JSON" -H "Metadata-Flavor: Google")

variables=(
    "ASPNETCORE_ENVIRONMENT"
    "ASPNETCORE_POSTGRES_HOST"
    "ASPNETCORE_POSTGRES_PORT"
    "ASPNETCORE_POSTGRES_DATABASE"
    "ASPNETCORE_POSTGRES_USER"
    "ASPNETCORE_POSTGRES_PASSWORD"
    "ASPNETCORE_STORAGE_BUCKET"
    "ASPNETCORE_EMAIL"
    "ASPNETCORE_EMAIL_PASSWORD"
    "GROQ_API_KEY"
    "GOOGLE_APPLICATION_CREDENTIALS"
)

for var in "${variables[@]}"; do
    value=$(curl -s "$URL/$var" -H "Metadata-Flavor: Google")
    if [ -n "$value" ]; then echo "$var='$value'" >> "$ENV_FILE"; fi
done

# Set the permissions for the environment variables file
chmod 600 /etc/environmentvariables.conf

# Set the time
timedatectl set-timezone Europe/Brussels

# Check if necessary packages are installed
if ! dpkg -l dotnet-sdk-7.0 &> /dev/null || ! dpkg -l git  &> /dev/null || ! dpkg -l wget &> /dev/null || ! dpkg -l apt-transport-https &> /dev/null; then
    sudo apt-get update && sudo apt-get install -y wget apt-transport-https
    wget https://packages.microsoft.com/config/debian/10/packages-microsoft-prod.deb -O /tmp/packages-microsoft-prod.deb
    sudo dpkg -i /tmp/packages-microsoft-prod.deb && sudo rm /tmp/packages-microsoft-prod.deb
    sudo apt-get update && sudo apt-get upgrade -y
    sudo apt-get install -y git dotnet-sdk-7.0
fi

# Clone the repository and install the necessary packages
cd /root && git clone https://$GITLAB_USERNAME:$GITLAB_TOKEN@gitlab.com/kdg-ti/integratieproject-1/202324/23_codeforge/development.git

# Install Ops Agent if not already installed
if ! dpkg -l google-cloud-ops-agent  &> /dev/null; then
    curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
    sudo bash /root/add-google-cloud-ops-agent-repo.sh --also-install
    sudo rm -rf /root/add-google-cloud-ops-agent-repo.sh
fi

# Check if Node.js is installed
if ! command -v node &> /dev/null || ! command -v npm &> /dev/null; then
    wget -qO- https://raw.githubusercontent.com/creationix/nvm/v0.39.0/install.sh | bash
    . /.nvm/nvm.sh && nvm install 20.11.1
fi

# Build the application
export HOME=/root
cd /root/development/MVC/ClientApp && . /.nvm/nvm.sh && npm rebuild && npm install && npm run build

# Publish the application
cd /root/development/MVC && dotnet publish /root/development/MVC/MVC.csproj -c Release -o /root/app

# Create the systemd service
mkdir -p /var/www/dotnet
chown -R www-data:www-data /var/www/dotnet
cp -r /root/app/* /var/www/dotnet

echo $GOOGLE_APPLICATION_CREDENTIALS_JSON > $GOOGLE_APPLICATION_CREDENTIALS

cat <<EOF > /etc/systemd/system/dotnet.service
[Unit]
Description=Dotnet CodeForge Service
After=network.target

[Service]
User=www-data
WorkingDirectory=/var/www/dotnet
ExecStart=/usr/bin/dotnet /var/www/dotnet/MVC.dll
Restart=always
EnvironmentFile=/etc/environmentvariables.conf
Environment=ASPNETCORE_URLS=http://0.0.0.0:5000

[Install]
WantedBy=multi-user.target
EOF

# Start the service
systemctl daemon-reload
systemctl enable dotnet.service
systemctl start dotnet.service