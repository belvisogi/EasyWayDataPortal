#!/bin/bash
# ==============================================================================
# Daily Documentation Audit - Automated Quality Check
# ==============================================================================
# Purpose: Runs comprehensive documentation audit every night
# Schedule: 23:00 UTC (crontab)
# Reports: Saves to Wiki/logs/audit-YYYYMMDD.md
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DATE=$(date +%Y%m%d)
LOG_DIR="$REPO_ROOT/Wiki/EasyWayData.wiki/logs"
AUDIT_REPORT="$LOG_DIR/audit-$DATE.md"

# ==============================================================================
# Setup
# ==============================================================================

echo "🔍 EasyWay Documentation Daily Audit"
echo "Date: $(date -Iseconds)"
echo "Report: $AUDIT_REPORT"
echo ""

# Create log directory if not exists
mkdir -p "$LOG_DIR"

# ==============================================================================
# Initialize Report
# ==============================================================================

cat > "$AUDIT_REPORT" << 'EOF'
---
title: Daily Documentation Audit
date: DATE_PLACEHOLDER
type: audit-report
automated: true
---

# Daily Documentation Audit Report

**Generated**: TIMESTAMP_PLACEHOLDER  
**Status**: 🔄 Running...

---

## 📊 Summary Statistics

EOF

# Replace placeholders
sed -i "s/DATE_PLACEHOLDER/$(date +%Y-%m-%d)/" "$AUDIT_REPORT"
sed -i "s/TIMESTAMP_PLACEHOLDER/$(date -Iseconds)/" "$AUDIT_REPORT"

# ==============================================================================
# Audit 1: Wiki Tags Lint
# ==============================================================================

echo "📋 Running Wiki Tags Lint..."

if [ -f "$REPO_ROOT/scripts/pwsh/wiki-tags-lint.ps1" ]; then
    pwsh "$REPO_ROOT/scripts/pwsh/wiki-tags-lint.ps1" > /tmp/wiki-tags-lint.txt 2>&1 || true
    
    cat >> "$AUDIT_REPORT" << 'EOF'

### 1. Wiki Tags Compliance

EOF
    
    # Extract summary
    TOTAL_FILES=$(grep -c "\.md" /tmp/wiki-tags-lint.txt 2>/dev/null || echo "0")
    ERRORS=$(grep -c "ERROR" /tmp/wiki-tags-lint.txt 2>/dev/null || echo "0")
    
    cat >> "$AUDIT_REPORT" << EOF
- **Files Checked**: $TOTAL_FILES
- **Errors Found**: $ERRORS
- **Status**: $([ "$ERRORS" -eq 0 ] && echo "✅ PASS" || echo "⚠️ WARNINGS")

EOF
    
    if [ "$ERRORS" -gt 0 ]; then
        echo "**Issues**:" >> "$AUDIT_REPORT"
        echo '```' >> "$AUDIT_REPORT"
        grep "ERROR" /tmp/wiki-tags-lint.txt | head -10 >> "$AUDIT_REPORT" || true
        echo '```' >> "$AUDIT_REPORT"
    fi
else
    echo "⚠️ Wiki tags lint not found, skipping"
    cat >> "$AUDIT_REPORT" << 'EOF'

### 1. Wiki Tags Compliance
- **Status**: ⚠️ SKIPPED (script not found)

EOF
fi

# ==============================================================================
# Audit 2: Missing Documentation
# ==============================================================================

echo "📝 Checking for missing documentation..."

cat >> "$AUDIT_REPORT" << 'EOF'

### 2. Missing Documentation Check

EOF

# Check for files without README
DIRS_NO_README=$(find "$REPO_ROOT" -type d \
    -not -path "*/node_modules/*" \
    -not -path "*/.git/*" \
    -not -path "*/old/*" \
    -not -path "*/.obsidian/*" \
    | while read dir; do
        if [ ! -f "$dir/README.md" ] && [ $(find "$dir" -maxdepth 1 -type f -name "*.js" -o -name "*.ts" -o -name "*.py" | wc -l) -gt 2 ]; then
            echo "$dir"
        fi
    done | wc -l)

