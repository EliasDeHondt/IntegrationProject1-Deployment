![logo](https://eliasdh.com/assets/media/images/logo-github.png)
# 💙🤍Instructions GCloud CLI🤍💙

## 📘Table of Contents

1. [📘Table of Contents](#📘table-of-contents)
2. [🖖Introduction](#🖖introduction)
3. [✨Steps](#✨steps)
    1. [👉Step 1: Update and upgrade system](#👉step-1-update-and-upgrade-system)
    2. [👉Step 2: Install tools](#👉step-2-install-tools)
    3. [👉Step 3: Import the Google Cloud public key](#👉step-3-import-the-google-cloud-public-key)
    4. [👉Step 4: Add the gcloud CLI distribution URI as a package source](#👉step-4-add-the-gcloud-cli-distribution-uri-as-a-package-source)
    5. [👉Step 5: Update and install the gcloud CLI](#👉step-5-update-and-install-the-gcloud-cli)
    6. [👉Step 6: (Optional) Install any of the following additional components](#👉step-6-optional-install-any-of-the-following-additional-components)
    7. [👉Step 7: Run gcloud init to get started](#👉step-7-run-gcloud-init-to-get-started)
4. [📦Extra](#📦extra)
5. [🔗Links](#🔗links)

---

## 🖖Introduction

The Google Cloud CLI is a command-line tool that provides a way to manage resources on Google Cloud Platform. It is a unified tool that allows you to perform many tasks, such as deploying applications, managing APIs, and monitoring your Google Cloud Platform services.

## ✨Steps

### 👉Step 1: Update and upgrade system
    
```bash
sudo apt-get update && sudo apt-get upgrade -y
```

### 👉Step 2: Install tools

```bash
sudo apt-get install apt-transport-https ca-certificates gnupg curl sudo
```

### 👉Step 3: Import the Google Cloud public key

- For newer distributions (Debian 9+ or Ubuntu 18.04+) run the following command:
    ```bash
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
    ```
- For older distributions, run the following command:
    ```bash
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
    ```
- If your distribution's apt-key command doesn't support the --keyring argument, run the following command:
    ```bash	
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
    ```

### 👉Step 4: Add the gcloud CLI distribution URI as a package source

- For newer distributions (Debian 9+ or Ubuntu 18.04+), run the following command:
    ```bash
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
    ```
- For older distributions that don't support the signed-by option, run the following command:
    ```bash
    echo "deb https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
    ```

> Note: Make sure you don't have duplicate entries for the cloud-sdk repo in /etc/apt/sources.list.d/google-cloud-sdk.list. If you have duplicate entries, remove them.

### 👉Step 5: Update and install the gcloud CLI

```bash
sudo apt-get update && sudo apt-get install google-cloud-cli
```

- Docker:
    - `Docker Tip`: If installing the gcloud CLI inside a Docker image, use a single RUN step instead:
        ```bash
        RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg && apt-get update -y && apt-get install google-cloud-sdk -y 
        ```
    - For older base images that do not support the gpg --dearmor command:
        ```bash
        RUN echo "deb http://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - && apt-get update -y && apt-get install google-cloud-sdk -y
        ```

### 👉Step 6: (Optional) Install any of the following additional components

- google-cloud-cli
- google-cloud-cli-anthos-auth
- google-cloud-cli-app-engine-go
- google-cloud-cli-app-engine-grpc
- google-cloud-cli-app-engine-java
- google-cloud-cli-app-engine-python
- google-cloud-cli-app-engine-python-extras
- google-cloud-cli-bigtable-emulator
- google-cloud-cli-cbt
- google-cloud-cli-cloud-build-local
- google-cloud-cli-cloud-run-proxy
- google-cloud-cli-config-connector
- google-cloud-cli-datastore-emulator
- google-cloud-cli-firestore-emulator
- google-cloud-cli-gke-gcloud-auth-plugin
- google-cloud-cli-kpt
- google-cloud-cli-kubectl-oidc
- google-cloud-cli-local-extract
- google-cloud-cli-minikube
- google-cloud-cli-nomos
- google-cloud-cli-pubsub-emulator
- google-cloud-cli-skaffold
- google-cloud-cli-spanner-emulator
- google-cloud-cli-terraform-validator
- google-cloud-cli-tests
- kubectl

> Install all of the above components by running the following command:
```bash
sudo apt-get install google-cloud-sdk google-cloud-sdk-anthos-auth google-cloud-sdk-app-engine-go google-cloud-sdk-app-engine-grpc google-cloud-sdk-app-engine-java google-cloud-sdk-app-engine-python google-cloud-sdk-app-engine-python-extras google-cloud-sdk-bigtable-emulator google-cloud-sdk-cbt google-cloud-sdk-cloud-build-local google-cloud-sdk-cloud-run-proxy google-cloud-sdk-config-connector google-cloud-sdk-datastore-emulator google-cloud-sdk-firestore-emulator google-cloud-sdk-gke-gcloud-auth-plugin google-cloud-sdk-kpt google-cloud-sdk-kubectl-oidc google-cloud-sdk-local-extract google-cloud-sdk-minikube google-cloud-sdk-nomos google-cloud-sdk-pubsub-emulator google-cloud-sdk-skaffold google-cloud-sdk-spanner-emulator google-cloud-sdk-terraform-validator google-cloud-sdk-tests kubectl
```

### 👉Step 7: Run gcloud init to get started

```bash
gcloud init
```

![logo](/Images/How-To-Configure-GCloud-CLI-1.png)

> Type `Y` to get started.


![logo](/Images/How-To-Configure-GCloud-CLI-2.png)

> Go to the link and select your account and click `Allow`.
> Copy the code and paste it in the terminal.


![logo](/Images/How-To-Configure-GCloud-CLI-3.png)

> Select the project you want to use. If you don't have a project, create one.

## 📦Extra

- To add a account, run the following command:
    ```bash
    gcloud auth login
    ```
- To verify the installation, run the following command:
    ```bash
    gcloud --version
    ```
- To update the gcloud CLI, run the following command:
    ```bash
    sudo apt-get update && sudo apt-get install google-cloud-sdk
    ```
- To uninstall the gcloud CLI, run the following command:
    ```bash
    sudo apt-get remove google-cloud-sdk
    ```
- If you want to remove all configuration files, run the following command:
    ```bash
    sudo apt-get remove --purge google-cloud-sdk
    ```

## 🔗Links
- 👯 Web hosting company [EliasDH.com](https://eliasdh.com).
- 📫 How to reach us elias.dehondt@outlook.com