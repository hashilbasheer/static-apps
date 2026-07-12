# Static CI/CD Demo.

Simple static HTML application for demonstrating:

- Docker build
- GitHub Actions CI
- Container image push
- GitOps deployment with Helm and Argo CD

## Local Docker build

```bash
docker build \
  --build-arg VERSION=$(git rev-parse --short HEAD 2>/dev/null || echo local) \
  --build-arg BUILD_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ") \
  --build-arg ENVIRONMENT=local \
  -t static-cicd-demo:local .
