---
id: ew-archive-imported-docs-2026-01-30-infra-oracle-env-doc
title: Oracle Environment Snapshot (Dev/Staging Current)
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
# Oracle Environment Snapshot (Dev/Staging Current)

## Snapshot Metadata
- Date: 2026-01-25
- Purpose: freeze the exact current Oracle VM state so it is not lost
- Environment role: Dev/Staging (current)

## Server Identity
- Provider: Oracle Cloud
- VM name: `vm-easyway-dev`
- Public IP: `80.225.86.168`
- OS: Ubuntu (desktop installed for RDP access)

## Access Paths

### SSH (primary)
- User: `ubuntu`
- Key file (local path): `C:\old\Virtual-machine\ssh-key-2026-01-25.key`
- Command:
  ```powershell
  ssh -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" ubuntu@80.225.86.168
  ```

### RDP (GUI)
- Host: `80.225.86.168`
- User: `produser`
- Password: `EasyWay2026!` (rotate after validation)
- Port: `3389`

## Installed Desktop Stack (for RDP)
- `ubuntu-desktop-minimal`
- `xrdp`
- `xorgxrdp`
- `gnome-session`

## Notes
- This VM is the current Dev/Staging environment; it is not the production target.
- Production is planned on Hetzner (see `docs/SERVER_BOOTSTRAP_PROTOCOL.md`).
- Access details above are current as of the snapshot date and should be revalidated after any server change.

## Credentials Rotation (Required after validation)
- Change `produser` password to a new secret and store it in the password manager.
- If the SSH key is regenerated, update the local path reference and re-run access validation.

## Related Docs
- `docs/infra/ORACLE_QUICK_START.md`
- `docs/SERVER_BOOTSTRAP_PROTOCOL.md`


