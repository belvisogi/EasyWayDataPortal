---
id: docs-conventions
title: EasyWayData Portal – Regole Semplici (La Nostra Bibbia)
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
# EasyWayData Portal – Regole Semplici (La Nostra Bibbia)

Scopo: rendere la wiki chiara per persone e AI. Anche un bambino di 6 anni può capirla. Regole brevi, esempi chiari, sempre uguali.

## 1) Nomi di file e cartelle (semplici)
- Solo minuscole, trattini `-`, numeri. Niente spazi, niente `%2D`, niente accenti, niente backtick/quote.
- Forma: kebab-case (es: `login-flussi-onboarding.md`).
- Evita maiuscole (es: `README.md` → `readme.md` se serve coerenza locale).
- Esempi di rinomina:
  - `api-esterne-integrazione.md` → `api-esterne-integrazione.md`
  - `GET-CRUD-`api_users`.md` → `get-crud-api-users.md`
  - `best-practice-naming-and-scalability.md` → `best-practice-naming-and-scalability.md`

## 1.1) Convenzione di Nomenclatura – kebab-case vs snake_case

---

---

title: Convenzione di Nomenclatura – kebab-case vs snake_case
tags: [standard, naming, ai, database, api, frontend]

# 🧭 Linea Guida EasyWay Data Portal  
## Uso di kebab-case e snake_case per AI, DB e API

### 🎯 Obiettivo
Garantire coerenza semantica e tecnica nell’intero ecosistema EasyWay Data Portal, migliorando:
- leggibilità umana e machine-readability,
- comprensione da parte dei modelli AI conversazionali,
- coerenza tra API, database e frontend.

---

### 🔹 1. kebab-case (es. `data-quality-report`)

Usa kebab-case per:
| Contesto | Esempio | Motivo |
|-----------|----------|--------|
| URL / Routing Web | `/dashboard/data-quality-report` | SEO-friendly, leggibile, separa chiaramente i token |
| Slug o ID semantici | `user-profile-settings` | Chiaro per AI e utenti |
| Cartelle e file del frontend | `user-dashboard/summary-view.tsx` | Standard moderno in ambienti web |
| Tag semantici / Ontologie AI | `ai-data-quality` | Aiuta l’AI a riconoscere i concetti distinti |

Motivazione AI: il trattino `-` aiuta la tokenizzazione e la comprensione semantica: `data-quality-report` → `data`, `quality`, `report`.

---

### 🔹 2. snake_case (es. `data_quality_report`)

Usa snake_case per:
| Contesto | Esempio | Motivo |
|-----------|----------|--------|
| Database (SQL Server) | `user_profile_id`, `created_at` | Standard tecnico compatibile e leggibile |
| File CSV / JSON / API payloads | `{ "user_id": 1001 }` | Uniforme e facilmente parsabile |
| Script o codice server-side | `def process_user_data():` | Convenzione tecnica consolidata |
| Chiavi di configurazione/metadati | `portal_schema_name` | Evita ambiguità con trattini nei parser |

Motivazione AI: gli underscore sono neutri per la tokenizzazione nei contesti tecnici e non confondono interpreti/parsers.

---

### 🔹 3. Regola generale EasyWay

### Mappa di conversione consigliata (canonico → derivati)

 ```text 
Canonico (slug/tag): kebab-case    es. user-profile-settings
snake_case (DB/payload):           user_profile_settings
PascalCase (classi/DTO):           UserProfileSettings
camelCase (variabili/JS):          userProfileSettings
 ``` 

Regola: il canonico è kebab-case; gli altri sono derivati meccanici per il dominio tecnico di riferimento.

| Ambito | Formato raccomandato |
|---------|----------------------|
| Database (colonne, tabelle, viste) | snake_case |
| API REST (endpoint URL) | kebab-case |
| Frontend Web / React component path | kebab-case |
| Script o variabili codice server | snake_case |
| AI Conversational / Prompt / Tag semantici | kebab-case |
| File system / repository folders | kebab-case |

---

