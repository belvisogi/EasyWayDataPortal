# Ubuntu VM Setup for EasyWay Development

## 🎯 Overview

This guide sets up an Ubuntu VM to run EasyWay scripts against Azure SQL Server.

**Stack:**
- Ubuntu 22.04 LTS (or newer)
- PowerShell Core 7+
- Azure SQL Server (existing)
- Node.js 18+ (for db-deploy-ai)
- Git

---

## 📋 Prerequisites

- Ubuntu VM (8GB RAM, 50GB disk recommended)
- Azure SQL Server connection string
- Git repository access

---

## 🚀 Quick Setup (Automated)

```bash
# Download and run setup script
curl -o setup-easyway.sh https://raw.githubusercontent.com/your-repo/scripts/setup-easyway.sh
chmod +x setup-easyway.sh
sudo ./setup-easyway.sh
```

---

## 📖 Manual Setup (Step-by-Step)

### 1. Update System

```bash
sudo apt update
sudo apt upgrade -y
```

### 2. Install PowerShell Core

```bash
# Install PowerShell via snap (easiest)
sudo snap install powershell --classic

# Verify installation
pwsh --version
# Expected: PowerShell 7.x.x
```

**Alternative (via apt):**
```bash
# Download Microsoft repository GPG keys
wget -q https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb

# Register the Microsoft repository
sudo dpkg -i packages-microsoft-prod.deb

# Update package list
sudo apt update

# Install PowerShell
sudo apt install -y powershell

# Verify
pwsh --version
```

### 3. Install SQL Server Tools

```bash
# Add Microsoft repository
curl https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
curl https://packages.microsoft.com/config/ubuntu/22.04/prod.list | sudo tee /etc/apt/sources.list.d/msprod.list

# Update and install
sudo apt update
sudo apt install -y mssql-tools unixodbc-dev

# Add to PATH
echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bashrc
source ~/.bashrc

# Verify
sqlcmd -?
```

### 4. Install Node.js (for db-deploy-ai)

```bash
# Install Node.js 18.x
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Verify
node --version
npm --version
```

### 5. Install Git

```bash
sudo apt install -y git

# Configure Git
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

### 6. Clone EasyWay Repository

```bash
# Create workspace
mkdir -p ~/workspace
cd ~/workspace

# Clone repository
git clone <your-repo-url> EasyWayDataPortal
cd EasyWayDataPortal
```

### 7. Install db-deploy-ai

```bash
# Navigate to db-deploy-ai directory
cd ~/workspace/EasyWayDataPortal/db-deploy-ai

# Install dependencies
npm install

# Verify
npm run --help
```

### 8. Configure Azure SQL Connection

```bash
# Create .env file for connection string
cd ~/workspace/EasyWayDataPortal

# Edit .env (or use your preferred method)
nano .env
```

**Add:**
```env
AZURE_SQL_CONNECTION_STRING="Server=tcp:your-server.database.windows.net,1433;Initial Catalog=EasyWayDataPortal;Persist Security Info=False;User ID=your-user;Password=your-password;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
```

**Or use PowerShell profile:**
```bash
pwsh
```

```powershell
# In PowerShell
$profile
# Note the path, then edit it
nano $profile
```

**Add to profile:**
```powershell
# Azure SQL Connection
$env:AZURE_SQL_SERVER = "your-server.database.windows.net"
$env:AZURE_SQL_DATABASE = "EasyWayDataPortal"
$env:AZURE_SQL_USER = "your-user"
$env:AZURE_SQL_PASSWORD = "your-password"
```

### 9. Test Connection

```bash
# Test with sqlcmd
sqlcmd -S your-server.database.windows.net -d EasyWayDataPortal -U your-user -P your-password -Q "SELECT @@VERSION"
```

**Expected:** SQL Server version info

### 10. Test PowerShell Scripts

```bash
pwsh

# In PowerShell
cd ~/workspace/EasyWayDataPortal

