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
    5. [👉Step 4: Restore & Build The Project](#👉step-4-restore--build-the-project)
    6. [👉Step 5: Deploy The Application](#👉step-5-deploy-the-application)

---

## 🖖Introduction

This document will guide you through the process of deploying the MVP of the CodeForge application to the Google Cloud Platform. The MVP is a simple web application that is built using the .NET 7 framework. The application uses a PostgreSQL database to store data. The application is hosted on the Google Cloud Platform using the App Engine service. The database is hosted on the Google Cloud Platform using the Cloud SQL service. The application is deployed using the Google Cloud CLI.

## ✨Steps

### 👉Step 0: Preparations

- Update and upgrade system
    ```bash	
    sudo apt-get update && sudo apt-get upgrade -y
    ```

- Install the .NET SDK 7.0 or later.
    ```bash	
    sudo apt-get install dotnet-sdk-7.0
    dotnet --version # Check if the installation was successful
    ```

- Insall the Google Cloud CLI [Instructions GCloud CLI](https://github.com/EliasDeHondt/IntegrationProject1-Deployment/blob/main/Documentation/Instructions-GCloud-CLI.md)

### 👉Step 1: Create Environment / Project

- Create a new project in the Google Cloud Console
    ```bash	
    gcloud projects create $PROJECTID
    ```

- Set the project
    ```bash
    gcloud config set project $PROJECTID
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
    gcloud sql instances create db1 --database-version=POSTGRES_15 --tier=db-f1-micro --region=europe-west1 --authorized-networks=0.0.0.0/0
    ```

- Create a database user and delete the default user
    ```bash
    gcloud sql users create admin --instance=db1 --password=123
    gcloud sql users delete postgres --instance=db1 --quiet
    ```

### 👉Step 3: Clone The GitHub Repository

- Clone the repository
    ```bash
    git clone https://github.com/EliasDeHondt/IntegrationProject1-Development.git
    ```

- Navigate to the project folder
    ```bash
    cd IntegrationProject1-Development
    ```

### 👉Step 4: Restore & Build The Project

- Restore the project
    ```bash
    dotnet restore
    ```

- Build the project
    ```bash
    dotnet build
    ```

### 👉Step 5: Deploy The Application

- Deploy the application (`This can take a few minutes`)
    ```bash
    gcloud app deploy --quiet
    ```

- You can find your URL at the end of the output of the previous command.
    ```bash
    gcloud app browse
    ```








    

### 👉Step x: Create Bucket (Google Cloud Storage)

- Create a bucket in the Google Cloud Console
    ```bash	
    gsutil mb -l europe-west1 gs://mybucket
    ```






## 📦Extra

- Delete a PostgreSQL database in the Google Cloud Console
    ```bash	
    gcloud sql databases delete codeforge --instance=db1 --quiet
    ```

- Delete de google cloud project
    ```bash	
    gcloud projects delete PROJECT_ID --quiet
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

## 🔗Links
- 👯 Web hosting company [EliasDH.com](https://eliasdh.com).
- 📫 How to reach us eliasdehondt@outlook.com.