### 🔹 4. Esempio di coerenza complessiva

| Componente | Nome coerente |
|-------------|----------------|
| Tabella DB | `portal_user_profile` |
| API REST | `/api/user-profile/details` |
| File Frontend | `/components/user-profile/details-view.tsx` |
| Variabile Server | `user_profile_id` |
| Prompt AI | `explain-user-profile-data-quality` |

---

### 🔹 5. Note di standardizzazione

- I trattini `-` non devono mai essere usati nei nomi di variabili o tabelle (incompatibile con SQL/Python).  
- Gli underscore `_` non devono mai essere usati negli URL o nei tag AI.  
- Ogni parola deve essere in minuscolo ASCII (niente accenti/simboli; `&` → `and`).  
- I separatori devono essere coerenti con il contesto (nessun mix `data_quality-report`).

Quick Check (regex)
```text
# Slug (senza estensione)
kebab-case: ^[a-z0-9]+(?:-[a-z0-9]+)*$
snake_case: ^[a-z0-9]+(?:_[a-z0-9]+)*$

# File con estensione (comune)
kebab-case file .md: ^[a-z0-9]+(?:-[a-z0-9]+)*\.md$
snake_case file .md: ^[a-z0-9]+(?:_[a-z0-9]+)*\.md$

# File con estensioni permesse
kebab-case: ^[a-z0-9]+(?:-[a-z0-9]+)*\.(?:md|yml|yaml|json|sql|ps1)$
snake_case: ^[a-z0-9]+(?:_[a-z0-9]+)*\.(?:md|yml|yaml|json|sql|ps1)$

# Percorsi (normalizza i separatori a / prima del match)
# es.: $path.Replace('\\','/') -match ...
path kebab-case: ^(?:[a-z0-9]+(?:-[a-z0-9]+)*/)*[a-z0-9]+(?:-[a-z0-9]+)*\.(?:md|yml|yaml|json|sql|ps1)$
path snake_case: ^(?:[a-z0-9]+(?:_[a-z0-9]+)*/)*[a-z0-9]+(?:_[a-z0-9]+)*\.(?:md|yml|yaml|json|sql|ps1)$
```text

Note pratiche
- Usa il trattino ASCII “-” U+002D, non i trattini tipografici (–, —).
- Niente doppie/estreme: no `--`, `__`, `-nome`, `nome-`.
- I check sono pensati per “slug” e per “file.ext”: applica la regex giusta per il contesto.
- È normale applicare più passate di pulizia (come setacciare la farina): prima i casi evidenti (percent-encoding, maiuscole), poi i dettagli (accenti, simboli), poi l’allineamento finale.

Eccezioni del linter (whitelist ragionata)
- File di servizio e allegati: `.gitignore`, `**/.order`, `**/.attachments/**` (esclusi dai check)
- Meta della root: `ACTIVITY_LOG.md`, `DOCS_CONVENTIONS.md`, `LLM_READINESS_CHECKLIST.md`, `TODO_CHECKLIST.md`, `INDEX.md` (tenuti in UPPERCASE per riconoscibilità)
- Segmenti legacy (solo path check): `EasyWay_WebApp/`, `01_database_architecture/`, `01b_schema_structure/` (il controllo path è disattivato per questi segmenti finché non si pianifica una migrazione)

Strategia di miglioramento iterativo
- Prima riduci il rumore con whitelist minime e rename a basso rischio.
- Poi affronta rinomine di cartelle legacy (se necessario) con aggiornamento link e indici.
- Gli script `review-examples.ps1` e `review-run.ps1` recepiscono queste eccezioni e possono essere estesi in futuro.

Anti-pattern comuni: `Data_Quality`, `data_quality-report`, `UserProfile`, `dataquality`, `data-quality_2024`.

## 2) Struttura delle pagine (sempre uguale)
Ogni pagina Markdown segue questo ordine di sezioni (H2/H3 chiari):
- Scopo (perché esiste questa pagina)
- Prerequisiti (cosa serve prima)
- Passi (step 1, 2, 3… chiari e corti)
- Esempi (codice o comandi reali)
- Errori comuni (come riconoscerli, come risolverli)
- Domande a cui risponde (3–7 Q&A brevi)
- Collegamenti (2–5 link utili a pagine sorelle)

