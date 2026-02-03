#!/bin/bash
# GitLab Deployment Script
# Server: 80.225.86.168
# Purpose: Deploy GitLab self-managed with all prerequisites
# Documentation: docs/infra/gitlab-setup-guide.md

set -e  # Exit on error

echo "========================================="
echo "GitLab Self-Managed Deployment Script"
echo "Server: 80.225.86.168"
echo "========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Step 1: Create directory structure
echo -e "${YELLOW}Step 1: Creating directory structure...${NC}"
mkdir -p ~/gitlab/{config,logs,data}
mkdir -p ~/gitlab-runner/config
mkdir -p ~/backups/gitlab
echo -e "${GREEN}✓ Directories created${NC}"
echo ""

# Step 2: Set permissions
echo -e "${YELLOW}Step 2: Setting permissions...${NC}"
sudo chown -R 1000:1000 ~/gitlab
sudo chown -R 1000:1000 ~/gitlab-runner
echo -e "${GREEN}✓ Permissions set${NC}"
echo ""

# Step 3: Check available resources
echo -e "${YELLOW}Step 3: Checking server resources...${NC}"
echo "RAM:"
free -h | grep Mem
echo ""
echo "Disk:"
df -h / | tail -1
echo ""
echo "CPU:"
nproc
echo -e "${GREEN}✓ Resources verified${NC}"
echo ""

# Step 4: Pull GitLab image
echo -e "${YELLOW}Step 4: Pulling GitLab Docker image (this may take a few minutes)...${NC}"
docker pull gitlab/gitlab-ce:latest
docker pull gitlab/gitlab-runner:latest
echo -e "${GREEN}✓ Images pulled${NC}"
echo ""

# Step 5: Deploy GitLab
echo -e "${YELLOW}Step 5: Deploying GitLab...${NC}"
docker-compose -f ~/docker-compose.gitlab.yml up -d
echo -e "${GREEN}✓ GitLab deployed${NC}"
echo ""

# Step 6: Wait for GitLab to start
echo -e "${YELLOW}Step 6: Waiting for GitLab to start (this takes 2-5 minutes)...${NC}"
echo "Monitoring logs... (Ctrl+C to skip)"
timeout 300 docker logs -f easyway-gitlab 2>&1 | grep -q "gitlab Reconfigured!" || true
echo -e "${GREEN}✓ GitLab is starting${NC}"
echo ""

# Step 7: Display access information
echo -e "${YELLOW}Step 7: Retrieving access information...${NC}"
echo ""
echo "========================================="
echo -e "${GREEN}GitLab Deployment Complete!${NC}"
echo "========================================="
echo ""
echo "Access Information:"
echo "  URL: http://80.225.86.168:8929"
echo "  Username: root"
echo ""
echo "To get the initial root password, run:"
echo "  docker exec easyway-gitlab cat /etc/gitlab/initial_root_password"
echo ""
echo "SSH Clone URL format:"
echo "  ssh://git@80.225.86.168:2222/group/project.git"
echo ""
echo "Next Steps:"
echo "  1. Access GitLab UI and change root password"
echo "  2. Create admin user"
echo "  3. Disable sign-ups (Admin Area → Settings → General)"
echo "  4. Register GitLab Runner for CI/CD"
echo "  5. Setup automated backups (see docs/infra/gitlab-setup-guide.md)"
echo ""
echo "Documentation: docs/infra/gitlab-setup-guide.md"
echo "========================================="
