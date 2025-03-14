# Hello API with Kubernetes, Helm, Kustomize, and ArgoCD

This repository contains a simple Hello API service deployed using various Kubernetes tools.

## Project Structure

```
.
├── api/                    # Go application
│   ├── cmd/               # Main application code
│   └── Dockerfile         # Container image definition
├── helm/                  # Helm chart
│   └── hello-api/        # Chart files
├── kustomize/            # Kustomize configurations
│   ├── base/             # Base configuration
│   └── overlays/         # Environment-specific overlays
└── argocd/              # ArgoCD configuration
```

## Prerequisites

- Kubernetes cluster
- Helm v3
- Kustomize
- ArgoCD installed in your cluster
- Go 1.21+
- Docker

## Building the Application

```bash
cd api
docker build -t hello-api:1.0.1 .
```

## Deploying with Helm

```bash
cd helm
helm install hello-api ./hello-api
```

## Deploying with Kustomize

```bash
kubectl apply -k kustomize/overlays/dev
```

## Deploying with ArgoCD

1. Update the repository URL in `argocd/application.yaml`
2. Apply the ArgoCD application:

```bash
kubectl apply -f argocd/application.yaml
```

## API Endpoints

- `GET /`: Returns a hello message with version information

## Configuration

The application can be configured using environment variables:

- `PORT`: Server port (default: 8080)
- `APP_VERSION`: Application version (default: 1.0.0) 