Scrittura: frasi brevi, parole semplici, niente “vedi sopra/sotto”. Evita termini ambigui. Se usi sigle, spiega la prima volta.

## 3) Metadati in testa (front matter YAML)
Metti questo blocco all’inizio di ogni `.md` (sopra il titolo):

```text
---
id: ew-<slug-unico>
title: Titolo umano breve
summary: 1–2 frasi semplici sul contenuto
status: draft | review | approved | deprecated
owner: team-api | team-data | team-ops | team-frontend
created: '2025-01-01'
updated: '2025-01-01'
tags:
  - domain/webapp
  - layer/how-to
  - artifact/endpoint
  - audience/dev
  - privacy/internal
  - language/it
intents:
  - cosa vuoi fare (es: creare tabella pippo)
llm:
  include: true
  pii: none | contains-pii
  chunk_hint: 400-600
  redaction: [email, phone]
entities: []  # id da entities.yaml
---
```text

Note:
- `summary` è fondamentale: aiuta la ricerca e l’AI.
- `tags` e `entities` migliorano risposte precise.
- `llm.include: false` per file da NON esporre all’AI.

## 4) Macro cartelle (semplici e chiare)
- `01-architettura/` (db, backend, frontend, integrazioni)
- `02-api/` (linee guida, endpoint, test)

## Domande a cui risponde
- Quali convenzioni usare per nomi di file, cartelle e slug?
- Quando scegliere kebab-case e quando snake_case nei diversi contesti?
- Qual è la struttura minima di una pagina e quali metadati servono?
- Come scrivere esempi e codice in modo uniforme e AI‑friendly?
- Quali eccezioni/whitelist adotta il linter e perché?
- `03-datalake/` (naming, accesso, pipeline)
- `04-security-compliance/` (IAM, policy, audit, PII)
- `05-operations/` (deploy, iac, logging, runbook)
- `06-flussi-prodotto/` (onboarding, notifiche, use case)

Mantieni nomi brevi e chiari. Se serve ordinare, usa prefissi locali `01-`, `02-`.

## 5) Regole per codice, tabelle e API (norme MUST)
- Sempre idempotente: script che non rompono se rilanciati.
- Commenti chiari: spiega cosa fa e perché.
- Esempi reali: richieste/risposte API, DDL tabelle, query.

### 5.1 Database (DBA)
- Nomi: `snake_case`, singolare per tabelle (es: `pippo`).
- PK: `<table>_id`. Default UTC per `created_at`.
- Vincoli nominati: `pk_`, `fk_`, `idx_`, `ck_`, `df_`.
- Soft delete (se serve): `deleted_at` + vista filtrata.
- Esempio base (SQL Server):

```text
IF OBJECT_ID('portal.pippo','U') IS NULL
BEGIN
  CREATE TABLE portal.pippo (
    pippo_id INT IDENTITY(1,1) NOT NULL,
    name NVARCHAR(200) NOT NULL,
    status TINYINT NOT NULL CONSTRAINT df_pippo_status DEFAULT (1),
    created_at DATETIME2(3) NOT NULL CONSTRAINT df_pippo_created_at DEFAULT (SYSUTCDATETIME()),
    updated_at DATETIME2(3) NULL,
    deleted_at DATETIME2(3) NULL,
    CONSTRAINT pk_pippo PRIMARY KEY CLUSTERED (pippo_id),
    CONSTRAINT ck_pippo_status CHECK (status IN (0,1))
  );
END
GO

CREATE INDEX idx_pippo__status ON portal.pippo (status);
GO
```text

Checklist DBA (rapida): nomi ok, idempotenza ok, default UTC, indici, FK, commenti.

### 5.2 API (Backend)
- Rotte chiare: `/api/config`, `/api/branding`, `/api/users`.
- Specifica sempre: metodo, path, input, validazioni, output, errori.
- Esempi `curl` e JSON ben formattati.

