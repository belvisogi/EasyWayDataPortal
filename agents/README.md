# 🧑‍💻 agents/ — EntryPoint per tutti gli agent di EasyWay DataPortal

Questa directory raccoglie _tutti gli agent_ agentici del progetto EasyWay DataPortal.  
Gli agent sono servizi/script modulari, ognuno responsabile di una funzione chiave (provisioning, audit, doc, governance, QA, ecc), **self-contained**, con manifest/documentazione propria, pronti per essere usati, estesi, automatizzati o orchestrati (anche via n8n).

---

## 📁 Indice agent attuali

| Agent                    | Manifest      | Descrizione breve                                 | Template/Ricetta demo       |
|--------------------------|--------------|--------------------------------------------------|-----------------------------|
| agent_dba                | manifest.json| Migrazioni, inventario e audit DB, drift check   | templates/, test/, doc/     |
| agent_governance         | manifest.json| Quality gates, checklist, doc enforce             | templates/, test/           |
| agent_docs_review        | manifest.json| Normalizzazione Wiki, check glossario/Faq, Lint   | templates/, test/, check-*  |
| agent_datalake           | manifest.json| Naming/ACL, compliance/esportazione Datalake      | templates/, doc/            |
| agent_pr_manager         | manifest.json| Review, merge, gestione PR/issue                  | templates/                  |
| agent_frontend           | manifest.json| Job di orchestrazione front-end                   | templates/                  |
| agent_template           | manifest.json| Starter/boilerplate per nuovi agent               | templates/, doc/            |
| ...                      | ...          | ...                                              | ...                         |

*(Aggiungi qui ogni nuovo agent, aggiorna la tabella custom)*

---

## 📜 Come aggiungere un nuovo agent

1. Copia da `agent_template/` tutte le cartelle base (manifest.json, templates/, test/, doc/)
2. Compila manifest e README con obiettivi/capability
3. Registra template/demo in agents/agent_nome/templates/
4. (Opzionale) Inserisci esempio call/test in test/
5. Aggiorna questa tabella qui sopra!

---

## 🔗 Quicklinks & reference

- [Onboarding centrale](../wiki/EasyWayData.wiki/onboarding/README.md)
- [Best practice agent e scripting cross-platform](../wiki/EasyWayData.wiki/onboarding/best-practice-scripting.md)
- [Guide sandbox/zero trust](../wiki/EasyWayData.wiki/onboarding/setup-playground-zero-trust.md)
- [Developer & agent experience upgrades](../wiki/EasyWayData.wiki/onboarding/developer-agent-experience-upgrades.md)
- [Knowledge base vettoriale (AI/RAG/LLM)](../wiki/EasyWayData.wiki/ai/knowledge-vettoriale-easyway.md)
- [Documentazione: contesto standard](../wiki/EasyWayData.wiki/onboarding/documentazione-contesto-standard.md)
- [Glossario, FAQ, troubleshooting](../wiki/EasyWayData.wiki/glossario-errori-faq.md)

---

> 📢 Contribuisci migliorando agent, ricette, test e documentazione!  
> Proponi PR, issue o suggerimenti dove vuoi ampliare automazione e best practice.
