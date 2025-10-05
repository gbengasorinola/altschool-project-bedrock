# InnovateMart’s Inaugural EKS Deployment
Welcome to the InnovateMart EKS Deployment project! This repository contains the necessary configurations and scripts to deploy a scalable and secure e-commerce platform using Amazon Elastic Kubernetes Service (EKS).

---

## Project Overview
InnovateMart is an e-commerce platform designed to provide a seamless shopping experience. This project focuses on deploying the application on AWS EKS, ensuring high availability, scalability, and security.

---

## Features
- **Scalable Architecture**: Leveraging Kubernetes for automatic scaling based on demand.
- **Secure Deployment**: Implementing best practices for security, including IAM roles and network policies.
- **CI/CD Integration**: Automated deployment pipelines for continuous integration and delivery.
- **Monitoring and Logging**: Integration with AWS CloudWatch and Prometheus for monitoring application performance.

---

## Project Structure
``` plaintext
project-bedrock/
│── README.md
│── .gitignore
│── versions.tf
│── provider.tf
│── variables.tf
│── outputs.tf
│── main.tf                
│
├── modules/
│   ├── vpc/
│   │    ├── main.tf
│   │    ├── variables.tf
│   │    ├── outputs.tf
│   │
│   ├── eks/
│   │    ├── main.tf
│   │    ├── variables.tf
│   │    ├── outputs.tf
└── .github/
    └── workflows/
         ├── terraform.yml
```

---

## Table of Contents

