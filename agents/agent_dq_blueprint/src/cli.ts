#!/usr/bin/env ts-node
/* Minimal MVP: legge un CSV (solo header + qualche euristica) e produce policy_proposals.json + policy_set.json */
import * as fs from 'fs';

type Heuristics = {
  patterns: Record<string, { regex: string; category: string }>;
  keywords: Record<string, { suggest: string[]; blocking: boolean }>;
  domain_cardinality_threshold: number;
  probabilistic_defaults: { mostly: number };
  deterministic_defaults: { mostly: number };
};

function arg(k: string, def?: string) {
  const i = process.argv.indexOf(k);
  return i >= 0 ? process.argv[i + 1] : def;
}

function guessColumnsFromCsv(path: string) {
  const text = fs.readFileSync(path, 'utf8');
  const lines = text.split(/\r?\n/).filter(Boolean);
  const header = lines[0]?.split(',').map(s => s.trim()) || [];
  return header;
}

function loadHeuristics(p: string): Heuristics {
  return JSON.parse(fs.readFileSync(p, 'utf8')) as Heuristics;
}

function proposeRules(headers: string[], heur: Heuristics, impactDefault: number) {
  const proposals: any[] = [];
  for (const h of headers) {
    const hLow = h.toLowerCase();
    // Completeness
    proposals.push({
      rule_id: `R_NULL_${h.toUpperCase()}`,
      title: `${h} must not be null`,
      category: 'COMPLETENESS',
      scope: 'ELEMENT',
      element_ref: [h],
      policy_type: 'DETERMINISTIC',
      check: 'element is not null',
      mostly: heur.deterministic_defaults.mostly,
      severity_base: 'ALERT_WITH_DISCARD',
      discard_mode: 'ROW',
      impact_score: impactDefault,
      description: `Completeness check for ${h}`
    });
    // Keywords based
    for (const kw of Object.keys(heur.keywords)) {
      if (hLow.includes(kw)) {
        const cfg = heur.keywords[kw];
        if (cfg.suggest.includes('UNIQUENESS')) {
          proposals.push({
            rule_id: `R_UNIQ_${h.toUpperCase()}`,
            title: `${h} must be unique`,
            category: 'UNIQUENESS',
            scope: 'ELEMENT',
            element_ref: [h],
            policy_type: 'DETERMINISTIC',
            check: `unique key (${h})`,
            mostly: heur.deterministic_defaults.mostly,
            severity_base: cfg.blocking ? 'BLOCKING' : 'ALERT_WITH_DISCARD',
            discard_mode: 'ROW',
            impact_score: Math.max(impactDefault, 0.7),
            description: `Uniqueness enforced on ${h}`
          });
        }
        if (cfg.suggest.includes('FRESHNESS')) {
          proposals.push({
            rule_id: `R_FRESH_${h.toUpperCase()}`,
            title: `${h} freshness within SLA`,
            category: 'FRESHNESS',
            scope: 'ELEMENT',
            element_ref: [h],
            policy_type: 'DETERMINISTIC',
            check: `${h} within SLA`,
            mostly: heur.deterministic_defaults.mostly,
            severity_base: 'ALERT_WITHOUT_DISCARD',
            impact_score: impactDefault,
            description: `Freshness check for ${h}`
          });
        }
      }
    }
    // Patterns based
    for (const [name, pat] of Object.entries(heur.patterns)) {
      if (hLow.includes(name)) {
        proposals.push({
          rule_id: `R_FMT_${name.toUpperCase()}_${h.toUpperCase()}`,
          title: `${h} matches ${name} pattern`,
          category: 'FORMAT',
          scope: 'ELEMENT',
          element_ref: [h],
          policy_type: 'DETERMINISTIC',
          check: `element matches /${pat.regex}/`,
          mostly: heur.deterministic_defaults.mostly,
          severity_base: 'ALERT_WITH_DISCARD',
          discard_mode: 'ROW',
          impact_score: impactDefault,
          description: `Format check (${name}) for ${h}`
        });
      }
    }
  }
  return proposals;
}

function main() {
  const action = arg('--action', 'blueprint-from-file');
  const input = arg('--input');
  const domain = arg('--domain');
  const flow = arg('--flow');
  const instance = arg('--instance');
  const impactDefault = Number(arg('--impact', '0.5'));
  const heurPath = arg('--heuristics', 'agents/agent_dq_blueprint/heuristics/heuristics.v0.json');
  if (action !== 'blueprint-from-file' || !input || !domain || !flow || !instance) {
    console.error('Usage: ts-node agents/agent_dq_blueprint/src/cli.ts --action blueprint-from-file --input <file.csv> --domain <id> --flow <id> --instance <id> [--impact 0.5]');
    process.exit(1);
  }
  const heur = loadHeuristics(heurPath);
  const headers = guessColumnsFromCsv(input);
  const proposals = proposeRules(headers, heur, impactDefault);
  const policySet = {
    id: `${domain}-${flow}-${instance}-initial`,
    version: '0.1.0',
    scope: { domain_id: domain, flow_id: flow, instance_id: instance },
    rules: proposals.map(p => ({ rule_id: p.rule_id, rule_version: '0.1.0', severity_base: p.severity_base, impact_score: p.impact_score }))
  };
  fs.mkdirSync('out/blueprint', { recursive: true });
  fs.writeFileSync('out/blueprint/policy_proposals.json', JSON.stringify(proposals, null, 2));
  fs.writeFileSync('out/blueprint/policy_set.json', JSON.stringify(policySet, null, 2));
  const result = { ok: true, summary: { columns: headers.length, rules_proposed: proposals.length }, policy_proposals: proposals, policy_set: policySet, artifacts: ['out/blueprint/policy_proposals.json', 'out/blueprint/policy_set.json'] };
  console.log(JSON.stringify(result, null, 2));
}

main();

