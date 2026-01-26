---
id: dependency-graph
title: 🗺️ The Map (Dependency Knowledge Graph)
summary: Breve descrizione del documento.
status: draft
owner: team-docs
created: '2025-01-01'
updated: '2025-01-01'
tags:
  - layer/reference
  - privacy/internal
  - language/it
llm:
  include: true
  pii: none
  chunk_hint: 400-600
  redaction: [email, phone]
entities: []
---
# 🗺️ The Map (Dependency Knowledge Graph)

> *"Una farfalla sbatte le ali nel DB, e un uragano colpisce il Frontend."* - Agent Cartographer

Questo file traccia le dipendenze critiche tra i domini EasyWay.
Il grafo è strutturato secondo la **Matrix of Components vs Applications**.

## 🏗️ Macro Structure (The Matrix)

### 1. Azure Domain
#### 1.1 Virtual Machines (VM)
*   `VM:PortalMonitor`
*   `VM:InformaticaAxon`
*   `VM:AzureDevOps` --(hosts)--> `ADO:Project:EasyWay`

#### 1.2 Data Platform
*   `Synapse:Workspace` --(contains)--> `SQLPool:Primary`
*   `Synapse:SparkPool`
*   `AzureSQL:Repos`

#### 1.3 Storage & Compute
*   `Storage:DataLake` --(stores)--> `Container:Landing`
*   `Databricks:Workspace`

#### 1.4 Services
*   `LogicApp:Orchestrator`

### 2. M365 Domain
#### 2.1 Analytics & Logic
*   `PowerBI:Gateway`
*   `PowerBI:Workspace` --(contains)--> `PBI:Report:Sales`
*   `Table:Users` --(provides_data_to)--> `API:GetUsers`
*   `API:GetUsers` --(consumed_by)--> `WebApp:Page:UserList`

