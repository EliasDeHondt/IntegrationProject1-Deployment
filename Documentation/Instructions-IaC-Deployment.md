![logo](https://eliasdh.com/assets/media/images/logo-github.png)
# 💙🤍Instructions IaC Deployment🤍💙

## 📘Table of Contents

1. [📘Table of Contents](#📘table-of-contents)
2. [🖖Introduction](#🖖introduction)
3. [✨Steps](#✨steps)
    1. [👉Step 0: Preparations](#👉step-0-preparations)
    2. [👉Step 1: Configure Environment](#👉step-1-configure-environment)
4. [🔗Links](#🔗links)

---

## 🖖Introduction

This document will guide you through the process of deploying the entire infrastructure of the CodeForge application to the Google Cloud Platform. The infrastructure is deployed using Infrastructure as Code [Deployment Script IaC](/Scripts/Deployment-Script-IaC.sh).

## ✨Steps

### 👉Step 0: Preparations

- Insall the Google Cloud CLI [Instructions GCloud CLI](https://github.com/EliasDeHondt/IntegrationProject1-Deployment/blob/main/Documentation/Instructions-GCloud-CLI.md)

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
- Run the [Create Infrastructure IaC Script](/Scripts/Deployment-Script-IaC.sh.sh)
    ```bash
    chmod +x Deployment-Script-IaC.sh
    sudo ./Deployment-Script-IaC.sh
    ```
> ***The script will do the rest!***

## 🔗Links
- 👯 Web hosting company [EliasDH.com](https://eliasdh.com).
- 📫 How to reach us elias.dehondt@outlook.com