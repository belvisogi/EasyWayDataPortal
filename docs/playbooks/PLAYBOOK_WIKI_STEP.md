# PLAYBOOK_WIKI_STEP – Step Wiki EasyWayDataPortal

## Scopo

Definire come l’agente deve lavorare sulle pagine `step-N-*.md` della **wiki EasyWayDataPortal** in modo:

- coerente con lo stile della wiki,
- LLM‑ready (Q&A, Prerequisiti, Passi, Verify),
- non “orfano” (buona rete di link in ingresso/uscita),
- sicuro rispetto agli strumenti usati,
- allineato al comportamento atteso dagli **agent** definiti in `agents/*` e dagli script `scripts/wiki-*`.

Questo playbook **estende** le regole generali di `PLAYBOOK_GLOBAL.md`.

---

## Quando usare questo playbook

Usalo quando il task riguarda uno o più file:

- sotto `Wiki/EasyWayData.wiki/...` (root canonica della documentazione EasyWayDataPortal),
- con nome che segue il pattern: `step-N-qualcosa.md`, ad esempio:
  - `step-1-setup-ambiente.md`
  - `step-4-query-dinamiche-locale-datalake.md`
  - `step-5-validazione-avanzata-dati-in-ingresso.md`
- oppure file "child" dentro la cartella dello step, ad esempio:
  - `step-5-validazione-avanzata-dati-in-ingresso/validazione-avanzata.md`

### Nota su naming legacy

Nella wiki esistono pagine legacy con naming non conforme, ad esempio:

- `STEP-2-—-Struttura-src-e-primi-file.md`
- file con maiuscole, caratteri speciali, spazi, percent‑encoding.

Regole:

- Per i **nuovi step** usare sempre `step-n-...` in `kebab-case` ASCII sotto `Wiki/EasyWayData.wiki/...`.
- Se incontri un **legacy**:
  - Non cancellare né spostare subito.
  - Prima aggancia il contenuto alla catena degli step (index / `Vedi anche` / link dai parent).
  - Valuta una migrazione in 2 fasi:
    1. `canonical-copy+redirect-note` (nuovo file canonico + stub legacy).
    2. (Opzionale, in una wave dedicata) spostamento fisico in `old/wiki/` quando i link sono stati aggiornati.

Esempi di task tipici:

- “mi sistemi lo step‑5, lo vedo orfano”
- “allinea lo step‑N con gli index/anchors”
- “aggiungi FAQ, edge case e cross‑link allo step‑X”
- “normalizza i legacy STEP-* in coppia canonico + stub e prepara lo spostamento in old/wiki”.

---

## Tool consentiti per questo playbook

Valgono sempre le regole di `PLAYBOOK_GLOBAL.md`. In aggiunta, per i task WIKI_STEP l’agente può:

- usare **in autonomia**:
  - `search_files`, `list_files`, `read_file`
  - `replace_in_file` per modificare porzioni dei `.md`
  - `write_to_file` solo per:
    - creare nuovi playbook in `.axetrules/`
    - creare nuovi file markdown di wiki quando esplicitamente richiesto (es. nuova pagina canonica step‑N)
- usare `execute_command` **solo** per:
  - script `wiki-*` nella cartella `scripts/` (normalize, index, anchors, gap, related-links, ecc.)
  - comandi non distruttivi che lavorano su file wiki/indici/report

Non è autorizzato:

- cancellare file wiki,
- modificare codice applicativo (TS/JS/infra) come parte di PLAYBOOK_WIKI_STEP,
- eseguire script di deploy o comandi su DB.

---

## Passi operativi standard (step-N)

Per ogni task su uno `step-N-*.md`, l'agente segue questi 4 passi.

### 0. Report file non conformi + proposta migrazione “safe” (best practice)

Quando in un'area Wiki sono presenti file legacy/non conformi (maiuscole, caratteri speciali, percent-encoding, ecc.), prima di proporre rinomine è consigliato produrre:

1. **Report** dei file non conformi (output in `Wiki/EasyWayData.wiki/logs/reports/`, nessuna modifica ai contenuti se `-DryRun`):

   ```powershell
   pwsh Wiki/EasyWayData.wiki/scripts/review-run.ps1 -Root Wiki/EasyWayData.wiki -Mode kebab -CheckAnchors -DryRun
   ```

2. **Proposta migrazione safe** (artefatto in `out/`), con tabella tipo:

   | File | Issue | Azione proposta | New path (se applica) | Link map? | Note |
   |---|---|---|---|---|---|

Azioni ammesse (safe-by-default):

- `keep+link`: non rinominare; agganciare via indici/`Vedi anche`.
- `canonical-copy+redirect-note`: creare copia canonica in `kebab-case` e lasciare nel legacy una nota di redirect + `status: deprecated` (se applicabile).
- `rename+linkmap`: rinominare/spostare **solo** se puoi aggiornare tutti i link (usando una link map) e accetti l'impatto su riferimenti esterni.

