---
id: ew-standards-infrastructure-standards
title: EasyWay Infrastructure Standards 🏗️
summary: TODO - aggiungere un sommario breve.
status: draft
owner: team-platform
tags: [domain/docs, layer/spec, privacy/internal, language/it, audience/dev]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
type: guide
---
# EasyWay Infrastructure Standards 🏗️

> **Philosophy**: "Secure by Design, Resilient by Default."
> This document defines the MANDATORY standards for any service deployed in the EasyWay ecosystem.

## 1. Security & User Isolation 🔒

### The "Unified App Runner" Rule (UID 1000)
**Principle**: No container shall run as `root`.
**Implementation**:
-   All containers MUST run as **UID 1000** (GID 1000).
-   Use `user: "1000:1000"` in `docker-compose.yml` if the image supports it.
-   If building custom images (`Dockerfile`):
    ```dockerfile
    # Create standard user
    RUN groupadd -g 1000 apprunner && \
        useradd -m -u 1000 -g apprunner apprunner
    # Switch context
    USER apprunner
    ```
-   **Shared Volumes**: Host directories mounted into containers must be owned by UID 1000.
    ```bash
    chown -R 1000:1000 ./data-directory
    ```

### Secrets Management
-   **No Hardcoded Secrets**: Never commit passwords or API keys to git.
-   **Environment Variables**: Use `.env` files (git-ignored) or Docker Secrets.

## 2. Stability & Resilience 🛡️

### Restart Policies
**Mandatory**: Every service in `docker-compose.yml` MUST include:
```yaml
restart: unless-stopped
```
*Exceptions*: One-off tasks or migration scripts.

### Version Pinning
**Mandatory**: Use specific tags (e.g., `n8n:1.25.1`), NOT `latest`.
*Why?*: `latest` is non-deterministic and leads to "it worked yesterday" failures.

## 3. Networking 🌐

### The Traverse Proxy Pattern
-   **No Direct Exposure**: Do not bind ports like `8080:80` to the host unless strictly necessary for tunneling.
-   **Internal Overlay**: All services communicate via `easyway-net`.
-   **Gateway**: Traefik is the ONLY entry point for HTTP/S traffic.

## 4. Maintenance 🧹

### Clean Build Contexts
-   **Goal**: Fast, small builds.
-   use `.dockerignore` to exclude `node_modules`, `.git`, `logs`, and `tmp` files.



