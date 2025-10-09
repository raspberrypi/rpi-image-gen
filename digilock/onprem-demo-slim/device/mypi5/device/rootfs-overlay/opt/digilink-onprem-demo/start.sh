#!/bin/sh
# Load all Docker tar files from /opt/digilink-onprem-demo
for tarfile in /opt/digilink-onprem-demo/*.tar; do
  echo "Loading $tarfile..."
  docker load < "$tarfile"
done

# Start Docker Compose services
docker compose -f /opt/digilink-onprem-demo/docker-compose.demo.yml up -d