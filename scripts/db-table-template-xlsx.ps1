Param(
  [string]$OutPath = 'docs/agentic/templates/sheets/db-table-create.template.xlsx',
  [string]$TableCsv = 'docs/agentic/templates/sheets/db-table-create.table.csv',
  [string]$ColumnsCsv = 'docs/agentic/templates/sheets/db-table-create.columns.csv',
  [string]$IndexesCsv = 'docs/agentic/templates/sheets/db-table-create.indexes.csv'
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $TableCsv)) { throw "Missing $TableCsv" }
if (-not (Test-Path $ColumnsCsv)) { throw "Missing $ColumnsCsv" }
if (-not (Test-Path $IndexesCsv)) { throw "Missing $IndexesCsv" }

$csvTable = Import-Csv -Path $TableCsv
$csvColumns = Import-Csv -Path $ColumnsCsv
$csvIndexes = Import-Csv -Path $IndexesCsv

$dir = Split-Path -Parent $OutPath
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
if (Test-Path $OutPath) { Remove-Item -Force $OutPath }

$fullPath = Join-Path (Resolve-Path '.').Path $OutPath

$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
$wb = $excel.Workbooks.Add()

function Write-Sheet($sheet, $rows) {
  if (-not $rows -or $rows.Count -eq 0) { return }
  $headers = $rows[0].PSObject.Properties.Name
  for ($c = 0; $c -lt $headers.Count; $c++) { $sheet.Cells.Item(1, $c + 1) = $headers[$c] }
  $r = 2
  foreach ($row in $rows) {
    $c = 1
    foreach ($h in $headers) {
      $sheet.Cells.Item($r, $c) = $row.$h
      $c++
    }
    $r++
  }
  $sheet.Columns.AutoFit() | Out-Null
}

$sheetTable = $wb.Worksheets.Item(1)
$sheetTable.Name = 'Table'
Write-Sheet -sheet $sheetTable -rows $csvTable

$sheetColumns = $wb.Worksheets.Add()
$sheetColumns.Name = 'Columns'
Write-Sheet -sheet $sheetColumns -rows $csvColumns

$sheetIndexes = $wb.Worksheets.Add()
$sheetIndexes.Name = 'Indexes'
Write-Sheet -sheet $sheetIndexes -rows $csvIndexes

$sheetNotes = $wb.Worksheets.Add()
$sheetNotes.Name = 'Istruzioni'
$notes = @(
  'USO RAPIDO (DB TABLE TEMPLATE)',
  '',
  '1) Compila il foglio \"Table\" (una sola riga per tabella).',
  '2) Compila il foglio \"Columns\" (una riga per colonna).',
  '3) Compila il foglio \"Indexes\" (opzionale).',
  '',
  'Campi standard:',
  '- include_audit=true genera colonne audit standard.',
  '- include_soft_delete=true genera colonne soft delete standard.',
  '',
  'Genera intent JSON:',
  'pwsh scripts/db-table-intent-from-sheet.ps1 -TableCsv <table.csv> -ColumnsCsv <columns.csv> -IndexesCsv <indexes.csv> -OutIntent out/intents/intent.db-table-create.generated.json',
  '',
  'Esegui agent DBA:',
  'pwsh scripts/agent-dba.ps1 -Action db-table:create -IntentPath out/intents/intent.db-table-create.generated.json -LogEvent',
  '',
  'Datalake (placeholder):',
  'abfss://<filesystem>@<storage>.dfs.core.windows.net/portal-assets/templates/db/'
)
for ($i = 0; $i -lt $notes.Count; $i++) { $sheetNotes.Cells.Item($i + 1, 1) = $notes[$i] }
$sheetNotes.Columns.AutoFit() | Out-Null

$wb.SaveAs($fullPath, 51)
$wb.Close($false)
$excel.Quit()
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($sheetTable) | Out-Null
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($sheetColumns) | Out-Null
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($sheetIndexes) | Out-Null
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($sheetNotes) | Out-Null
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($wb) | Out-Null
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($excel) | Out-Null
[gc]::Collect(); [gc]::WaitForPendingFinalizers()

Write-Output "Created $OutPath"
