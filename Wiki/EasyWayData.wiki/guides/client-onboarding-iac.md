---
type: guide
status: active
tags:
  - domain/infra
  - tool/terraform
  - process/onboarding
created: 2026-02-04
---

# 🏗️ Client Onboarding: GitLab via IaC

**Consiglio**: Usare **Terraform**.
**Perché**: Ti permette di creare un "Blueprint Standard" (Gruppi, Branch Protection, Utenti Bot) e applicarlo identico a tutti i clienti cambiando solo un file di variabili (`client-x.tfvars`). È idempotente (non crea duplicati se lo lanci due volte).

---

## 1. The Blueprint Concept

Non creiamo utenti a mano. Definiamo lo "Scheletro Sovereign" che vendiamo al cliente.

**Struttura Standard**:
*   `Client-Root/`
    *   `Platform/` (Agenti, Core)
    *   `Business/` (I loro progetti)
*   **Protection**: Branch `main` protetto di default.
*   **Bots**: `bot_guard` e `bot_release` creati automaticamente.

---


## 2. Prerequisite: The "Provisioner Bot" 🤖

**Sicurezza**: NON usare il tuo token personale.
Crea (a mano, una volta sola) un utente dedicato su GitLab:
*   **Nome**: `Provisioner Bot`
*   **Username**: `provisioner_bot`
*   **Ruolo**: Admin (per poter creare gruppi/utenti).
*   **Token**: Loggati come lui -> Settings -> Access Tokens -> Scopes: `api`.

Usa QUESTO token per Terraform.
*   ✅ **Audit**: Sai che le modifiche le ha fatte lo script.
*   ✅ **Safety**: Se ti rubano il token, revochi il bot, non il tuo account.

## 3. How to Re-Use (The Multitenant Strategy)

Per ogni cliente, crei solo un file di configurazione leggero.

### Esempio: `customers/cliente-alfa.tfvars`
```hcl
gitlab_url   = "http://80.225.86.168:8929/"
client_name  = "ClienteAlfa"
admin_email  = "admin@alfa.com"
enable_agents = true
```

### Esempio: `customers/cliente-beta.tfvars`
```hcl
gitlab_url   = "https://gitlab.beta.corp/"
client_name  = "ClienteBeta"
admin_email  = "ops@beta.com"
enable_agents = true
```

---

## 3. Operational Workflow

1.  **Init**: `terraform init`
2.  **Plan**: `terraform plan -var-file="customers/cliente-alfa.tfvars"` (Vedi cosa succederà)
3.  **Apply**: `terraform apply -var-file="customers/cliente-alfa.tfvars"` (Creazione fisica)

---

## 4. Requirements

*   Terraform CLI installato.
*   Token Admin GitLab (da passare come variabile d'ambiente `GITLAB_TOKEN`).

---

## 5. Maintenance

Se aggiorni lo standard (es. aggiungi un nuovo gruppo "Security"), basta aggiornare il codice Terraform (`main.tf`) e rilanciare `apply` su tutti i clienti. Tutti si aggiornano all'istante.
