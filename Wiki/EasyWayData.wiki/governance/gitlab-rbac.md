---
type: governance
status: draft
tags:
  - domain/security
  - tool/gitlab
created: 2026-02-04
---

# 🛡️ GitLab Governance & RBAC Model

Questo documento definisce la struttura di Gruppi, Progetti e Accessi per l'istanza GitLab Self-Managed (http://80.225.86.168:8929/).

---

## 1. 🏢 Group Structure (Taxonomy)

La struttura dei gruppi riflette i domini di business e la sovranità dei dati.

```mermaid
graph TD
    Root[EasyWayData]
    Root --> Platform[📂 Platform (Core)]
    Root --> Domains[📂 Domains (Business)]
    Root --> External[📂 External (Vendors)]
    
    Platform --> Agents[🤖 Agents Repository]
    Platform --> Infra[☁️ Infrastructure / IaC]
    
    Domains --> Finance[💰 Finance]
    Domains --> HR[👥 HR]
    
    External --> VendorA[🏭 Vendor A]
    External --> VendorB[🏭 Vendor B]
```

### Definizione Gruppi
*   **Platform**: Codice Core, Framework (Valentino), Agenti (Council). Accesso ristretto.
*   **Domains**: Progetti di business. Accesso per team specifici.
*   **External**: Sandbox per fornitori. Isolamento rigoroso (impossibile pushare su Main senza `agent_guard`).

---

## 2. 🔑 Roles & Permissions

Mappatura dei ruoli GitLab sui nostri Persona.

| GitLab Role | Persona | Permessi Chiave |
| :--- | :--- | :--- |
| **Owner** | `Admin / Architect` | Gestione Gruppi, Secrets, Compliance |
| **Maintainer** | `Tech Lead / Release Agent` | Merge su Main, Gestione Pipelines |
| **Developer** | `Developer Agent / Team` | Push su feature/*, Open MR |
| **Reporter** | `Product Owner / Vendor` | Read Code, View Issues, No Code Push |
| **Guest** | `Stakeholder` | Solo visualizzazione Ticket |

> ⚠️ **Regola Aurea**: Nessun umano (eccetto Admin in emergenza) ha permesso di Push diretto su `main`. Solo `agent_release` (Maintainer) può farlo.

---

## 3. 🤖 Service Accounts (Bot Users)

Per l'automazione agentica, creeremo i seguenti Utenti Bot:

1.  **`bot_guard`** (Role: Reporter + Webhook):
    *   Legge MR, commenta, blocca pipeline.
2.  **`bot_developer`** (Role: Developer):
    *   Può aprire MR e pushare su feature branches.
3.  **`bot_release`** (Role: Maintainer):
    *   L'unico autorizzato a mergiare su `develop` e `main`.

---

## 4. 📝 Onboarding Checklist

Per ogni nuovo utente/agente:
1.  [ ] Creare utente su GitLab.
2.  [ ] Assegnare al Gruppo corretto (es. `Domains/Finance`).
3.  [ ] Impostare 2FA (Obbligatorio).
## 5. 🛡️ Security Strategy (Split Model)

Abbiamo adottato un modello di **Split Inheritance** per prevenire movimenti laterali in caso di attacco.

| Gruppo | Ruolo Dev | Effetto |
| :--- | :--- | :--- |
| `EasyWay/Domains` | **Developer** | ✅ Può scrivere, creare branch, modificare app di business. |
| `EasyWay/Platform` | **Reporter** | 👁️ Può SOLO LEGGERE. Non può modificare Agenti o Infra. |

**Vantaggio**: Se un token sviluppatore viene rubato, l'attaccante è confinato nel dominio di business e non può compromettere la Supply Chain (Agenti/Terraform).
