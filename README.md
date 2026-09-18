# Kubernetes GitOps Deployment Platform on AWS

A production-style DevOps project that demonstrates how a containerized application can be tested, secured, and deployed to Kubernetes using a GitOps workflow on AWS.

## Architecture

```text
Developer
   ↓
GitHub
   ↓
GitHub Actions
   ├── Tests
   ├── Docker Build
   └── Trivy Scan
          ↓
       Amazon ECR
          ↓
   GitOps Repository
          ↓
       Argo CD
          ↓
      Amazon EKS
          ↓
 Kubernetes Ingress
          ↓
     AWS ALB
          ↓
       FastAPI
```

## What it demonstrates

* **Terraform** for reproducible AWS infrastructure
* **Docker** for application containerization
* **GitHub Actions** for CI and automated image publishing
* **Trivy** for container vulnerability scanning
* **Amazon ECR** for container images
* **Amazon EKS** for Kubernetes workloads
* **Helm** for application packaging
* **Argo CD** for GitOps-based deployment and self-healing
* **AWS Load Balancer Controller** for public application access
* **Kubernetes HPA** for CPU-based autoscaling
* **Health probes** for application reliability

## GitOps workflow

Application source code and deployment configuration are maintained separately.

A code change triggers the CI pipeline, which tests the application, builds the container, scans it with Trivy, and publishes the image to ECR.

The desired Kubernetes configuration is maintained in a separate Git repository. Argo CD continuously monitors this repository and reconciles the EKS cluster with the declared state.

This provides traceable deployments, automated synchronization, and self-healing when the live cluster differs from Git.

## Application

The demo application is a small FastAPI service with:

```text
GET /
GET /health
GET /api/info
```

## Future improvements

* Amazon CloudWatch Container Insights and dashboards
* Automated image promotion between the application and GitOps repositories
* HTTPS with ACM
* Deployment environments such as staging and production
* Additional observability and alerting

## Project goal

The goal of this project is to demonstrate a practical cloud-native delivery workflow where infrastructure, application builds, security checks, and Kubernetes deployments are automated and managed through version-controlled configuration.
