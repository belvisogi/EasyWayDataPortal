param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$ForwardArgs
)

$target = Join-Path $PSScriptRoot "..\..\agents\core\tools\agent-llm-router.ps1"
if (-not (Test-Path -LiteralPath $target)) {
    throw "Canonical script not found: $target"
}

& pwsh -NoProfile -File $target @ForwardArgs
exit $LASTEXITCODE
