import fs from "fs";
import path from "path";
import { AgentsRepo, AgentRecord } from "../types";

// Fallback static list when AGENTS_PATH is not set or manifests are unreadable
const STATIC_AGENTS: AgentRecord[] = [
  { agent_id: "agent_infra",                 name: "agent_infra",                 level: "L3", status: "ONLINE", last_run: null },
  { agent_id: "agent_levi",                  name: "agent_levi",                  level: "L3", status: "ONLINE", last_run: null },
  { agent_id: "agent_pr_gate",               name: "agent_pr_gate",               level: "L3", status: "ONLINE", last_run: null },
  { agent_id: "agent_review",                name: "agent_review",                level: "L3", status: "ONLINE", last_run: null },
  { agent_id: "agent_scrummaster",           name: "agent_scrummaster",           level: "L3", status: "ONLINE", last_run: null },
  { agent_id: "agent_security",              name: "agent_security",              level: "L3", status: "ONLINE", last_run: null },
  { agent_id: "agent_backend",               name: "agent_backend",               level: "L2", status: "IDLE",   last_run: null },
  { agent_id: "agent_dba",                   name: "agent_dba",                   level: "L2", status: "IDLE",   last_run: null },
  { agent_id: "agent_docs_sync",             name: "agent_docs_sync",             level: "L2", status: "IDLE",   last_run: null },
  { agent_id: "agent_frontend",              name: "agent_frontend",              level: "L2", status: "IDLE",   last_run: null },
  { agent_id: "agent_vulnerability_scanner", name: "agent_vulnerability_scanner", level: "L2", status: "IDLE",   last_run: null },
];

function readManifests(agentsPath: string): AgentRecord[] {
  try {
    const dirs = fs.readdirSync(agentsPath, { withFileTypes: true })
      .filter(d => d.isDirectory())
      .map(d => d.name);

    const records: AgentRecord[] = [];
    for (const dir of dirs) {
      const manifestPath = path.join(agentsPath, dir, "manifest.json");
      if (!fs.existsSync(manifestPath)) continue;
      try {
        const raw = JSON.parse(fs.readFileSync(manifestPath, "utf-8"));
        records.push({
          agent_id: raw.id ?? dir,
          name: raw.name ?? dir,
          level: raw.level ?? "L1",
          description: raw.description ?? null,
          status: "ONLINE",
          last_run: null,
        });
      } catch {
        // skip malformed manifest
      }
    }
    return records.length > 0 ? records : STATIC_AGENTS;
  } catch {
    return STATIC_AGENTS;
  }
}

export class MockAgentsRepo implements AgentsRepo {
  async list(): Promise<AgentRecord[]> {
    const agentsPath = process.env.AGENTS_PATH;
    if (agentsPath) return readManifests(agentsPath);
    return STATIC_AGENTS;
  }
}
