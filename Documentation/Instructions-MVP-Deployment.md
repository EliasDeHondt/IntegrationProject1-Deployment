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
    gcloud sql instances create PostgreSQL --database-version=POSTGRES_13 --region=europe-west1
    ```

- Create a database user
    ```bash
    gcloud sql users create admin --instance=PostgreSQL --password=123
    ```
    
- Create a database
    ```bash
    gcloud sql databases create mydatabase --instance=PostgreSQL
    ```

### 👉Step 2: Create Bucket (Google Cloud Storage)

- Create a bucket in the Google Cloud Console
    ```bash	
    gsutil mb -l europe-west1 gs://mybucket
    ```


## 🔗Links
- 👯 Web hosting company [EliasDH.com](https://eliasdh.com).
- 📫 How to reach us eliasdehondt@outlook.com.