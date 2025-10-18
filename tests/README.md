# tests/

Struttura e linee guida per i test del monorepo EasyWayDataPortal.

## Obiettivi
- Smoke/integration rapidi sugli endpoint via REST Client (`.http`).
- In prospettiva: integrazione Jest per API e harness per test su SP (DB di test).

## Struttura iniziale
- `api/rest-client/*.http` — chiamate pronte con header `X-Tenant-Id`.
- Col tempo: `api/jest/` per test automatici (mocks o DB test), `db/` per test SP.

## Prerequisiti
- API in esecuzione in locale o su un App Service di test.
- VS Code + estensione REST Client (per file `.http`).

## Come usare i file .http
1. Apri un file `.http` in `tests/api/rest-client/`.
2. Imposta la base URL e l’header `X-Tenant-Id`.
3. Esegui le richieste tramite i link “Send Request”.

Nota: nel modulo API esiste già `easyway-portal-api/src/tests/easyway-api-test.http`; qui centralizziamo i test a livello di monorepo.

