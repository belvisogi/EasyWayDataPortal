# Piano di Migrazione Etica, Antifragile e Vendor-Independent
## Evoluzione consapevole della piattaforma DevOps

---

## 1. Scopo del documento

Questo documento definisce un **piano di evoluzione intenzionale** della piattaforma DevOps,
con l’obiettivo di costruire un sistema:

- etico ma pragmatico,
- antifragile nel tempo,
- indipendente da singoli vendor,
- adatto a persone e agenti automatici,
- capace di sopravvivere a cambiamenti improvvisi dello status quo.

Il documento **non descrive una migrazione forzata**  
ma la costruzione di una **assicurazione strutturale di continuità**.

---

## 2. Principio fondante

### Il codice è un bene interno

Il codice sorgente è sempre trattato come un **asset interno e strategico**:

- indipendentemente dal fatto che l’infrastruttura sia interna o esterna,
- indipendentemente dal tool o vendor utilizzato,
- indipendentemente dal modello operativo corrente.

Questo implica:
- piena proprietà,
- piena portabilità,
- piena possibilità di uscita.

L’uso di servizi esterni **non modifica questo principio**.

---

## 3. Principi guida

1. **Nessun tool è permanente**
   - Ogni piattaforma è sostituibile per definizione.

2. **Nessun Big Bang**
   - Le piattaforme possono coesistere.
   - Il cambiamento è sempre volontario.

3. **Portabilità prima delle feature**
   - Le feature non devono creare dipendenze strutturali.

4. **Codice, pipeline e conoscenza sono inseparabili**
   - Tutto ciò che conta deve vivere nel codice.

5. **Agent-first mindset**
   - Il sistema deve essere utilizzabile anche da entità automatiche,
     non solo da persone tramite UI.

---

## 4. Stato attuale

- Piattaforma principale: Azure DevOps
- Repository: Git
- CI/CD: Azure Pipelines
- Issue tracking: Azure Boards
- Documentazione: Wiki DevOps + documentazione informale

Criticità osservate:
- parziale dipendenza da task e configurazioni proprietarie,
- conoscenza non completamente versionata,
- lock-in crescente non intenzionale.

---

## 5. Visione target

- Repository Git standard come fonte di verità
- CI/CD dichiarativo e portabile
- Documentazione versionata nel codice
- Piattaforma DevOps sostituibile
- Agenti automatici come cittadini di prima classe
- Possibilità reale di operare in modalità self-managed

La piattaforma target naturale è **GitLab self-managed / locale**,
ma il valore del documento è **indipendente dal tool specifico**.

---

## 6. Architettura target – GitLab Self-Managed (Locale)

### 6.1 Scelta architetturale

La piattaforma DevOps è prevista in modalità **self-managed / locale** per:

- controllo completo su codice e metadati,
- riduzione del lock-in tecnologico,
- trasparenza per audit e sicurezza,
- supporto naturale agli agenti,
- possibilità di spegnimento o migrazione senza dipendenze esterne.

La piattaforma è considerata **parte dell’architettura**, non un servizio SaaS.

---

### 6.2 Architettura minima iniziale

Componenti:
- GitLab self-managed (Omnibus)
- GitLab Runner
- Storage persistente
- Backup automatici

Configurazione indicativa:
- 1 VM o server
- 4–8 GB RAM
- 2–4 vCPU

Sufficiente per:
- repository Git
- merge request
- issue tracking
- CI/CD
- API per agenti e automazioni

---

### 6.3 Scalabilità

La crescita avviene per addizione:
- runner separati,
- storage esterno,
- alta affidabilità,
- separazione dei servizi.

Nessun redesign forzato.

---

## 7. Gestione dei repository

### 7.1 Modello operativo

- Il repository “ufficiale” vive sul server GitLab.
- È un repository Git standard.
- Gli sviluppatori lavorano sempre in locale.

Flusso standard:
1. clone del repository
2. lavoro locale (branch, commit)
3. push verso il repository centrale
4. merge request, review, CI/CD

