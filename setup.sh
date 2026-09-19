#!/bin/sh
# ONE-TIME bootstrap: creates network, blue + green containers, and the nginx router.
# Usage: ./setup.sh <dockerhub-username>/bluegreen-node-app:latest
set -e
IMAGE=${1:?Usage: ./setup.sh <dockerhub-username>/bluegreen-node-app:latest}

docker network create bluegreen-net 2>/dev/null || true
docker rm -f app-blue app-green nginx-proxy 2>/dev/null || true

docker run -d --name app-blue  --network bluegreen-net -p 3001:3000 \
  -e APP_COLOR=blue  -e APP_VERSION=1 "$IMAGE"
docker run -d --name app-green --network bluegreen-net -p 3002:3000 \
  -e APP_COLOR=green -e APP_VERSION=1 "$IMAGE"

echo "server app-blue:3000;" > nginx/active.inc      # blue is live first

docker run -d --name nginx-proxy --network bluegreen-net -p 8081:80 \
  -v "$(pwd)/nginx/nginx.conf:/etc/nginx/nginx.conf:ro" \
  -v "$(pwd)/nginx/active.inc:/etc/nginx/active.inc" \
  nginx:alpine

echo "Done. Live site: http://localhost:8081  | blue: :3001 | green: :3002"
