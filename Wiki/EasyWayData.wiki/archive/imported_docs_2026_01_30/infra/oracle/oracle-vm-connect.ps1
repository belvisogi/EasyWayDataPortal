# Oracle Cloud VM - Connection Manager
# Version: 1.0
# Gestisce test connessione, SSH e RDP per VM Oracle Cloud

param(
    [Parameter(Mandatory = $false)]
    [string]$VMIp,
    
    [Parameter(Mandatory = $false)]
    [string]$SSHKeyPath,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet('test', 'ssh', 'rdp', 'all')]
    [string]$Action = 'all',
    
    [Parameter(Mandatory = $false)]
    [string]$Username = 'ubuntu',
    
    [Parameter(Mandatory = $false)]
    [string]$RDPUsername = 'produser'
)

# Configurazione di default (modifica questi valori!)
$DefaultVMIp = "80.225.86.168"
$DefaultSSHKeyPath = "C:\old\Virtual-machine\ssh-key-2026-01-25.key"

# Usa valori di default se non specificati
if (-not $VMIp) { $VMIp = $DefaultVMIp }
if (-not $SSHKeyPath) { $SSHKeyPath = $DefaultSSHKeyPath }

function Write-Header {
    param([string]$Text)
    Write-Host "`n═══════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  $Text" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
}

function Write-Step {
    param([string]$Text)
    Write-Host "`n$Text" -ForegroundColor Yellow
}

function Write-Success {
    param([string]$Text)
    Write-Host "  ✅ $Text" -ForegroundColor Green
}

function Write-Error {
    param([string]$Text)
    Write-Host "  ❌ $Text" -ForegroundColor Red
}

function Write-Warning {
    param([string]$Text)
    Write-Host "  ⚠️  $Text" -ForegroundColor Yellow
}

function Write-Info {
    param([string]$Text)
    Write-Host "  ℹ️  $Text" -ForegroundColor Cyan
}

function Test-SSHConnection {
    Write-Header "Oracle Cloud VM - Connection Test"
    
    Write-Step "[1/4] Checking SSH key..."
    if (Test-Path $SSHKeyPath) {
        Write-Success "SSH key found: $SSHKeyPath"
    }
    else {
        Write-Error "SSH key NOT found: $SSHKeyPath"
        return $false
    }
    
    Write-Step "[2/4] Checking public key..."
    $PubKeyPath = "$SSHKeyPath.pub"
    if (-not (Test-Path $PubKeyPath)) {
        Write-Warning "Public key not found, generating..."
        try {
            ssh-keygen -y -f $SSHKeyPath | Out-File -FilePath $PubKeyPath -Encoding ASCII
            Write-Success "Public key generated: $PubKeyPath"
        }
        catch {
            Write-Error "Failed to generate public key"
            Write-Info "Run manually: ssh-keygen -y -f `"$SSHKeyPath`" > `"$PubKeyPath`""
        }
    }
    else {
        Write-Success "Public key exists"
    }
    
    Write-Step "[3/4] Testing network connectivity (ping)..."
    $pingResult = Test-Connection -ComputerName $VMIp -Count 2 -Quiet -ErrorAction SilentlyContinue
    if ($pingResult) {
        Write-Success "VM responds to ping"
    }
    else {
        Write-Warning "No ping response (normal for Oracle Cloud - ICMP blocked)"
    }
    
    Write-Step "[4/4] Testing SSH port 22..."
    $portOpen = $false
    try {
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $connect = $tcpClient.BeginConnect($VMIp, 22, $null, $null)
        $wait = $connect.AsyncWaitHandle.WaitOne(5000, $false)
        
        if ($wait -and $tcpClient.Connected) {
            Write-Success "Port 22 is OPEN and reachable!"
            $portOpen = $true
            $tcpClient.Close()
        }
        else {
            Write-Error "Port 22 TIMEOUT - Cannot connect"
            $tcpClient.Close()
        }
    }
    catch {
        Write-Error "Port 22 REFUSED - Connection rejected"
    }
    
    Write-Header "Test Summary"
    
    if ($portOpen) {
        Write-Success "SSH connection is possible!"
        Write-Info "Ready to connect via SSH or install desktop"
        return $true
    }
    else {
        Write-Error "SSH port is NOT reachable"
        Write-Warning "You need to fix the Ubuntu firewall first!"
        Write-Host ""
        Write-Host "  Solution:" -ForegroundColor Yellow
        Write-Host "  1. Go to Oracle Cloud Console" -ForegroundColor White
        Write-Host "  2. Compute → Instances → Your VM" -ForegroundColor White
        Write-Host "  3. Resources → Console Connection" -ForegroundColor White
        Write-Host "  4. Click 'Launch Cloud Shell Console'" -ForegroundColor White
        Write-Host "  5. Run these commands:" -ForegroundColor White
        Write-Host ""
        Write-Host "     sudo iptables -I INPUT 1 -p tcp --dport 22 -j ACCEPT" -ForegroundColor Green
        Write-Host "     sudo iptables -I INPUT 1 -p tcp --dport 3389 -j ACCEPT" -ForegroundColor Green
        Write-Host "     sudo apt update && sudo apt install -y iptables-persistent" -ForegroundColor Green
        Write-Host "     sudo netfilter-persistent save" -ForegroundColor Green
        Write-Host ""
        Write-Info "Full guide: C:\old\oracle-cloud-vm-setup-guide.md"
        return $false
    }
}

