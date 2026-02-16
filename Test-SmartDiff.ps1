# Test-SmartDiff.ps1
$diff = @"
diff --git a/src/example.ps1 b/src/example.ps1
index 123..456 100644
--- a/src/example.ps1
+++ b/src/example.ps1
@@ -10,4 +10,5 @@
 function Test-Thing {
     Write-Host 'Old Code'
-    return `$false
+    Write-Host 'New Code'
+    return `$true
 }
"@

Import-Module "$PSScriptRoot\agent\core\Invoke-AgentTool.ps1" -Force

Write-Host "Testing SmartDiff logic..."
$result = Invoke-AgentTool -Task SmartDiff -Target $diff

Write-Host "`n---------- RESULT ----------"
Write-Host $result
Write-Host "----------------------------"

if ($result -match "__new hunk__" -and $result -match "12 \+    return `$true") {
    Write-Host "✅ VERIFICATION PASSED: Hunk markers and line numbers found." -ForegroundColor Green
}
else {
    Write-Host "❌ VERIFICATION FAILED" -ForegroundColor Red
}