GitLab **coordina**, ma non possiede il codice.

---

### 7.2 Backup e portabilità

- Backup periodici dei repository Git
- Backup di database e configurazioni
- Possibilità di migrazione verso qualunque piattaforma Git compatibile

Il codice resta utilizzabile anche in assenza della piattaforma.

---

## 8. Strategia di migrazione

### Fase 0 – Allineamento
- Azure DevOps è considerato temporaneo.
- Ogni nuova scelta deve essere portabile.

### Fase 1 – Bonifica Azure DevOps
- Riduzione task proprietari
- Pipeline basate su script standard
- Wiki convertita in Markdown versionato
- Repository Git indipendenti dalla UI

### Fase 2 – Piattaforma parallela
- Introduzione GitLab self-managed
- Migrazione di un progetto reale pilota
- Confronto operativo, non teorico

### Fase 3 – Agenti
- Agenti operano su Git, issue, MR
- Nessuna dipendenza critica da Azure DevOps
- GitLab come ambiente naturale degli agenti

### Fase 4 – Exit volontaria
- Nuovi progetti nativi sulla nuova piattaforma
- Legacy migrato solo se conveniente
- DevOps dismesso solo quando non crea più valore

---

## 9. Antifragilità e assicurazione salvavita

### 9.1 Premessa

Un “cigno nero” non può essere previsto né simulato.
Se fosse possibile, non sarebbe tale.

Questo piano **non tenta di prevedere l’imprevisto**,
ma di garantire che **non sia fatale**.

---

### 9.2 Assicurazione strutturale

Le scelte descritte in questo documento costituiscono
una **assicurazione salvavita tecnica e organizzativa**.

Un’assicurazione:
- non evita l’evento,
- non lo controlla,
- non lo prevede,
ma garantisce che **le conseguenze non distruggano il sistema**.

---

### 9.3 Condizioni sempre garantite

Indipendentemente da come cambi lo status quo:

- il codice resta accessibile,
- i repository Git sono recuperabili,
- le pipeline sono ricostruibili,
- la documentazione è trasferibile,
- gli agenti sono riallocabili,
- esiste sempre una continuità operativa possibile.

Il sistema non entra in panico.
Entra in **transizione controllata**.

---

## 10. Ruolo degli agenti automatici

- Gli agenti operano su Git, issue e merge request.
- Utilizzano token dedicati e tracciabili.
- Non dipendono da API proprietarie non sostituibili.

Gli agenti aumentano la capacità del team,
senza diventare un nuovo punto di lock-in.

---

## 11. Checklist anti-lock-in (operativa)

- Repository Git standard
- Pipeline dichiarative
- Script eseguibili fuori dalla piattaforma
- Documentazione nel codice
- Accessi nominali e revocabili
- Backup testati
- Exit strategy documentata

Se una di queste condizioni viene meno,
il rischio strutturale sta aumentando.

---

## 12. Roadmap evolutiva (3–5 anni)

- **0–12 mesi**
  - Bonifica DevOps
  - GitLab parallelo
  - Prime automazioni

- **12–36 mesi**
  - GitLab per nuovi progetti
  - DevOps solo legacy
  - Agenti avanzati

- **36–60 mesi**
  - Piena sovranità tecnica
  - Possibile dismissione DevOps
  - Piattaforma come asset interno

---

## 13. Linee guida operative per il team

- Tutto il codice in Git
- Tutta la conoscenza nel codice
- Nessun tool indispensabile
- Ogni dipendenza deve avere un’alternativa concettuale
- Gli agenti sono tracciabili e limitati
- Le decisioni sono documentate

---

## 14. Chiusura

Questo documento non è una scelta di tool,
ma una **scelta di postura nel tempo**.

> Non possiamo sapere cosa cambierà.
> Sappiamo però che, se cambiasse,
> non resteremmo senza via di uscita.

Questo è lo scopo ultimo del piano.
