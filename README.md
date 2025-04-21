# GCP Infrastructure as Code with Terraform

This repository contains Terraform configuration to deploy a complete GCP infrastructure including storage buckets, compute instances, networking components, Google Kubernetes Engine (GKE) cluster, and Cloud Run services.

## Project Structure

The project is organized into the following files:

- **main.tf** - Contains all the resource definitions including storage buckets, compute instances, networking, GKE cluster, and Cloud Run services
- **variables.tf** - Defines all the variables used throughout the project
- **providers.tf** - Sets up the Google Cloud provider
- **backend.tf** - Configures the GCS backend for storing Terraform state
- **backend.tfvars** - Contains the backend configuration values
- **inputs.tfvars** - Contains secret/sensitive variables to be passed to Terraform

## Infrastructure Components

### Storage

1. **Backend Bucket (apriltfbackend)** - Used for storing Terraform state with public access prevention enforced
2. **Static Site Bucket** - Configured as a website with lifecycle rules to move old objects to COLDLINE storage

### Compute

1. **Virtual Machines** - Two e2-micro Debian 11 VMs
2. **GKE Cluster** - A private Kubernetes cluster with two preemptible nodes

### Networking

1. **VPC Network** - Custom VPC network with manual subnet creation
2. **Subnet** - Configured with primary IP range and secondary IP ranges

### Container Services

1. **Artifact Registry** - Docker repository for storing container images
2. **Cloud Run Service** - Serverless container service with public access

## Architecture Diagram

```
                                    +-------------------+
                                    |   GCS Buckets     |
                                    |                   |
                                    | - Terraform State |
                                    | - Static Website  |
                                    +-------------------+
                                             |
                                             |
                    +------------------------+------------------------+
                    |                                                 |
          +---------v---------+                           +-----------v-----------+
          |  VPC Network      |                           |  Container Services   |
          |                   |                           |                       |
          | - Custom Subnet   |                           | - Artifact Registry   |
          | - IP Ranges       |                           | - Cloud Run Service   |
          +---------+---------+                           +-----------+-----------+
                    |                                                 |
          +---------v---------+                                      |
          |  Compute          |                                      |
          |                   |                                      |
          | - 2 VMs           <--------------------------------------+
          | - GKE Cluster     |
          +-------------------+
```

## Deployment Instructions

1. **Initialize Terraform with backend configuration**:
   ```
   terraform init -backend-config=backend.tfvars
   ```

2. **Plan the deployment**:
   ```
   terraform plan -var-file=inputs.tfvars
   ```

3. **Apply the configuration**:
   ```
   terraform apply -var-file=inputs.tfvars
   ```

## Security Notes

- The backend bucket has public access prevention enforced
- The GKE cluster is configured as a private cluster with authorized networks
- Credentials should be kept secure and never committed to version control
- The Cloud Run service is publicly accessible (modify IAM roles if this is not desired)

## Lifecycle Management

- Static site objects older than 365 days are automatically moved to COLDLINE storage
- VMs are configured to allow stopping for updates
- The GKE cluster has preemptible nodes to reduce costs