#!/bin/bash
# release/deploy.sh
# Sovereign Deployment Script for EasyWay MVP Appliance
# Usage: ./deploy.sh [--init]

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${GREEN}[EasyWay]${NC} $1"; }
error() { echo -e "${RED}[Error]${NC} $1"; }

# 1. Environment Check
log "Checking environment..."
if [ ! -f .env ]; then
    error "Missing .env file. Please create one from .env.example."
    exit 1
fi

# Load variables for script use (set -a to export automatically)
set -a
source .env
set +a

# 2. Docker Check
if ! command -v docker &> /dev/null; then
    error "Docker is not installed."
    exit 1
fi

# 3. Pull & Start
log "Starting Sovereign Appliance..."
docker compose pull
docker compose up -d --wait

log "Services are Healthy."

# 4. Initialization (Optional)
if [ "$1" == "--init" ]; then
    log "Running Database Initialization (Seed)..."
    if [ ! -f init.sql ]; then
        error "init.sql not found in current directory."
        exit 1
    fi
    
    # Copy init.sql to container
    docker cp init.sql easyway-db:/tmp/init.sql
    
    # Execute via sqlcmd
    # Note: Using /opt/mssql-tools/bin/sqlcmd as per Azure SQL Edge
    docker exec easyway-db /opt/mssql-tools/bin/sqlcmd \
        -S localhost -U sa -P "$SQL_SA_PASSWORD" \
        -i /tmp/init.sql
        
    log "Database Initialized."
fi

log "Deployment Complete. Access Portal at http://localhost:8080"
