#!/usr/bin/env pwsh
<#
.SYNOPSIS
    AI Agent con RAG (Retrieval Augmented Generation)
.DESCRIPTION
    Workflow: Query → Retrieval (ChromaDB) → LLM (Ollama) → Response → Log
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Query,
    
    [int]$TopK = 3
)

$ErrorActionPreference = 'Stop'

# Function to get script path
function Get-ScriptPath {
    if ($PSScriptRoot) { return $PSScriptRoot }
    return "."
}
$scriptRoot = Get-ScriptPath

Write-Host "🤖 EasyWay AI Agent with RAG" -ForegroundColor Cyan
Write-Host "Query: $Query`n" -ForegroundColor Yellow

# STEP 1: Retrieval
Write-Verbose "🔍 STEP 1: Semantic Search..."

# Call Python script ensuring we use python3
$retrievalCmd = "python3 $scriptRoot/chromadb_manager.py search `"$Query`""
Write-Verbose "Exec: $retrievalCmd"

try {
    $retrievalJson = Invoke-Expression $retrievalCmd
    $retrieval = $retrievalJson | ConvertFrom-Json
}
catch {
    Write-Error "Failed to execute retrieval: $_"
    exit 1
}

if ($retrieval.error) {
    Write-Error "Retrieval Error: $($retrieval.error)"
    exit 1
}

$retrievedDocs = @()
if ($retrieval.results) {
    $retrievedDocs = $retrieval.results | ForEach-Object {
        @{
            filename  = $_.metadata.filename
            content   = $_.content
            distance  = $_.distance
            relevance = [math]::Round((1 - $_.distance), 2)
        }
    }
}

Write-Verbose "`n📚 Retrieved Documents ($($retrievedDocs.Count)):"
if ($retrievedDocs) {
    $retrievedDocs | ForEach-Object {
        Write-Verbose "  - $($_.filename) (relevance: $($_.relevance))"
    }
}

# STEP 2: Context Preparation
Write-Verbose "`n🧠 STEP 2: Preparing LLM prompt..."

$context = "No relevant documents found."
if ($retrievedDocs.Count -gt 0) {
    $context = ($retrievedDocs | ForEach-Object {
            "Document: $($_.filename)`n$($_.content)`n---"
        }) -join "`n"
}

$llmPrompt = @"
You are EasyWay AI Agent, expert on Azure DevOps and data governance.

CONTEXT from knowledge base:
$context

USER QUERY:
$Query

Provide accurate answer based on context. If insufficient, say so.
"@

# STEP 3: LLM Generation
Write-Verbose "`n💬 STEP 3: Querying LLM (DeepSeek)..."

$ollamaRequest = @{
    model  = "deepseek-r1:7b"
    prompt = $llmPrompt
    stream = $false
} | ConvertTo-Json -Depth 10

try {
    $llmResponse = Invoke-RestMethod -Uri "http://localhost:11434/api/generate" `
        -Method Post `
        -Body $ollamaRequest `
        -ContentType "application/json"
    
    $answer = $llmResponse.response
}
catch {
    Write-Warning "LLM Call Failed. Ensure Ollama is running."
    $answer = "Error generating response: $($_.Exception.Message)"
}

# STEP 4: Display
Write-Host "`n✅ ANSWER:" -ForegroundColor Green
Write-Host $answer

# STEP 5: Log to SQLite
Write-Verbose "`n📊 STEP 5: Logging..."

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$retrievedStr = ($retrievedDocs.filename -join ', ')

$dbPath = "$HOME/easyway.db"

# Create log entry using sqlite3 CLI
$safeQuery = $Query -replace "'", "''"
# Simple escape for answer, can be improved
$safeAnswer = $answer -replace "'", "''"
$safeDocs = $retrievedStr -replace "'", "''"

$sql = "INSERT INTO agent_executions (agent_id, query_text, retrieved_docs, llm_response, timestamp) VALUES ('rag_agent', '$safeQuery', '$safeDocs', '$safeAnswer', '$timestamp');"

# Ensure table exists first (idempotent check)
$initSql = "CREATE TABLE IF NOT EXISTS agent_executions (execution_id INTEGER PRIMARY KEY AUTOINCREMENT, agent_id TEXT NOT NULL, query_text TEXT, retrieved_docs TEXT, llm_response TEXT, timestamp TEXT);"
$initCmd = "sqlite3 $dbPath ""$initSql"""
Invoke-Expression $initCmd > $null

$logCmd = "sqlite3 $dbPath ""$sql"""
Invoke-Expression $logCmd

Write-Verbose "✅ Logged execution"

# Output structured result
@{
    query          = $Query
    retrieved_docs = $retrievedDocs.filename
    answer         = $answer
    timestamp      = $timestamp
} | ConvertTo-Json -Depth 5
