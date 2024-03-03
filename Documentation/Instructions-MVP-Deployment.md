![logo](https://eliasdh.com/assets/media/images/logo-github.png)
# 💙🤍Instructions MVP Deployment🤍💙

## 📘Table of Contents

1. [📘Table of Contents](#📘table-of-contents)
2. [🖖Introduction](#🖖introduction)
3. [✨Steps](#✨steps)
    1. [👉Step 0: Preparations](#👉step-0-preparations)

---

## 🖖Introduction



## ✨Steps

### 👉Step 0: Preparations

- Update and upgrade system
    ```bash	
    sudo apt-get update && sudo apt-get upgrade -y
    ```

- Install the .NET SDK 8.0 or later.
    ```bash	
    sudo apt-get install dotnet-sdk-8.0
    dotnet --version # Check if the installation was successful
    ```
- Insall the Google Cloud CLI [Instructions GCloud CLI](https://github.com/EliasDeHondt/IntegrationProject1-Deployment/blob/main/Documentation/Instructions-GCloud-CLI.md)

### 👉Step 1: Create PostgreSQL Database (Google Cloud SQL)

- Create a PostgreSQL database in the Google Cloud Console
    ```bash	
    gcloud sql instances create db1 --database-version=POSTGRES_13 --tier=db-f1-micro --region=europe-west1
    ```

- Create a database user
    ```bash
    gcloud sql users create admin --instance=db1 --password=123
    ```
    
- Create a database
    ```bash
    gcloud sql databases create codeforge --instance=db1
    ```

### 👉Step 2: Create Bucket (Google Cloud Storage)

- Create a bucket in the Google Cloud Console
    ```bash	
    gsutil mb -l europe-west1 gs://mybucket
    ```

















## 📦Extra

- Get Connection String
    ```bash
    gcloud sql instances describe db1 --format="value(connectionName)"
    ```
    Or
    ```bash
    #!/bin/bash
    ############################
    # @author Elias De Hondt   #
    # @see https://eliasdh.com #
    # @since 01/03/2024        #
    ############################
    # FUNCTIE: This script is used to get the connection string for a Cloud SQL instance

    # Vervang deze waarden door de werkelijke waarden voor je Cloud SQL-instance en gebruiker
    INSTANCE_NAME="db1"
    USER_NAME="admin"
    PASSWORD="123"

    # Haal het primaire IP-adres op
    IP_ADDRESS=$(gcloud sql instances describe $INSTANCE_NAME --format="value(ipAddresses.ipAddress)")

    # Stel de standaard poort in
    PORT=5432

    # Stel de verbindingsreeks samen
    CONNECTION_STRING="Host=${IP_ADDRESS};Port=${PORT};Database=codeforge;User Id=${USER_NAME};Password=${PASSWORD}"

    echo "Connection String: ${CONNECTION_STRING}"
    ```

## 🔗Links
- 👯 Web hosting company [EliasDH.com](https://eliasdh.com).
- 📫 How to reach us eliasdehondt@outlook.com.