![logo](https://eliasdh.com/assets/media/images/logo-github.png)
# 💙🤍Instructions IaC Deployment🤍💙

## 📘Table of Contents

- [💙🤍Instructions IaC Deployment🤍💙](#instructions-iac-deployment)
  - [📘Table of Contents](#table-of-contents)
  - [🖖Introduction](#introduction)
  - [✨Steps](#steps)
    - [👉Step 0: Preparations](#step-0-preparations)
    - [👉Step 1: Configure Environment](#step-1-configure-environment)
    - [👉Step 2: Run Create Script](#step-2-run-create-script)
    - [👉Step 3: Configure Custom Domain](#step-3-configure-custom-domain)
  - [🔗Links](#links)

---

## 🖖Introduction

This document will guide you through the process of deploying the entire infrastructure of the CodeForge application to the Google Cloud Platform. The infrastructure is deployed using Infrastructure as Code [Deployment Script IaC](../../Scripts/Deployment-Script-IaC.sh).

## ✨Steps

### 👉Step 0: Preparations

- Insall the Google Cloud CLI [Instructions GCloud CLI](https://github.com/EliasDH-com/Documentation/blob/main/Documentation/Instructions-GCloud-CLI.md)

### 👉Step 1: Configure Environment

- Type the following command to initialize the Google Cloud CLI
    ```bash
    gcloud init
    ```
- Press `1` to log in with your Google account.
- Select your Google account.
- The step for selecting a project is not required `CTRL+C` to skip.

### 👉Step 2: Run Create Script

- Clone the repository
    ```bash
    git clone https://github.com/EliasDeHondt/IntegrationProject1-Deployment.git
    ```
- Navigate to the project folder
    ```bash
    cd IntegrationProject1-Deployment/Scripts
    ```
- Run the [Deployment Script IaC](/Scripts/Deployment-Script-IaC.sh)
    ```bash
    sudo chmod +x Deployment-Script-IaC.sh
    sudo ./Deployment-Script-IaC.sh
    ```
**The script will do the rest!**

### 👉Step 3: Configure Custom Domain

- When you did not use the default configuration of the script, you will need to go to your DNS provider and add a records That contains the public IP address of the load balancer you will get this IP address at the end of the script execution.

**Example of a DNS record:**

![Instructions IaC Deployment 1](../../Images/Instructions-IaC-Deployment-1.png)

## 🔗Links
- 👯 Web hosting company [EliasDH.com](https://eliasdh.com).
- 📫 How to reach us elias.dehondt@outlook.com