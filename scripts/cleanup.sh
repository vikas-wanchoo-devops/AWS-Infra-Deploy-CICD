#!/bin/bash
set -e
echo "Cleaning up old Docker images..."
docker system prune -af
echo "Cleanup complete."
