param(
  [string]$Path = "Wiki/EasyWayData.wiki",
  [string]$TaxonomyPath = "docs/agentic/templates/docs/tag-taxonomy.json",
  [string[]]$ExcludePaths = @('logs/reports'),
  [int]$ScanLines = 120,
  [switch]$Apply,
  [string]$SummaryOut = "wiki-tags-autofix.json"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# This script is a safe wrapper that repairs common tag-shape issues without rewriting content.
# It delegates to:
# - scripts/wiki-frontmatter-termination-fix.ps1 (fixes unterminated YAML delimiter)
# - scripts/wiki-tags-facetize.ps1 (converts privacy-internal -> privacy/internal, etc.)

$term = pwsh scripts/wiki-frontmatter-termination-fix.ps1 -Path $Path -ExcludePaths $ExcludePaths -ScanLines $ScanLines -Apply:$Apply | ConvertFrom-Json
$facet = pwsh scripts/wiki-tags-facetize.ps1 -Path $Path -TaxonomyPath $TaxonomyPath -ExcludePaths $ExcludePaths -Apply:$Apply | ConvertFrom-Json

$summary = [ordered]@{
  applied = [bool]$Apply
  path = $Path
  taxonomy = $TaxonomyPath
  excluded = $ExcludePaths
  terminationFix = @{ changed = $term.changed; files = $term.files; scanLines = $term.scanLines }
  facetize = @{ changed = $facet.changed; files = $facet.files }
}

$json = $summary | ConvertTo-Json -Depth 6
Set-Content -LiteralPath $SummaryOut -Value $json -Encoding utf8
Write-Output $json
