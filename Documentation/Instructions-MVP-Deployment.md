![logo](https://eliasdh.com/assets/media/images/logo-github.png)
# 💙🤍Instructions MVP Deployment🤍💙

## 📘Table of Contents

1. [📘Table of Contents](#📘table-of-contents)
2. [🖖Introduction](#🖖introduction)
3. [✨Steps](#✨steps)
    1. [👉Step 0: Preparations](#👉step-0-preparations)
    2. [👉Step 1: Create Environment / Project](#👉step-1-create-environment--project)
    3. [👉Step 2: Create PostgreSQL Database (Google Cloud SQL)](#👉step-2-create-postgresql-database-google-cloud-sql)
    4. [👉Step 3: Clone The GitHub Repository](#👉step-3-clone-the-github-repository)
    5. [👉Step 6: Deploy The Application](#👉step-4-deploy-the-application)
    6. [👉Step 7: Configure Custom Domain](#👉step-5-configure-custom-domain)
4. [📦Extra](#📦extra)
5. [🔗Links](#🔗links)

---

## 🖖Introduction

This document will guide you through the process of deploying the MVP of the CodeForge application to the Google Cloud Platform. The MVP is a simple web application that is built using the .NET 7 framework. The application uses a PostgreSQL database to store data. The application is hosted on the Google Cloud Platform using the App Engine service. The database is hosted on the Google Cloud Platform using the Cloud SQL service. The application is deployed using the Google Cloud CLI.

## ✨Steps

### 👉Step 0: Preparations

- Insall the Google Cloud CLI [Instructions GCloud CLI](https://github.com/EliasDeHondt/IntegrationProject1-Deployment/blob/main/Documentation/Instructions-GCloud-CLI.md)

### 👉Step 1: Create Environment / Project

- Create a new project in the Google Cloud Console
    ```bash	
    gcloud projects create $PROJECT_ID
    ```
- Set the project
    ```bash
    gcloud config set project $PROJECT_ID
    ```
- Set the billing account
    ```bash
    gcloud beta billing projects link $(gcloud config get-value project) --billing-account=$(gcloud beta billing accounts list --format="value(ACCOUNT_ID)")
    ```
- Enable the required services
    ```bash	
    gcloud services enable sqladmin.googleapis.com
    gcloud services enable appengineflex.googleapis.com
    ```
- Make sure to create your application first.
    ```bash	
    gcloud app create --region=europe-west1 --project=$(gcloud config get-value project)
    ```

### 👉Step 2: Create PostgreSQL Database (Google Cloud SQL)

- Create a PostgreSQL database in the Google Cloud Console (`This can take a few minutes`)
    ```bash	
    gcloud sql instances create $INSTANCE_NAME --database-version=POSTGRES_15 --tier=db-f1-micro --region=europe-west1 --authorized-networks=0.0.0.0/0
    ```
- Create a database user and delete the default user
    ```bash
    gcloud sql users create $USERNAME --instance=$INSTANCE_NAME --password=$PASSWORD
    gcloud sql users delete postgres --instance=$INSTANCE_NAME --quiet
    ```
- Create a database
    ```bash
    gcloud sql databases create $DATABASE_NAME --instance=$INSTANCE_NAME
    ```

### 👉Step 3: Clone The GitHub Repository
- Clone the repository
    ```bash
    git clone https://github.com/EliasDeHondt/IntegrationProject1-Development.git
    cd IntegrationProject1-Development
    ```

### 👉Step 4: Deploy The Application

- Deploy the application (`This can take a few minutes`)
    ```bash
    gcloud app deploy --quiet
    ```

### 👉Step 5: Configure Custom Domain

- Verify your domain (`This can take a day for the DNS to propagate it depends on the domain provider and the TTL`)
    ```bash
    gcloud domains verify $DOMAIN_NAME
    ```
- Add your custom domain
    ```bash
    gcloud domains create-mapping $DOMAIN_NAME --project=$(gcloud config get-value project)
    ```
- Configure SSL
    ```bash
    gcloud beta app domain-mappings update $DOMAIN_NAME --certificate-management=managed --project=$(gcloud config get-value project)
    ```
- You can find your URL at the end of the output of the previous command.
    ```bash
    gcloud app browse
    ```

## 📦Extra

- Delete a PostgreSQL database in the Google Cloud Console
    ```bash	
    gcloud sql databases delete $DATABASE_NAME --instance=$INSTANCE_NAME --quiet
    ```
- Delete de google cloud project
    ```bash	
    gcloud projects delete $(gcloud config get-value project) --quiet
    ```
- Get Connection String
    ```bash
    #!/bin/bash
    ############################
    # @author Elias De Hondt   #
    # @see https://eliasdh.com #
    # @since 01/03/2024        #
    ############################
    # FUNCTIE: This script is used to get the connection string for a Cloud SQL instance
    INSTANCE_NAME="db1"
    USER_NAME="admin"
    PASSWORD="123"
    PORT=5432

    IP_ADDRESS=$(gcloud sql instances describe $INSTANCE_NAME --format="value(ipAddresses[0].ipAddress)")
    CONNECTION_STRING="Host=${IP_ADDRESS};Port=${PORT};Database=codeforge;User Id=${USER_NAME};Password=${PASSW>
    echo "Connection String: ${CONNECTION_STRING}"
    ```
- Navigate to the project folder
    ```bash
    cd IntegrationProject1-Development/MVC/ClientApp
    npm rebuild
    npm run build
    cd ../../
    ```
- Restore the project
    ```bash
    dotnet restore
    ```
- Build the project
    ```bash
    dotnet build
    ```

## 🔗Links
- 👯 Web hosting company [EliasDH.com](https://eliasdh.com).
- 📫 How to reach us elias.dehondt@outlook.com