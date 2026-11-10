#!/bin/bash
# ============================================================================
# backup-db.sh — Sauvegarde de la base de données PostgreSQL
# Usage : ./scripts/backup-db.sh [répertoire_de_sortie]
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

# Charger les variables
if [ -f .env ]; then
    set -a
    source .env
    set +a
fi

BACKUP_DIR="${1:-${PROJECT_DIR}/backups}"
mkdir -p "$BACKUP_DIR"

TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_FILE="${BACKUP_DIR}/esante_${POSTGRES_DB:-esante_senegal_prod}_${TIMESTAMP}.sql.gz"

echo "==> Sauvegarde de la base ${POSTGRES_DB:-esante_senegal_prod}..."

docker compose exec -T db pg_dump \
    -U "${POSTGRES_USER:-esante_user}" \
    -d "${POSTGRES_DB:-esante_senegal_prod}" \
    --no-owner \
    --no-privileges \
    | gzip > "$BACKUP_FILE"

SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
echo "Sauvegarde créée : $BACKUP_FILE ($SIZE)"

# Nettoyage : conserver les 10 dernières sauvegardes
KEEP=10
COUNT=$(ls -1 "$BACKUP_DIR"/esante_*.sql.gz 2>/dev/null | wc -l)
if [ "$COUNT" -gt "$KEEP" ]; then
    REMOVE=$((COUNT - KEEP))
    ls -1t "$BACKUP_DIR"/esante_*.sql.gz | tail -n "$REMOVE" | xargs rm -f
    echo "Nettoyage : $REMOVE ancienne(s) sauvegarde(s) supprimée(s), $KEEP conservée(s)."
fi
