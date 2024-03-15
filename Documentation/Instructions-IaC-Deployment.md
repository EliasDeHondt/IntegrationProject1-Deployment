![logo](https://eliasdh.com/assets/media/images/logo-github.png)
# 💙🤍Instructions IaC Deployment🤍💙

## 📘Table of Contents

1. [📘Table of Contents](#📘table-of-contents)
2. [🖖Introduction](#🖖introduction)
3. [✨Steps](#✨steps)
    1. [👉Step 0: Preparations](#👉step-0-preparations)
    2. [👉Step 1: Configure Environment](#👉step-1-configure-environment)
4. [📦Extra](#📦extra)
5. [🔗Links](#🔗links)

---

## 🖖Introduction

This document will guide you through the process of deploying the entire infrastructure of the CodeForge application to the Google Cloud Platform. The infrastructure is deployed using Infrastructure as Code [Create Script](/Scripts/Create-Infrastructure-IaC.sh) and [Delete Script](/Scripts/Delete-Infrastructure-IaC.sh). The infrastructure consists of a PostgreSQL database, custom domains, metadata server, VM instances, and load balancers. The infrastructure is deployed using the Google Cloud CLI.

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
- Insall nodejs and npm
    ```bash	
    sudo apt-get install wget
    wget -qO- https://raw.githubusercontent.com/creationix/nvm/v0.39.0/install.sh | bash
    source ~/.profile
    nvm install 20.11.1
    node --version
    npm --version
    ```
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
- Run the [Create Infrastructure IaC Script](/Scripts/Create-Infrastructure-IaC.sh)
    ```bash
    chmod +x Create-Infrastructure-IaC.sh
    sudo ./Create-Infrastructure-IaC.sh
    ```
> ***The script will do the rest!***

## 📦Extra

- Delete the infrastructure using the [Delete Infrastructure IaC Script](/Scripts/Delete-Infrastructure-IaC.sh)
    ```bash
    chmod +x Delete-Infrastructure-IaC.sh
    sudo ./Delete-Infrastructure-IaC.sh
    ```

## 🔗Links
- 👯 Web hosting company [EliasDH.com](https://eliasdh.com).
- 📫 How to reach us eliasdehondt@outlook.com.