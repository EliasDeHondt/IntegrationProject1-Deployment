#!/bin/bash
gcloud secrets versions access latest --secret="phygital-secrets" >> /root/.bashrc
source /root/.bashrc
echo $GIT_DIRECTORY
export DEBIAN_FRONTEND="noninteractive"
sudo deluser phygital
sudo rm -rf /home/phygital
sudo useradd -s /bin/bash -md /home/phygital phygital
sudo usermod --password phygital phygital
sudo usermod -aG sudo phygital
cd /home/phygital
sudo apt-get update 
sudo apt-get upgrade -y
sudo apt install curl wget git
curl https://packages.microsoft.com/config/debian/11/packages-microsoft-prod.deb  -O
sudo dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb
sudo apt update
sudo apt-get install -y dotnet-sdk-8.0
sudo apt-get install -y nodejs npm
if [ -d "/home/phygital/$GIT_DIRECTORY" ] ; then
    rm -rf /home/phygital/$GIT_DIRECTORY
    mkdir /home/phygital/$GIT_DIRECTORY
fi
git clone $GIT_URL /home/phygital/$GIT_DIRECTORY
cd /home/phygital/
mkdir /home/phygital/app
rm -rf /home/phygital/app/* 
cd /home/phygital/$GIT_DIRECTORY/UI-MVC/ClientApp 
npm install
sudo dotnet publish "/home/phygital/pm/UI-MVC/UI-MVC.csproj" -c Release -o /home/phygital/app/
sudo dotnet /home/phygital/app/Phygital.UI.MVC.dll
  
# mkdir -p /var/www/pm
# chown -R www-data:www-data /var/www/pm
# cp -r publish/* /var/www/pm

# cat <<EOF > kestrel-pm.service
# [Unit]
# Description=PM ASP.NET app

# [Service]
# WorkingDirectory=/var/www/pm
# ExecStart=/usr/bin/dotnet /var/www/pm/PM.UI.MVC.dll
# Restart=always
# Environment=ASPNETCORE_ENVIRONMENT=Test
# Environment=ASPNETCORE_URLS=http://0.0.0.0:5000

# [Install]
# WantedBy=multi-user.target
# EOF

# mv kestrel-pm.service /etc/systemd/system/
# systemctl daemon-reload
# systemctl start kestrel-pmexport

#----------------------------------------------------

# gcloud compute instances create codeforge-vm --source-instance-template=$template_name --zone=us-central1-c
# while true; do gcloud compute instances get-serial-port-output codeforge-vm --zone=us-central1-c; sleep 5; done

# gcloud compute instances delete codeforge-vm --zone=us-central1-c --quiet

# gcloud sql instances delete db1 --quiet


# gcloud compute networks subnets delete $subnet_name --region=$region --quiet
# gcloud compute networks delete $network_name --quiet


# gcloud compute forwarding-rules delete codeforge-forwarding-rule --global --quiet
# gcloud compute target-http-proxies delete codeforge-target-proxy --quiet
# gcloud compute url-maps delete codeforge-url-map --quiet
# gcloud compute backend-services delete codeforge-backend-service --global --quiet
# gcloud compute health-checks delete codeforge-health-check --quiet

# gcloud compute instance-groups managed delete codeforge-instance-group --zone=us-central1-c --quiet

# gcloud compute instance-templates delete codeforge-template --quiet

gcloud compute instances create codeforge-vm --source-instance-template=codeforge-template --zone=us-central1-c
while true; do gcloud compute instances get-serial-port-output codeforge-vm --zone=us-central1-c; sleep 5; done

gcloud compute instances delete codeforge-vm --zone=us-central1-c --quiet
gcloud compute instance-templates delete codeforge-template --quiet

# Get public IP of load balancer
gcloud compute forwarding-rules list # http://34.36.223.147/