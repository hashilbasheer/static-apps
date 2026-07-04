#!/usr/bin/env bash
set -euo pipefail

APP_NAME="static-cicd-demo"

mkdir -p "${APP_NAME}/src"
mkdir -p "${APP_NAME}/.github/workflows"

cat > "${APP_NAME}/src/index.html" <<'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Static CI/CD Demo</title>
  <link rel="stylesheet" href="./style.css" />
</head>
<body>
  <main class="container">
    <section class="card">
      <h1>Static CI/CD Demo</h1>

      <p class="subtitle">
        This page is deployed using GitHub Actions, Docker, Helm and Argo CD.
      </p>

      <div class="info-box">
        <div>
          <span class="label">Version / Commit ID</span>
          <span id="app-version" class="value">loading...</span>
        </div>

        <div>
          <span class="label">Build Time</span>
          <span id="build-time" class="value">loading...</span>
        </div>

        <div>
          <span class="label">Environment</span>
          <span id="environment" class="value">loading...</span>
        </div>
      </div>

      <p class="footer">
        Every new deployment should show the latest commit ID here.
      </p>
    </section>
  </main>

  <script src="./version.js"></script>
  <script src="./app.js"></script>
</body>
</html>
EOF

cat > "${APP_NAME}/src/style.css" <<'EOF'
* {
  box-sizing: border-box;
}

body {
  margin: 0;
  font-family: Arial, Helvetica, sans-serif;
  background: linear-gradient(135deg, #0f172a, #1e293b);
  color: #f8fafc;
  min-height: 100vh;
}

.container {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 24px;
}

.card {
  width: 100%;
  max-width: 720px;
  background: rgba(15, 23, 42, 0.9);
  border: 1px solid rgba(148, 163, 184, 0.25);
  border-radius: 20px;
  padding: 40px;
  box-shadow: 0 25px 80px rgba(0, 0, 0, 0.35);
}

h1 {
  margin: 0 0 12px;
  font-size: 42px;
}

.subtitle {
  color: #cbd5e1;
  font-size: 18px;
  margin-bottom: 32px;
}

.info-box {
  display: grid;
  gap: 18px;
  background: #020617;
  border-radius: 16px;
  padding: 24px;
  border: 1px solid rgba(148, 163, 184, 0.2);
}

.label {
  display: block;
  color: #94a3b8;
  font-size: 14px;
  margin-bottom: 6px;
}

.value {
  display: block;
  color: #38bdf8;
  font-size: 22px;
  font-weight: bold;
  word-break: break-all;
}

.footer {
  margin-top: 28px;
  color: #94a3b8;
  font-size: 14px;
}
EOF

cat > "${APP_NAME}/src/app.js" <<'EOF'
(function () {
  const buildInfo = window.__BUILD_INFO__ || {
    version: "local-dev",
    buildTime: "unknown",
    environment: "local"
  };

  document.getElementById("app-version").textContent = buildInfo.version;
  document.getElementById("build-time").textContent = buildInfo.buildTime;
  document.getElementById("environment").textContent = buildInfo.environment;
})();
EOF

cat > "${APP_NAME}/Dockerfile" <<'EOF'
FROM nginx:1.27-alpine

ARG VERSION=local-dev
ARG BUILD_TIME=unknown
ARG ENVIRONMENT=dev

WORKDIR /usr/share/nginx/html

RUN rm -rf ./*

COPY src/ .

RUN cat > /usr/share/nginx/html/version.js <<EOF_VERSION
window.__BUILD_INFO__ = {
  version: "${VERSION}",
  buildTime: "${BUILD_TIME}",
  environment: "${ENVIRONMENT}"
};
EOF_VERSION

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
EOF

cat > "${APP_NAME}/.dockerignore" <<'EOF'
.git
.github
README.md
node_modules
npm-debug.log
.DS_Store
EOF

cat > "${APP_NAME}/.github/workflows/docker-build-push.yaml" <<'EOF'
name: Build and Push Docker Image

on:
  push:
    branches:
      - main
      - dev
      - stage
      - prod

env:
  IMAGE_NAME: static-cicd-demo

jobs:
  build-and-push:
    name: Build and Push
    runs-on: ubuntu-latest

    permissions:
      contents: read
      packages: write

    steps:
      - name: Checkout source code
        uses: actions/checkout@v4

      - name: Set image metadata
        id: meta
        run: |
          SHORT_SHA=$(echo "${GITHUB_SHA}" | cut -c1-7)
          BUILD_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

          echo "short_sha=${SHORT_SHA}" >> "$GITHUB_OUTPUT"
          echo "build_time=${BUILD_TIME}" >> "$GITHUB_OUTPUT"

          if [ "${GITHUB_REF_NAME}" = "main" ]; then
            echo "environment=prod" >> "$GITHUB_OUTPUT"
          else
            echo "environment=${GITHUB_REF_NAME}" >> "$GITHUB_OUTPUT"
          fi

      - name: Login to GitHub Container Registry
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Build Docker image
        run: |
          IMAGE_REPOSITORY="ghcr.io/${{ github.repository_owner }}/${IMAGE_NAME}"

          docker build \
            --build-arg VERSION=${{ steps.meta.outputs.short_sha }} \
            --build-arg BUILD_TIME=${{ steps.meta.outputs.build_time }} \
            --build-arg ENVIRONMENT=${{ steps.meta.outputs.environment }} \
            -t ${IMAGE_REPOSITORY}:${{ steps.meta.outputs.short_sha }} \
            -t ${IMAGE_REPOSITORY}:${{ github.ref_name }} \
            .

      - name: Push Docker image
        run: |
          IMAGE_REPOSITORY="ghcr.io/${{ github.repository_owner }}/${IMAGE_NAME}"

          docker push ${IMAGE_REPOSITORY}:${{ steps.meta.outputs.short_sha }}
          docker push ${IMAGE_REPOSITORY}:${{ github.ref_name }}

      - name: Print image details
        run: |
          echo "Image pushed successfully"
          echo "Image: ghcr.io/${{ github.repository_owner }}/${IMAGE_NAME}:${{ steps.meta.outputs.short_sha }}"
          echo "Environment: ${{ steps.meta.outputs.environment }}"
          echo "Build time: ${{ steps.meta.outputs.build_time }}"
EOF

cat > "${APP_NAME}/README.md" <<'EOF'
# Static CI/CD Demo

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
