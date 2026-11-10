#!/bin/bash
# ============================================================================
# rollback.sh — Rollback vers les versions précédentes des images
# Usage : ./scripts/rollback.sh <backend_tag> <frontend_tag>
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

if [ $# -lt 2 ]; then
    echo "Usage : $0 <backend_tag> <frontend_tag>"
    echo "Exemple : $0 abc1234-42 abc1234-42"
    echo ""
    echo "Tags récents :"
    echo "  Backend  : $(docker inspect --format='{{.Config.Image}}' esante-backend 2>/dev/null || echo 'non déployé')"
    echo "  Frontend : $(docker inspect --format='{{.Config.Image}}' esante-frontend 2>/dev/null || echo 'non déployé')"
    exit 1
fi

BACKEND_TAG="$1"
FRONTEND_TAG="$2"

echo "============================================"
echo "  e-Santé Sénégal — ROLLBACK"
echo "  Backend  -> ${BACKEND_TAG}"
echo "  Frontend -> ${FRONTEND_TAG}"
echo "============================================"

# Charger les variables d'environnement
set -a
source .env
set +a

export BACKEND_TAG FRONTEND_TAG

echo "==> Récupération des images de rollback..."
docker compose pull backend frontend

echo "==> Arrêt des services applicatifs..."
docker compose stop backend frontend

echo "==> Redémarrage avec les anciennes versions..."
docker compose up -d

echo "==> Vérification de santé..."
"$SCRIPT_DIR/healthcheck.sh"

echo ""
echo "Rollback terminé. Versions déployées :"
echo "  Backend  : ${BACKEND_TAG}"
echo "  Frontend : ${FRONTEND_TAG}"
