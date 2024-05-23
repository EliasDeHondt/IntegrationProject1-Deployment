#!/bin/bash
############################
# @author Elias De Hondt   #
# @see https://eliasdh.com #
# @since 01/03/2024        #
############################

projectid=codeforge-20240514045342

# Cascading delete for instance template.
gcloud compute forwarding-rules delete codeforge-forwarding-rule --global --quiet
gcloud compute target-https-proxies delete codeforge-target-proxy --quiet
gcloud compute url-maps delete codeforge-url-map --quiet
gcloud compute backend-services delete codeforge-backend-service --global --quiet
gcloud compute instance-groups managed delete codeforge-instance-group --zone=us-central1-c --quiet
gcloud compute instance-templates delete codeforge-template --quiet

# Delete the vm instance.
gcloud compute instances delete codeforge-instance-group-432q --zone=us-central1-c --quiet

# Create a new instance template.
gcloud compute instance-templates create codeforge-template \
    --machine-type=n1-standard-4 \
    --image-project=ubuntu-os-cloud \
    --image-family=ubuntu-2004-lts \
    --no-address \
    --subnet=projects/$projectid/regions/us-central1/subnetworks/codeforge-subnet \
    --metadata-from-file=startup-script=Startup-Script-Gcloud-DotNet-Ubuntu.sh
gcloud compute instance-groups managed create codeforge-instance-group \
    --base-instance-name=codeforge-instance-group \
    --size=1 \
    --template=codeforge-template \
    --zone=us-central1-c
gcloud compute instance-groups managed set-autoscaling codeforge-instance-group \
    --zone=us-central1-c \
    --min-num-replicas=1 \
    --max-num-replicas=5 \
    --cool-down-period=60 \
    --target-cpu-utilization=0.80
gcloud compute backend-services create codeforge-backend-service \
    --protocol=HTTP \
    --health-checks=codeforge-health-check \
    --session-affinity=CLIENT_IP \
    --global
gcloud compute backend-services add-backend codeforge-backend-service \
    --instance-group=codeforge-instance-group \
    --instance-group-zone=us-central1-c \
    --global
gcloud compute instance-groups set-named-ports codeforge-instance-group \
    --named-ports=http:5000 \
    --zone=us-central1-c
gcloud compute url-maps create codeforge-url-map \
    --default-service=codeforge-backend-service
gcloud compute target-https-proxies create codeforge-target-proxy \
    --url-map=codeforge-url-map \
    --ssl-certificates=codeforge-ssl-certificate
gcloud compute forwarding-rules create codeforge-forwarding-rule \
    --target-https-proxy=codeforge-target-proxy \
    --ports=443 \
    --global

# Get the IP address of the load balancer.
gcloud compute forwarding-rules list --format="value(IPAddress)"

# Get the status of the dotnet service.
systemctl status dotnet.service