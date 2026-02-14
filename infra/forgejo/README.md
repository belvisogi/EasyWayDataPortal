# Forgejo Local Stack

This stack runs:
- Forgejo server (`atelier`)
- Forgejo Actions runner (`runner`)

It fixes the common failure where the runner restarts showing only the help page because it was started without `daemon`.

## 1) Bootstrap

```bash
cd infra/forgejo
cp .env.example .env
```

Edit `.env` and set `RUNNER_TOKEN` from Forgejo:
- `Site Administration` -> `Actions` -> `Runners` -> `Create registration token`

## 2) Start Forgejo server

```bash
docker compose --env-file .env up -d
```

Complete the Forgejo web setup at `http://<host>:3030/` before enabling the runner.

## 3) Enable Actions runner

```bash
docker compose --env-file .env --profile actions up -d
```

## 3) Verify

```bash
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
docker logs --tail 80 forgejo-runner-1
```

Expected:
- `easyway-atelier` is `Up`
- `forgejo-runner-1` is `Up` (not restarting)
- runner logs contain registration success and daemon startup

## 4) Recovery (if runner token changed)

```bash
docker compose --env-file .env down
docker volume rm forgejo_runner-data
docker compose --env-file .env up -d
```

This forces a fresh runner registration.