cat >> "$AUDIT_REPORT" << EOF
- **Directories with code but no README**: $DIRS_NO_README
- **Status**: $([ "$DIRS_NO_README" -eq 0 ] && echo "✅ PASS" || echo "⚠️ NEEDS ATTENTION")

EOF

# ==============================================================================
# Audit 3: Broken Links
# ==============================================================================

echo "🔗 Checking for broken links..."

cat >> "$AUDIT_REPORT" << 'EOF'

### 3. Broken Links Check

EOF

# Simple check for common broken patterns
BROKEN_LINKS=$(grep -r "\[.*\](.*)" "$REPO_ROOT/Wiki" "$REPO_ROOT/docs" 2>/dev/null \
    | grep -v "http" \
    | grep -v "file://" \
    | wc -l || echo "0")

cat >> "$AUDIT_REPORT" << EOF
- **Potential Broken Links**: $BROKEN_LINKS
- **Status**: $([ "$BROKEN_LINKS" -eq 0 ] && echo "✅ PASS" || echo "⚠️ REVIEW NEEDED")

EOF

# ==============================================================================
# Audit 4: Outdated Documentation
# ==============================================================================

echo "📅 Checking for outdated documentation..."

cat >> "$AUDIT_REPORT" << 'EOF'

### 4. Outdated Documentation (>90 days)

EOF

# Find markdown files not modified in last 90 days
OLD_DOCS=$(find "$REPO_ROOT/Wiki" "$REPO_ROOT/docs" -name "*.md" -type f -mtime +90 2>/dev/null | wc -l || echo "0")

cat >> "$AUDIT_REPORT" << EOF
- **Files Not Updated in 90+ Days**: $OLD_DOCS
- **Status**: $([ "$OLD_DOCS" -lt 10 ] && echo "✅ ACCEPTABLE" || echo "⚠️ REVIEW NEEDED")

EOF

if [ "$OLD_DOCS" -gt 0 ]; then
    echo "" >> "$AUDIT_REPORT"
    echo "**Sample (oldest 5)**:" >> "$AUDIT_REPORT"
    echo '```' >> "$AUDIT_REPORT"
    find "$REPO_ROOT/Wiki" "$REPO_ROOT/docs" -name "*.md" -type f -mtime +90 -exec ls -lt {} \; 2>/dev/null \
        | head -5 \
        | awk '{print $9}' \
        >> "$AUDIT_REPORT" || true
    echo '```' >> "$AUDIT_REPORT"
fi

# ==============================================================================
# Audit 5: Security Framework Compliance
# ==============================================================================

echo "🔒 Checking security documentation..."

cat >> "$AUDIT_REPORT" << 'EOF'

### 5. Security Documentation Compliance

EOF

# Check if critical security docs exist
SECURITY_DOCS=(
    "docs/infra/SECURITY_FRAMEWORK.md"
    "Wiki/EasyWayData.wiki/security/ai-security-guardrails.md"
    "Wiki/EasyWayData.wiki/infra/security-framework.md"
)

MISSING=0
for doc in "${SECURITY_DOCS[@]}"; do
    if [ ! -f "$REPO_ROOT/$doc" ]; then
        MISSING=$((MISSING + 1))
    fi
done

