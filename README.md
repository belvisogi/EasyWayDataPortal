# EasyWay Data Portal — Onboarding & Architettura

Benvenuto!  
Questa repository contiene il portale EasyWay Data Portal, progettato per essere agentic-ready, cloud-native e facilmente estendibile.  
**Questa pagina è la porta di ingresso: qui trovi tutto ciò che serve per capire, avviare e contribuire al progetto.**

---

## 1. Cos’è EasyWay Data Portal

- Portale dati multi-tenant, API-first, con architettura agentica e automazione avanzata.
- Basato su Azure (App Service, SQL, Blob, Key Vault, App Insights), Node.js/TypeScript, e best practice DevOps.
- Tutte le mutazioni dati passano da Store Procedure con auditing/logging centralizzato.

---

## 2. Onboarding rapido

1. **Clona la repo**  
   `git clone ...`
2. **Setup ambiente**  
   - Node.js 18+, npm install in `EasyWay-DataPortal/easyway-portal-api/`
   - Variabili ambiente: vedi [deployment-decision-mvp.md](Wiki/EasyWayData.wiki/deployment-decision-mvp.md)
   - DB: Azure SQL, provisioning via script in `DataBase/provisioning/`
3. **Avvio locale**  
   - `cd EasyWay-DataPortal/easyway-portal-api/ && npm run dev`
   - Test API: vedi collezioni Postman in `tests/postman/`
4. **Deploy cloud**  
   - Pipeline Azure DevOps (vedi [roadmap.md](Wiki/EasyWayData.wiki/roadmap.md) e [deployment-decision-mvp.md](Wiki/EasyWayData.wiki/deployment-decision-mvp.md))
   - Segreti via Key Vault, slot di staging, smoke test post-deploy

---

## 3. Architettura (sintesi)

- **Cloud**: Azure App Service, SQL, Blob, Key Vault, App Insights, Entra ID (roadmap)
- **Principi agentici**: orchestratore, manifest.json, goals.json, template SQL/SP, gates CI/CD, human-in-the-loop
- **Sicurezza**: segreti solo in Key Vault, rate limiting, validazione input, audit log
- **Documentazione**: Wiki ricca, template, checklist, roadmap, TODO pubblici

Per dettagli:  
- [Architettura Azure](docs/infra/azure-architecture.md)  
- [Principi agentici](docs/agentic/AGENTIC_READINESS.md)  
- [Valutazione stato & gap](VALUTAZIONE_EasyWayDataPortal.md)  
- [Decisione deploy MVP](Wiki/EasyWayData.wiki/deployment-decision-mvp.md)

---

## 4. Roadmap & TODO

- Roadmap evolutiva: [roadmap.md](Wiki/EasyWayData.wiki/roadmap.md)
- Razionalizzazione e uniformamento: [TODO_CHECKLIST.md](Wiki/EasyWayData.wiki/TODO_CHECKLIST.md)

---

## 5. Contribuire

- Segui le convenzioni di naming e i template agentici (vedi Wiki)
- Proponi PR incrementali, con test e documentazione aggiornata
- Consulta la [Wiki](Wiki/EasyWayData.wiki/INDEX.md) per ogni dettaglio

---

## 6. Link utili

- [Wiki — Indice Globale](Wiki/EasyWayData.wiki/INDEX.md)
- [Onboarding API](EasyWay-DataPortal/easyway-portal-api/README.md)
- [Provisioning DB](DataBase/provisioning/README.md)
- [Test & QA](tests/README.md)

---

**Per ogni dubbio, consulta la Wiki o apri una issue!**
