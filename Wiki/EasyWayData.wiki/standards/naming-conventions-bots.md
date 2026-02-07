---
type: standard
status: proposal
tags:
  - domain/governance
  - naming/convention
created: 2026-02-04
---

# 🤖 Naming Standards: Service Accounts & Bots

Per mantenere ordine e professionalità, proponiamo 3 livelli di standard naming per gli account non umani.
Consiglio vivamente l'approccio **"Functional"** per i clienti, e **"Mythological"** solo per i brain interni (come Levi).

---


## 0. The Golden Rule: Internal vs External
*   **Internal ID** (Code/Folder): `agent_<ruolo>` (es. `agent_guard`). Questo è il nome della "classe".
*   **External Identity** (GitLab/AD): `ew_<ruolo>` (es. `ew_guard`). Questo è il nome dell'utente "vivo".

## Proposta 1: Functional (Consigliata per Clienti Enterprise)
Chiara, noiosa, auto-esplicativa. Nessuno chiederà "chi è?".

| Ruolo | Nome Visualizzato | Username | Email Template |
| :--- | :--- | :--- | :--- |
| **Provisioning** | `Svc Provisioner` | `svc_provisioner` | `bots+provisioner@domain.com` |
| **CI/CD Guard** | `Svc Guard` | `svc_guard` | `bots+guard@domain.com` |
| **Release** | `Svc Release` | `svc_release` | `bots+release@domain.com` |
| **Developer** | `Svc Developer` | `svc_dev` | `bots+dev@domain.com` |

*   **Pattern**: `svc_<ruolo>`
*   **Vantaggio**: Ordinamento alfabetico perfetto in lista utenti.

---

## Proposta 2: Elemental (Minimalista)
Per startup o team agili.

| Ruolo | Nome | Username |
| :--- | :--- | :--- |
| **Provisioning** | `Root` | `bot_root` |
| **CI/CD** | `Build` | `bot_build` |
| **Release** | `Deploy` | `bot_deploy` |

---

## Proposta 3: Mythological (Stile "EasyWay")
Da usare solo internamente o per prodotti specifici (es. Project Levi).

| Ruolo | Nome | Username |
| :--- | :--- | :--- |
| **Provisioning** | `Atlas` (Regge il mondo) | `atlas_bot` |
| **Guard** | `Heimdall` (Il Guardiano) | `heimdall_bot` |
| **Release** | `Hermes` (Il Messaggero) | `hermes_bot` |
| **Developer** | `Vulcan` (Il Fabbro) | `vulcan_bot` |

---

## Raccomandazione Finale
Per il tuo setup su `http://80.225.86.168:8929/`, usiamo lo standard **Functional** con prefisso `ew_` (EasyWay) per evitare conflitti?

1.  **`ew_provisioner`** (L'Admin che crea tutto)
2.  **`ew_guard`** (Il Poliziotto)
3.  **`ew_release`** (Il Releaser)

Confermi `ew_provisioner` come nome del creatore supremo?