## 🕵️ Crawler Findings (Auto-Generated - 01/17/2026 20:49:01)
* Found evidence of **Synapse/SQL**: ile:/db/migrations/V1__baseline.sql (Category: Data Platform)
* Found evidence of **Synapse/SQL**: ile:/db/migrations/V1__create_schemas.sql (Category: Data Platform)
* Found evidence of **Synapse/SQL**: ile:/db/migrations/V10__rls_configuration.sql (Category: Data Platform)
* Found evidence of **Synapse/SQL**: ile:/db/migrations/V11__stored_procedures_users_read.sql (Category: Data Platform)
* Found evidence of **Synapse/SQL**: ile:/db/migrations/V12__config_read.sql (Category: Data Platform)
* Found evidence of **Synapse/SQL**: ile:/db/migrations/V13__agent_chat.sql (Category: Data Platform)
* Found evidence of **Synapse/SQL**: ile:/db/migrations/V13__ensure_sp_get_config_by_tenant.sql (Category: Data Platform)
* Found evidence of **Synapse/SQL**: ile:/db/migrations/V14__refactor_onboarding_sp.sql (Category: Data Platform)
* Found evidence of **Synapse/SQL**: ile:/db/migrations/V2__core_sequences.sql (Category: Data Platform)
* Found evidence of **Synapse/SQL**: ile:/db/migrations/V3__portal_core_tables.sql (Category: Data Platform)
* Found evidence of **Synapse/SQL**: ile:/db/migrations/V3_1__portal_more_tables.sql (Category: Data Platform)
* Found evidence of **Synapse/SQL**: ile:/db/migrations/V4__portal_logging_tables.sql (Category: Data Platform)
* Found evidence of **Synapse/SQL**: ile:/db/migrations/V5__rls_setup.sql (Category: Data Platform)
* Found evidence of **Synapse/SQL**: ile:/db/migrations/V6__stored_procedures_core.sql (Category: Data Platform)
* Found evidence of **Synapse/SQL**: ile:/db/migrations/V7__seed_minimum.sql (Category: Data Platform)
* Found evidence of **Synapse/SQL**: ile:/db/migrations/V8__extended_properties.sql (Category: Data Platform)
* Found evidence of **Synapse/SQL**: ile:/db/migrations/V9__stored_procedures_users_config_acl.sql (Category: Data Platform)
* Found evidence of **Synapse/SQL**: ile:/docs/agentic/templates/ddl/template_table.sql (Category: Data Platform)
* Found evidence of **Synapse/SQL**: ile:/docs/agentic/templates/docs/agent-chat-retention.job.sql (Category: Data Platform)
* Found evidence of **Synapse/SQL**: ile:/docs/agentic/templates/sp/template_sp_debug_insert.sql (Category: Data Platform)
* Found evidence of **Synapse/SQL**: ile:/docs/agentic/templates/sp/template_sp_delete.sql (Category: Data Platform)
* Found evidence of **Synapse/SQL**: ile:/docs/agentic/templates/sp/template_sp_insert.sql (Category: Data Platform)
* Found evidence of **Synapse/SQL**: ile:/docs/agentic/templates/sp/template_sp_update.sql (Category: Data Platform)
* Found evidence of **Synapse/SQL**: ile:/old/db/_ARCHIVED_DDL/DataBase_legacy/DDL_EASYWAY_DATAPORTAL.sql (Category: Data Platform)
* Found evidence of **Synapse/SQL**: ile:/old/db/_ARCHIVED_DDL/DataBase_legacy/programmability/sp/sp_get_config_by_tenant.sql (Category: Data Platform)
* Found evidence of **Synapse/SQL**: ile:/old/db/_ARCHIVED_DDL/DataBase_legacy/programmability/sp/sp_subscribe_notification.sql (Category: Data Platform)
* Found evidence of **Synapse/SQL**: ile:/old/db/_ARCHIVED_DDL/DataBase_legacy/programmability/sp/sp_update_user.sql (Category: Data Platform)
* Found evidence of **Synapse/SQL**: ile:/old/db/_ARCHIVED_DDL/DataBase_legacy/provisioning/00_schema.sql (Category: Data Platform)
* Found evidence of **Synapse/SQL**: ile:/old/db/_ARCHIVED_DDL/DataBase_legacy/provisioning/10_tables.sql (Category: Data Platform)
* Found evidence of **Synapse/SQL**: ile:/old/db/_ARCHIVED_DDL/DataBase_legacy/provisioning/20_fk_indexes.sql (Category: Data Platform)
* Found evidence of **Synapse/SQL**: ile:/old/db/_ARCHIVED_DDL/DataBase_legacy/provisioning/30_seed_minimal.sql (Category: Data Platform)
* Found evidence of **Synapse/SQL**: ile:/old/db/_ARCHIVED_DDL/DataBase_legacy/provisioning/40_extended_properties.sql (Category: Data Platform)
* Found evidence of **Synapse/SQL**: ile:/old/db/_ARCHIVED_DDL/DataBase_legacy/provisioning/50_sp_debug_register_tenant_and_user.sql (Category: Data Platform)
* Found evidence of **Synapse/SQL**: ile:/old/db/_ARCHIVED_DDL/ddl_portal_exports/DDL_PORTAL_STOREPROCES_EASYWAY_DATAPORTAL.sql (Category: Data Platform)
* Found evidence of **Synapse/SQL**: ile:/old/db/_ARCHIVED_DDL/ddl_portal_exports/DDL_PORTAL_TABLE_EASYWAY_DATAPORTAL.sql (Category: Data Platform)
* Found evidence of **Synapse/SQL**: ile:/old/db/_ARCHIVED_DDL/ddl_portal_exports/DDL_STATLOG_STOREPROCES_EASYWAY_DATAPORTAL.sql (Category: Data Platform)
* Found evidence of **WebApp**: ile:/ (Category: Frontend)
* Found evidence of **WebApp**: ile:/ (Category: Frontend)
* Found evidence of **WebApp**: ile:/agents/agent_frontend/index.html (Category: Frontend)
* Found evidence of **WebApp**: ile:/apps/portal-frontend/index.html (Category: Frontend)
* Found evidence of **WebApp**: ile:/apps/portal-frontend/dist/index.html (Category: Frontend)
* Found evidence of **WebApp**: ile:/apps/portal-frontend/dist/static_tools/db-diagram-viewer.html (Category: Frontend)
* Found evidence of **WebApp**: ile:/apps/portal-frontend/dist/static_tools/plan-viewer.html (Category: Frontend)
* Found evidence of **WebApp**: ile:/apps/portal-frontend/public/static_tools/db-diagram-viewer.html (Category: Frontend)
* Found evidence of **WebApp**: ile:/apps/portal-frontend/public/static_tools/plan-viewer.html (Category: Frontend)
* Found evidence of **WebApp**: ile:/db/db-deploy-ai/viewer/index.html (Category: Frontend)
* Found evidence of **WebApp**: ile:/mvp_wiki_dq/out/graph-view.html (Category: Frontend)
* Found evidence of **WebApp**: ile:/out/ado-best-practices/learn-microsoft-com-azure-devops-boards-backlogs-create-your-backlog-view-azure-devops.html (Category: Frontend)
* Found evidence of **LogicApp/Flow**: ile:/agent-ready-audit.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/db-ddl-inventory.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs-dq-scorecard.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/fm.patch.all.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/fm.patch.data-all.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/fm.patch.portal-all.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/fm.patch.security-all.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/whatfirst-lint.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/wiki-gap-report.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/wiki-gap.all.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/wiki-gap.data-all.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/wiki-gap.governance-all.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/wiki-gap.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/wiki-gap.portal-all.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/wiki-gap.security-all.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/wiki-gap.smoke.controlplane-governance-20.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/wiki-links-anchors-lint.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/wiki-sections-patch.all.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/wiki-sections-unpatch.all.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/agents/goals.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/agents/agent_ado_userstory/manifest.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/agents/agent_ado_userstory/priority.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/agents/agent_ado_userstory/templates/intent.ado-bestpractice-prefetch.sample.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/agents/agent_ado_userstory/templates/intent.ado-bootstrap.sample.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/agents/agent_ado_userstory/templates/intent.ado-userstory-create.sample.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/agents/agent_ams/manifest.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/agents/agent_ams/priority.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/agents/agent_api/manifest.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/agents/agent_api/priority.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/agents/agent_audit/manifest.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/agents/agent_backend/manifest.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/agents/agent_backend/priority.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/agents/agent_cartographer/manifest.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/agents/agent_chronicler/manifest.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/agents/agent_creator/manifest.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/agents/agent_creator/priority.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/agents/agent_creator/templates/intent.agent-scaffold.sample.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/agents/agent_datalake/manifest.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/agents/agent_datalake/priority.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/agents/agent_datalake/templates/currentPaths.sample.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/agents/agent_datalake/templates/intent.dlk-apply-acl.sample.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/agents/agent_datalake/templates/intent.dlk-ensure-structure.sample.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/agents/agent_datalake/templates/intent.dlk-export-log.sample.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/agents/agent_datalake/templates/intent.dlk-set-retention.sample.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/agents/agent_datalake/templates/intent.etl-slo-validate.sample.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/agents/agent_datalake/templates/slo/slo.sample.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/agents/agent_dba/manifest.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/agents/agent_dba/priority.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/agents/agent_dba/templates/intent.db-ddl-inventory.sample.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/agents/agent_dba/templates/intent.db-table-create.sample.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/agents/agent_dba/templates/intent.db-user-create.sample.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/agents/agent_dba/templates/intent.db-user-revoke.sample.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/agents/agent_dba/templates/intent.db-user-rotate.sample.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/agents/agent_docs_review/manifest.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/agents/agent_docs_review/priority.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/agents/agent_docs_sync/manifest.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/agents/agent_dq_blueprint/manifest.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/agents/agent_dq_blueprint/heuristics/heuristics.v0.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/agents/agent_frontend/manifest.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/agents/agent_frontend/priority.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/agents/agent_frontend/data/roster.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/agents/agent_gedi/manifest.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/agents/agent_governance/manifest.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/agents/agent_governance/priority.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/agents/agent_infra/manifest.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/agents/agent_infra/priority.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/agents/agent_observability/manifest.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/agents/agent_observability/priority.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/agents/agent_pr_manager/manifest.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/agents/agent_pr_manager/priority.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/agents/agent_release/manifest.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/agents/agent_release/priority.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/agents/agent_retrieval/manifest.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/agents/agent_retrieval/priority.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/agents/agent_scrummaster/manifest.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/agents/agent_scrummaster/priority.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/agents/agent_second_brain/manifest.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/agents/agent_security/manifest.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/agents/agent_security/priority.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/agents/agent_synapse/manifest.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/agents/agent_synapse/priority.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/agents/agent_synapse/skills/templates/intent.sample-echo.sample.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/agents/agent_synapse/skills/templates/intent.sample.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/agents/agent_template/manifest.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/agents/agent_template/priority.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/agents/agent_template/templates/intent.sample-echo.sample.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/agents/agent_template/templates/intent.sample.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/agents/core/schemas/action-result.schema.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/agents/core/schemas/agent-manifest.schema.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/agents/core/schemas/agent-priority.schema.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/agents/core/schemas/event.schema.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/agents/core/schemas/kb-recipe.schema.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/agents/core/schemas/plan.schema.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/agents/core/templates/priority.template.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/agents/memory/exotic-tags-analysis.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/agents/memory/files-without-tags.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/agents/memory/knowledge-graph.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/agents/memory/link-suggestions.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/agents/memory/tag-master-hierarchy.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/apps/portal-frontend/package-lock.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/apps/portal-frontend/package.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/apps/portal-frontend/tsconfig.app.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/apps/portal-frontend/tsconfig.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/apps/portal-frontend/tsconfig.node.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/apps/portal-frontend/dist/static_tools/mock/plan-sample.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/apps/portal-frontend/dist/static_tools/mock/portal-diagram-sample.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/apps/portal-frontend/public/static_tools/mock/plan-sample.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/apps/portal-frontend/public/static_tools/mock/portal-diagram-sample.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/db/db-deploy-ai/package-lock.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/db/db-deploy-ai/package.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/db/db-deploy-ai/schema/blueprint.schema.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/db/db-deploy-ai/schema/easyway-portal.blueprint.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/playbooks/pb-UNIQ-04.sample.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/mapping.entrate-uscite.candidates.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/docs/agent-ready-rubric.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/docs/retrieval-bundles.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/docs/tag-taxonomy.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/docs/tag-taxonomy.scopes.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/events/samples/argos.coach.nudge.sent.sample.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/events/samples/argos.contract.proposal.sample.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/events/samples/argos.gate.decision.sample.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/events/samples/argos.policy.proposal.sample.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/events/samples/argos.profile.drift.sample.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/events/samples/argos.run.completed.sample.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/events/samples/argos.ticket.opened.sample.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/events/schemas/argos.coach.nudge.sent.schema.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/events/schemas/argos.contract.proposal.schema.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/events/schemas/argos.gate.decision.schema.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/events/schemas/argos.policy.proposal.schema.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/events/schemas/argos.profile.drift.schema.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/events/schemas/argos.run.completed.schema.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/events/schemas/argos.ticket.opened.schema.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/events/schemas/common.schema.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/intents/ado-bestpractice-prefetch.intent.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/intents/ado-bootstrap.intent.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/intents/ado-userstory-create.intent.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/intents/agent.scaffold.intent.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/intents/analytics.materialize-defaults.intent.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/intents/api.error.triage.intent.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/intents/api.openapi.validate.intent.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/intents/api.rbac.configure.intent.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/intents/apply-appsettings-starter.intent.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/intents/db-drift-check.intent.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/intents/db-generate-docs.intent.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/intents/db-migrate.intent.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/intents/db-user-create.intent.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/intents/db-user-revoke.intent.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/intents/db-user-rotate.intent.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/intents/db.ddl-inventory.intent.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/intents/db.table.create.intent.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/intents/docs-confluence-dq-kanban.intent.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/intents/docs-dq-audit.intent.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/intents/docs-related-links-apply.intent.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/intents/dq.validate.intent.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/intents/etl.load-staging.intent.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/intents/etl.merge-target.intent.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/intents/generate-appsettings-from-env.intent.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/intents/iam.provision.access.intent.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/intents/infra.terraform.plan.intent.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/intents/ingest.upload-file.intent.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/intents/kb.assessment.intent.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/intents/kv.secret.set.intent.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/intents/obs.healthcheck.intent.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/intents/orchestrator.n8n.dispatch.intent.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/intents/predeploy-checklist.intent.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/intents/rag.export-wiki-chunks.intent.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/intents/release.preflight.security.intent.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/intents/runtime.bundle.intent.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/intents/schema.map-apply.intent.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/intents/schema.map-suggest.intent.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/intents/sync-appsettings-guardrail.intent.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/intents/whatfirst-lint.intent.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/orchestrations/ado-bootstrap.manifest.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/orchestrations/ado-userstory-create.manifest.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/orchestrations/agent-scaffold.manifest.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/orchestrations/api-error-triage.manifest.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/orchestrations/api-rbac-configure.manifest.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/orchestrations/apply-appsettings-starter.manifest.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/orchestrations/db-drift-check.manifest.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/orchestrations/db-generate-docs.manifest.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/orchestrations/db-migrate.manifest.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/orchestrations/db-table-create.manifest.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/orchestrations/db-user-create.manifest.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/orchestrations/db-user-revoke.manifest.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/orchestrations/db-user-rotate.manifest.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/orchestrations/docs-confluence-dq-kanban.manifest.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/orchestrations/docs-dq-audit.manifest.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/orchestrations/docs-related-links-apply.manifest.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/orchestrations/generate-appsettings-from-env.manifest.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/orchestrations/iam-provision-access.manifest.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/orchestrations/kb-assessment.manifest.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/orchestrations/predeploy-checklist.manifest.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/orchestrations/release-preflight-security.manifest.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/orchestrations/sync-appsettings-guardrail.manifest.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/orchestrations/ux_prompts.en.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/orchestrations/ux_prompts.it.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/orchestrations/wf.excel-csv-upload.manifest.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/orchestrations/whatfirst-lint.manifest.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/plans/diary.schema.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/plans/plan.schema.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/plans/samples/release.preflight.security.diary.sample.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/plans/samples/release.preflight.security.plan.sample.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/docs/agentic/templates/registry-sample/policy-set.sample.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/dsl/user.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/EasyWay-DataPortal/package-lock.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/EasyWay-DataPortal/package.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/EasyWay-DataPortal/easyway-portal-api/.eslintrc.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/EasyWay-DataPortal/easyway-portal-api/checklist.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/EasyWay-DataPortal/easyway-portal-api/drift.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/EasyWay-DataPortal/easyway-portal-api/package-lock.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/EasyWay-DataPortal/easyway-portal-api/package.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/EasyWay-DataPortal/easyway-portal-api/tsconfig.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/EasyWay-DataPortal/easyway-portal-api/data/dev-users.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/EasyWay-DataPortal/easyway-portal-api/data/db/portal-diagram.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/EasyWay-DataPortal/easyway-portal-api/logs/business.log.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/EasyWay-DataPortal/easyway-portal-api/logs/error.log.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/mvp_wiki_dq/config/scopes.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/mvp_wiki_dq/config/tag-taxonomy.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/mvp_wiki_dq/intents/confluence.params.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/mvp_wiki_dq/intents/doc-nav.intent.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/mvp_wiki_dq/out/backlog.wiki.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/mvp_wiki_dq/out/gap.20260109-042249.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/mvp_wiki_dq/out/gap.20260109-044324.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/mvp_wiki_dq/out/gap.20260109-051332.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/mvp_wiki_dq/out/gap.20260109-051808.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/mvp_wiki_dq/out/gap.20260109-060854.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/mvp_wiki_dq/out/gap.20260109-063513.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/mvp_wiki_dq/out/graph-view.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/mvp_wiki_dq/out/graph.20260109-042249.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/mvp_wiki_dq/out/graph.20260109-044324.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/mvp_wiki_dq/out/graph.20260109-051332.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/mvp_wiki_dq/out/graph.20260109-051808.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/mvp_wiki_dq/out/graph.20260109-060854.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/mvp_wiki_dq/out/graph.20260109-063513.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/mvp_wiki_dq/out/links.20260109-042249.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/mvp_wiki_dq/out/links.20260109-044324.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/mvp_wiki_dq/out/links.20260109-051332.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/mvp_wiki_dq/out/links.20260109-051808.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/mvp_wiki_dq/out/links.20260109-060854.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/mvp_wiki_dq/out/links.20260109-063513.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/mvp_wiki_dq/out/scorecard.wiki.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/mvp_wiki_dq/out/tags.20260109-051332.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/mvp_wiki_dq/out/tags.20260109-051808.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/mvp_wiki_dq/out/tags.20260109-060854.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/mvp_wiki_dq/out/tags.20260109-063513.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/mvp_wiki_dq/out/tags.test.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/mvp_wiki_dq/templates/orch/confluence-dq-kanban.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/mvp_wiki_dq/templates/orch/mvpctl.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/mvp_wiki_dq/templates/orch/wiki-dq-audit.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/out/docs-dq-backlog.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/out/mvp_wiki_dq.links.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/out/sm-ooda-test.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/out/whatfirst-lint.after-related-apply.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/out/wiki-link-graph.EasyWayData.wiki.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/out/wiki-links-anchors-lint.EasyWayData.wiki.after-atomic-flows-agent-links.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/out/wiki-links-anchors-lint.EasyWayData.wiki.after-orphans.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/out/wiki-links-anchors-lint.EasyWayData.wiki.after-related-apply-dryrun.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/out/wiki-links-anchors-lint.EasyWayData.wiki.after-related-apply-real.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/out/wiki-links-anchors-lint.EasyWayData.wiki.after-related-apply.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/out/wiki-links-anchors-lint.EasyWayData.wiki.after-related.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/out/wiki-links-anchors-lint.EasyWayData.wiki.after-step1-onboarding.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/out/wiki-links-anchors-lint.EasyWayData.wiki.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/out/wiki-links-anchors-lint.WikiRoot.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/out/wiki-related-links.suggestions.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/out/wiki-related-links.suggestions.smoke.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/out/db/db-table-create.sample_feature_flag.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/out/db/db-table-lint.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/out/db/gen-test.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/out/db/lint-test.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/out/db/portal-diagram.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/out/docs/agents-manifest-audit.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/out/docs/wiki-links-anchors-lint.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/out/wiki-related-links-apply/20260109-011604/apply-summary.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/out/wiki-related-links-apply/20260109-014639/apply-summary.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/out/wiki-related-links-apply/20260109-015339/apply-summary.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/scripts/easyway-secrets.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/scripts/intents/doc-nav-improvement-001.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/scripts/intents/docs-dq-confluence-cloud-001.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/scripts/variables/db-required-objects.sample.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/scripts/variables/easyway-secrets.sample.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/tests/postman/EasyWay.postman_collection.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/Wiki/.obsidian/app.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/Wiki/.obsidian/appearance.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/Wiki/.obsidian/community-plugins.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/Wiki/.obsidian/core-plugins.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/Wiki/.obsidian/graph.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/Wiki/.obsidian/workspace.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/Wiki/.obsidian/plugins/azure-linker/manifest.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/Wiki/.vscode/settings.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/Wiki/EasyWayData.wiki/.obsidian.example/app.json (Category: Services)
* Found evidence of **LogicApp/Flow**: ile:/Wiki/EasyWayData.wiki/.obsidian.example/core-plugins.json (Category: Services)



