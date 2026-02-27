---
title: Multi-Environment Docker Strategy (DEV / CERT / PROD)
tags: [domain/deployment, layer/spec, audience/ops, audience/dev, privacy/internal, language/it, docker, environments, dev, cert, prod]
status: active
updated: 2026-02-27
id: ew-deployment-multi-environment-docker-strategy
type: guide
summary: Strategia per eseguire ambienti DEV e CERT in isolamento logico sullo stesso server OCI, senza necessità di infrastruttura aggiuntiva. PROD su server separato in futuro.
owner: team-platform
llm:
  include: true
  pii: none
  chunk_hint: 5000
  redaction: [email, phone]
pii: none
---

[[../start-here.md|Home]] > [[../deployment/|Deployment]] > Multi-Environment Docker Strategy

# Multi-Environment Docker Strategy (DEV / CERT / PROD)

## Contesto

Il team ha un singolo server OCI (Ubuntu, `80.225.86.168`). Non è necessario un secondo
server per avere ambienti DEV e CERT separati: si usa **isolamento logico via Docker**,
due stack indipendenti sulla stessa macchina.

Il modello di branch (`develop → DEV`, `release/* → CERT`, `main → PROD`) funziona
identicamente su uno o più server — cambia solo dove punta il deploy, non le regole Git.

---

## Architettura target

```
Ubuntu OCI (80.225.86.168)
│
├─ Stack DEV  (docker compose -p easyway-dev)
│   ├─ frontend        → porta 3000
│   ├─ portal-api      → porta 3001
│   ├─ azure-sql-edge  → porta 1433 (dev)
│   └─ rete: easyway-dev-network
│
└─ Stack CERT  (docker compose -p easyway-cert)
    ├─ frontend        → porta 4000
    ├─ portal-api      → porta 4001
    ├─ azure-sql-edge  → porta 1434 (cert)
    └─ rete: easyway-cert-network

Nginx/Traefik (reverse proxy)
    ├─ dev.easyway.internal  → :3000
    └─ cert.easyway.internal → :4000
```

I due stack non condividono né rete né volumi — i dati sono completamente isolati.

---

## Mapping branch → ambiente → stack

| Branch | Ambiente | Stack Docker | Trigger deploy |
| :--- | :--- | :--- | :--- |
| `develop` | **DEV** | `easyway-dev` | Merge su `develop` (pipeline CI) |
| `release/*` | **CERT** | `easyway-cert` | Creazione branch `release/*` (pipeline CI) |
| `main` | **PROD** | server separato (futuro) | PR `release/*` → `main` mergiata |

---

## Isolamento: cosa è separato per stack

| Risorsa | DEV | CERT |
| :--- | :--- | :--- |
| Container names | `easyway-dev-frontend` | `easyway-cert-frontend` |
| Porte host | 3000/3001/1433 | 4000/4001/1434 |
| Volumi Docker | `easyway-dev-*` | `easyway-cert-*` |
| Database | `easyway_dev` | `easyway_cert` |
| File `.env` | `.env.dev` | `.env.cert` |
| Network Docker | `easyway-dev-network` | `easyway-cert-network` |

---

## File di configurazione

### `docker-compose.dev.yml`
Override per DEV: porte 3000/3001, DB dev, hot-reload abilitato.

### `docker-compose.cert.yml`
Override per CERT: porte 4000/4001, DB cert, hot-reload disabilitato, configurazione
più vicina alla produzione.

### `.env.dev` / `.env.cert`
Variabili di ambiente separate per database, API keys, feature flags.
NON committare — gestiti via `/opt/easyway/.env.secrets` sul server (per le secrets condivise)
e file separati per le variabili ambiente-specifiche.

---

## Deploy pipeline: come funziona

### Merge su `develop` → deploy su DEV

```yaml
# azure-pipelines.yml — stage DeployDev
- stage: DeployDev
  condition: eq(variables['Build.SourceBranch'], 'refs/heads/develop')
  steps:
    - script: |
        ssh ubuntu@80.225.86.168 '
          cd ~/EasyWayDataPortal &&
          git pull origin develop &&
          docker compose -p easyway-dev -f docker-compose.yml -f docker-compose.dev.yml up -d --build
        '
```

### Creazione `release/*` → deploy su CERT

```yaml
# azure-pipelines.yml — stage DeployCert
- stage: DeployCert
  condition: startsWith(variables['Build.SourceBranch'], 'refs/heads/release/')
  steps:
    - script: |
        ssh ubuntu@80.225.86.168 '
          cd ~/EasyWayDataPortal &&
          git pull origin $RELEASE_BRANCH &&
          docker compose -p easyway-cert -f docker-compose.yml -f docker-compose.cert.yml up -d --build
        '
```

---

## Percorso di adozione

```
FASE 1 (ora)      → un server, stack DEV già attivo (invariato)
                    aggiungere stack CERT con docker-compose.cert.yml

FASE 2 (futuro)   → PROD su server separato (quando go-live)
                    stessa pipeline, solo endpoint SSH diverso
```

La fase 2 non richiede cambiamenti alla pipeline CI né alle regole Git — solo
una variabile `PROD_SERVER` diversa nello step di deploy.

---

## Considerazioni operative

### Risorse server
Due stack sullo stesso server consumano circa il doppio delle risorse.
Monitorare CPU/RAM — se CERT è inattivo (fuori UAT), si può spegnere:
```bash
docker compose -p easyway-cert down   # spegne CERT senza perdere dati
docker compose -p easyway-cert up -d  # riaccende quando serve UAT
```

### Backup dati CERT
I dati CERT sono effimeri per natura (UAT reset tra un ciclo e l'altro), ma è buona
pratica fare dump del DB prima di ogni deploy CERT per poter ripristinare in caso di
test distruttivi.

### Feature flags per ambiente
Il modo più pulito per differenziare il comportamento DEV vs CERT è tramite variabile
in `.env.dev` / `.env.cert`:
```
ENVIRONMENT=dev   # oppure cert
FEATURE_FT3=false # disabilitato in CERT, abilitato in DEV
```

---

## Vedi anche

- [[../standards/gitlab-workflow.md|GitLab Workflow Standard — Environment Mapping]]
- [[../control-plane/release-use-cases.md|Release Use Cases — Rilasci Selettivi e Interventi Urgenti]]
- [[production-deployment-2026-02-07.md|Production Deployment Log 2026-02-07]]
- [[../control-plane/index.md|Control Plane — Panoramica]]
