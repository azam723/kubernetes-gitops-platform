# Kubernetes GitOps Deployment Platform on AWS

![AWS](https://img.shields.io/badge/AWS-EKS-orange?logo=amazonaws&logoColor=white)
![Kubernetes](https://img.shields.io/badge/Kubernetes-1.29-326CE5?logo=kubernetes&logoColor=white)
![Terraform](https://img.shields.io/badge/Terraform-IaC-844FBA?logo=terraform&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-container-2496ED?logo=docker&logoColor=white)
![GitHub Actions](https://img.shields.io/badge/CI-GitHub%20Actions-2088FF?logo=githubactions&logoColor=white)
![Argo CD](https://img.shields.io/badge/GitOps-Argo%20CD-EF7B4D?logo=argo&logoColor=white)
![Trivy](https://img.shields.io/badge/Security-Trivy-1904DA)

A production-style DevOps project demonstrating a full GitOps delivery pipeline: a containerized FastAPI application is tested, scanned, built, and deployed to Kubernetes on AWS, with Argo CD continuously reconciling the live cluster against a version-controlled desired state.

---

## Architecture

<img width="480" alt="GitOps pipeline architecture diagram" src="https://github.com/user-attachments/assets/ccfcd5a2-23a4-402b-9402-f0d35e54cd69" />

## Why this project

Most CI/CD demos stop at "push image, run `kubectl apply`." This project instead separates **build** from **deploy**: CI never touches the cluster directly. Argo CD watches a dedicated GitOps repo and reconciles EKS to match it so every deployment is traceable to a Git commit, and the cluster self-heals if it drifts from that declared state.

## Stack

| Layer | Tool | Purpose |
|---|---|---|
| Infrastructure | Terraform | Reproducible AWS provisioning (VPC, EKS, IAM) |
| Containerization | Docker | Application packaging |
| CI | GitHub Actions | Test → build → scan → publish |
| Security | Trivy | Container vulnerability scanning in-pipeline |
| Registry | Amazon ECR | Image storage |
| Orchestration | Amazon EKS | Kubernetes control plane / workloads |
| Packaging | Helm | Application chart management |
| Delivery | Argo CD | GitOps sync + self-healing |
| Ingress | AWS Load Balancer Controller | Public access via ALB |
| Scaling | Kubernetes HPA | CPU-based autoscaling |
| Reliability | Liveness/readiness probes | Health-checked rollouts |

## Application

Minimal FastAPI service used to exercise the pipeline:

```text
GET /           → basic response
GET /health     → liveness/readiness target
GET /api/info   → sample data endpoint
```

## GitOps workflow

1. A code change is pushed to `app-repo`.
2. GitHub Actions runs tests, builds the Docker image, scans it with Trivy, and if clean pushes it to Amazon ECR.
3. CI updates the image tag in `gitops-repo` (the desired-state repo).
4. Argo CD detects the change and syncs EKS to match it.
5. If someone manually edits a live resource (`kubectl edit`, etc.), Argo CD detects the drift and reverts it,  no drift survives outside Git.

## Repository structure

```text
app-repo/                  # this repo — application + CI
├── app/                   # FastAPI source
│   ├── main.py
│   └── requirements.txt
├── Dockerfile
├── .github/workflows/
│   └── ci.yml             # test → build → trivy → push to ECR
├── terraform/
│   ├── main.tf
│   ├── eks.tf
│   └── variables.tf
└── README.md

gitops-repo/                # separate repo — watched by Argo CD
├── helm/
│   ├── Chart.yaml
│   ├── values.yaml
│   └── templates/
└── argocd/
    └── application.yaml
```

## Quick start

```bash
# 1. Provision infrastructure
cd terraform && terraform init && terraform apply

# 2. Install Argo CD on the cluster
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# 3. Point Argo CD at the GitOps repo
kubectl apply -f argocd/application.yaml

# 4. Watch it sync
argocd app sync gitops-demo-api
kubectl get pods -w
```

## Screenshots

**Argo CD — synced and healthy**
<img width="900" alt="Argo CD sync and health status" src="https://github.com/user-attachments/assets/7b0f2258-0c27-4bff-81a3-47f00a564d06" />

**GitHub Actions — test, build, Trivy scan, push**
<img width="900" alt="GitHub Actions CI pipeline run" src="https://github.com/user-attachments/assets/82784332-f212-4a9b-8ccb-d42fa09ae736" />

**Cluster state — pods, HPA, ingress**
<img width="900" alt="kubectl get pods, hpa, ingress output" src="https://github.com/user-attachments/assets/9d20342e-766f-4038-a9f6-c398e067addb" />

**Live platform validation**
<img width="900" alt="Application served via ALB" src="https://github.com/user-attachments/assets/7b8c902d-090b-4069-8574-a4eeba3a3901" />

## Validation / what I tested

- [x] Killed a pod manually and confirmed Kubernetes rescheduled it within Ns
- [x] Generated load and confirmed HPA scaled replicas from X → Y
- [x] Manually edited a live Deployment and confirmed Argo CD reverted it within Ns (self-healing proof)
- [x] Pushed a bad image and confirmed Trivy blocked the pipeline before it reached ECR
- [x] Confirmed `/health` failing correctly stops traffic routing via readiness probe

Screenshots for each of the above are in [`docs/evidence`](./docs/evidence).

## Troubleshooting

Real issues hit while building this, and how they were resolved.

<!--
Format for each entry:
### Short title of the problem
**Symptom:** what you saw (error message, unexpected output)
**Cause:** what was actually going wrong
**Fix:** the command/config change that resolved it
-->

### Trivy blocked the pipeline on a vulnerable base image
**What it demonstrates:** the security gate works as designed, not just that it exists.
**Symptom:** During the initial CI runs, Trivy reported HIGH/CRITICAL vulnerabilities in the built image. GitHub Actions failed at the scanning stage before the image could reach ECR.
**Cause:** The base image shipped with outdated OS packages carrying known CVEs.
**Fix:** Updated the Dockerfile to upgrade OS packages before installing Python dependencies, then rebuilt and rescanned locally before pushing:

```bash
docker build -t gitops-demo-api .
trivy image gitops-demo-api
```

The scan passed and the image continued through the pipeline to Amazon ECR.
**Takeaway:** Scanning has to happen in CI, before publish, not after deploy. This is exactly the failure mode a security gate is meant to catch.

### ALB returned 502 Bad Gateway despite a healthy cluster
**What it demonstrates:** tracing the traffic path methodically instead of guessing or restarting things at random.
**Symptom:** After configuring the AWS Load Balancer Controller, the public URL returned `502 Bad Gateway` even though the cluster and pods appeared healthy.
**Cause:** Traced the request path end to end — ALB → Target Group → Service → Pod → App:

```bash
kubectl get ingress
kubectl describe ingress gitops-demo-api
kubectl get svc gitops-demo-api
kubectl describe svc gitops-demo-api
kubectl get endpoints gitops-demo-api
kubectl get pods -l app.kubernetes.io/name=gitops-demo-api -o wide
kubectl get deployment gitops-demo-api -o yaml
kubectl get pods --show-labels
```

This surfaced a mismatch between the Deployment's selector and the pod labels generated by the Helm chart — the Service had no matching endpoints, so the ALB had nothing to route to.
**Fix:** Aligned the Deployment selector with the Helm chart's label scheme. Once Argo CD reconciled the change, `curl http://<ALB-DNS>/health` returned `200 OK`.
**Takeaway:** A healthy ALB and a healthy cluster don't guarantee a healthy request path. Trace the full chain — `ALB → Target Group → Service → Pod → App` — rather than assuming the problem is at the layer where the symptom shows up.

### HPA load test failed because the cluster couldn't schedule the load generator
**What it demonstrates:** Kubernetes scheduling and pod capacity constraints, and adapting the approach when the first plan hits a wall.
**Symptom:** To test autoscaling, a separate CPU-load pod was created. It stuck in `Pending`:

```bash
kubectl get pods
```

The scheduler reported:

```text
0/2 nodes are available: 2 Too many pods
```

**Cause:** The EKS nodes were already at their pod-scheduling capacity — this had nothing to do with CPU utilization. Confirmed with:

```bash
kubectl get nodes
kubectl get pods -A
kubectl describe pod cpu-load
```

**Fix:** Rather than scheduling another pod, generated CPU load inside the existing application pod instead:

```bash
kubectl exec -it <APP_POD_NAME> -- sh -c \
'for i in 1 2 3 4; do while true; do :; done & done; wait'
```

HPA detected the increased utilization (`kubectl get hpa`) and scaled the deployment from 1 → 2 replicas, then scaled back down once the load stopped.
**Takeaway:** A `Ready` node doesn't guarantee it can schedule another pod — pod capacity per node is a separate constraint from CPU/memory headroom, and it's worth checking early when a pod won't leave `Pending`.

<!-- Add more entries below as you hit and resolve issues -->

## Cost & teardown

Amazon EKS control plane + ALB + NAT gateway incur ongoing cost (~$0.10/hr EKS control plane, plus node and load-balancer charges roughly **$70–100/month** if left running). To tear down:

```bash
kubectl delete -f argocd/application.yaml
cd terraform && terraform destroy
```

## Future improvements

Scoped out to keep this time-boxed, in priority order:

1. **HTTPS via ACM** — currently HTTP-only on the ALB
2. **Staging/production environments** — single environment today
3. **Automated image promotion** between app and GitOps repos (currently manual tag bump)
4. **Observability** — CloudWatch Container Insights, dashboards, alerting

## Project goal

Demonstrate a practical, production-ready cloud-native delivery workflow in which infrastructure, builds, security checks, and deployments are fully automated and driven by version-controlled configuration rather than manual steps.
