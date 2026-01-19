# Configuration Directory

This directory contains centralized configuration files for the EasyWayDataPortal project.

## Files

### `paths.json`
Central path configuration to avoid hardcoded paths throughout the project.

**Usage in PowerShell:**
```powershell
# Load configuration
$config = Get-Content (Join-Path $PSScriptRoot '.config\paths.json') | ConvertFrom-Json
$projectRoot = $config.paths.projectRoot

# Use in scripts
$wikiPath = $config.paths.wiki
```

**Best Practices:**
- ✅ Always use relative paths in generated documentation
- ✅ Use `file:///` protocol with relative paths for portability
- ✅ Load paths from this config file in all scripts
- ❌ Never hardcode absolute paths in generated files
- ❌ Never commit user-specific paths (OneDrive, local drives)

### `paths.schema.json`
JSON Schema for validating `paths.json` structure.

## Migration Notes

**Legacy Path:**
```
C:\Users\EBELVIGLS\OneDrive - NTT DATA EMEAL\Documents\EasyWayDataPortal
```

**New Path:**
```
C:\old\EasyWayDataPortal
```

All scripts have been updated to use the configuration file instead of hardcoded paths.