### 0.b Strategia `canonical-copy+redirect-note` + old/wiki

Soluzione tecnica raccomandata:

1. Crea il file **canonico** `kebab-case` in `Wiki/EasyWayData.wiki/...`, con:
   - `id` pulito (`step-n-...`),
   - front‑matter completo (`status: draft` o `published`),
   - sezioni standard (Perché serve, Domande a cui risponde, Prerequisiti, Passi, Verify, Vedi anche),
   - `llm.include: true`.

2. Nel file **legacy**:
   - Imposta:
     - `status: deprecated`
     - `canonical: ./<nuovo-file-canonico>.md`
     - `llm.include: false`
     - un tag aggiuntivo tipo `status/deprecated` se utile al tagging.
   - Nel contenuto mantieni solo una **nota di redirect** + link alla pagina canonica (stub minimale):
     ```md
     > **Questa pagina è legacy / non canonica.**  
     > Usa la versione aggiornata e indicizzata per gli agent:
     >
     > - [Titolo canonico](./step-n-qualcosa.md)
     ```

3. (Fase successiva, opzionale, guidata da governance)  
   Spostare il legacy in `old/wiki/` **solo quando**:
   - tutti i link interni sono stati aggiornati al file canonico,
   - eventuali report `wiki-links-*` e `wiki-index-*` non riportano più riferimenti critici al path legacy,
   - la decisione di spostamento è coerente con la strategia di archiviazione (es. ondata coordinata di cleanup).

---

### 1. Mappare le pagine step-N (parent + child)

1.1. Cercare le occorrenze:

- usare `search_files` con regex tipo `step-5-validazione-avanzata-dati-in-ingresso` o `step-\d-` sotto `Wiki/EasyWayData.wiki`.
- identificare:
  - file parent: `.../step-N-qualcosa.md`
  - file child: `.../step-N-qualcosa/...*.md` (es. `validazione-avanzata.md`)

1.2. Individuare metadati e chunk esistenti:

- leggere da:
  - `Wiki/EasyWayData.wiki/index.md`
  - `index_master.*` (csv/jsonl)
  - `chunks_master.jsonl`
- capire se esistono già:
  - `summary`, `anchors`, `Q&A`, ecc. che possono essere riusati nel markdown.

---

### 2. Allineare contenuto del parent (how‑to)

Per il file parent `step-N-*.md`:

2.1. Struttura minima da garantire

- Front‑matter con almeno:
  - `id`, `title`, `tags`, `owner`, `summary`, `status`, `llm.*`, `entities`, `updated`
- Sezioni standard LLM‑ready:
  - `### Perché serve` (o equivalente H3 strutturale)
  - blocchi:
    - `## Domande a cui risponde`
    - `## Prerequisiti`
    - `## Passi`
    - `## Verify`
    - `## Vedi anche` (se non già presente)

2.2. Contenuti da riempire (o completare)

- Riutilizzare quanto possibile i testi già presenti in:
  - `chunks_master.jsonl` per quel `doc_id`
  - index master (summary e anchors)
- Per pages come lo **step‑5**:
  - Aggiungere sezioni specifiche (es. Zod vs Joi, esempio utenti, ecc.) dove previste:
    - `### A. Tecnologia consigliata: ...`
    - `### B. Esempio ...`
    - `### C. ...` (se applicabile)

2.3. Editing

- Usare `replace_in_file` per:
  - aggiungere sezioni mancanti,
  - allineare titoli/ancore a quanto definito in `anchors_master.*`,
  - mantenere lo stile testuale coerente con il resto della wiki.

---

### 3. Collegare parent ↔ child e cross‑link

3.1. Link tra step

- Verificare che lo step:
  - sia raggiungibile da almeno:
    - uno step precedente (es. `step-1-setup-ambiente.md`),
    - l’indice globale (`Wiki/EasyWayData.wiki/index.md`) o indici di sezione.
- Assicurarsi che il parent contenga una sezione tipo `## Vedi anche` con link a:
  - step precedenti/successivi,
  - eventuali orchestrazioni/flow correlati (es. n8n, `atomic_flows`).

3.2. Link parent ↔ child

- Dal parent verso il child:
  - esempio:
    ```md
    - [validazione avanzata](./step-5-validazione-avanzata-dati-in-ingresso/validazione-avanzata.md)
    ```
- Dal child verso il parent:
  - se presente come TODO, convertirlo in link reale:
    ```md
    - [step 5 validazione avanzata dati in ingresso](../step-5-validazione-avanzata-dati-in-ingresso.md)
    ```

3.3. Cross‑link tematici

Quando il task richiede di **arricchire cross‑link / FAQ / edge case** (come per lo step‑5), l’agente può:

