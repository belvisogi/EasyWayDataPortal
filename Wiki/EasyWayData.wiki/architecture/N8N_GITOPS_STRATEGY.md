---
id: ew-architecture-n8n-gitops-strategy
title: n8n GitOps Strategy: "The Workflow Factory" 🏭
summary: TODO - aggiungere un sommario breve.
status: draft
owner: team-platform
tags: [domain/docs, layer/reference, privacy/internal, language/it, audience/dev]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
type: guide
---
# n8n GitOps Strategy: "The Workflow Factory" 🏭

## 1. Governance & Separation
We will separate **Development** (Source Code) from **Runtime** (Appliance).

### 📂 The Repositories
1.  **`EasyWayDataPortal` (The Appliance)**
    -   Contains: `docker-compose`, infrastructure config, `portal-api` code, frontend.
    -   Role: The **Production Environment**.
2.  **`Work-space-n8n` (The Factory)**
    -   Contains: Pure n8n Workflow JSON files.
    -   Structure:
        ```text
        /Workflow-Name
          ├── workflow.json      (The logic)
          ├── README.md          (Documentation)
          └── test-input.json    (Example payload)
        ```
    -   Role: **Source of Truth** & Version Control.

## 2. The Deployment Pipeline 🚀

### Step 1: Develop & Commit
1.  Developer works in n8n UI (Local or Dev instance).
2.  Exports workflow to `MyWorkflow.json` in `Work-space-n8n`.
3.  Commits and pushes to Git.

### Step 2: Release to Server
On the remote server, we pull the latest factories:
```bash
cd ~/Work-space-n8n
git pull
```

### Step 3: "Install" (The Appliance Connect)
We create a `deploy-workflows.ps1` script that:
1.  **Copies** JSON files from `Work-space-n8n` to `~/EasyWayDataPortal/agents/core/n8n` (The "Mounted Volume").
2.  **Imports** them into the live n8n database:
    ```bash
    docker exec easyway-orchestrator n8n import:workflow --input=/home/node/workflows/MyWorkflow.json
    ```

## 3. Host User Audit 👤
Current users on `80.225.86.168`:
-   **`ubuntu` (UID 1000)**: The main operational user. Maps to our containers. ✅
-   `produser` (UID 1002): Legacy/Other?
-   `easyway` (UID 1003): Likely a previous test.
-   `testreaduser` (UID 1004): Likely a previous test.

**Recommendation**: Stick to `ubuntu` (UID 1000) as the "Appliance Owner".

## 4. Configuration Strategy (Parameterization) 🛠️
To keep workflows portable, we avoid hardcoding.

### A. Infrastructure & Secrets (Env Vars)
-   **Where**: `.env` file in `EasyWayDataPortal` (managed by Docker).
-   **What**: Database Hosts, API Keys, Passwords.
-   **Usage in n8n**: `{{ $env.OPENAI_API_KEY }}`.

### B. Business Logic (Config Files)
-   **Where**: `config.json` inside the `Work-space-n8n` repo.
-   **What**: Prompts, Model Names, Confidence Thresholds, Feature Flags.
-   **Usage in n8n**:
    1.  Workflow starts with a **"Load Config"** node (Read JSON File).
    2.  Downstream nodes use `{{ $json.config.model_name }}`.
-   **Benefit**: You change valid thresholds in Git without editing the workflow logic graph.

## 5. Debugging & Simulation 🐞
"How do I test if I don't have the server's `config.json`?"

## 5. Debugging: The Local Replica 🧬
"Don't simulate. Replicate."

Instead of manual pinning, we give developers a **Local n8n Instance** that mirrors Production.

### A. The Device (Local Docker)
We create a simple `docker-compose.dev.yml` in the repo:
```yaml
services:
  n8n-dev:
    image: n8nio/n8n:latest
    ports: ["5678:5678"]
    volumes:
      - ./workflows:/home/node/workflows   # Mount your source code
      - ./config.json:/home/node/config.json # Mount your config
    environment:
      - N8N_ Encryption_KEY=dev-key
```

### B. The Flow
1.  Run `docker compose up` on your laptop.
2.  n8n opens at `localhost:5678`.
3.  It **reads the real `config.json`** from your disk.
4.  You build/debug with real file reads.
5.  **Works?** -> Git Push.
6.  **Server** -> Git Pull.

No manual copy-paste. What you see locally is what runs remotely.

## 6. Enterprise Gap Analysis 🔍
Is this "Fortune 500" ready? **Not yet.** It's "Scale-Up" ready.

| Feature | Current Strategy | Enterprise Grade | Gap |
| :--- | :--- | :--- | :--- |
| **Automation** | Manual `git pull` on server | **CI/CD Pipeline** (Jenkins/GitHub Actions) auto-deploys on merge. | 🟧 Medium |
| **Testing** | Manual testing on Local Replica | **Automated Integration Tests** that run against the workflow before deploy. | 🟧 Medium |
| **Secrets** | Docker `.env` file | **Vault / AWS Secrets Manager** with rotation. | 🟩 Low (Acceptable for now) |
| **Reliability** | Single Node | **Queue Mode** (Primary + Workers) for High Availability. | 🟥 High (If mission critical) |
| **RBAC** | Git Access = Admin | **Fine-grained Roles** (Who can deploy vs who can edit). | 🟧 Medium |

### Final Verdict: "Solid Mid-Market Architecture" 🏆
This architecture is robust, version-controlled, and consistent. It prevents 90% of failures.
To reach "Enterprise", we just need to automate the `git pull` (CI/CD) and add Workers (HA).


