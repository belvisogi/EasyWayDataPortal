Param(
  [string]$OutPath = 'docs/agentic/templates/sheets/access-registry.template.xlsx',
  [string]$RegistryCsv = 'docs/agentic/templates/sheets/access-registry.csv'
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $RegistryCsv)) { throw "Missing $RegistryCsv" }

$rows = Import-Csv -Path $RegistryCsv
$dir = Split-Path -Parent $OutPath
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
if (Test-Path $OutPath) { Remove-Item -Force $OutPath }

$fullPath = Join-Path (Resolve-Path '.').Path $OutPath

$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
$wb = $excel.Workbooks.Add()

function Write-Sheet($sheet, $data) {
  if (-not $data -or $data.Count -eq 0) { return }
  $headers = $data[0].PSObject.Properties.Name
  for ($c = 0; $c -lt $headers.Count; $c++) { $sheet.Cells.Item(1, $c + 1) = $headers[$c] }
  $r = 2
  foreach ($row in $data) {
    $c = 1
    foreach ($h in $headers) {
      $sheet.Cells.Item($r, $c) = $row.$h
      $c++
    }
    $r++
  }
  $sheet.Columns.AutoFit() | Out-Null
}

$sheetRegistry = $wb.Worksheets.Item(1)
$sheetRegistry.Name = 'Registry'
Write-Sheet -sheet $sheetRegistry -data $rows

$sheetNotes = $wb.Worksheets.Add()
$sheetNotes.Name = 'Istruzioni'
$notes = @(
  'REGISTRY ACCESSI (AUDIT)',
  '',
  'Compila una riga per accesso tecnico (DB/Datalake).',
  'Non inserire mai valori segreti.',
  '',
  'Campi chiave:',
  '- access_id: identificativo interno',
  '- system: db | datalake | api | other',
  '- resource: risorsa target (es. portal-sql, portal-assets)',
  '- identity_type: managed_identity | service_principal | user',
  '- secret_ref: nome secret in Key Vault (solo riferimento)',
  '- rotation_days/last_rotation/expiry_date: per audit'
)
for ($i = 0; $i -lt $notes.Count; $i++) { $sheetNotes.Cells.Item($i + 1, 1) = $notes[$i] }
$sheetNotes.Columns.AutoFit() | Out-Null

$wb.SaveAs($fullPath, 51)
$wb.Close($false)
$excel.Quit()
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($sheetRegistry) | Out-Null
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($sheetNotes) | Out-Null
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($wb) | Out-Null
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($excel) | Out-Null
[gc]::Collect(); [gc]::WaitForPendingFinalizers()

Write-Output "Created $OutPath"