- [InnovateMart’s Inaugural EKS Deployment](#innovatemarts-inaugural-eks-deployment)
  - [Project Overview](#project-overview)
  - [Features](#features)
  - [Project Structure](#project-structure)
  - [Table of Contents](#table-of-contents)
  - [Prerequisites](#prerequisites)
  - [Technologies Used](#technologies-used)
  - [Backend Setup](#backend-setup)
  - [Terraform Configuration](#terraform-configuration)
    - [main.tf](#maintf)
    - [outputs.tf](#outputstf)
    - [variables.tf](#variablestf)
    - [versions.tf](#versionstf)
  - [VPC Modules Configuration](#vpc-modules-configuration)
    - [main.tf](#maintf-1)
    - [variables.tf](#variablestf-1)
    - [outputs.tf](#outputstf-1)
  - [EKS Modules Configuration](#eks-modules-configuration)
    - [main.tf](#maintf-2)
    - [variables.tf](#variablestf-2)
    - [outputs.tf](#outputstf-2)
  - [Push to GitHub](#push-to-github)
  - [Provision EC2 Instance](#provision-ec2-instance)
  - [SSH into EC2 Instance](#ssh-into-ec2-instance)
      - [Installed Dependencies and Configured AWS CLI:](#installed-dependencies-and-configured-aws-cli)
  - [Terraform Initialization and Deployment](#terraform-initialization-and-deployment)
  - [This successfully created the VPC and EKS cluster.](#this-successfully-created-the-vpc-and-eks-cluster)
  - [Kubernetes Configuration \& IAM Admin Access](#kubernetes-configuration--iam-admin-access)
    - [IAM Admin Access](#iam-admin-access)
  - [Deploy The Retail Store Application](#deploy-the-retail-store-application)
  - [Confirm Pod Status, Service \& Load Balancer Mapping, and Deployment Rollout](#confirm-pod-status-service--load-balancer-mapping-and-deployment-rollout)
  - [Developer Access — Read-Only IAM User for EKS](#developer-access--read-only-iam-user-for-eks)
    - [Map User to EKS Cluster](#map-user-to-eks-cluster)
    - [Test Developer Access](#test-developer-access)
    - [Access Credentials](#access-credentials)
  - [CI/CD Pipeline with GitHub Actions](#cicd-pipeline-with-github-actions)
    - [Branch Protection and PR Reviews](#branch-protection-and-pr-reviews)
  - [Advanced Networking \& Security](#advanced-networking--security)
    - [Set Variables for Advanced Networking \& Security](#set-variables-for-advanced-networking--security)
    - [Enable IAM OIDC provider for the cluster](#enable-iam-oidc-provider-for-the-cluster)
    - [Create an IAM Policy For the Controller](#create-an-iam-policy-for-the-controller)
    - [Create a Service Account for the Controller](#create-a-service-account-for-the-controller)
    - [Install the AWS Load Balancer Controller using Helm](#install-the-aws-load-balancer-controller-using-helm)
    - [Verify the Installation](#verify-the-installation)
    - [Create Ingress Resource for Load Balancer](#create-ingress-resource-for-load-balancer)
    - [Domain + Route 53 Setup](#domain--route-53-setup)
    - [Create a TLS Certificate using AWS Certificate Manager (ACM)](#create-a-tls-certificate-using-aws-certificate-manager-acm)
    - [Update Ingress Resource with TLS](#update-ingress-resource-with-tls)
  - [Conclusion](#conclusion)


---

## Prerequisites
- AWS Account with necessary permissions
- AWS CLI installed and configured
- kubectl installed
- eksctl installed
- Linux terminal (e.g. Termius)

---

## Technologies Used
- Terraform
- AWS (EKS, VPC, IAM, S3, DynamoDB, Route 53, ACM)
- Kubernetes
- GitHub Actions
- Helm

---

## Backend Setup
I opened S3 using the AWS Console and created a bucket with the following details:
- **Bucket Name**: `altschool-project-bedrock-terraform`
- **Region**: `eu-west-2`
- **Versioning**: Disabled
- **Encryption**: Enabled (AES-256)
- **Block Public Access**: Enabled

Next, I created a DynamoDB table for state locking with the following details:
- **Table Name**: `altschool-project-bedrock-terraform-locks`
- **Primary Key**: `LockID` (String)
- **Region**: `eu-west-2`

---

## Terraform Configuration
On my local machine, I configured the files `main.tf`, `outputs.tf`, `providers.tf`, `variables.tf`, and `versions.tf` to set up VPC and EKS resources.

### main.tf
```hcl
module "vpc" {
  source = "./modules/vpc"
  region = var.region
  project = var.project
  vpc_cidr = "10.0.0.0/16"
  azs = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

module "eks" {
  source          = "./modules/eks"
  cluster_name    = "${var.project}-eks-cluster"
  cluster_version = "1.30"
  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets
}
```
### outputs.tf
```hcl
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "private_subnets" {
  value = module.vpc.private_subnets
}

output "public_subnets" {
  value = module.vpc.public_subnets
}
```
### variables.tf
```hcl
variable "region" {
  description = "The AWS region to create resources in."
  type        = string
  default     = "eu-west-2"
}

variable "project" {
  default = "project-bedrock"
}
```
### versions.tf
```hcl
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.19"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5"
    }
  }
}
```

---

## VPC Modules Configuration
Under the `modules/vpc` directory, I created `main.tf`, `variables.tf`, and `outputs.tf` to define the VPC resources.

### main.tf
```hcl
terraform {
  required_version = ">= 1.5.0"
}

provider "aws" {
  region = var.region
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "5.1.2"

  name = "${var.project}-vpc"
  cidr = var.vpc_cidr

  azs             = var.azs
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    Project   = var.project
    Owner = "DevOps"
  }
  
}
```

### variables.tf
```hcl
variable "region" {
  description = "The AWS region to deploy resources"
  type        = string
  default     = "eu-west-2"
}

variable "project" {
  description = "Project Bedrock"
  type        = string
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "A list of availability zones in the region"
  type        = list(string)
  default     = ["eu-west-2a", "eu-west-2b", "eu-west-2c"] 
}

variable "private_subnets" {
    description = "A list of private subnet CIDR blocks"
    type        = list(string)
}

variable "public_subnets" {
    description = "A list of public subnet CIDR blocks"
    type        = list(string)
}
```

### outputs.tf
```hcl
output "vpc_id" {
  value = module.vpc.vpc_id
}

output "private_subnets" {
  value = module.vpc.private_subnets
}

output "public_subnets" {
  value = module.vpc.public_subnets
}
```
---

## EKS Modules Configuration
Under the `modules/eks` directory, I created `main.tf`, `variables.tf`, and `outputs.tf` to define the EKS resources.

### main.tf
```hcl
# -----------------------------
# IAM Role for EKS Cluster
# -----------------------------

resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.cluster_name}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      },
    ]
  })
  
}

resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSClusterPolicy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSServicePolicy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
}

# -----------------------------
# IAM Role for Worker Nodes
# -----------------------------

resource "aws_iam_role" "eks_node_role" {
  name = "${var.cluster_name}-eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_node_AmazonEKSWorkerNodePolicy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_node_AmazonEC2ContainerRegistryReadOnly" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "eks_node_AmazonEKS_CNI_Policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

# -----------------------------
# EKS Cluster
# ----------------------------- 

resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = var.cluster_version

  vpc_config {
    subnet_ids = var.private_subnets
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.eks_cluster_AmazonEKSServicePolicy,
  ]
}

# -----------------------------
# EKS Node Group
# ----------------------------- 

resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = var.private_subnets

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  instance_types = ["t3.medium"]

  depends_on = [
    aws_iam_role_policy_attachment.eks_node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.eks_node_AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.eks_node_AmazonEKS_CNI_Policy,
  ]
}
```

### variables.tf
```hcl
variable "cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "The Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.30"
}

variable "vpc_id" {
  description = "The ID of the VPC where the EKS cluster will be deployed"
  type        = string
}

variable "private_subnets" {
  description = "A list of private subnet IDs for the EKS cluster"
  type        = list(string)
}
```

### outputs.tf
```hcl
output "cluster_id" {
  description = "The ID of the EKS cluster"
  value       = aws_eks_cluster.this.id
}

output "cluster_endpoint" {
  description = "The endpoint of the EKS cluster"
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_security_group_id" {
  description = "The security group ID of the EKS cluster"
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "node_group_ids" {
  description = "The IDs of the EKS node groups"
  value       = aws_eks_node_group.this.id
}
```

---
## Push to GitHub
On my local machine, within the root folder `project-bedrock`, I initialized a git repository, added all files, committed the changes, and pushed to the `altschool-project-bedrock` repo on GitHub:

```bash
git init
git remote add origin https://github.com/gbengasorinola/altschool-project-bedrock.git
git add .
git commit -m "Initial commit"
git push -u origin main
```
---

## Provision EC2 Instance
I provisioned an EC2 instance using the AWS Management Console with the following details:
- **AMI**: Ubuntu Server 22.04 LTS (HVM), SSD Volume Type
- **Instance Type**: t2.micro
- **Key Pair**: Created a new key pair named `lnd-key-bedrock.pem` and downloaded it
- **Storage**: 8 GB General Purpose SSD
  
---

## SSH into EC2 Instance
I used Termius to SSH into my EC2 instance using this code:
```bash
ssh -i "lnd-key-bedrock.pem" ubuntu@ec2-18-132-3-138.eu-west-2.compute.amazonaws.com
```
After connecting, I updated the package lists and installed necessary packages:
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y git unzip curl
```
Next, I cloned the GitHub repo into the EC2 instance.

#### Installed Dependencies and Configured AWS CLI:
```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
aws --version
aws configure
```

I installed Terraform:
```bash
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --default-keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg apt-key add - && \
sudo apt-add-repository "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" && \
sudo apt-get update && \
sudo apt-get install terraform
terraform -v
```
I installed `kubectl`:
```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client
```

I installed `eksctl`:
```bash
curl -sLO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz"
tar -xzf eksctl_$(uname -s)_amd64.tar.gz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin
eksctl version
```

I installed `helm`:
```bash
curl https://baltocdn.com/helm/signing.asc | sudo gpg --default-keyring /usr/share/keyrings/helm.gpg --dearmor -o /usr/share/keyrings/helm.gpg
echo "deb [signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm.list
sudo apt-get update
sudo apt-get install helm
helm version
```

---

## Terraform Initialization and Deployment

I ran the following commands in the terminal to initialize and deploy the infrastructure:

```bash
terraform init
terraform validate
terraform fmt
terraform plan
terraform apply
```
This successfully created the VPC and EKS cluster.
---
## Kubernetes Configuration & IAM Admin Access
To configure `kubectl` to interact with the EKS cluster, I ran:
```bash
aws eks --region eu-west-2 update-kubeconfig --name project-bedrock-eks-cluster
kubectl get nodes
``` 
This updated the kubeconfig file with the necessary cluster information.

### IAM Admin Access
To grant admin access to the EKS cluster, I edited the `aws-auth` ConfigMap to include my IAM user:
```bash
kubectl edit -n kube-system configmap/aws-auth
```
I added the following under `mapUsers`:
```yaml
  mapUsers: |
    - userarn: arn:aws:iam::498457984677:user/super-user
      username: super-user
      groups:
        - system:masters
```
And applied and verified the changes:
```bash
kubectl apply -f aws-auth.yaml
kubectl describe configmap aws-auth -n kube-system
```
This granted my IAM user admin access to the EKS cluster.

---

## Deploy The Retail Store Application
I applied the Kubernetes manifests located in the `retail-store-sample-app` repo on GitHub using:
```bash
kubectl apply -f https://github.com/aws-containers/retail-store-sample-app/releases/latest/download/kubernetes.yaml
kubectl wait --for=condition=available deployments --all --timeout=300s
```
This deployed the retail store application to the EKS cluster.

To get the LoadBalancer URL, I ran:
```bash
kubectl get svc -A | grep LoadBalancer
```
I accessed the application using the LoadBalancer URL in my web browser.

This is the URL: http://a3bc17fe477f8410a89525138bf3fb73-1497101076.eu-west-2.elb.amazonaws.com/

![Alt text](https://github.com/gbengasorinola/altschool-project-bedrock/blob/main/Screen%20Shot%202025-10-05%20at%202.49.12%20AM.png)

---

## Confirm Pod Status, Service & Load Balancer Mapping, and Deployment Rollout
I ran the following command to check if the pods are in Running or Ready state:
```bash
kubectl get pods
```

Confirmed if the load balancer is linked to the service:
```bash
kubectl get svc
```

Checked deployment rollout:
```bash
kubectl get deployments
kubectl describe deployment <your-deployment-name>
```
---

## Developer Access — Read-Only IAM User for EKS
On AWS Console, I navigated to IAM and created a new user named `developer-InnovateMart` with programmatic access. I attached a custom policy with the following permissions:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "EKSReadOnly",
      "Effect": "Allow",
      "Action": [
        "eks:Describe*",
        "eks:List*",
        "eks:AccessKubernetesApi",
        "logs:GetLogEvents",
        "logs:DescribeLogStreams",
        "logs:DescribeLogGroups"
      ],
      "Resource": "*"
    }
  ]
}
```
### Map User to EKS Cluster
I edited the `aws-auth` ConfigMap to include the new IAM user:
```bash
kubectl edit -n kube-system configmap/aws-auth
```

I added the following under `mapUsers`:
```yaml
mapUsers: |
  - userarn: arn:aws:iam::498457984677:user/developer-InnovateMart
    username: developer-InnovateMart
    groups:
      - view-only-group
```

I created a ClusterRole named `view-only-clusterrole` with read-only access to the cluster:
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: view-only-role
rules:
  - apiGroups: ["", "apps", "extensions"]
    resources: ["pods", "services", "deployments", "replicasets", "events", "configmaps", "namespaces"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["batch"]
    resources: ["jobs", "cronjobs"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["autoscaling"]
    resources: ["horizontalpodautoscalers"]
    verbs: ["get", "list", "watch"]
```

Then, I created a ClusterRoleBinding to bind the `view-only-group` to the `developer-InnovateMart` user:
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: view-only-binding
subjects:
  - kind: Group
    name: view-only-group
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: view-only-role
  apiGroup: rbac.authorization.k8s.io
```

I applied the ClusterRole and ClusterRoleBinding:
```bash
kubectl apply -f view-only-clusterrole.yaml
kubectl apply -f view-only-binding.yaml
```

This ensures that the `developer-InnovateMart` user can:
- View pods, services, deployments, and other resources in the EKS cluster
- Access logs in CloudWatch
- Cannot make any changes to the cluster resources

### Test Developer Access
I configured `kubectl` for the `developer-InnovateMart` user:
```bash
aws eks --region eu-west-2 update-kubeconfig --name project-bedrock-eks-cluster --role-arn arn:aws:iam::498457984677:user/developer-InnovateMart
```
I verified the access by running:
```bash
kubectl get pods
kubectl get svc
kubectl get deployments
```

I created a simple test script `test-access.sh` in the `terraform` folder that the developer can run to verify their access. It checks if they can:
- View pods
- Describe services
- Scale deployment
- View logs
- Delete pod
- Apply manifest

### Access Credentials
On the developer's machine, I provided the access key ID and secret access key for the `developer-InnovateMart` user to configure AWS CLI.
```bash
aws configure
```
- **Access key ID**: AAKIAXIDTJH2S4WXTSMMY
- **Secret access key**: A86uW8qM9N1oatzM95TMjnVSBHG4WyQEo3xP4zE5
- **Default region name**: eu-west-2
- **Default output format**: json

Then update the kubeconfig:
```bash
aws eks update-kubeconfig --region eu-west-2 --name project-bedrock-eks-cluster
```

---

## CI/CD Pipeline with GitHub Actions
I set up a GitHub Actions workflow to automate the Terraform deployment process. The workflow is defined in `.github/workflows/terraform.yml`:
- On push to feature branches → run terraform plan
- On merge to main branch → run terraform apply

Not to hardcode sensitive information, I used GitHub Secrets to store:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_REGION`

### Branch Protection and PR Reviews
I enabled branch protection rules on the `main` branch to require pull request reviews before merging. I headed to Repo → Settings → Branches → Add rule and enabled the following rules for the `main` branch:
- Require a pull request before merging
- Require approvals
- Require review from Code Owners
- Require status checks to pass before merging (selected the GitHub Actions workflow)
- Require linear history
- Do not allow bypassing the above settings

For PR reviews, I created a new environment `production` and added Required reviewers to ensure that at least one team member reviews and approves the changes before they are merged into the `main` branch.

---

## Advanced Networking & Security
### Set Variables for Advanced Networking & Security
I set the variables and values for:
- export AWS_REGION=eu-west-2
- export ACCOUNT_ID=498457984677
- export CLUSTER_NAME=<your-eks-cluster-name>
- export VPC_ID=$(aws eks describe-cluster --name $CLUSTER_NAME --region $AWS_REGION \
  --query "cluster.resourcesVpcConfig.vpcId" --output text)

### Enable IAM OIDC provider for the cluster
I ran the following command to enable the IAM OIDC provider for the EKS cluster:
```bash
eksctl utils associate-iam-oidc-provider --region $AWS_REGION --cluster $CLUSTER_NAME --approve
```
This allows the cluster to use IAM roles for service accounts.

### Create an IAM Policy For the Controller
I created an IAM policy named `AmazonEKSLoadBalancerControllerPolicy` with the necessary permissions for the AWS Load Balancer Controller:
```bash
curl -o iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json
aws iam create-policy --policy-name AmazonEKSLoadBalancerControllerPolicy --policy-document file://iam_policy.json
export LBC_POLICY_ARN=arn:aws:iam::$ACCOUNT_ID:policy/AWSLoadBalancerControllerIAMPolicy
``` 

### Create a Service Account for the Controller
I created a Kubernetes namespace and service account for the AWS Load Balancer Controller:
```bash
kubectl create namespace kube-system
eksctl create iamserviceaccount \
  --cluster=$CLUSTER_NAME \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --attach-policy-arn=$LBC_POLICY_ARN \
  --override-existing-serviceaccounts \
  --approve
```

### Install the AWS Load Balancer Controller using Helm
I added the EKS Helm chart repository and installed the AWS Load Balancer Controller:
```bash
helm repo add eks https://aws.github.io/eks-charts
helm repo update
helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=$CLUSTER_NAME \
  --set region=$AWS_REGION \
  --set vpcId=$VPC_ID \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller
```

### Verify the Installation
I verified that the AWS Load Balancer Controller pods are running:
```bash
kubectl -n kube-system rollout status deployment/aws-load-balancer-controller
kubectl -n kube-system get deploy aws-load-balancer-controller
``` 

### Create Ingress Resource for Load Balancer
I created an Ingress resource to expose the application using the AWS Load Balancer Controller:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ui-ingress
  namespace: default
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP":80}]'
    alb.ingress.kubernetes.io/healthcheck-path: /
    alb.ingress.kubernetes.io/healthcheck-port: traffic-port
spec:
  ingressClassName: alb
  rules:
    - http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: ui
                port:
                  number: 80
```

### Domain + Route 53 Setup

I used sub-domain `innovatemat.duckdns.org` for the application. I headed to Route 53 on AWS Console and created a hosted zone with the following details:
- **Domain Name**: `innovatemart.duckdns.org`
- **Type**: Public Hosted Zone

I obtained the ALB DNS name from the LoadBalancer created earlier:
```bash
kubectl get svc -A | grep LoadBalancer
```

I created an A record in the Route 53 hosted zone to point to the ALB DNS name using an alias:
- **Record Name**: left blank to use the root domain
- **Record Type**: A - IPv4 address
- **Alias**: Yes
- **Alias Target**: Selected the ALB DNS name from the dropdown

![Alt text](https://github.com/gbengasorinola/altschool-project-bedrock/blob/main/Screen%20Shot%202025-10-05%20at%202.20.08%20AM.png)

### Create a TLS Certificate using AWS Certificate Manager (ACM)
I requested a public certificate for `innovatemart.duckdns.org` in ACM in the `eu-west-2` region and validated it using DNS validation.

![Alt text](https://github.com/gbengasorinola/altschool-project-bedrock/blob/main/Screen%20Shot%202025-10-04%20at%2010.31.51%20PM.png)

**Note**: I was unable to proceed with the TLS setup as DuckDNS does not support adding the required CNAME records for DNS validation in Route 53.


### Update Ingress Resource with TLS
Once the certificate is issued, I updated the Ingress resource to use the TLS certificate:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ui-ingress
  namespace: default
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP":80},{"HTTPS":443}]'
    alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:eu-west-2:498457984677:certificate/f6998394-609a-4f2a-9962-50ab62a1accf
    alb.ingress.kubernetes.io/ssl-redirect: "443"
spec:
  ingressClassName: alb
  rules:
    - host: innovatecart.duckdns.org
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: ui
                port:
                  number: 80
```

I applied the updated Ingress manifest:
```bash
kubectl apply -f ui-ingress.yaml
```
This configures the Ingress to use HTTPS with the specified TLS certificate.

![Alt text](https://github.com/gbengasorinola/altschool-project-bedrock/blob/main/Screen%20Shot%202025-10-04%20at%2010.29.20%20PM.png)

## Conclusion
This project successfully deployed the InnovateMart e-commerce platform on AWS EKS with advanced networking and security features. The application is accessible via a secure HTTPS endpoint, and the infrastructure is managed using Terraform and GitHub Actions for CI/CD.



