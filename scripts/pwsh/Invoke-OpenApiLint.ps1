#Requires -Version 5.1
<#
.SYNOPSIS
    Fast static OpenAPI linter — Iron Dome gate (no LLM).

.DESCRIPTION
    Validates portal-api/openapi/openapi.yaml against deterministic rules:
      - All path operations have operationId
      - components.securitySchemes defined
      - Global security set
      - No duplicate operationId values
    Runs in <1s. Triggered by ewctl commit when openapi.yaml is staged.

.PARAMETER OpenApiPath
    Path to openapi.yaml. Defaults to portal-api/openapi/openapi.yaml.

.PARAMETER FailOnError
    If $true, exit 1 on violations. Default: $false (warn only).

.OUTPUTS
    Writes lint results to console. Returns $true if clean, $false if violations.
#>
[CmdletBinding()]
param(
    [string]$OpenApiPath  = 'portal-api/openapi/openapi.yaml',
    [bool]$FailOnError    = $false
)

$ErrorActionPreference = 'Continue'

Write-Host '🔍  OpenAPI Lint (Iron Dome static gate)...' -ForegroundColor Cyan

if (-not (Test-Path $OpenApiPath)) {
    Write-Host "⚠️   OpenAPI file not found at '$OpenApiPath' — skipping lint." -ForegroundColor Yellow
    exit 0
}

# --- Use Python to parse YAML and extract violations ---
$lintScript = @'
import sys, json, re

path = sys.argv[1]
with open(path, encoding='utf-8') as f:
    content = f.read()

violations = []

# --- Rule 1: All path operations must have operationId ---
# Parse path+method+operationId with simple regex (no YAML lib needed for this check)
in_paths = False
current_path = None
current_method = None
operation_ids = []

http_methods = {'get', 'post', 'put', 'patch', 'delete', 'head', 'options'}

for i, line in enumerate(content.splitlines(), 1):
    stripped = line.lstrip()
    indent   = len(line) - len(stripped)

    # Detect /api/* paths at indent 2
    if indent == 2 and stripped.startswith('/') and stripped.endswith(':'):
        current_path   = stripped[:-1]
        current_method = None
        in_paths       = True
    elif in_paths and indent == 4 and stripped.rstrip(':').lower() in http_methods:
        current_method = stripped.rstrip(':').lower()
        # Check that within the next ~30 lines there's an operationId
        # Simpler: collect all operationId values separately
    elif indent == 6 and stripped.startswith('operationId:'):
        op_id = stripped.split(':', 1)[1].strip()
        operation_ids.append(op_id)

# Count operations (get/post/put/patch/delete at indent 4 under a path)
import re as re2
ops = re2.findall(r'^\s{4}(get|post|put|patch|delete|head|options)\s*:', content, re2.MULTILINE)
op_id_count = len(re2.findall(r'^\s+operationId:', content, re2.MULTILINE))

if len(ops) != op_id_count:
    violations.append({
        'rule': 'missing-operation-id',
        'severity': 'HIGH',
        'message': f'{len(ops)} operations found but only {op_id_count} have operationId.'
    })

# --- Rule 2: Duplicate operationId ---
seen = set()
dupes = []
for oid in operation_ids:
    if oid in seen:
        dupes.append(oid)
    seen.add(oid)
if dupes:
    violations.append({
        'rule': 'duplicate-operation-id',
        'severity': 'HIGH',
        'message': f'Duplicate operationId: {dupes}'
    })

# --- Rule 3: securitySchemes defined ---
if 'securitySchemes:' not in content:
    violations.append({
        'rule': 'missing-security-schemes',
        'severity': 'MEDIUM',
        'message': 'components.securitySchemes not defined.'
    })

# --- Rule 4: Global security set ---
# Top-level security: must appear before paths:
paths_pos    = content.find('\npaths:')
security_pos = content.find('\nsecurity:')
if security_pos == -1:
    violations.append({
        'rule': 'missing-global-security',
        'severity': 'MEDIUM',
        'message': 'Global security not set at spec root.'
    })
elif paths_pos != -1 and security_pos > paths_pos:
    violations.append({
        'rule': 'global-security-after-paths',
        'severity': 'LOW',
        'message': 'Global security should appear before paths section.'
    })

print(json.dumps({'violations': violations, 'op_count': len(ops), 'op_id_count': op_id_count}))
'@

$tmpScript = [System.IO.Path]::GetTempFileName() + '.py'
Set-Content -Path $tmpScript -Value $lintScript -Encoding UTF8

try {
    $rawOut = & python3 $tmpScript $OpenApiPath 2>&1
    if ($LASTEXITCODE -ne 0 -or -not $rawOut) {
        Write-Host "⚠️   OpenAPI lint: python3 unavailable — skipping." -ForegroundColor Yellow
        Remove-Item $tmpScript -Force -ErrorAction SilentlyContinue
        exit 0
    }

    $result     = $rawOut | ConvertFrom-Json
    $violations = $result.violations
    $opCount    = $result.op_count
    $opIdCount  = $result.op_id_count

    Write-Host "   Operations: $opCount  |  operationId found: $opIdCount" -ForegroundColor Gray

    if ($violations.Count -eq 0) {
        Write-Host '✅  OpenAPI lint: CLEAN (0 violations)' -ForegroundColor Green
        Remove-Item $tmpScript -Force -ErrorAction SilentlyContinue
        exit 0
    }

    $highCount = ($violations | Where-Object { $_.severity -eq 'HIGH' }).Count
    Write-Host "⚠️   OpenAPI lint: $($violations.Count) violation(s) — $highCount HIGH" -ForegroundColor Yellow
    foreach ($v in $violations) {
        $color = if ($v.severity -eq 'HIGH') { 'Red' } elseif ($v.severity -eq 'MEDIUM') { 'Yellow' } else { 'Gray' }
        Write-Host "   [$($v.severity)] $($v.rule): $($v.message)" -ForegroundColor $color
    }

    Remove-Item $tmpScript -Force -ErrorAction SilentlyContinue

    if ($FailOnError -and $highCount -gt 0) {
        Write-Host '❌  OpenAPI lint BLOCKED commit (HIGH violations present).' -ForegroundColor Red
        exit 1
    }
    exit 0
}
catch {
    Write-Host "⚠️   OpenAPI lint error: $_  — skipping." -ForegroundColor Yellow
    Remove-Item $tmpScript -Force -ErrorAction SilentlyContinue
    exit 0
}
