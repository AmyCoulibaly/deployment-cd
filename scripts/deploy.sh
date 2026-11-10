#!/bin/bash
# ============================================================================
# deploy.sh — Déploie ou met à jour l'application e-Santé Sénégal
# Usage : ./scripts/deploy.sh [backend_tag] [frontend_tag]
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

BACKEND_TAG="${1:-${BACKEND_TAG:-latest}}"
FRONTEND_TAG="${2:-${FRONTEND_TAG:-latest}}"

# Vérification du fichier .env
if [ ! -f .env ]; then
    echo "ERREUR : Le fichier .env est absent."
    echo "Copiez .env.example vers .env et renseignez les valeurs."
    exit 1
fi

# Chargement des variables
set -a
source .env
set +a

export BACKEND_TAG FRONTEND_TAG

echo "============================================"
echo "  e-Santé Sénégal — Déploiement"
echo "  Backend  : ${DOCKERHUB_USER}/esante-senegal-backend:${BACKEND_TAG}"
echo "  Frontend : ${DOCKERHUB_USER}/esante-frontend:${FRONTEND_TAG}"
echo "============================================"

# Authentification Docker Hub
echo "==> Récupération des images..."
docker compose pull backend frontend

# Arrêt et redémarrage des conteneurs applicatifs (la base reste active)
echo "==> Arrêt des services applicatifs..."
docker compose stop backend frontend

echo "==> Démarrage des services..."
docker compose up -d

# Attente des healthchecks
echo "==> Vérification de santé des services..."
"$SCRIPT_DIR/healthcheck.sh"

echo ""
echo "Déploiement terminé avec succès."
echo "Application accessible sur : http://localhost:${FRONTEND_PORT:-80}"
