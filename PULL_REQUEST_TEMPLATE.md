## Checklist PR – EasyWayDataPortal

- [ ] Wiki: front‑matter LLM presente su ogni nuova/aggiornata pagina (`id,title,summary,status,owner,tags,llm.include,llm.chunk_hint,llm.pii,llm.redaction,entities`)
- [ ] Lint: eseguito `scripts/wiki-frontmatter-lint.ps1 -Path Wiki/EasyWayData.wiki -FailOnError` localmente (oppure verificato job CI)
- [ ] Autofix (se necessario): eseguito `scripts/wiki-frontmatter-autofix.ps1 -Path Wiki/EasyWayData.wiki` e revisionati i cambi
- [ ] Privacy: nessuna PII in summary/front‑matter; redaction coerente
- [ ] KB: aggiornata una ricetta se la modifica introduce un nuovo flusso/procedura
- [ ] CI: gates `ewctl` verdi (Checklist/DB Drift/KB Consistency) su branch di PR

Sezione WHAT‑first (obbligatoria per nuovi workflow/use case)
- [ ] Orchestrazione (manifest JSON) presente in `docs/agentic/templates/orchestrations/`
- [ ] Intents (WHAT JSON) presenti in `docs/agentic/templates/intents/`
- [ ] UX prompts localizzati in `docs/agentic/templates/orchestrations/ux_prompts.it.json|en.json`
- [ ] Pagina Wiki di orchestrazione/Use Case aggiunta/aggiornata

Note:
- Per applicare gli autofix direttamente ai file: aggiungi `-Apply` (e opzionale `-ForceReplace` per sovrascrivere front‑matter esistenti).
