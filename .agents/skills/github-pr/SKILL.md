---
name: github-pr
description: Enterprise skill to manage and create GitHub Pull Requests autonomously. Use this when the user requests to create a pull request on GitHub, explicitly requiring scripts to do so. This skill provides parameterized bash, powershell, and python scripts to securely create a fully populated Pull Request directly via GitHub APIs.
---

# GitHub PR Creator Skill

This skill provides enterprise-grade, parameterized scripts to autonomously create GitHub Pull Requests. It ensures that title, description, and security checklists are systematically enforced in every PR.

## Modes of Operation

The scripts automatically support two modes:
1. **API Mode (Recommended)**: If `$GITHUB_TOKEN` is set, the script will autonomously create the PR via the GitHub REST API.
2. **Local Link Mode (Fallback)**: If `$GITHUB_TOKEN` is NOT set, the script will instead generate a fully populated, URL-encoded GitHub link that the user can simply click to open the pre-filled PR in their browser.

## Security Warning
**Never output or hardcode GitHub PATs in any script.** Always load tokens from an environment variable (e.g. `$GITHUB_TOKEN` or `$GITEA_API_TOKEN` depending on platform standards).
The PR creation MUST enforce the project's security checklist.

## Provided Implementations

To maximize cross-platform compatibility, this skill provides three equivalent scripts in the `scripts/` directory. Use the one most appropriate for the current execution environment:

1. **PowerShell**: `scripts/create-pr.ps1`
2. **Bash**: `scripts/create-pr.sh`
3. **Python**: `scripts/create_pr.py`

### Common Parameters
All three scripts accept the following standard parameters:
- `SourceBranch`: The branch containing the changes (e.g. `feature-name`)
- `TargetBranch`: The destination branch (usually `develop` or `main`)
- `Title`: A conventional commit formatted title (e.g. `feat(api): login endpoint`)
- `Description`: The markdown description of the PR details.
- `SecurityChecklist`: The markdown string containing the mandatory Security Checklist.
- `--Draft`: (Optional) Flag to create a Draft PR.

### Environment Variable
If the `GITHUB_TOKEN` environment variable is set, the API will be used. Otherwise, a pre-filled URL will be generated.

## How to execute

When the user asks you to create a PR on GitHub, execute one of the scripts provided in `scripts/`.

Example (Python):
```bash
python .agents/skills/github-pr/scripts/create_pr.py \
  --source feature/my-branch \
  --target develop \
  --title "feat(core): update PR logic" \
  --description "Description text..." \
  --checklist "- [x] Check 1"
```

Example (PowerShell):
```powershell
.agents/skills/github-pr/scripts/create-pr.ps1 `
  -SourceBranch "feature/my-branch" `
  -TargetBranch "develop" `
  -Title "feat(core): update PR logic" `
  -Description "Description text..." `
  -SecurityChecklist "- [x] Check 1"
```

Example (Bash):
```bash
./.agents/skills/github-pr/scripts/create-pr.sh \
  "feature/my-branch" \
  "develop" \
  "feat(core): update PR logic" \
  "Description text..." \
  "- [x] Check 1"
```

## Security Checklist Template
When generating the `SecurityChecklist` parameter, **MUST** use the official project template format like this:
```markdown
## Checklist PR – EasyWayDataPortal

- [ ] Wiki: front-matter LLM presente su ogni nuova/aggiornata pagina (`id,title,summary,status,owner,tags,llm.include,llm.chunk_hint,llm.pii,llm.redaction,entities`)
- [ ] Lint: eseguito `scripts/wiki-frontmatter-lint.ps1 -Path Wiki/EasyWayData.wiki -FailOnError` localmente (oppure verificato job CI)
- [ ] Autofix (se necessario): eseguito `scripts/wiki-frontmatter-autofix.ps1 -Path Wiki/EasyWayData.wiki` e revisionati i cambi
- [ ] Privacy: nessuna PII in summary/front-matter; redaction coerente
- [ ] KB: aggiornata una ricetta se la modifica introduce un nuovo flusso/procedura
- [ ] CI: gates `ewctl` verdi (Checklist/DB Drift/KB Consistency) su branch di PR

Sezione WHAT-first (obbligatoria per nuovi workflow/use case)
- [ ] Orchestrazione (manifest JSON) presente in `docs/agentic/templates/orchestrations/`
- [ ] Intents (WHAT JSON) presenti in `docs/agentic/templates/intents/`
- [ ] UX prompts localizzati in `docs/agentic/templates/orchestrations/ux_prompts.it.json|en.json`
- [ ] Pagina Wiki di orchestrazione/Use Case aggiunta/aggiornata
```