### 5.3 ETL / Datalake
- Descrivi: sorgente, mapping, regole qualità, schedule, output.
- Formati chiari: schema colonne (nome, tipo, null, note).
- Riferimento: ETL/ELT Playbook e Template per pipeline (vedi Wiki: etl-elt-playbook, etl-elt-template).

### 5.4 AMS / Operazioni
- Runbook semplici: come avviare/fermare, verifiche salute, log utili.
- Allarmi: cosa scatta, dove arriva, come si gestisce.

### 5.5 Analista / BI
- Definisci metriche: nome, formula, fonte, filtro.
- Dashboard: obiettivo, utenti, viste chiave, drilldown.

## 6) “Ricette” per l’AI (task standard)
Ogni ricetta descrive input minimi, output obbligatori, esempi buoni/cattivi.
- create-table: usa schema DB di sopra (DDL completo + indici + rollback).
- create-endpoint: route, DTO, validazioni, esempi request/response.
- create-job-etl: sorgente→sink, mapping, qualità dati, schedule, monitoraggio.

## 7) Domande a cui le pagine devono rispondere
- Cosa fa? Per chi? Con quali passi? Con quali input? Cosa esce? Come verifico? Cosa può andare storto? Dove trovo altro?

## 8) Piccole regole d’oro
- Una idea per paragrafo. Frasi brevi. Parole semplici.
- Niente immagini di testo (usa codice). Diagrammi in `mermaid` se servono.
- Date ISO-8601, orari UTC. Evita “oggi/ieri”.

## 9) Activity Log del progetto (CSV-friendly)
- Formato riga: `timestampUTC¦type¦scope¦status¦owner¦message`
- Timestamp UTC: `yyyyMMddHHmmssZ` (es: `20250101120000Z`)
- Delimitatore: barra spezzata `¦` per separare i campi in modo sicuro nei CSV
- Una azione per riga; descrizione breve senza newline

Esempi
```text
20250101120000Z¦SCAN¦wiki¦success¦team-docs¦Scansione H1–H3 e naming issues
20250101123000Z¦RENAME¦endpoint¦success¦team-api¦Rinominato endp-002-get-api-branding.md
20250101124500Z¦DOC¦conventions¦success¦team-docs¦Aggiornata guida kebab-case vs snake_case
```text

Append veloce (PowerShell)
```text
$ts = (Get-Date).ToUniversalTime().ToString('yyyyMMddHHmmss');
$type='DOC'; $scope='conventions'; $status='success'; $owner='team-docs'; $msg='Aggiornata guida naming';
Add-Content EasyWayData.wiki/ACTIVITY_LOG.md ("${ts}Z¦${type}¦${scope}¦${status}¦${owner}¦${msg}")
```text

Script dedicato
- Usa lo script helper per appending strutturato:
```text
EasyWayData.wiki/scripts/add-log.ps1 -Type DOC -Scope conventions -Status success -Owner team-docs -Message "Aggiornata guida naming"
```text

Opzioni di split e mirror
- Parametri aggiuntivi:
  - `-Split none|monthly|scope` (default: `none`)
  - `-MirrorToMaster $true|$false` (default: `true`)
- Esempi:
```text
# Log in master + log mensile in logs/date/yyyymm.log
EasyWayData.wiki/scripts/add-log.ps1 -Type DOC -Scope conventions -Status success -Owner team-docs -Message "Aggiornata guida naming" -Split monthly

# Log in master + log per ambito in logs/scope/endpoint.log
EasyWayData.wiki/scripts/add-log.ps1 -Type RENAME -Scope endpoint -Status success -Owner team-api -Message "Rinominati 3 file endpoint" -Split scope

# Solo log per ambito, senza master (sconsigliato)
EasyWayData.wiki/scripts/add-log.ps1 -Type LINT -Scope wiki -Status warn -Owner team-docs -Message "Naming checker warning" -Split scope -MirrorToMaster:$false
```text

