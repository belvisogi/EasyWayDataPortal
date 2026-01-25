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
    nodejs \
    npm \
    curl \
    nano \
    gnupg \
    lsb-release \
    && rm -rf /var/lib/apt/lists/*

# Install PowerShell (ARM64 supported method)
RUN wget -q "https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb" && \
    dpkg -i packages-microsoft-prod.deb && \
    rm packages-microsoft-prod.deb && \
    apt-get update && \
    apt-get install -y powershell

# Install Azure CLI
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Python Libraries (incl. ChromaDB)
# Python Libraries (incl. ChromaDB)
# Note: On Ubuntu 24.04+ this requires --break-system-packages, harmless in container
RUN pip3 install --break-system-packages chromadb numpy pandas openai azure-storage-blob azure-identity

# Node.js Agent Dependencies (if any)
# RUN npm install -g n8n # Optional

# Environment Setup
ENV EASYWAY_MODE="Framework"
ENV AGENTS_DIR="/app/agents"
ENV SCRIPTS_DIR="/app/scripts"

# Copy EasyWay Ecosystem
WORKDIR /app
COPY scripts /app/scripts
COPY agents /app/agents
COPY Wiki /app/Wiki

# Default Entrypoint: PowerShell
CMD [ "pwsh" ]
