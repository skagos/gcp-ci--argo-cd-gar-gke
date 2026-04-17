# ☸️ GCP CI/CD Pipeline with Argo CD, GAR, and GKE

> A production-ready GitOps CI/CD pipeline leveraging Google Cloud Platform's best-in-class services

<div align="center">

![GCP](https://img.shields.io/badge/Cloud-GCP-blue?logo=google-cloud)
![Kubernetes](https://img.shields.io/badge/Container%20Orchestration-Kubernetes-326ce5?logo=kubernetes)
![Argo CD](https://img.shields.io/badge/GitOps-Argo%20CD-EF7B4D)
![Infrastructure](https://img.shields.io/badge/IaC-Terraform-623CE4?logo=terraform)

</div>


<img width="1638" height="812" alt="image" src="https://github.com/user-attachments/assets/f10250e1-fb9c-4de0-a6c2-e618139c5c5f" />



## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Detailed Setup](#detailed-setup)
  - [Step 1: Google Artifact Registry](#step-1-google-artifact-registry)
  - [Step 2: Google Kubernetes Engine](#step-2-google-kubernetes-engine)
  - [Step 3: kubectl Configuration](#step-3-kubectl-configuration)
  - [Step 4: Argo CD Setup](#step-4-argo-cd-setup)
  - [Step 5: Service Accounts & GitHub Integration](#step-5-service-accounts--github-integration)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)

## Overview

This project demonstrates a **complete, enterprise-grade CI/CD pipeline** on Google Cloud Platform using:

| Component | Purpose |
|-----------|---------|
| 🗄️ **Google Artifact Registry (GAR)** | Secure container image storage |
| ☸️ **Google Kubernetes Engine (GKE)** | Managed Kubernetes orchestration |
| 🔄 **Argo CD** | GitOps-based continuous deployment |
| 📦 **Terraform** | Infrastructure as Code |
| ⚙️ **GitHub Actions** | CI/CD automation & pipeline orchestration |

## Architecture

```
GitHub Repository → GitHub Actions → Google Artifact Registry
                                          ↓
                                    Argo CD (GKE)
                                          ↓
                                    Application Pods
```

## Prerequisites

Ensure you have the following tools installed and configured:

- [ ] **Google Cloud Account** with an active project
- [ ] **Terraform** v1.0+ ([Install](https://www.terraform.io/downloads))
- [ ] **gcloud CLI** ([Install](https://cloud.google.com/sdk/docs/install))
- [ ] **kubectl** v1.24+ ([Install](https://kubernetes.io/docs/tasks/tools/))
- [ ] **Docker** ([Install](https://docs.docker.com/get-docker/))
- [ ] **GitHub Account** with repository access (optional for CI/CD)




## ⚡ Quick Start

```bash
# 1. Clone this repository
git clone <your-repo-url>
cd gcp-ci--argo-cd-gar-gke

# 2. Set up infrastructure
cd gcp-artifact-registry && terraform apply -var-file="terraform.tfvars"
cd ../gcp-gke && terraform apply -var-file="terraform.tfvars"

# 3. Configure kubectl
gcloud container clusters get-credentials ci-cd-cluster --zone us-central1-a

# 4. Deploy Argo CD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# 5. Access Argo CD
kubectl port-forward svc/argocd-server -n argocd 8080:443
# Open: http://localhost:8080
```

---

## 📚 Detailed Setup

### Step 1: Google Artifact Registry

Set up Google Artifact Registry using Terraform for secure container image storage.

#### 1.1 Initialize Terraform

```bash
cd gcp-artifact-registry
terraform init
```

#### 1.2 Apply Configuration

```bash
terraform apply -var-file="terraform.tfvars"
```

#### 1.3 Enable Required APIs

```bash
gcloud services enable artifactregistry.googleapis.com
gcloud services enable container.googleapis.com
```

#### 1.4 Test Artifact Registry

**Authenticate Docker with GAR:**
```bash
gcloud auth configure-docker us-central1-docker.pkg.dev
```

**Build and push a test image:**
```bash
# Build
docker build -t my-test-image:latest .

# Tag
docker tag my-test-image:latest \
  us-central1-docker.pkg.dev/applied-ridge-414907/my-docker-repo/my-test-image:latest

# Push
docker push \
  us-central1-docker.pkg.dev/applied-ridge-414907/my-docker-repo/my-test-image:latest
```

 **Verification:** Check your images in the [GCP Console](https://console.cloud.google.com/artifacts)

---

### Step 2: Google Kubernetes Engine

Deploy a managed GKE cluster using Terraform.

#### 2.1 Initialize and Apply

```bash
cd gcp-gke
terraform init
terraform apply -var-file="terraform.tfvars"
```

 This may take 5-10 minutes to complete.

---

### Step 3: kubectl Configuration

Configure kubectl to connect to your GKE cluster after Terraform deployment.

#### 3.1 Get Cluster Credentials

```bash
gcloud container clusters get-credentials ci-cd-cluster \
  --zone us-central1-a \
  --project your-gcp-project-id

# Verify connection
kubectl get nodes
```

#### 3.2 Managing Multiple Clusters

If you're working with multiple clusters (GKE, AKS, etc.):

```bash
# Update gcloud components
gcloud components update
gcloud components install gke-gcloud-auth-plugin

# List all contexts
kubectl config get-contexts

# Switch context
kubectl config use-context gke-context-name

# Set default namespace
kubectl config set-context --current --namespace=default

# Use specific kubeconfig
kubectl --kubeconfig=~/.kube/gke-config get nodes
```

> 💡 **Pro Tip:** Keep a dedicated kubeconfig for GKE locally or in the repo so GitHub Actions always targets the correct cluster without accidental context switches.

---

### Step 4: Argo CD Setup

Install and configure Argo CD for GitOps-based deployments.

#### 4.1 Create Namespace and Install Argo CD

```bash
# Create namespace
kubectl create namespace argocd

# Install Argo CD
kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

#### 4.2 Verify Installation

```bash
kubectl get pods -n argocd
```

Expected output: You should see several Argo CD pods running.

#### 4.3 Access Argo CD UI

**Port forward to access the dashboard:**
```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

🔗 **Access at:** [http://localhost:8080](http://localhost:8080)

#### 4.4 Get Initial Admin Password

**For Linux/macOS:**
```bash
kubectl get secret argocd-initial-admin-secret -n argocd \
  -o jsonpath="{.data.password}" | base64 --decode
```

**For PowerShell:**
```powershell
$secret = kubectl get secret argocd-initial-admin-secret -n argocd `
  -o jsonpath="{.data.password}"
[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($secret))
```

#### 4.5 Deploy Kustomization

Apply the Argo CD kustomization configuration:

```bash
kubectl apply -f argo-cd\(kustomization\).yaml
```

---

### Step 5: Service Accounts & GitHub Integration

Set up service accounts and image updater for automated deployments.

#### 5.1 Install Argo CD Image Updater

```bash
kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj-labs/argocd-image-updater/stable/config/install.yaml

# Verify installation
kubectl get pods -n argocd | grep image-updater
```

#### 5.2 Configure Image Updater

Edit the image updater configuration:

```bash
kubectl edit configmap argocd-image-updater-config -n argocd
```

**Application with image updater annotations:**
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: test-app
  namespace: argocd
  annotations:
    argocd-image-updater.argoproj.io/image-list: myapp=us-central1-docker.pkg.dev/YOUR-PROJECT-ID/my-docker-repo/hello-test-app
    argocd-image-updater.argoproj.io/myapp.update-strategy: latest
    argocd-image-updater.argoproj.io/myapp.pull-secret: pullsecret:argocd/gcr-secret
spec:
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

#### 5.3 Create GitHub Actions Service Account

**List service accounts:**
```bash
gcloud iam service-accounts list --project=YOUR-PROJECT-ID
```

**Create service account key:**
```bash
gcloud iam service-accounts keys create gar-key.json \
  --iam-account=github-actions-sa@YOUR-PROJECT-ID.iam.gserviceaccount.com \
  --project=YOUR-PROJECT-ID
```

#### 5.4 Create Docker Registry Secrets

**PowerShell setup:**
```powershell
# Read and encode key
$key = Get-Content 'gar-key.json' -Raw
$b64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($key))

# Create secret for image updater (argocd namespace)
kubectl create secret docker-registry gcr-secret `
  --docker-server=us-central1-docker.pkg.dev `
  --docker-username=_json_key `
  --docker-password=$b64 `
  -n argocd

# Create secret for pod pulls (default namespace)
kubectl create secret docker-registry gar-pull-secret `
  --docker-server=us-central1-docker.pkg.dev `
  --docker-username=_json_key `
  --docker-password=$b64 `
  -n default
```

#### 5.5 Apply Auto-Sync Policy

```bash
kubectl patch application test-app -n argocd --type merge \
  -p '{"spec":{"syncPolicy":{"automated":{"prune":true,"selfHeal":true}}}}'
```

---

## 🐛 Troubleshooting

| Issue | Solution |
|-------|----------|
| **Terraform init fails** | Ensure GCP credentials are set: `gcloud auth application-default login` |
| **kubectl can't connect** | Re-run: `gcloud container clusters get-credentials ci-cd-cluster...` |
| **Argo CD UI not accessible** | Check port-forward: `kubectl get svc -n argocd` |
| **Image pull errors** | Verify secrets: `kubectl get secrets -n default` |
| **Image updater not detecting changes** | Check annotations and restart: `kubectl rollout restart deployment/argocd-image-updater -n argocd` |

---

## 📁 Project Structure

```
.
├── app/                        # Application source
├── gcp-artifact-registry/      # GAR Terraform configs
├── gcp-gke/                    # GKE Terraform configs
├── helm/                       # Helm chart for deployment
├── k8s-manifests/              # Raw Kubernetes manifests
├── argo-cd(kustomization).yaml # Argo CD setup
├── Dockerfile                  # Container image
└── README.md                   # This file
```

## Step 5: Service Account Setup for GitHub Actions

1. Create a Service Account:
   ```bash
   gcloud iam service-accounts create github-actions-sa --display-name="GitHub Actions Service Account"
   ```

2. Grant permissions:
   ```bash
   gcloud projects add-iam-policy-binding applied-ridge-414907 \
   --member="serviceAccount:github-actions-sa@applied-ridge-414907.iam.gserviceaccount.com" \
   --role="roles/artifactregistry.writer"
   ```

3. Create and download key:
   ```bash
   gcloud iam service-accounts keys create key.json \
   --iam-account=github-actions-sa@applied-ridge-414907.iam.gserviceaccount.com
   ```

⚠️ **Security Notes:**
- Never commit `key.json` to the repository
- Add to `.gitignore`:
  ```
  key.json
  ```
- Delete locally after uploading to GitHub Secrets
- Use least privilege: `roles/artifactregistry.writer` is sufficient for pushing images
- For deployments, add `roles/container.developer` later

## Step 6: Deploy Application

Test the Kubernetes deployment:

```bash
kubectl apply -f k8s-manifests/deployment.yaml
kubectl apply -f k8s-manifests/service.yaml
kubectl get svc
```
