# Base Image: PowerShell on Ubuntu
FROM mcr.microsoft.com/powershell:lts-ubuntu-22.04

# Core Dependencies
RUN apt-get update && apt-get install -y \
    git \
    python3 \
    python3-pip \
    nodejs \
    npm \
    curl \
    nano \
    && rm -rf /var/lib/apt/lists/*

# Azure CLI (for Compatibility, though mostly mocked in Framework Mode)
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Python Libraries (incl. ChromaDB)
RUN pip3 install chromadb numpy pandas openai azure-storage-blob azure-identity

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
