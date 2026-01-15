#!/bin/bash
# Pre-commit hook for KB integrity check
# Installation: cp scripts/pre-commit.sh .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit

echo "🔍 Running KB integrity check..."

# Check if Python is available
if ! command -v python3 &> /dev/null; then
    echo "⚠️  Python 3 not found, skipping KB scan"
    exit 0
fi

# Scan all KB files
KB_FILES=(
    "agents/kb/recipes.jsonl"
    "agents/kb/ado-setup-recipe.jsonl"
    "agents/kb/deploy-recipes.jsonl"
    "agents/kb/sprint-recipes.jsonl"
    "agents/kb/test-pr-recipes.jsonl"
)

SCAN_FAILED=0

for KB_FILE in "${KB_FILES[@]}"; do
    if [ -f "$KB_FILE" ]; then
        # Check if file is staged for commit
        if git diff --cached --name-only | grep -q "$KB_FILE"; then
            echo "  Scanning: $KB_FILE"
            python3 scripts/kb-security-scan.py "$KB_FILE"
            
            if [ $? -ne 0 ]; then
                SCAN_FAILED=1
            fi
        fi
    fi
done

if [ $SCAN_FAILED -ne 0 ]; then
    echo ""
    echo "❌ KB integrity check FAILED"
    echo "   Commit blocked due to security violations"
    echo ""
    echo "To fix:"
    echo "  1. Review violations above"
    echo "  2. Remove suspicious patterns from KB"
    echo "  3. Run: python3 scripts/kb-security-scan.py <file>"
    echo "  4. Commit again after fixes"
    echo ""
    echo "To bypass (NOT RECOMMENDED):"
    echo "  git commit --no-verify"
    exit 1
fi

echo "✅ KB integrity check passed"
exit 0
