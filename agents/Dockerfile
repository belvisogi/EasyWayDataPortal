# Base Image: Ubuntu 22.04 (ARM-friendly)
FROM ubuntu:22.04

# Avoid prompts
ENV DEBIAN_FRONTEND=noninteractive

# Core Dependencies (incl. prerequisites for PowerShell & Azure CLI)
RUN apt-get update && apt-get install -y \
    wget \
    apt-transport-https \
    software-properties-common \
    git \
    python3 \
    python3-pip \
    python3-venv \
    python3-venv \
    curl \
    nano \
    nano \
    gnupg \
    gnupg \
    lsb-release \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 20 (ARM64 supported) - Force clean install
RUN apt-get remove -y nodejs npm libnode* || true
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs
RUN node -v && npm -v

# Install PowerShell (Universal Binary Method for ARM64)
# Url for PowerShell 7.4.1 (LTS) ARM64
RUN wget -q https://github.com/PowerShell/PowerShell/releases/download/v7.4.1/powershell-7.4.1-linux-arm64.tar.gz && \
    mkdir -p /opt/microsoft/powershell/7 && \
    tar zxf powershell-7.4.1-linux-arm64.tar.gz -C /opt/microsoft/powershell/7 && \
    chmod +x /opt/microsoft/powershell/7/pwsh && \
    ln -s /opt/microsoft/powershell/7/pwsh /usr/bin/pwsh && \
    rm powershell-7.4.1-linux-arm64.tar.gz

# Install Azure CLI (Temporarily disabled for faster build/ARM64 stability)
# RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Python Libraries (incl. ChromaDB)
# Python Libraries (incl. ChromaDB)
RUN pip3 install chromadb numpy pandas openai azure-storage-blob azure-identity qdrant-client sentence-transformers

# Node.js Agent Dependencies (if any)
# RUN npm install -g n8n # Optional

# Create App User (UID 1000) for Security
RUN groupadd -g 1000 easyway && \
    useradd -m -u 1000 -g easyway -s /bin/bash easyway

# Environment Setup
ENV EASYWAY_MODE="Framework"
ENV AGENTS_DIR="/app/agents"
ENV SCRIPTS_DIR="/app/scripts"

# Copy EasyWay Ecosystem with correct ownership
WORKDIR /app
COPY --chown=easyway:easyway scripts /app/scripts
COPY --chown=easyway:easyway agents /app/agents
COPY --chown=easyway:easyway Wiki /app/Wiki

# Switch to non-root user
USER easyway

# Health check
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD test -f /tmp/runner-health || exit 1

# Default Entrypoint: Agent Runner (non-interactive, keeps container alive)
CMD [ "pwsh", "-NoProfile", "-File", "/app/agents/entrypoint.ps1" ]
