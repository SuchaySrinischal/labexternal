#!/usr/bin/env bash
# Deploy the Maven WAR application from GitHub to an Ubuntu EC2 instance.
# Run from any directory: bash aws-deploy.sh

set -euo pipefail

REPO_URL="https://github.com/SuchaySrinischal/labexternal.git"
PROJECT_DIR="$HOME/labexternal"
IMAGE_NAME="mywebapp"
CONTAINER_NAME="app-demo"
HOST_PORT="6060"
CONTAINER_PORT="8080"

echo "=== 1. Update Ubuntu and install required tools ==="
sudo apt update
sudo apt install -y docker.io git nano

echo "=== 2. Enable and start Docker ==="
sudo systemctl enable --now docker

echo "=== 3. Clone or update the project ==="
if [ -d "$PROJECT_DIR/.git" ]; then
    echo "Repository already exists at $PROJECT_DIR"
    git -C "$PROJECT_DIR" pull --ff-only
else
    git clone "$REPO_URL" "$PROJECT_DIR"
fi

cd "$PROJECT_DIR"

echo "=== 4. Check deployment files ==="
if [ ! -f "Dockerfile" ]; then
    echo "ERROR: Dockerfile was not found in $PROJECT_DIR"
    exit 1
fi

if ! compgen -G "target/*.war" > /dev/null; then
    echo "ERROR: No WAR file found in target/. Build the Maven project and ensure the WAR is committed/present."
    exit 1
fi

echo "=== 5. Build Docker image ==="
sudo docker build -t "$IMAGE_NAME" .

echo "=== 6. Replace any previous container and start the application ==="
sudo docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
sudo docker run -d \
    --name "$CONTAINER_NAME" \
    -p "${HOST_PORT}:${CONTAINER_PORT}" \
    "$IMAGE_NAME"

echo "=== 7. Verify deployment ==="
sudo docker ps --filter "name=$CONTAINER_NAME"
echo
echo "Deployment command completed."
echo "Open: http://<EC2-PUBLIC-IP>:${HOST_PORT}/works/"
echo "IMPORTANT: Allow inbound TCP port ${HOST_PORT} in the EC2 Security Group."