- aggiungere link in `## Vedi anche` verso pagine coerenti, ad esempio:
  - gestione log & policy dati sensibili,
  - endpoint reali (`ENDPOINT/endp-001-get-api-config.md`, ecc.),
  - policy API / stored procedure,
  - pagine sul ruolo degli agent (es. `10-ai-agents.md`),
  - checklist di test API, ecc.

I link devono essere:

- **relativi** (stesso stile della wiki),
- coerenti con quanto già indicizzato in `index_master.*` e `link-graph`.

---

### 4. Verificare riferimenti e conformità

4.1. Report wiki (quando disponibili)

- Se il task lo richiede o è utile, l’agente può usare `execute_command` per lanciare script tipo:
  - `wiki-gap-report.ps1`
  - `wiki-index-lint.ps1`
  - `wiki-links-anchors-lint.ps1`
  - `wiki-related-links.ps1` (in modalità report o apply se esplicitamente richiesto)

4.2. Cosa controllare

- Che lo step:
  - non sia più marcato come “missing-file” negli anchor report,
  - sia presente in `index_master.*` con id/title/summary coerenti,
  - abbia le ancore attese (Perché serve, A/B/C, Q&A, Prerequisiti, Passi, Verify),
  - risulti connesso nel `wiki-link-graph` (almeno un link in ingresso, più link in uscita).

---

## Caso speciale: step‑5 validazione avanzata dati in ingresso

Quando il task riguarda `step-5-validazione-avanzata-dati-in-ingresso` e l’utente chiede esplicitamente di:

> “Applica le modifiche che hai proposto allo step‑5:
> - aggiungi sezione FAQ & Edge case con i punti che hai elencato
> - aggiungi i cross-link a log & policy dati sensibili, endp-001 /api/config, policy API/SP e 10-ai-agents
> Modifica direttamente il file step-5-validazione-avanzata-dati-in-ingresso.md usando replace_in_file.”

L’agente è autorizzato a:

1. Aggiungere nel parent una sezione dedicata, ad esempio:

   ```md
   ### FAQ & Edge case

   - **Cosa succede se Zod fallisce la validazione?**
   - **Come gestisco campi opzionali ma con regole di business forti?**
   - **Come distinguo errori di client (400) da errori di sistema (500)?**
   - **Quando ha senso usare Joi invece di Zod?**
   - Edge case: numeri in querystring, date/timezone, array in query, payload grandi, multi‑tenant e `X-Tenant-Id`.
   ```

2. Arricchire `## Vedi anche` con link a:

   - gestione log & policy dati sensibili (`gestione-log-and-policy-dati-sensibili.md`),
   - `ENDPOINT/endp-001-get-api-config.md`,
   - `policy-api-store-procedure-easyway-data-portal.md`,
   - `10-ai-agents.md` o equivalenti.

3. Applicare queste modifiche **direttamente** con `replace_in_file` sul file:

   - `Wiki/EasyWayData.wiki/easyway-webapp/05_codice_easyway_portale/easyway_portal_api/step-5-validazione-avanzata-dati-in-ingresso.md`

senza richiedere ulteriori conferme, purché:

- le modifiche:
  - non cancellino intere sezioni utili,
  - rispettino la struttura esistente,
  - restino all’interno del perimetro wiki.

---

## Criteri di “Done” per un task WIKI_STEP

Un task guidato da questo playbook è completato quando:

- Per ogni step-N coinvolto:
  - il file parent ha front‑matter completo e sezioni:
    - Perché serve,
    - Domande a cui risponde,
    - Prerequisiti,
    - Passi,
    - Verify,
    - più eventuali A/B/C, FAQ & Edge case, Vedi anche dove previsto.
  - esiste almeno un link in ingresso (step precedente o indice) e più link in uscita (child, step collegati, checklist).
- Gli eventuali child rilevanti:
  - puntano correttamente al parent (non restano TODO “orfani”),
  - sono coerenti con il ruolo assegnato (spec, how‑to di dettaglio, ecc.).
- Se sono stati lanciati script wiki:
  - non emergono errori critici per i file appena modificati (missing-file, anchor mismatch, ecc.).
- È chiaro, anche per gli **agent**, quali file sono:
  - canonici (step‑N in kebab-case, `llm.include: true`),
  - legacy con stub (`status: deprecated`, `llm.include: false`, `canonical: ...`),
  - candidati allo spostamento in `old/wiki/` in una wave di cleanup.
- L’agente fornisce nel riepilogo finale:
  - elenco dei file modificati,
  - (eventuali) comandi/script eseguiti,
  - nota esplicita su:
    - legacy trasformati in `canonical + stub`,
    - eventuali TODO rimasti che richiedono decisioni di governance (es. spostamento effettivo in `old/wiki/`).
