---
id: agent-roster
title: 🤖 Agent Marketplace & Roster
summary: Auto-generated from filename
status: draft
owner: team-platform
tags: []
llm:
  pii: none
  redaction: [email, phone]
  include: true
  chunk_hint: 5000
entities: []
---
# 🤖 Agent Marketplace & Roster

Discover the comprehensive collection of EasyWay agents. Classified by **Strategic Role (Brains)** and **Executive Function (Arms)**.

---

## 🧠 Brains (Strategic Agents)
> *High autonomy, OODA Loop enabled, Principles-driven.*

<table>
<tr>
<td><h3>🔬 Agent Cartographer (The Navigator)</h3><p><b>mapper</b></p><p><i>Mantiene la Mappa delle Dipendenze (Knowledge Graph). Prima di ogni modifica distruttiva, viene consultato per simulare gli impatti a cascata ('Butterfly Effect Analysis').</i></p><br/><p>🏷️ <code>brain</code> 🧠 <code>gpt-4-turbo</code> 📚 <code>1 docs</code></p><p><small><b>Tools:</b> <span title='GenAI: graph_query'>🔧</span> <span title='GenAI: impact_simulator'>🔧</span> <span title='GenAI: dependency_mapper'>🔧</span> </small></p><hr/><b>Key Skills:</b><ul><li>graph:query</li><li>graph:update</li><li>impact:simulate</li></ul><p><small>Owner: team-architecture | ID: agent_cartographer</small></p></td>
<td><h3>🔧 Agent Chronicler (The Bard)</h3><p><b>historian</b></p><p><i>The Voice of History. Osserva l'evoluzione dell'ecosistema, registra le pietre miliari e celebra i momenti di vera innovazione ('A star is born').</i></p><br/><p>🏷️ <code>brain</code> 🧠 <code>gpt-4o</code> 📚 <code>2 docs</code></p><p><small><b>Tools:</b> <span title='GenAI: event_listener'>🔧</span> <span title='GenAI: history_writer'>🔧</span> <span title='GenAI: announcer'>🔧</span> </small></p><hr/><b>Key Skills:</b><ul><li>chronicle:record</li><li>chronicle:announce</li></ul><p><small>Owner: team-platform | ID: agent_chronicler</small></p></td>
</tr><tr>
<td><h3>🔧 Agent_DBA</h3><p><b>Agent_DBA</b></p><p><i>Gestione migrazioni DB, drift check, documentazione ERD/SP, RLS rollout</i></p><br/><p>🏷️ <code>brain</code> 🧠 <code>Default</code> </p><p><small><b>Tools:</b> <span title='OS: npm'>💻</span> <span title='OS: pwsh'>💻</span> <span title='OS: sqlcmd'>💻</span> <span title='OS: az'>☁️</span> </small></p><hr/><b>Key Skills:</b><ul><li>db-user:create</li><li>db-user:rotate</li><li>db-user:revoke</li><li>db-doc:ddl-inventory</li><li>db-metadata:extract</li><li>db-metadata:diff</li><li>db-guardrails:check</li><li>db-table:create</li><li>db-blueprint:generate</li></ul><p><small>Owner: Platform Team | ID: agent_dba</small></p></td>
<td><h3>☁️ Agent GEDI (Guardian EasyWay Delle Intenzioni)</h3><p><b>philosophy_guardian</b></p><p><i>Custode del Manifesto EasyWay. Ricorda a tutti - agenti e umani - i principi fondamentali: qualità > velocità, misuriamo due tagliamo una, il percorso conta, lasciare impronta tangibile.</i></p><br/><p>🏷️ <code>brain</code> 🧠 <code>gpt-4o</code> 📚 <code>2 docs</code></p><p><small><b>Tools:</b> <span title='GenAI: reasoning_engine'>🔧</span> <span title='GenAI: manifesto_search'>🔧</span> </small></p><hr/><b>Key Skills:</b><ul><li>gedi:ooda.loop</li></ul><p><small>Owner: team-platform | ID: agent_gedi</small></p></td>
</tr><tr>
<td><h3>🔧 agent_governance</h3><p><b>Agent_Governance</b></p><p><i>Policy, qualità, gates e approvazioni per DB/API/Docs</i></p><br/><p>🏷️ <code>brain</code> 🧠 <code>Default</code> </p><p><small><b>Tools:</b> <span title='OS: pwsh'>💻</span> <span title='OS: node'>💻</span> </small></p><hr/><b>Key Skills:</b><ul><li><i>Specialist Task</i></li></ul><p><small>Owner: Platform Team | ID: agent_governance</small></p></td>
<td><h3>💻 agent_scrummaster</h3><p><b>Agent_ScrumMaster</b></p><p><i>Facilitatione agile conversazionale: backlog/roadmap, governance operativa, DoD/gates, allineamento Epics/Features/Tasks.</i></p><br/><p>🏷️ <code>brain</code> 🧠 <code>Default</code> </p><p><small><b>Tools:</b> <span title='OS: pwsh'>💻</span> <span title='OS: az'>☁️</span> <span title='OS: curl'>💻</span> </small></p><hr/><b>Key Skills:</b><ul><li><i>Specialist Task</i></li></ul><p><small>Owner: Platform Team | ID: agent_scrummaster</small></p></td>
</tr>
</table>

