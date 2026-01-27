#!/bin/bash
set -euo pipefail

ENVIRONMENT="${1:-}"
CONFIG_FILE="${CONFIG_FILE:-.deploy.conf}"

if [ -z "$ENVIRONMENT" ]; then
    echo "Usage: $0 <environment>"
    echo "Environments: development, staging, production"
    exit 1
fi

case "$ENVIRONMENT" in
    development|staging|production)
        echo "Deploying to $ENVIRONMENT..."
        ;;
    *)
        echo "Error: Unknown environment: $ENVIRONMENT"
        exit 1
        ;;
esac

if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

DEPLOY_HOST="${DEPLOY_HOST:-localhost}"
DEPLOY_PATH="${DEPLOY_PATH:-/var/www/app}"

echo "Target: $DEPLOY_HOST:$DEPLOY_PATH"
echo "Environment: $ENVIRONMENT"

if [ "$ENVIRONMENT" = "production" ]; then
    read -p "Are you sure you want to deploy to production? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Deployment cancelled."
        exit 0
    fi
fi

echo "Deployment would proceed here..."
echo "Done."
