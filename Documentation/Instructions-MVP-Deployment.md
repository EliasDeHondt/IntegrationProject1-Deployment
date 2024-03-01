![logo](/Images/logo.png)
# 💙🤍Instructions MVP Deployment🤍💙



---

## 📘Table of Contents

1. [Introduction](#introduction)
3. [Steps](#steps)


---

## 🖖Introduction



## ✨Steps

### 👉 Step 0: Preparing

- Install the [Cloud CLI](/Documentation/Instructions-GCloud-CLI.md).
- Create a new directory for the app and change to that directory.
    ```bash
    mkdir YOUR_APP_NAME
    cd YOUR_APP_NAME
    ```
- Enable billing for your project.
    ```bash
    gcloud alpha billing projects link YOUR_PROJECT_ID --billing-account YOUR_BILLING_ACCOUNT_ID
    ```

### 👉 Step 1: Create a new Google Cloud project

- Create a new Google Cloud project or select an existing project. Replace `YOUR_PROJECT_ID` with your project ID.
    ```bash
    gcloud projects create YOUR_PROJECT_ID
    ```
- Set the project ID.
    ```bash
    gcloud config set project YOUR_PROJECT_ID
    ```

### 👉 Step 2: Enable the Cloud Build API

- Enable the Cloud Build API.
    ```bash
    gcloud services enable cloudbuild.googleapis.com
    ```

### 👉 Step 3: Create the app

```bash
gcloud init
sudo apt-get install google-cloud-sdk-app-engine-go
gcloud app create --project=YOUR_PROJECT_ID
gcloud components install app-engine-go
```


## 🔗Links
- 👯 Web hosting company [EliasDH.com](https://eliasdh.com).
- 📫 How to reach us eliasdehondt@outlook.com.