# Flyway (Community) – Skeleton

Questo skeleton consente di gestire migrazioni DB in modo migration‑based.

Struttura
- `db/flyway/sql/` – script di migrazione (V1__..., V2__...)
- `db/flyway/flyway.conf` – configurazione (connessione/parametri)

Comandi tipici (CLI)
```
# Imposta le env
$env:FLYWAY_URL = 'jdbc:sqlserver://<host>:1433;databaseName=<db>;encrypt=true;trustServerCertificate=false'
$env:FLYWAY_USER = '<user>'
$env:FLYWAY_PASSWORD = '<password>'

# Oppure via Azure AD (vedi doc Flyway Teams) – per Community usare credenziali SQL

# Esegui
flyway -configFiles=flyway.conf validate
flyway -configFiles=flyway.conf baseline -baselineVersion=1
flyway -configFiles=flyway.conf migrate
```

Note
- Su DB già esistenti: usa `baseline` per allineare lo stato iniziale.
- Per feature avanzate (AAD, reportistica), valutare Flyway Teams.

