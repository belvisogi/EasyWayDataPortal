---
description: How to create a new Wiki Page with correct structure and automated enrichment
---

# Create New Wiki Page

1.  **Create the File**
    - Copy content from `Wiki/EasyWayData.wiki/_template.md`.
    - Set the filename in kebab-case (e.g., `my-new-page.md`).
    - Place it in the correct domain folder (e.g., `orchestrations/`, `domains/`).

2.  **Draft Initial Content**
    - Fill in the YAML frontmatter:
        - `title`: Human readable title.
        - `summary`: "TODO" (The agent will fix this).
        - `status`: `draft`.
        - `owner`: The responsible team.
        - `tags`: Appropriate tags.
    - Write the core content under `## Contenuto`.

3.  **Run Enrichment Agent**
    - Execute the enrichment script to generate the Summary and Questions automatically.
    
    ```powershell
    ./scripts/agent-enrich-docs.ps1
    ```
    
    *Note: Ensure `easyway-secrets.json` is configured or Env Vars are set.*

4.  **Verify & Commit**
    - Check if `summary` is populated.
    - Check if `## Domande a cui risponde` is added.
    - Check if `status` is updated to `active` (optional, can remain draft if incomplete).