## 💪 Arms (Executive Agents)
> *High speed, Deterministic, Task-oriented.*

<table>
<tr>
<td><h3>🛠️ agent_ado_userstory</h3><p><b>Agent_ADO_UserStory</b></p><p><i>Gestione User Story su Azure DevOps: prefetch best practices (Wiki + esterne) e creazione work item con output strutturato.</i></p><br/><p>🏷️ <code>arm</code> 🧠 <code>Default</code> </p><p><small><b>Tools:</b> <span title='OS: pwsh'>💻</span> </small></p><hr/><b>Key Skills:</b><ul><li>ado:bestpractice.prefetch</li><li>ado:bootstrap</li><li>ado:userstory.create</li></ul><p><small>Owner: Platform Team | ID: agent_ado_userstory</small></p></td>
<td><h3>💻 agent_ams</h3><p><b>Agent_AMS</b></p><p><i>Automazione operativa conversazionale (Checklist, Variable Group, deploy helpers)</i></p><br/><p>🏷️ <code>arm</code> 🧠 <code>Default</code> </p><p><small><b>Tools:</b> <span title='OS: pwsh'>💻</span> <span title='OS: npm'>💻</span> <span title='OS: curl'>💻</span> </small></p><hr/><b>Key Skills:</b><ul><li><i>Specialist Task</i></li></ul><p><small>Owner: Platform Team | ID: agent_ams</small></p></td>
</tr><tr>
<td><h3>💻 agent_api</h3><p><b>Agent_API</b></p><p><i>Triage e tracciamento errori API; produce output strutturato per orchestrazioni n8n.</i></p><br/><p>🏷️ <code>arm</code> 🧠 <code>Default</code> </p><p><small><b>Tools:</b> <span title='OS: pwsh'>💻</span> </small></p><hr/><b>Key Skills:</b><ul><li>api-error:triage</li></ul><p><small>Owner: Platform Team | ID: agent_api</small></p></td>
<td><h3>💻 Agent_Audit</h3><p><b>Inspector</b></p><p><i>Responsabile della verifica di conformità architetturale degli agenti.</i></p><br/><p>🏷️ <code>arm</code> 🧠 <code>Default</code> </p><hr/><b>Key Skills:</b><ul><li>audit:agents.inspect</li></ul><p><small>Owner: Platform Team | ID: agent_audit</small></p></td>
</tr><tr>
<td><h3>💻 agent_backend</h3><p><b>Agent_Backend</b></p><p><i>Owner implementazione API: OpenAPI, pattern middleware auth/tenant, lint e scaffolding endpoint (distinct da agent_api triage).</i></p><br/><p>🏷️ <code>arm</code> 🧠 <code>Default</code> </p><p><small><b>Tools:</b> <span title='OS: pwsh'>💻</span> <span title='OS: npm'>💻</span> </small></p><hr/><b>Key Skills:</b><ul><li>api:openapi-validate</li></ul><p><small>Owner: Platform Team | ID: agent_backend</small></p></td>
<td><h3>💻 agent_creator</h3><p><b>Agent_Creator</b></p><p><i>Scaffolding governato di nuovi agenti (manifest/templates/KB/Wiki) usando pattern canonici + contesto RAG (Azure AI Search) orchestrato da n8n.</i></p><br/><p>🏷️ <code>arm</code> 🧠 <code>Default</code> </p><p><small><b>Tools:</b> <span title='OS: pwsh'>💻</span> <span title='OS: git'>🐙</span> </small></p><hr/><b>Key Skills:</b><ul><li>agent:scaffold</li></ul><p><small>Owner: Platform Team | ID: agent_creator</small></p></td>
</tr><tr>
<td><h3>🐙 agent_datalake</h3><p><b>Agent_Datalake</b></p><p><i>Gestione operativa e compliance del Datalake: naming, ACL, audit, retention, export log, policy.</i></p><br/><p>🏷️ <code>arm</code> 🧠 <code>Default</code> </p><p><small><b>Tools:</b> <span title='OS: pwsh'>💻</span> <span title='OS: azcopy'>☁️</span> <span title='OS: terraform'>💻</span> </small></p><hr/><b>Key Skills:</b><ul><li>dlk-ensure-structure</li><li>dlk-apply-acl</li><li>dlk-set-retention</li><li>dlk-export-log</li><li>etl-slo:validate</li></ul><p><small>Owner: Platform Team | ID: agent_datalake</small></p></td>
<td><h3>💻 agent_docs_review</h3><p><b>Agent_Docs_Review</b></p><p><i>Revisione documentazione: normalizzazione Wiki, indici/chunk, coerenza KB, supporto aggiunta ricette.</i></p><br/><p>🏷️ <code>arm</code> 🧠 <code>Default</code> </p><p><small><b>Tools:</b> <span title='OS: pwsh'>💻</span> </small></p><hr/><b>Key Skills:</b><ul><li><i>Specialist Task</i></li></ul><p><small>Owner: Platform Team | ID: agent_docs_review</small></p></td>
</tr><tr>
<td><h3>💻 agent_docs_sync</h3><p><b>Agent_Docs_Sync</b></p><p><i>Mantiene allineamento tra documentazione e codice: valida tag metadata, verifica cross-references, suggerisce aggiornamenti docs quando script cambiano.</i></p><br/><p>🏷️ <code>arm</code> 🧠 <code>Default</code> </p><p><small><b>Tools:</b> <span title='OS: pwsh'>💻</span> </small></p><hr/><b>Key Skills:</b><ul><li>docs:check</li><li>docs:validate</li><li>docs:report</li><li>docs:sync</li><li>docs:scan</li></ul><p><small>Owner: Platform Team | ID: agent_docs_sync</small></p></td>
<td><h3>💻 agent_dq_blueprint</h3><p><b>Blueprint</b></p><p><i>Genera un blueprint iniziale di regole DQ (Policy Proposal + Policy Set) da CSV/XLSX/schema, integrato con ARGOS.</i></p><br/><p>🏷️ <code>arm</code> 🧠 <code>Default</code> </p><hr/><b>Key Skills:</b><ul><li></li></ul><p><small>Owner: Platform Team | ID: agent_dq_blueprint</small></p></td>
</tr><tr>
<td><h3>💻 EasyWay Agent Marketplace</h3><p><b>Specialist</b></p><p><i>No description provided.</i></p><br/><p>🏷️ <code>arm</code> 🧠 <code>Default</code> </p><hr/><b>Key Skills:</b><ul><li><i>Specialist Task</i></li></ul><p><small>Owner: Platform Team | ID: agent_frontend</small></p></td>
<td><h3>💻 agent_infra</h3><p><b>Agent_Infra</b></p><p><i>IaC/Terraform governato: validate/plan/apply (WhatIf-by-default), drift infra e runbook.</i></p><br/><p>🏷️ <code>arm</code> 🧠 <code>Default</code> </p><p><small><b>Tools:</b> <span title='OS: pwsh'>💻</span> <span title='OS: terraform'>💻</span> <span title='OS: az'>☁️</span> </small></p><hr/><b>Key Skills:</b><ul><li>infra:terraform-plan</li></ul><p><small>Owner: Platform Team | ID: agent_infra</small></p></td>
</tr><tr>
<td><h3>☁️ agent_observability</h3><p><b>Agent_Observability</b></p><p><i>Osservabilita': health check, standard logging, suggerimenti OTel/AppInsights e runbook troubleshooting (no secrets).</i></p><br/><p>🏷️ <code>arm</code> 🧠 <code>Default</code> </p><p><small><b>Tools:</b> <span title='OS: pwsh'>💻</span> </small></p><hr/><b>Key Skills:</b><ul><li>obs:healthcheck</li></ul><p><small>Owner: Platform Team | ID: agent_observability</small></p></td>
<td><h3>💻 agent_pr_manager</h3><p><b>Agent_PR_Manager</b></p><p><i>Crea e propone Pull Request agentiche con esiti gates e riferimenti artifact. Nessun merge autonomo.</i></p><br/><p>🏷️ <code>arm</code> 🧠 <code>Default</code> </p><p><small><b>Tools:</b> <span title='OS: pwsh'>💻</span> <span title='OS: git'>🐙</span> <span title='OS: az'>☁️</span> </small></p><hr/><b>Key Skills:</b><ul><li><i>Specialist Task</i></li></ul><p><small>Owner: Platform Team | ID: agent_pr_manager</small></p></td>
</tr><tr>
<td><h3>☁️ agent_release</h3><p><b>Agent_Release</b></p><p><i>Packaging/versioning del runtime bundle (copia parziale) per runner segregato: build artifact e publish (no segreti).</i></p><br/><p>🏷️ <code>arm</code> 🧠 <code>Default</code> </p><p><small><b>Tools:</b> <span title='OS: pwsh'>💻</span> <span title='OS: git'>🐙</span> </small></p><hr/><b>Key Skills:</b><ul><li>runtime:bundle</li></ul><p><small>Owner: Platform Team | ID: agent_release</small></p></td>
<td><h3>🐙 agent_retrieval</h3><p><b>Agent_Retrieval</b></p><p><i>Gestione RAG: indicizzazione Wiki/KB, retrieval bundles, sync verso vector DB (on-demand), anti-duplicati/canonical.</i></p><br/><p>🏷️ <code>arm</code> 🧠 <code>Default</code> </p><p><small><b>Tools:</b> <span title='OS: pwsh'>💻</span> </small></p><hr/><b>Key Skills:</b><ul><li>rag:export-wiki-chunks</li></ul><p><small>Owner: Platform Team | ID: agent_retrieval</small></p></td>
</tr><tr>
<td><h3>💻 agent_second_brain</h3><p><b>Navigator</b></p><p><i>Responsabile della navigabilità semantica, Context Injection e manutenzione dei Breadcrumbs.</i></p><br/><p>🏷️ <code>arm</code> 🧠 <code>Default</code> </p><hr/><b>Key Skills:</b><ul><li>brain:breadcrumbs.generate</li><li>brain:breadcrumbs.clean</li></ul><p><small>Owner: Platform Team | ID: agent_second_brain</small></p></td>
<td><h3>💻 agent_security</h3><p><b>Agent_Security</b></p><p><i>Provisioning governance-driven di segreti/identity accesso (DB/Datalake): Key Vault, reference, audit e registry (no valori segreti nei log).</i></p><br/><p>🏷️ <code>arm</code> 🧠 <code>Default</code> </p><p><small><b>Tools:</b> <span title='OS: pwsh'>💻</span> <span title='OS: az'>☁️</span> </small></p><hr/><b>Key Skills:</b><ul><li>kv-secret:set</li><li>kv-secret:reference</li><li>access-registry:propose</li></ul><p><small>Owner: Platform Team | ID: agent_security</small></p></td>
</tr><tr>
<td><h3>☁️ agent_synapse</h3><p><b>Agent_Synapse</b></p><p><i>[EXPERIMENTAL - Phase 2] Gestione workspace Synapse/DataFactory: scaffolding cartelle, linting PySpark, gestione Linked Services e template standard. In valutazione per roadmap analytics avanzati.</i></p><br/><p>🏷️ <code>arm</code> 🧠 <code>Default</code> </p><p><small><b>Tools:</b> <span title='OS: pwsh'>💻</span> </small></p><hr/><b>Key Skills:</b><ul><li>synapse:scaffold</li><li>synapse:check-sql</li></ul><p><small>Owner: Platform Team | ID: agent_synapse</small></p></td>
<td><h3>💻 agent_template</h3><p><b>Template</b></p><p><i>Scheletro di agente agent-first: intent JSON, azioni idempotenti, output strutturato, allowed_paths.</i></p><br/><p>🏷️ <code>arm</code> 🧠 <code>gpt-4-turbo</code> 📚 <code>2 docs</code></p><p><small><b>Tools:</b> <span title='GenAI: web_search'>🌐</span> <span title='GenAI: code_interpreter'>🐍</span> <span title='OS: pwsh'>💻</span> <span title='OS: git'>🐙</span> <span title='OS: az'>☁️</span> </small></p><hr/><b>Key Skills:</b><ul><li>sample:echo</li></ul><p><small>Owner: team-platform | ID: agent_template</small></p></td>
</tr>
</table>

## 📊 Ecosystem Stats
- **Total Agents**: 26
- **Strategic Brains**: 6
- **Executive Arms**: 20

_(Generated via scripts/generate-agent-roster.ps1)_


