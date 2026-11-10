#!/bin/bash
# ============================================================================
# healthcheck.sh — Vérifie la santé de tous les services e-Santé Sénégal
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

MAX_RETRIES=30
SLEEP_SECONDS=2
OK=true

check_service() {
    local name="$1"
    local url="$2"
    local retries=0

    echo -n "  Vérification de $name..."
    while [ $retries -lt $MAX_RETRIES ]; do
        if curl -sf "$url" > /dev/null 2>&1; then
            echo " OK"
            return 0
        fi
        retries=$((retries + 1))
        sleep $SLEEP_SECONDS
    done
    echo " ÉCHEC (après ${MAX_RETRIES} tentatives)"
    return 1
}

echo "==> Vérification de santé des services..."

# Charger les variables depuis .env si disponible
if [ -f .env ]; then
    set -a; source .env; set +a
fi
FRONTEND_PORT="${FRONTEND_PORT:-80}"

# PostgreSQL via docker compose exec
if docker compose exec -T db pg_isready -U "${POSTGRES_USER:-esante_user}" > /dev/null 2>&1; then
    echo "  PostgreSQL... OK"
else
    echo "  PostgreSQL... ÉCHEC"
    OK=false
fi

# Backend (via docker compose exec — le port n'est pas exposé sur l'hôte)
echo -n "  Vérification de Backend API..."
if docker compose exec -T backend curl -sf http://localhost:5000/health > /dev/null 2>&1; then
    echo " OK"
else
    echo " ÉCHEC"
    OK=false
fi

# Frontend (exposé sur l'hôte via le port configuré)
check_service "Frontend" "http://localhost:${FRONTEND_PORT}/healthz" || OK=false

echo ""
if [ "$OK" = true ]; then
    echo "Tous les services sont opérationnels."
    exit 0
else
    echo "ATTENTION : Un ou plusieurs services ne répondent pas."
    docker compose ps
    exit 1
fi
