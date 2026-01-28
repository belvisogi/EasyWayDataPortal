# Infrastructure Audit & Gap Analysis
**Date**: 2026-01-27
**Target**: Docker Stack (`apps`, `infra`)

## 1. Stability & Resilience ⚠️
| Findings | Risk | Recommendation |
| :--- | :--- | :--- |
| **Restart Policies** | ✅ Fixed | All containers set to `restart: unless-stopped`. Resilient to crashes and reboots. |
| **No Healthchecks** | 🟠 Medium | Apps don't declare health. Docker doesn't know when to restart them or when dependencies are ready. |

## 2. Versioning & Determinism ⚠️
| Findings | Risk | Recommendation |
| :--- | :--- | :--- |
| **image: latest** | 🟠 Medium | `sql-edge:latest`, `n8n:latest`, `minio:latest`. A redeploy tomorrow could pull a breaking version. Pin versions (e.g., `n8n:1.25.1`). |

## 3. Security (Least Privilege) ⚠️
| Findings | Risk | Recommendation |
| :--- | :--- | :--- |
| **Root Execution** | ✅ Fixed | `portal-api`, `agent-runner`, and `n8n` now run as **UID 1000**. Reduced attack surface. |
| **Port Exposure** | 🟡 Low | Ports 3000, 5678, 1433 are bound to `0.0.0.0`. Valid for debugging, but in Prod should bind to `127.0.0.1` or rely solely on Traefik/Tunnel. |
| **Default Passwords** | 🟡 Low | Default `EasyWayStrongPassword1!` is visible in `docker-compose.apps.yml`. Ensure `.env` is used in Prod. |

## 4. Docker Context
- **Good**: `agent-runner` correctly uses root context to access shared libraries (`scripts`, `Wiki`).
- **Good**: `api` uses minimal context for fast builds.

## Summary
The infrastructure is **Functional** but **Not Production-Hardened**.
It is perfect for a Development/POC Data Portal. For Production, we must add Restart Policies and pinpoint versions.
