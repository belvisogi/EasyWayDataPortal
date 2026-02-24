# Macro Skills Catalog

Questo folder contiene le skill di livello macro-use-case (layer documentale/orchestrativo).

## Source of truth

- Catalogo canonico: `docs/skills/catalog.json`
- Schema: `docs/skills/catalog.schema.json`
- Skill documentate: `docs/skills/<skill-id>/SKILL.md`

## Bridge per console/UI

Genera il file consumabile dalla Agent Console:

```powershell
pwsh scripts/pwsh/generate-macro-skills-registry.ps1
```

Output:

- `docs/skills/catalog.generated.json`

## Regola operativa

- Non modificare manualmente `catalog.generated.json`.
- Aggiornare `catalog.json` + `SKILL.md`, poi rigenerare.
