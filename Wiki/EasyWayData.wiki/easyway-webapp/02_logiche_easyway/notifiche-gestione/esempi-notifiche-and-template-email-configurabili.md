---
id: ew-esempi-notifiche-and-template-email-configurabili
title: Esempi Notifiche & Template Email Configurabili
summary: Esempi pratici per template email/notifications configurabili via file Excel su Storage.
status: draft
owner: team-docs
created: '2025-01-01'
updated: '2025-01-01'
tags: [domain/control-plane, layer/reference, audience/dev, privacy/internal, language/it, notifications, email]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
---

# Esempi Notifiche & Template Email Configurabili (Excel su Storage)

## 1. Flusso Gestione Template Email

1. Amministratore o product owner carica un file Excel (es. `email_templates.xlsx`) nella cartella `portal-assets/` dello Storage Datalake.
2. Il microservizio notifiche, ogni volta che deve inviare un'email:
   - accede al file Excel tramite API Storage
   - legge il template relativo al tipo di notifica richiesto (es: onboarding, alert, billing)
   - effettua il merge dei dati dinamici (nome utente, data, tenant, ecc.) nelle variabili del template
   - invia l'email secondo le preferenze utente (lingua, canale)
3. Il sistema può aggiornare i template senza deployare codice, solo sostituendo il file Excel.
4. Tutte le modifiche e gli invii sono loggati (tabella `notification_log`).

## 2. Struttura file Excel `email_templates.xlsx`

| Tipo_Notifica | Lingua | Oggetto | Corpo |
|--------------|--------|---------|-------|
| onboarding | IT | Benvenuto su EasyWay Data Portal | Ciao {{nome}}, il tuo account per {{tenant}} è stato attivato! |
| onboarding | EN | Welcome to EasyWay Data Portal | Hi {{name}}, your account for {{tenant}} is now active! |
| alert_sicurezza | IT | Accesso anomalo rilevato | È stato rilevato un accesso anomalo al tuo account il {{data}} |
| alert_sicurezza | EN | Suspicious Login Detected | A suspicious login to your account was detected on {{date}} |
| reset_password | IT | Reimposta la tua password | Per reimpostare la password clicca qui: {{reset_link}} |
| reset_password | EN | Reset Your Password | To reset your password click here: {{reset_link}} |

- Colonne consigliate: `Tipo_Notifica`, `Lingua`, `Oggetto`, `Corpo`
- Placeholder variabili: usa doppie graffe (`{{ }}`) per tutti i dati dinamici (es. nome, link, tenant, data)

---

## 3. Esempio di codice (pseudo, architettura agnostica)

```python
import pandas as pd

def get_template(tipo, lingua, params, excel_path):
    df = pd.read_excel(excel_path)
    tpl = df[(df['Tipo_Notifica']==tipo) & (df['Lingua']==lingua)].iloc[0]
    oggetto = tpl['Oggetto'].format(**params)
    corpo = tpl['Corpo']
    for k, v in params.items():
        corpo = corpo.replace(f'{{{{{k}}}}}', str(v))
    return oggetto, corpo
```

Esempio chiamata:

```python
params = {"nome": "Mario", "tenant": "AziendaXYZ", "data": "21/07/2025", "reset_link": "https://..."}
oggetto, corpo = get_template("onboarding", "IT", params, "email_templates.xlsx")
```

---

## 4. Flusso "Ready for Codice"

```text
[Admin] -> [Carica email_templates.xlsx su portal-assets/]
      |
      v
[Microservizio Notifiche] -> [Leggi template Excel via API Storage]
      |
      v
[Costruisci email con merge variabili] -> [Invia email]
      |
      v
[Log invio + template utilizzato + outcome]
```

---

## 5. Best Practice

- Versiona sempre i template (timestamp, backup excel)
- Mantieni template multilingua e personalizzati per tenant, aggiungendo colonna "Tenant" se serve
- Testa sempre il parsing/merge dati su ambiente di sviluppo
- Logga nome file, versione, tipo notifica per ogni invio
- Aggiornare i template non richiede deploy, basta sostituire Excel

---

## 6. Esempi concreti (IT/EN)

Esempio Onboarding IT:
- Oggetto: `Benvenuto su EasyWay Data Portal`
- Corpo: `Ciao {{nome}}, il tuo account per {{tenant}} è stato attivato!`

Esempio Alert Sicurezza EN:
- Oggetto: `Suspicious Login Detected`
- Corpo: `A suspicious login to your account was detected on {{date}}.`

Nota operativa:
Ogni modifica ai template viene tracciata e può essere validata da admin. In produzione i template sono gestiti solo via Storage e mai hardcodati nel codice.

## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?

