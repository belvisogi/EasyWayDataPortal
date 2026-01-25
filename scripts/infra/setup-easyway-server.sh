#!/bin/bash
set -e

# ==============================================================================
# 🛠️ EasyWay Infrastructure Agent (The Builder)
# ==============================================================================
# Questo script applica lo standard "EasyWay Server" definito in docs/infra/SERVER_STANDARDS.md.
# È idempotente: può essere lanciato più volte senza rompere nulla.
#
# USAGE: sudo ./setup-easyway-server.sh
# ==============================================================================

# 1. Check Root
if [ "$EUID" -ne 0 ]; then
  echo "❌ ERRORE: Questo script deve essere eseguito come root (usa sudo)."
  exit 1
fi

echo "🚀 Avvio procedura EasyWay Server Standard..."

# ==============================================================================
# 2. Creazione Utenti e Gruppi
# ==============================================================================
echo "👤 Configurazione Utenti e Gruppi..."

# Gruppo Developers (se non esiste)
if ! getent group easyway-dev >/dev/null; then
    groupadd easyway-dev
    echo "   ✅ Gruppo 'easyway-dev' creato."
else
    echo "   ok: Gruppo 'easyway-dev' esiste già."
fi

# Utente Service 'easyway' (se non esiste)
if ! id -u easyway >/dev/null 2>&1; then
    useradd -m -s /bin/bash easyway
    echo "   ✅ Utente 'easyway' creato."
else
    echo "   ok: Utente 'easyway' esiste già."
fi

# Aggiungi utenti al gruppo easyway-dev
# Aggiungiamo 'easyway' e l'utente corrente (su Oracle è 'ubuntu' o 'opc')
usermod -aG easyway-dev easyway

# Rileva utente admin (chi sta lanciando il comando via sudo)
REAL_USER=${SUDO_USER:-$USER}
if [ "$REAL_USER" != "root" ]; then
    usermod -aG easyway-dev "$REAL_USER"
    echo "   ✅ Utente '$REAL_USER' aggiunto al gruppo 'easyway-dev'."
fi

# ==============================================================================
# 3. Struttura Directory (FHS Standard)
# ==============================================================================
echo "📂 Creazione Alberatura Directory..."

DIRECTORIES=(
    "/opt/easyway"
    "/opt/easyway/bin"
    "/opt/easyway/config"
    "/opt/easyway/releases"
    "/var/lib/easyway"
    "/var/lib/easyway/db"
    "/var/lib/easyway/uploads"
    "/var/lib/easyway/backups"
    "/var/log/easyway"
)

for DIR in "${DIRECTORIES[@]}"; do
    if [ ! -d "$DIR" ]; then
        mkdir -p "$DIR"
        echo "   ✅ Directory creata: $DIR"
    else
        echo "   ok: Directory esiste: $DIR"
    fi
done

# ==============================================================================
# 4. Permessi Sacri
# ==============================================================================
echo "🔒 Applicazione Permessi..."

# Tutto appartiene a easyway:easyway-dev
chown -R easyway:easyway-dev /opt/easyway
chown -R easyway:easyway-dev /var/lib/easyway
chown -R easyway:easyway-dev /var/log/easyway

# Permessi:
# 775 = rwxrwxr-x
# Proprietario (easyway): RWX
# Gruppo (easyway-dev): RWX (così i dev possono deployare!)
# Altri: R-X (lettura pubblica, o 770 per chiudere tutto)
chmod -R 775 /opt/easyway
chmod -R 775 /var/lib/easyway
chmod -R 775 /var/log/easyway

# Imposta il bit SGID sulle directory
# (i nuovi file creati erediteranno il gruppo easyway-dev)
find /opt/easyway -type d -exec chmod g+s {} +
find /var/lib/easyway -type d -exec chmod g+s {} +
find /var/log/easyway -type d -exec chmod g+s {} +

echo "   ✅ Permessi applicati (775 + SGID)."

# ==============================================================================
# 5. Link di Convenienza
# ==============================================================================
echo "🔗 Creazione Symlink..."

if [ ! -L "/home/easyway/app" ]; then
    ln -s /opt/easyway /home/easyway/app
    echo "   ✅ Link creato: /home/easyway/app -> /opt/easyway"
fi

echo "✅ SETUP COMPLETATO CON SUCCESSO!"
echo "   Ora puoi deployare in /opt/easyway senza usare sudo (se sei nel gruppo easyway-dev)."
echo "   Ricorda di fare logout/login per aggiornare i gruppi del tuo utente."
