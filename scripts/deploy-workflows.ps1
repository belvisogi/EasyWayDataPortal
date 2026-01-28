# Deploy n8n Workflows
# Strategy: GitOps (Repo -> Container -> CLI Import)

$RemoteWorkspace = "$HOME/Work-space-n8n"
$n8nContainer = "easyway-orchestrator"
$n8nInternalPath = "/home/node/workflows"

Write-Host "🚀 Starting Deployment of n8n Workflows..." -ForegroundColor Green

# 1. Copy Config & Workflows to Shared Volume (Container Mount)
# Note: For this to work, we must CP directly into the container or use a mounted volume.
# Since we have a volume mounted at ./agents/core/n8n -> /home/node/workflows in docker-compose,
# We just copy files there!

$MountPath = "$HOME/EasyWayDataPortal/agents/core/n8n"

Write-Host "📂 Copying files to Volume Mount: $MountPath"
Copy-Item -Path "$RemoteWorkspace/config.json" -Destination "$MountPath/config.json" -Force
Copy-Item -Path "$RemoteWorkspace/workflows/*.json" -Destination "$MountPath/" -Force

# 2. Fix Permissions (n8n runs as UID 1000)
Write-Host "🔒 Applying Permissions (UID 1000)..."
# We use docker exec to run chown INSIDE the container to be 100% sure
docker exec -u 0 $n8nContainer chown -R 1000:1000 /home/node/workflows

# 3. Import Workflows using n8n CLI
Write-Host "⚡ Importing Workflows via CLI..."
$workflows = Get-ChildItem "$RemoteWorkspace/workflows/*.json"
foreach ($wf in $workflows) {
    $wfName = $wf.Name
    Write-Host "   - Importing: $wfName"
    docker exec $n8nContainer n8n import:workflow --input="$n8nInternalPath/$wfName"
}

Write-Host "✅ Deployment Complete!" -ForegroundColor Green
