from fastapi import FastAPI
from datetime import datetime

app = FastAPI(
    title="Kubernetes GitOps Demo API",
    description="Demo application for a cloud-native GitOps platform",
    version="1.0.0",
)


@app.get("/")
def root():
    return {
        "message": "Kubernetes GitOps Platform",
        "status": "running",
    }


@app.get("/health")
def health():
    return {
        "status": "healthy",
        "timestamp": datetime.utcnow().isoformat(),
    }


@app.get("/api/info")
def info():
    return {
        "application": "gitops-demo-api",
        "version": "1.0.0",
        "environment": "development",
    }