# Test a simple script
./scripts/pwsh/test-connection.ps1
```

---

## 🧪 Verification Checklist

Run these commands to verify setup:

```bash
# PowerShell
pwsh --version
# Expected: 7.x.x

# SQL Tools
sqlcmd -?
# Expected: Usage info

# Node.js
node --version
# Expected: v18.x.x

# Git
git --version
# Expected: git version 2.x.x

# Azure SQL Connection
sqlcmd -S your-server.database.windows.net -d EasyWayDataPortal -U your-user -P your-password -Q "SELECT 1"
# Expected: 1
```

---

## 🚀 First Migration Test

```bash
pwsh

# In PowerShell
cd ~/workspace/EasyWayDataPortal

# Run consolidation script
./db/scripts/consolidate-baseline.ps1

# Apply Agent Management migration
./db/scripts/apply-agent-management-migration.ps1 -Server "your-server.database.windows.net" -Database "EasyWayDataPortal" -User "your-user" -Password "your-password"
```

---

## 🛡️ Security Best Practices

### 1. Use Azure Key Vault (Recommended)

```bash
# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Login
az login

# Get secret from Key Vault
az keyvault secret show --name "sql-connection-string" --vault-name "your-keyvault" --query value -o tsv
```

### 2. Use Managed Identity (If VM is in Azure)

```powershell
# In PowerShell
# Connect using Managed Identity (no password needed)
$token = az account get-access-token --resource https://database.windows.net --query accessToken -o tsv
# Use token for authentication
```

### 3. Restrict Firewall

```bash
# Add VM IP to Azure SQL firewall
az sql server firewall-rule create \
  --resource-group your-rg \
  --server your-server \
  --name AllowVM \
  --start-ip-address YOUR_VM_IP \
  --end-ip-address YOUR_VM_IP
```

---

## 📦 Optional: Install VS Code

```bash
# Download and install VS Code
sudo snap install code --classic

# Install PowerShell extension
code --install-extension ms-vscode.powershell
```

---

## 🐳 Alternative: Docker Container

If you prefer containerization:

```bash
# Pull PowerShell container
docker pull mcr.microsoft.com/powershell:latest

# Run with volume mount
docker run -it --rm \
  -v ~/workspace/EasyWayDataPortal:/workspace \
  -e AZURE_SQL_SERVER="your-server.database.windows.net" \
  mcr.microsoft.com/powershell:latest
```

---

## 🔧 Troubleshooting

### PowerShell Not Found
```bash
# Reinstall via snap
sudo snap install powershell --classic
```

### SQL Connection Fails
```bash
# Check firewall
az sql server firewall-rule list --resource-group your-rg --server your-server

# Test connectivity
nc -zv your-server.database.windows.net 1433
```

### Permission Denied
```bash
# Make scripts executable
chmod +x ./db/scripts/*.ps1
```

---

## 📊 Performance Tuning

### Increase PowerShell Memory Limit
```bash
# Edit PowerShell config
pwsh
```

```powershell
# In PowerShell
$PSVersionTable
# Check current limits

# Increase if needed (in profile)
$env:PSModuleAnalysisCachePath = "/tmp/PSModuleCache"
```

### Use SSD for Workspace
```bash
# Mount SSD (if available)
sudo mkdir /mnt/ssd
sudo mount /dev/sdb1 /mnt/ssd
ln -s /mnt/ssd/workspace ~/workspace
```

---

## 🎯 Next Steps

After setup is complete:

1. ✅ Run `consolidate-baseline.ps1`
2. ✅ Apply `20260119_AGENT_MGMT_console.sql`
3. ✅ Run `sync-agents-to-db.ps1`
4. ✅ Test telemetry with one agent
5. ✅ Validate dashboard queries

---

## 📚 Resources

- [PowerShell on Linux](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-linux)
- [Azure SQL Connectivity](https://learn.microsoft.com/en-us/azure/azure-sql/database/connect-query-content-reference-guide)
- [db-deploy-ai Documentation](../db-deploy-ai/README.md)

---

**Created:** 2026-01-20  
**Updated:** 2026-01-20  
**Owner:** team-platform
