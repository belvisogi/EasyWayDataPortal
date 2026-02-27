# ADO Session Awareness — Strategia Antifragile

> **Problema**: Claude Code non riceve push da Azure DevOps.
> Senza un meccanismo attivo, siamo ciechi sullo stato di PR, branch e pipeline.
>
> **Soluzione adottata**: architettura a layer indipendenti dove ogni layer
> funziona autonomamente — il sistema non degrada se un layer superiore fallisce.

---

## Il Problema

Azure DevOps è il source of truth per PR, branch e pipeline runs.
Claude Code non ha un canale passivo per ricevere aggiornamenti:
non esiste push, polling automatico o subscription.

Il risultato pratico: a inizio sessione Claude opera su informazioni stantie,
non sa quali PR sono state mergiate, quali branch sono aggiornati,
quali pipeline sono passate o fallite.

---

## Perché una Strategia a Layer (Antifragile)

### Analisi delle alternative

| Approccio | Failure mode | Rilevabilità | Dipendenze |
|-----------|-------------|--------------|------------|
| **Solo webhook → n8n → file** | n8n down → dati stantii in silenzio | nessuna | n8n sempre up |
| **Solo polling script** | ADO API down → errore esplicito | immediata | nessuna extra |
| **Solo handoff manuale** | dipende dalla disciplina umana | dipende | nessuna |

**Webhook + n8n** è potente ma fragile: quando si rompe, non lo sai.
Il dato è lì, sembra fresco, ma è stantio. *Failure silenzioso* = peggiore dei casi.

**Polling script** ha il failure mode migliore: se ADO è irraggiungibile,
l'errore è esplicito e immediato. Non puoi procedere ignorando il problema.

### Principio guida del progetto

> "Misura due, taglia uno — il sistema avvisa, non blocca. L'umano decide."
> *(SourceSyncGuard, Session 31)*

Un sistema antifragile non è quello che non si rompe mai,
è quello che **si rompe in modo visibile** e che **migliora sotto stress**.

---

## Architettura a Layer

```
Layer 2 — Fallback umano (always available)
┌─────────────────────────────────────────────────────┐
│ Handoff document aggiornato a fine ogni sessione    │
│ → se tutto il resto fallisce, l'umano sa lo stato  │
└─────────────────────────────────────────────────────┘
          ↑ copre quando Layer 1 non funziona

Layer 1 — Enhancement event-driven (optional, future)
┌─────────────────────────────────────────────────────┐
│ ADO Webhook → n8n → control-plane/session-state.md │
│ → aggiorna il file ad ogni evento PR/pipeline       │
│ → quando funziona: info pronte prima del briefing   │
│ → quando n8n è down: Layer 0 copre tutto            │
└─────────────────────────────────────────────────────┘
          ↑ copre quando Layer 0 è lento/assente

Layer 0 — Base obbligatoria (zero dipendenze extra)
┌─────────────────────────────────────────────────────┐
│ Get-ADOBriefing.ps1                                 │
│ → query ADO REST API on-demand                      │
│ → output: snapshot PR + branch + pipeline state     │
│ → chiamato da Claude SEMPRE come prima azione       │
│ → se fallisce: errore esplicito, si sa subito       │
└─────────────────────────────────────────────────────┘
```

**Proprietà chiave**: ogni layer è **autonomo**.
- Layer 0 non dipende da Layer 1.
- Layer 1 non è richiesto per Layer 1 funzioni.
- Il sistema funziona con tutti i layer automatici down (Layer 2 sempre attivo).

---

## Layer 0 — Get-ADOBriefing.ps1

### Posizione
```
scripts/pwsh/Get-ADOBriefing.ps1
```

### Cosa restituisce
- PR aperte verso `develop` e `main`
- PR chiuse nelle ultime 24h (per sapere cosa è stato mergiato)
- SHA corrente di `main` e `develop`
- Pipeline runs recenti (ultime 5)

### Utilizzo

```powershell
# Formato human-readable (default — per lettura diretta)
pwsh scripts/pwsh/Get-ADOBriefing.ps1

# Formato JSON (per elaborazione script)
pwsh scripts/pwsh/Get-ADOBriefing.ps1 -Json

# Filtra solo PR aperte
pwsh scripts/pwsh/Get-ADOBriefing.ps1 -OnlyOpen
```

### Regola operativa (NON DEROGABILE)

> **Claude chiama `Get-ADOBriefing.ps1` come PRIMA azione di ogni sessione**,
> prima di qualsiasi decisione su branch, PR o deploy.
>
> Se il briefing fallisce (ADO irraggiungibile), **fermarsi e segnalarlo**.
> Non procedere su informazioni stantie.

---

## Layer 1 — ADO Webhook → n8n (PLANNED)

### Architettura

```
ADO Service Hook (PR Completed / Pipeline Failed)
    ↓ HTTP POST a http://server:5678/webhook/ado-events
n8n Workflow "ADO Event Processor"
    ↓
Aggiorna control-plane/session-state.md
    ↓ git commit + push (via PAT)
File disponibile nel repo per lettura
```

### Configurazione richiesta (quando implementato)
1. ADO → Project Settings → Service Hooks → Web Hooks
   - Event: `Pull Request Merged`, `Build Completed`
   - URL: `http://80.225.86.168:5678/webhook/ado-events` (o via Caddy reverse proxy)
2. n8n workflow che legge il payload e aggiorna `session-state.md`
3. PAT con `Code (Read & Write)` per il commit automatico

### Note di sicurezza
- Il webhook endpoint n8n NON deve essere esposto pubblicamente senza autenticazione
- Usare shared secret nel header `X-ADO-Secret` + validazione in n8n
- Caddy può fare da reverse proxy con rate limiting

---

## Layer 2 — Handoff Manuale

Ogni sessione termina con un blocco HANDOFF nel messaggio finale che include:
- PR aperte/chiuse durante la sessione
- Branch state
- Prossime azioni prioritarie

Questo è il fallback umano garantito — zero dipendenze tecniche.

---

## Stato di Implementazione

| Layer | Stato | Note |
|-------|-------|------|
| Layer 0 — Get-ADOBriefing.ps1 | **DONE** | `scripts/pwsh/Get-ADOBriefing.ps1` |
| Layer 1 — n8n webhook | PLANNED | Dopo agent_pr_conflict_resolver |
| Layer 2 — Handoff manuale | ACTIVE | Ogni fine sessione |

---

## Riferimenti
- `platform-operational-memory.md §5e` — regola operativa session bootstrap
- `scripts/pwsh/Get-ADOBriefing.ps1` — implementazione Layer 0
- `control-plane/session-state.md` — file di stato (Layer 1, futuro)
- `control-plane/agents-missing-roadmap.md` — roadmap agent_pr_conflict_resolver
