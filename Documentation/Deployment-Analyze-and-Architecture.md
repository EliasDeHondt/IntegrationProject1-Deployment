![logo](https://eliasdh.com/assets/media/images/logo-github.png)
# 💙🤍Deployment Analyze and Architecture🤍💙

## 📘Table of Contents

1. [📘Table of Contents](#📘table-of-contents)
2. [🖖Introduction](#🖖introduction)
3. [📷Network Drawing](#📷network-drawing)
    1. [💭Description Connectivity](#💭description-connectivity)
4. [🔍Risk Analysis](#🔍risk-analysis)
    1. [🚀Deployment Risks](#4.1-🚀deployment-risks)
          1. [🚀GitLab Outage](#4.1-🚀gitlab-outage)
          2. [🚀Google Cloud Outage](#4.2-🚀google-cloud-outage)
    2. [📉Performance Risks](#4.2-📉performance-risks)
          1. [📉Resource Exhaustion](#4.1-📉resource-exhaustion)
          2. [📉Database Performance](#4.2-📉database-performance)
    3. [🛡️Security Risks](#4.3-🛡️security-risks)
          1. [🛡️Data Breach](#4.1-🛡️data-breach)
    4. [🛠️Operational Risks](#4.4-🛠️operational-risks)
          1. [🛠️Server Downtime](#4.1-🛠️server-downtime)
5. [📑Context](#📑context)
    1. [📑Project Collaboration](#📑project-collaboration)
    2. [📑Project Overview](#📑project-overview)
    3. [📑Project Objectives](#📑project-objectives)
    4. [📑Roles and Users](#📑roles-and-users)
    5. [📑Non-functional Requirements](#📑non-functional-requirements)
    6. [📑Material and Technology](#📑material-and-technology)
    7. [📑Usability and Performance](#📑usability-and-performance)
6. [🔗Links](#🔗links)

---

## 🖖Introduction

This document provides an overview of the network architecture and risk analysis for the deployment of the `Phygital` tool. The network architecture is designed to be scalable, secure, and reliable, with a focus on performance and availability. The risk analysis identifies potential risks and their impact on the deployment of the application. The risks are categorized into deployment, performance, security, and operational risks, with mitigation strategies to minimize their impact.

---

## 📷Network Drawing

![Network Drawing](/Images/Network-Drawing.png)

### 💭Description Connectivity

- Cables:
    - <font color="green">Green:</font> Secure
    - <font color="red">Red:</font> Not Secure
    - <font color="yellow">Yellow:</font> Power

- Components:
    - Router
    - Switch
    - UPS
    - Google Cloud
    - Internet
    - Firewall
    - Load Balancer
        - .NET Core
        - .NET Core
        - .NET Core
        - Autoscaling (....)
    - Metadata Server
    - Database Server
    - Bucket Storage

1. Question: *Find out how to connect to a GitLab private repository*
    - Anser: I will use the GitLab CI/CD to deploy the application to Google Cloud. The GitLab CI/CD will use a service account to authenticate with Google Cloud. The service account will have the necessary permissions to access the Google Cloud resources.
    - Link: [GitLab CI/CD](https://docs.gitlab.com/ee/ci/)

2. Question: *Check how the application in the cloud connects to its database*
    - Answer: The application in the cloud connects to its database using a connection string. The connection string contains the necessary information to connect to the database, such as the server name, database name, username, and password.
    - Link: [Connection Strings](https://docs.microsoft.com/en-us/dotnet/framework/data/adonet/connection-strings-and-configuration-files)

3. Question: *Check how you connect to any other cloud components*
    - Answer: The application in the cloud connects to other cloud components using their respective APIs. For example, the application can use the Google Cloud Storage API to access files in a bucket, or the Google Cloud Pub/Sub API to publish and subscribe to messages.
    - Link: [Google Cloud APIs](https://cloud.google.com/apis)

4. Question: *Describe how you can use the metadata server*
    - Answer: The metadata server provides information about the Google Cloud instance, such as its hostname, IP address, and project ID. The application can use this information to configure itself dynamically based on the environment it is running in.
    - Link: [Metadata Server](https://cloud.google.com/compute/docs/storing-retrieving-metadata)

5. Question: *Check the requirements for using autoscaling (horizontal scaling) for the application*
    - Answer: To use autoscaling, the application must be stateless and able to handle requests independently. The application must also be able to start and stop without losing any data or state. Additionally, the application must be able to handle a variable number of requests and scale up or down based on demand.
    - Link: [Autoscaling](https://cloud.google.com/compute/docs/autoscaler)

> **Note:** The network drawing is a simplified representation of the actual network architecture. Google Cloud does a lot of the heavy lifting, and the network is designed to be scalable and secure.

## 🔍Risk Analysis

### 1. 🚀Deployment Risks

#### 1.1 🚀GitLab Outage

- **Risk:** Potential GitLab outages.
- **Impact:** High
- **Probability:** Low
- **Mitigation:** Create multiple backups to an alternative Git service such as GitHub or Bitbucket.

#### 1.2 🚀Google Cloud Outage

- **Risk:** Potential Google Cloud outages.
- **Impact:** High
- **Probability:** Low
- **Mitigation:** If possible, deploy the application to multiple zones in the same region.

### 2. 📉Performance Risks

#### 2.1 📉Resource Exhaustion

- **Risk:** Resource exhaustion due to high traffic.
- **Impact:** High
- **Probability:** High
- **Mitigation:** Implement a load balancer and auto-scaling to handle high traffic.

#### 2.2 📉Database Performance

- **Risk:** Database performance issues due to high traffic.
- **Impact:** High
- **Probability:** Medium
- **Mitigation:** Implement a caching layer and optimize database queries. (`Lazy loading and eager loading`)

### 3. 🛡️Security Risks

#### 3.1 🛡️Data Breach

- **Risk:** Data breach due to security vulnerabilities.
- **Impact:** High
- **Probability:** Medium
- **Mitigation:** Make sure that no default passwords are used.

### 4. 🛠️Operational Risks

#### 4.1 🛠️Server Downtime

- **Risk:** Server downtime due to Google cloud credit limit.
- **Impact:** High
- **Probability:** Low
- **Mitigation:** Monitor Google cloud credit limit and set up alerts.

### 5. ☠️Loss of Employee

#### 5.1 ☠️Loss of Employee

- **Risk:** Loss of employee due to AI revolution.
- **Impact:** High
- **Probability:** High
- **Mitigation:** Create documentation to transfer knowledge.

## 📑Context

### 📑Project Collaboration

This project is a collaborative effort between Levuur and Tree Company. [Tree Company](https://treecompany.be) specializes in engaging and informing citizens on societal issues through digital solutions. Levuur, on the other hand, is an expert in participation and stakeholder management, designing and guiding tailored stakeholder processes for companies, governments, and organizations. Both Levuur and Tree Company are part of DBP Partners [DBP Partners](https://dbppartners.be), collaborating structurally in various projects.

### 📑Project Overview

The collaboration is part of an international Erasmus+ project involving Levuur, Tree Company, the city of Sint-Niklaas (Belgium), DYPALL Network (Portugal), and Danes Je Nov Dan (Slovenia). The primary goal is to design a 'Phygital' tool that local governments and organizations can utilize to gather input from young people on policy issues relevant to them. The tool aims to provide a novel, accessible way for young people to express their views on policies to local authorities by combining physical and digital elements.

### 📑Project Objectives

The main objective is to design a `Phygital` tool that meets the specified requirements and roles. The tool should be applicable to any organization seeking youth participation in decision-making processes. The standard case for testing involves the youth council of a municipality or city, engaging with young people about the upcoming local elections. Additionally, a second case, selected from your local context, should demonstrate the tool's versatility across various organizations.

### 📑Roles and Users

Four distinct roles have been identified for the tool: Eindgebruiker (young participant), Begeleider (facilitator present during tool usage), Beheerder van een deelplatform (local government or organizational administrator managing projects), and Beheerders van het gehele platform (platform administrators like Tree Company and Levuur).

### 📑Non-functional Requirements

The tool is expected to function in semi-public spaces like school halls, sports clubs, libraries, and community centers. Both guided and unguided usage scenarios need to be accommodated, requiring an attractive and intuitive design. The tool should cater to individual and group usage by young participants aged 17 to 25.

### 📑Material and Technology

While a fully finished casing is not part of the task, the setup should be robust enough for testing in different locations. It must work with standard hardware and software across the EU, be easily set up and dismantled, transportable, made of durable materials, and cost-efficient. The web application should be compatible with common browsers, scalable, and coded for maintenance and future enhancements.

### 📑Usability and Performance

Emphasis is placed on user-friendliness, engaging design, and performance meeting industry standards. The tool will undergo user tests to refine the design based on participant interactions. Performance, security, and testing standards must align with best practices.

## 🔗Links

- 👯 Web hosting company [EliasDH.com](https://eliasdh.com).
- 📫 How to reach us eliasdehondt@outlook.com.