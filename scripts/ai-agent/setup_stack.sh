#!/bin/bash
set -e

echo '>>> Installing PowerShell via Binary (ARM64 clean)...'
PWSH_VERSION=7.4.1
PWSH_ARCH=arm64
PWSH_TAR=powershell-${PWSH_VERSION}-linux-${PWSH_ARCH}.tar.gz
PWSH_URL=https://github.com/PowerShell/PowerShell/releases/download/v${PWSH_VERSION}/${PWSH_TAR}

if ! command -v pwsh &> /dev/null; then
    echo "Downloading PowerShell ${PWSH_VERSION}..."
    wget -q ${PWSH_URL}
    sudo mkdir -p /opt/microsoft/powershell/7
    sudo tar zxf ${PWSH_TAR} -C /opt/microsoft/powershell/7
    sudo chmod +x /opt/microsoft/powershell/7/pwsh
    sudo ln -sf /opt/microsoft/powershell/7/pwsh /usr/bin/pwsh
    rm ${PWSH_TAR}
    echo 'Powershell installed successfully.'
else
    echo 'Powershell already installed.'
fi

echo '>>> Checking Python dependencies (FORCE break-system-packages per dedicated VM)...'
sudo apt-get install -y python3-pip
python3 -m pip install --upgrade pip --break-system-packages
# Force install globally for agent simplicity
pip3 install --quiet --break-system-packages chromadb sentence-transformers numpy pandas

echo '>>> Verifying installations...'
/usr/bin/pwsh --version
python3 -c "import chromadb; print('ChromaDB version:', chromadb.__version__)"
python3 -c "from sentence_transformers import SentenceTransformer; print('sentence-transformers imported successfully')"

echo '>>> Setup Complete!'
