# Oracle Cloud SSH Test - Simple Version
param(
    [string]$VMIp = "80.225.86.168",
    [string]$SSHKeyPath = "C:\old\Virtual-machine\ssh-key-2026-01-25.key"
)

Write-Host "`n=== Oracle Cloud SSH Diagnostic ===" -ForegroundColor Cyan

# Test 1: Check SSH key exists
Write-Host "`n[1/4] Checking SSH key..." -ForegroundColor Yellow
if (Test-Path $SSHKeyPath) {
    Write-Host "  ✅ SSH key found" -ForegroundColor Green
}
else {
    Write-Host "  ❌ SSH key NOT found at: $SSHKeyPath" -ForegroundColor Red
    exit 1
}

# Test 2: Generate public key if needed
Write-Host "`n[2/4] Checking public key..." -ForegroundColor Yellow
$PubKeyPath = "$SSHKeyPath.pub"
if (-not (Test-Path $PubKeyPath)) {
    Write-Host "  Generating public key..." -ForegroundColor Yellow
    ssh-keygen -y -f $SSHKeyPath | Out-File -FilePath $PubKeyPath -Encoding ASCII
    Write-Host "  ✅ Public key generated" -ForegroundColor Green
}
else {
    Write-Host "  ✅ Public key exists" -ForegroundColor Green
}

# Test 3: Ping test
Write-Host "`n[3/4] Testing network connectivity..." -ForegroundColor Yellow
$pingResult = Test-Connection -ComputerName $VMIp -Count 2 -Quiet -ErrorAction SilentlyContinue
if ($pingResult) {
    Write-Host "  ✅ VM responds to ping" -ForegroundColor Green
}
else {
    Write-Host "  ⚠️  No ping response (normal for Oracle Cloud)" -ForegroundColor Yellow
}

# Test 4: SSH port test
Write-Host "`n[4/4] Testing SSH port 22..." -ForegroundColor Yellow
$portOpen = $false
try {
    $tcpClient = New-Object System.Net.Sockets.TcpClient
    $connect = $tcpClient.BeginConnect($VMIp, 22, $null, $null)
    $wait = $connect.AsyncWaitHandle.WaitOne(5000, $false)
    
    if ($wait -and $tcpClient.Connected) {
        Write-Host "  ✅ Port 22 is OPEN!" -ForegroundColor Green
        $portOpen = $true
        $tcpClient.Close()
    }
    else {
        Write-Host "  ❌ Port 22 TIMEOUT" -ForegroundColor Red
        $tcpClient.Close()
    }
}
catch {
    Write-Host "  ❌ Port 22 REFUSED" -ForegroundColor Red
}

# Summary
Write-Host "`n=== SUMMARY ===" -ForegroundColor Cyan

if ($portOpen) {
    Write-Host "`n✅ SSH port is reachable!" -ForegroundColor Green
    Write-Host "`nTry connecting:" -ForegroundColor Yellow
    Write-Host "  ssh -i `"$SSHKeyPath`" ubuntu@$VMIp" -ForegroundColor Cyan
}
else {
    Write-Host "`n❌ SSH port is NOT reachable" -ForegroundColor Red
    Write-Host "`nProblem: Ubuntu firewall (iptables) is blocking port 22" -ForegroundColor Yellow
    Write-Host "`nSolution:" -ForegroundColor Yellow
    Write-Host "  1. Go to Oracle Cloud Console" -ForegroundColor White
    Write-Host "  2. Compute → Instances → vm-easyway-prod" -ForegroundColor White
    Write-Host "  3. Resources → Console Connection" -ForegroundColor White
    Write-Host "  4. Click 'Launch Cloud Shell Console'" -ForegroundColor White
    Write-Host "  5. Run these commands:" -ForegroundColor White
    Write-Host ""
    Write-Host "     sudo iptables -I INPUT 1 -p tcp --dport 22 -j ACCEPT" -ForegroundColor Green
    Write-Host "     sudo iptables -I INPUT 1 -p tcp --dport 3389 -j ACCEPT" -ForegroundColor Green
    Write-Host "     sudo apt update && sudo apt install -y iptables-persistent" -ForegroundColor Green
    Write-Host "     sudo netfilter-persistent save" -ForegroundColor Green
    Write-Host ""
    Write-Host "  6. Run this script again to verify" -ForegroundColor White
    Write-Host "`nFull guide: C:\old\oracle-ssh-fix.md" -ForegroundColor Cyan
}

Write-Host ""
