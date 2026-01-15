#!/usr/bin/env python3
"""
KB Security Scanner - Layer 4 Defense
Scans Knowledge Base files for suspicious patterns and prompt injection attempts.
Designed to run as pre-commit hook or daily audit.
"""

import json
import re
import sys
from pathlib import Path
from typing import List, Dict, Any

# Dangerous patterns to detect in KB
DANGEROUS_PATTERNS = [
    # Instruction override
    (r'IGNORA.*ISTRUZIONI', 'Instruction override (IT)'),
    (r'IGNORE.*INSTRUCTIONS', 'Instruction override (EN)'),
    (r'OVERRIDE.*RULES', 'Rule override'),
    (r'DISREGARD.*PREVIOUS', 'Previous instruction disregard'),
    
    # Hidden instructions
    (r'\[HIDDEN\]', 'Hidden marker'),
    (r'<!--.*OVERRIDE.*-->', 'HTML comment override'),
    (r'/\*\s*INJECT\s*\*/', 'Code comment injection'),
    
    # Hardcoded credentials
    (r'password\s*=\s*["\'][^"\']{8,}["\']', 'Hardcoded password'),
    (r'api[_-]?key\s*=\s*["\'][^"\']+["\']', 'Hardcoded API key'),
    (r'secret\s*=\s*["\'][^"\']+["\']', 'Hardcoded secret'),
    
    # Privilege escalation
    (r'GRANT\s+ALL.*PUBLIC', 'Excessive privilege grant'),
    (r'CREATE\s+USER.*admin', 'Admin user creation'),
    (r'ALTER\s+USER.*sysadmin', 'Sysadmin privilege'),
    
    # Suspicious commands
    (r'xp_cmdshell', 'SQL command shell'),
    (r'exec\s*\(\s*["\']DROP', 'Dynamic DROP execution'),
    (r'bypass.*approval', 'Approval bypass'),
    (r'skip.*validation', 'Validation skip'),
]

# Severity levels
SEVERITY_CRITICAL = 'critical'
SEVERITY_HIGH = 'high'
SEVERITY_MEDIUM = 'medium'
SEVERITY_LOW = 'low'

def get_severity(pattern_description: str) -> str:
    """Determine severity based on pattern type"""
    critical_keywords = ['hardcoded password', 'api key', 'secret', 'privilege']
    high_keywords = ['override', 'ignore', 'bypass', 'xp_cmdshell']
    
    desc_lower = pattern_description.lower()
    
    if any(kw in desc_lower for kw in critical_keywords):
        return SEVERITY_CRITICAL
    elif any(kw in desc_lower for kw in high_keywords):
        return SEVERITY_HIGH
    else:
        return SEVERITY_MEDIUM

def scan_recipe(recipe: Dict[str, Any], recipe_id: str) -> List[Dict]:
    """Scan a single recipe for security violations"""
    violations = []
    
    # Convert recipe to string for scanning
    recipe_str = json.dumps(recipe, ensure_ascii=False)
    
    for pattern, description in DANGEROUS_PATTERNS:
        matches = re.findall(pattern, recipe_str, re.IGNORECASE)
        if matches:
            severity = get_severity(description)
            violations.append({
                'recipe_id': recipe_id,
                'pattern': pattern,
                'description': description,
                'matches': matches[:3],  # Limit to first 3 matches
                'severity': severity,
                'count': len(matches)
            })
    
    return violations

def scan_kb_file(kb_file: Path) -> Dict[str, Any]:
    """Scan entire KB file"""
    all_violations = []
    total_recipes = 0
    
    try:
        with open(kb_file, 'r', encoding='utf-8') as f:
            for line_num, line in enumerate(f, 1):
                if not line.strip():
                    continue
                    
                try:
                    recipe = json.loads(line)
                    total_recipes += 1
                    recipe_id = recipe.get('id', f'line-{line_num}')
                    violations = scan_recipe(recipe, recipe_id)
                    all_violations.extend(violations)
                except json.JSONDecodeError as e:
                    print(f"⚠️  Invalid JSON at line {line_num}: {e}", file=sys.stderr)
    
    except FileNotFoundError:
        print(f"❌ File not found: {kb_file}", file=sys.stderr)
        return {'error': 'file_not_found', 'success': False}
    
    # Categorize by severity
    critical = [v for v in all_violations if v['severity'] == SEVERITY_CRITICAL]
    high = [v for v in all_violations if v['severity'] == SEVERITY_HIGH]
    medium = [v for v in all_violations if v['severity'] == SEVERITY_MEDIUM]
    
    return {
        'success': len(all_violations) == 0,
        'total_recipes': total_recipes,
        'total_violations': len(all_violations),
        'critical': critical,
        'high': high,
        'medium': medium,
        'file': str(kb_file)
    }

def print_report(result: Dict[str, Any]):
    """Print scan results in human-readable format"""
    if not result.get('success', True):
        if result.get('error') == 'file_not_found':
            return
        print(f"❌ Scan failed: {result.get('error')}", file=sys.stderr)
        return
    
    if result['total_violations'] == 0:
        print(f"✅ KB scan passed: {result['file']}")
        print(f"   Scanned {result['total_recipes']} recipes, no violations found")
        return
    
    # Print header
    print(f"\n🚨 KB SECURITY SCAN FAILED: {result['file']}", file=sys.stderr)
    print(f"   Total recipes: {result['total_recipes']}", file=sys.stderr)
    print(f"   Total violations: {result['total_violations']}", file=sys.stderr)
    
    # Print by severity
    for severity_level, violations in [
        (SEVERITY_CRITICAL, result['critical']),
        (SEVERITY_HIGH, result['high']),
        (SEVERITY_MEDIUM, result['medium'])
    ]:
        if not violations:
            continue
            
        severity_icon = '🔴' if severity_level == SEVERITY_CRITICAL else '🟠' if severity_level == SEVERITY_HIGH else '🟡'
        print(f"\n{severity_icon} {severity_level.upper()} ({len(violations)}):", file=sys.stderr)
        
        for v in violations:
            print(f"  Recipe: {v['recipe_id']}", file=sys.stderr)
            print(f"  Issue: {v['description']}", file=sys.stderr)
            print(f"  Matches: {v['matches'][:2]}", file=sys.stderr)
            if v['count'] > 2:
                print(f"  (+ {v['count'] - 2} more)", file=sys.stderr)
            print(file=sys.stderr)

def main():
    if len(sys.argv) < 2:
        print("Usage: kb-security-scan.py <kb-file> [--json]", file=sys.stderr)
        print("\nExample:", file=sys.stderr)
        print("  python3 kb-security-scan.py agents/kb/recipes.jsonl", file=sys.stderr)
        sys.exit(1)
    
    kb_file = Path(sys.argv[1])
    json_output = '--json' in sys.argv
    
    result = scan_kb_file(kb_file)
    
    if json_output:
        print(json.dumps(result, indent=2))
    else:
        print_report(result)
    
    # Exit code: 0 if clean, 2 if critical, 1 if high/medium
    if result['success']:
        sys.exit(0)
    elif len(result.get('critical', [])) > 0:
        sys.exit(2)
    else:
        sys.exit(1)

if __name__ == '__main__':
    main()