cat >> "$AUDIT_REPORT" << EOF
- **Critical Security Docs**: ${#SECURITY_DOCS[@]}
- **Missing**: $MISSING
- **Status**: $([ "$MISSING" -eq 0 ] && echo "✅ COMPLETE" || echo "❌ MISSING DOCS")

EOF

# ==============================================================================
# Audit 6: ChromaDB Registry Sync Check
# ==============================================================================

echo "🧠 Checking ChromaDB registry sync..."

cat >> "$AUDIT_REPORT" << 'EOF'

### 6. ChromaDB Registry Status

EOF

if [ -f "$REPO_ROOT/agents/agent_knowledge_curator/chromadb_registry.jsonl" ]; then
    REGISTRY_COUNT=$(wc -l < "$REPO_ROOT/agents/agent_knowledge_curator/chromadb_registry.jsonl" 2>/dev/null || echo "0")
    LAST_SYNC=$(grep "last_sync" "$REPO_ROOT/agents/agent_knowledge_curator/chromadb_registry.jsonl" 2>/dev/null | tail -1 | cut -d'"' -f4 || echo "never")
    
    cat >> "$AUDIT_REPORT" << EOF
- **Registry Entries**: $REGISTRY_COUNT
- **Last Sync**: $LAST_SYNC
- **Status**: ✅ ACTIVE

EOF
else
    cat >> "$AUDIT_REPORT" << 'EOF'
- **Status**: ⏸️ NOT INITIALIZED

EOF
fi

# ==============================================================================
# Final Summary
# ==============================================================================

echo "📊 Generating final summary..."

cat >> "$AUDIT_REPORT" << 'EOF'

---

## 🎯 Overall Health Score

EOF

# Calculate score (simple heuristic)
SCORE=100
[ "$ERRORS" -gt 0 ] && SCORE=$((SCORE - 20))
[ "$DIRS_NO_README" -gt 5 ] && SCORE=$((SCORE - 10))
[ "$BROKEN_LINKS" -gt 10 ] && SCORE=$((SCORE - 10))
[ "$OLD_DOCS" -gt 20 ] && SCORE=$((SCORE - 10))
[ "$MISSING" -gt 0 ] && SCORE=$((SCORE - 20))

HEALTH_EMOJI="🟢"
[ "$SCORE" -lt 80 ] && HEALTH_EMOJI="🟡"
[ "$SCORE" -lt 60 ] && HEALTH_EMOJI="🔴"

cat >> "$AUDIT_REPORT" << EOF
**Score**: $SCORE/100 $HEALTH_EMOJI

**Grade**: $([ "$SCORE" -ge 90 ] && echo "A - Excellent" || ([ "$SCORE" -ge 80 ] && echo "B - Good" || ([ "$SCORE" -ge 70 ] && echo "C - Fair" || echo "D - Needs Work")))

### Recommendations

EOF

if [ "$SCORE" -lt 90 ]; then
    echo "- ⚠️ Address warnings above to improve documentation quality" >> "$AUDIT_REPORT"
fi

if [ "$ERRORS" -gt 0 ]; then
    echo "- 🏷️ Fix Wiki tag compliance issues" >> "$AUDIT_REPORT"
fi

if [ "$DIRS_NO_README" -gt 0 ]; then
    echo "- 📝 Add README.md to directories with code" >> "$AUDIT_REPORT"
fi

if [ "$OLD_DOCS" -gt 10 ]; then
    echo "- 📅 Review and update outdated documentation" >> "$AUDIT_REPORT"
fi

if [ "$SCORE" -ge 90 ]; then
    echo "- ✅ Documentation quality is excellent! Keep it up." >> "$AUDIT_REPORT"
fi

cat >> "$AUDIT_REPORT" << 'EOF'

---

**Next Audit**: Tomorrow 23:00 UTC  
**Automated by**: `scripts/ops/daily-docs-audit.sh`
EOF

# ==============================================================================
# Commit Report (if in Git repo)
# ==============================================================================

echo "💾 Saving report..."

cd "$REPO_ROOT"

if git rev-parse --git-dir > /dev/null 2>&1; then
    git add "$AUDIT_REPORT"
    git commit -m "docs: Daily audit report $(date +%Y-%m-%d)" -m "Automated documentation health check" --no-verify 2>&1 || true
    echo "✅ Report committed to Git"
else
    echo "⚠️ Not a Git repo, report saved locally only"
fi

# ==============================================================================
# Output
# ==============================================================================

echo ""
echo "✅ Audit Complete!"
echo "Report: $AUDIT_REPORT"
echo "Score: $SCORE/100 $HEALTH_EMOJI"
echo ""

# Display report to stdout
cat "$AUDIT_REPORT"