## 10) Script revisione doc (PowerShell)
Snippet pronti per controlli ricorrenti. Copia/incolla e adatta.

1) Check naming (slug/file/percorso) e report non conformi
```text
$ErrorActionPreference='Stop'
$root = 'EasyWayData.wiki'
$slugRx = '^[a-z0-9]+(?:-[a-z0-9]+)*$'
$fileRx = '^[a-z0-9]+(?:-[a-z0-9]+)*\.(?:md|yml|yaml|json|sql|ps1)$'
$pathRx = '^(?:[a-z0-9]+(?:-[a-z0-9]+)*/)*[a-z0-9]+(?:-[a-z0-9]+)*\.(?:md|yml|yaml|json|sql|ps1)$'
Get-ChildItem -Path $root -Recurse -File | ForEach-Object {
  $name = $_.Name; $slug = [IO.Path]::GetFileNameWithoutExtension($name)
  $path = ($_.FullName -replace '\\','/')
  $issues = @()
  if ($name -cmatch '[A-Z]') { $issues += 'uppercase' }
  if ($name -match '%[0-9A-Fa-f]{2}') { $issues += 'percent-encoded' }
  if ($name -match '[`"\'']') { $issues += 'quotes/backticks' }
  if ($name -match '�') { $issues += 'encoding-char' }
  if ($slug -notmatch $slugRx) { $issues += 'slug' }
  if ($name -notmatch $fileRx) { $issues += 'file' }
  if (($path -replace '^.+?/EasyWayData\.wiki/','') -notmatch $pathRx) { $issues += 'path' }
  if ($issues.Count) { '{0} | {1}' -f $path, ($issues -join ',') }
}
```text

2) Aggiungi front matter minimo se assente (funzione riusabile)
```text
function Add-FrontMatter($path, $id, $title, $tags){
  if (!(Test-Path -LiteralPath $path)) { return }
  $content = Get-Content -LiteralPath $path -Raw -Encoding UTF8
  if ($content -match '(?s)^---\s*\n') { return }
  $fm = @(
    '---',
    "id: $id",
    "title: $title",
    'summary: Breve descrizione del documento.',
    'status: draft',
    'owner: team-docs',
    "created: '2025-01-01'",
    "updated: '2025-01-01'",
    'tags:',
    "  - $tags",
    '  - privacy/internal',
    '  - language/it',
    'llm:',
    '  include: true',
    '  pii: none',
    '  chunk_hint: 400-600',
    '  redaction: [email, phone]',
    'entities: []',
    '---',''
  ) -join "`n"
  Set-Content -LiteralPath $path -Value ($fm + $content) -Encoding UTF8
}
```text

3) Aggiornamento link in blocco (mappa vecchio→nuovo)
```text
$map = @{
  'vecchio-nome.md' = 'nuovo-nome.md'
  'cartella%2Dold' = 'cartella-old'
}
Get-ChildItem -Path 'EasyWayData.wiki' -Recurse -File -Filter *.md | ForEach-Object {
  $c = Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8
  $orig = $c
  foreach($k in $map.Keys){ $c = $c -replace [regex]::Escape($k), $map[$k] }
  if($c -ne $orig){ Set-Content -LiteralPath $_.FullName -Value $c -NoNewline -Encoding UTF8 }
}
```text

4) Estrazione heading H1–H3 (per generare indici)
```text
Get-ChildItem -Path 'EasyWayData.wiki' -Recurse -File -Filter *.md | ForEach-Object {
  $rel = (Resolve-Path -Relative $_.FullName)
  Get-Content -LiteralPath $_.FullName -Encoding UTF8 | Where-Object { $_ -match '^(#|##|###)\s+' } | ForEach-Object {
    '{0}`t{1}' -f $rel, $_
  }
}
```text

5) Appendi al log (master + split)
```text
EasyWayData.wiki/scripts/add-log.ps1 -Type LINT -Scope wiki -Status success -Owner team-docs -Message "Naming check eseguito" -Split monthly
```text

Nota: questi snippet sono “setacci” incrementali. È normale ripassarli più volte e affinare i controlli via via che emergono casi bordo.

Riferimento script consolidato
- Usa le funzioni già pronte in: `EasyWayData.wiki/scripts/review-examples.ps1`
- Carica in sessione: `. EasyWayData.wiki/scripts/review-examples.ps1`
- Esempi:
```text
. EasyWayData.wiki/scripts/review-examples.ps1
Get-NameCompliance -Root 'EasyWayData.wiki' -Mode kebab | Out-Host
Write-Activity -Type LINT -Scope wiki -Status success -Owner team-docs -Message 'Naming check eseguito' -Split monthly
```text

Task runner (one-shot)
- Usa l’orchestratore: `EasyWayData.wiki/scripts/review-run.ps1`
- Parametri principali:
  - `-Root` (default: repo wiki)
  - `-Mode kebab|snake|both` (default: kebab)
  - `-FrontMatterCsv fm.csv` (Path,Id,Title,Tags,Owner,Summary)
  - `-LinksMapCsv links.csv` (Old,New)
  - `-IndexFolders @('path1','path2',...)`
  - `-Split none|monthly|scope` (default: monthly)
  - `-NoGlobalIndex` (disabilita la generazione dell’indice globale)
  - Esempio:
```text
EasyWayData.wiki/scripts/review-run.ps1 -FrontMatterCsv fm.csv -LinksMapCsv links.csv -Mode kebab -IndexFolders @(
  'EasyWayData.wiki/EasyWay_WebApp/05_codice_easyway_portale/easyway_portal_api/ENDPOINT',
  'EasyWayData.wiki/EasyWay_WebApp/02_logiche_easyway'
)
```text
  - Esempio senza indice globale:
```text
EasyWayData.wiki/scripts/review-run.ps1 -FrontMatterCsv fm.csv -LinksMapCsv links.csv -Mode kebab -NoGlobalIndex
```text

Esempi CSV
- Front matter CSV di esempio: `EasyWayData.wiki/scripts/examples/fm.csv`
- Link mapping CSV di esempio: `EasyWayData.wiki/scripts/examples/links.csv`

Indice Globale (obbligatorio)
- Mantieni sempre aggiornato `EasyWayData.wiki/INDEX.md` con H1/H2.
- Genera con la funzione pronta:
```text
. EasyWayData.wiki/scripts/review-examples.ps1
New-RootIndex -Root 'EasyWayData.wiki'
```text
- L’orchestratore `review-run.ps1` può essere esteso per includerlo automaticamente nelle run periodiche.

Entities Index
- Consulta l’elenco centralizzato delle entità: `EasyWayData.wiki/ENTITIES_INDEX.md`
- Fonte dati: `EasyWayData.wiki/entities.yaml` (mantenerlo allineato durante le revisioni)


## 5bis) Code fence (linguaggi ammessi)
- Usa sempre il linguaggio nei blocchi: `sql, `sh/`ash, `powershell, `json, `yaml, `js/`	s/`	sx, `python, `	ext.
- Default per SQL/DDL/DML: `sql. Per testo puro: `	ext.
- Evita fence senza lingua (aumentano l ambiguità per lAI e i tool di evidenziazione).
- LLM Front‑Matter (OBBLIGATORIO per le pagine Wiki)
  - Ogni pagina deve iniziare con front‑matter YAML con i campi: `id`, `title`, `summary`, `status`, `owner`, `tags`, `llm.include`, `llm.chunk_hint`, `llm.pii`, `llm.redaction`, `entities`.
  - Esempio:
    ---
    id: ew-argos-overview
    title: ARGOS – Overview e Integrazione
    summary: Integrazione ARGOS (gates, DSL, playbook, eventi)
    status: active
    owner: team-platform
    tags: [argos, dq, agents, language/it]
    llm:
      include: true
      pii: none
      chunk_hint: 250-400
      redaction: [email, phone]
    entities: []
    ---
  - Enforcement: il job di pipeline “Wiki LLM Front‑Matter Lint” fallisce se mancano i campi richiesti.
