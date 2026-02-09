. /app/agents/skills/retrieval/Invoke-LLMWithRAG.ps1

Write-Host "=== Test 2: LLM + RAG (Qdrant) ===" -ForegroundColor Cyan
$r = Invoke-LLMWithRAG -Query "Come gestire i segreti e le credenziali nel progetto EasyWay?" -AgentId "agent_security" -TopK 3 -MaxTokens 300
$r | ConvertTo-Json -Depth 5