function Connect-SSH {
    Write-Header "Connecting to VM via SSH"
    
    Write-Info "Connecting to: $Username@$VMIp"
    Write-Info "Using key: $SSHKeyPath"
    Write-Host ""
    
    $sshCommand = "ssh -i `"$SSHKeyPath`" $Username@$VMIp"
    Write-Host "  Command: $sshCommand" -ForegroundColor Gray
    Write-Host ""
    
    # Execute SSH
    & ssh -i $SSHKeyPath "$Username@$VMIp"
}

function Connect-RDP {
    Write-Header "Opening Remote Desktop Connection"
    
    Write-Info "Creating RDP connection to: $VMIp"
    Write-Info "Username: $RDPUsername"
    Write-Host ""
    
    # Create temporary RDP file
    $rdpFile = "$env:TEMP\oracle-vm.rdp"
    
    $rdpContent = @"
full address:s:$VMIp
username:s:$RDPUsername
screen mode id:i:2
use multimon:i:0
desktopwidth:i:1920
desktopheight:i:1080
session bpp:i:32
compression:i:1
keyboardhook:i:2
audiocapturemode:i:0
videoplaybackmode:i:1
connection type:i:7
networkautodetect:i:1
bandwidthautodetect:i:1
displayconnectionbar:i:1
enableworkspacereconnect:i:0
disable wallpaper:i:0
allow font smoothing:i:1
allow desktop composition:i:1
disable full window drag:i:0
disable menu anims:i:0
disable themes:i:0
disable cursor setting:i:0
bitmapcachepersistenable:i:1
audiomode:i:0
redirectprinters:i:0
redirectcomports:i:0
redirectsmartcards:i:0
redirectclipboard:i:1
redirectposdevices:i:0
autoreconnection enabled:i:1
authentication level:i:0
prompt for credentials:i:1
negotiate security layer:i:1
remoteapplicationmode:i:0
alternate shell:s:
shell working directory:s:
gatewayhostname:s:
gatewayusagemethod:i:0
gatewaycredentialssource:i:0
gatewayprofileusagemethod:i:0
promptcredentialonce:i:0
gatewaybrokeringtype:i:0
use redirection server name:i:0
rdgiskdcproxy:i:0
kdcproxyname:s:
"@
    
    $rdpContent | Out-File -FilePath $rdpFile -Encoding ASCII
    
    Write-Success "RDP file created: $rdpFile"
    Write-Info "Opening Remote Desktop Connection..."
    Write-Host ""
    Write-Host "  💡 When prompted, enter password for user: $RDPUsername" -ForegroundColor Yellow
    Write-Host ""
    
    # Launch RDP
    Start-Process "mstsc" -ArgumentList $rdpFile
}

function Show-Help {
    Write-Host @"

Oracle Cloud VM - Connection Manager
====================================

Usage:
  .\oracle-vm-connect.ps1 [-Action <action>] [-VMIp <ip>] [-SSHKeyPath <path>]

Actions:
  test    - Test SSH connectivity
  ssh     - Connect via SSH
  rdp     - Connect via Remote Desktop
  all     - Test connection and show options (default)

Parameters:
  -VMIp         VM IP address (default: $DefaultVMIp)
  -SSHKeyPath   Path to SSH private key (default: $DefaultSSHKeyPath)
  -Username     SSH username (default: ubuntu)
  -RDPUsername  RDP username (default: produser)

Examples:
  # Test connection
  .\oracle-vm-connect.ps1 -Action test

  # Connect via SSH
  .\oracle-vm-connect.ps1 -Action ssh

  # Connect via RDP
  .\oracle-vm-connect.ps1 -Action rdp

  # Test with custom IP
  .\oracle-vm-connect.ps1 -Action test -VMIp "123.456.789.0"

  # SSH with custom key
  .\oracle-vm-connect.ps1 -Action ssh -SSHKeyPath "C:\keys\mykey.pem"

"@
}

# Main execution
switch ($Action) {
    'test' {
        Test-SSHConnection
    }
    'ssh' {
        $testResult = Test-SSHConnection
        if ($testResult) {
            Connect-SSH
        }
        else {
            Write-Host "`n  Cannot connect - fix firewall first!" -ForegroundColor Red
            exit 1
        }
    }
    'rdp' {
        Connect-RDP
    }
    'all' {
        $testResult = Test-SSHConnection
        
        if ($testResult) {
            Write-Host "`n" -NoNewline
            Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
            Write-Host "  What would you like to do?" -ForegroundColor Cyan
            Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "  1. Connect via SSH" -ForegroundColor White
            Write-Host "  2. Connect via Remote Desktop (RDP)" -ForegroundColor White
            Write-Host "  3. Exit" -ForegroundColor White
            Write-Host ""
            $choice = Read-Host "Enter choice (1-3)"
            
            switch ($choice) {
                '1' { Connect-SSH }
                '2' { Connect-RDP }
                '3' { Write-Host "`nGoodbye!" -ForegroundColor Cyan; exit 0 }
                default { Write-Host "`nInvalid choice" -ForegroundColor Red; exit 1 }
            }
        }
    }
    'help' {
        Show-Help
    }
    default {
        Show-Help
    }
}
