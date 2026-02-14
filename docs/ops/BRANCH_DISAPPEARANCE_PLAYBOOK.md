# Branch Disappearance Playbook (ADO/Git Multi-Remote)

Date: 2026-02-14  
Owner: DevOps / Repo Governance  
Scope: branch visibile/non visibile a intermittenza su ADO, con ricomparsa dopo `git push origin --all`

## 1. Sintomo

- Un branch (es. `fix-forgejo-local`) risulta assente lato ADO in alcuni momenti.
- Lo stesso branch ricompare dopo push massivo (`git push origin --all`) o nuovo push esplicito.

## 2. Root Cause (validata operativamente)

1. Configurazione remoti non allineata alla policy multi-remote:
- clone locale con solo `origin` HTTPS, senza alias `ado/github/forgejo` stabili.

2. Flusso operativo non strutturato:
- push sporadici e non verificati post-push su tutti i target.
- assenza di monitor periodico branch-presence.

3. Effetto osservato:
- il push massivo (`--all`) forza ripubblicazione refs locali e maschera il problema invece di risolverlo strutturalmente.

Evidenza raccolta (2026-02-14):
1. `git ls-remote --heads ado` ha mostrato in alcuni momenti solo `main` (branch feature/develop assenti).
2. subito dopo push espliciti delle branch mancanti, le ref sono ricomparse.
3. dopo applicazione `Deny` su `Force push` per contributor/build service/service accounts, i monitor multi-sample hanno mostrato stabilita' (`status=ok` su tutte le branch monitorate).

Conclusione:
- il pattern e' compatibile con update/delete refs da actor concorrente lato ADO (utente, service account o pipeline), non con un difetto del solo client Git locale.

## 3. Stabilizzazione obbligatoria

1. Migrare remoti Git a SSH e separare `ado`, `github`, `forgejo`.
2. Usare script sequenziale standard con verifica post-push multi-pass.
3. Attivare monitor anti-sparizione branch con alert + auto-repair opzionale.
4. Conservare log operativo in `docs/ops/`.

## 4. Procedura Operativa

1. Migrazione remoti a SSH (preview):

```powershell
pwsh -File .\scripts\pwsh\set-git-remotes-ssh.ps1 `
  -AdoUrl "git@ssh.dev.azure.com:v3/ORG/PROJECT/REPO" `
  -GitHubUrl "git@github.com:ORG/REPO.git" `
  -ForgejoUrl "ssh://git@HOST:2222/ORG/REPO.git"
```

2. Applicazione remoti:

```powershell
pwsh -File .\scripts\pwsh\set-git-remotes-ssh.ps1 `
  -AdoUrl "git@ssh.dev.azure.com:v3/ORG/PROJECT/REPO" `
  -GitHubUrl "git@github.com:ORG/REPO.git" `
  -ForgejoUrl "ssh://git@HOST:2222/ORG/REPO.git" `
  -AlsoSetOriginToAdo `
  -Apply
```

3. Push standard con verifica rinforzata:

```powershell
pwsh -File .\scripts\pwsh\push-all-remotes.ps1 `
  -Branch fix-forgejo-local `
  -Remotes ado,github,forgejo `
  -PostPushChecks 5 `
  -PostPushCheckIntervalSeconds 10 `
  -RepairMissingBranch
```

4. Monitor periodico anti-sparizione:

```powershell
pwsh -File .\scripts\pwsh\watch-branch-presence.ps1 `
  -Branch fix-forgejo-local `
  -Remotes ado,github,forgejo `
  -IntervalSeconds 120 `
  -Samples 30 `
  -RepairMissingBranch
```

## 5. Incident Handling

1. Se il monitor segnala `missing|repair-failed|repair-error`:
- bloccare merge/release;
- eseguire push esplicito `refs/heads/<branch>:refs/heads/<branch>` sul remoto impattato;
- rilanciare monitor per confermare stabilita' per almeno 30 minuti.

1.b Audit forensics immediato (ADO):
- aprire `Organization settings -> Audit logs`;
- filtrare category Git/Repositories e azioni di update/delete refs;
- correlare actor e timestamp con finestre operative del monitor.

Finestre temporali di riferimento gia' osservate:
- 2026-02-14 14:47 CET
- 2026-02-14 15:05 CET
- 2026-02-14 17:42 CET

2. Aprire record incident in `docs/ops/agent-task-records/` con:
- timestamp;
- remoto impattato;
- output comando;
- azione di remediation;
- esito e follow-up.

## 6. Definition of Done

1. Remoti primari su SSH (`ado`, `github`, `forgejo`) verificati.
2. Tre run consecutivi `push-all-remotes.ps1` senza failure.
3. Monitor branch-presence senza eventi `missing` per 24h operative.
4. PR ADO #9 mergeabile con policy approvazione stabile (nessun drift remoti).
