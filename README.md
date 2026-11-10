# deployment-cd — e-Santé Sénégal

Dépôt d'orchestration et de déploiement de la plateforme de téléconsultation **e-Santé Sénégal**.

## Architecture

```
deployment-cd/
├── docker-compose.yml        # Orchestration des 3 services (db, backend, frontend)
├── Jenkinsfile               # Pipeline CD (déploiement automatisé)
├── .env.example              # Variables d'environnement (modèle)
├── .gitignore
├── README.md
├── scripts/
│   ├── deploy.sh             # Déploiement manuel
│   ├── healthcheck.sh        # Vérification de santé
│   ├── rollback.sh           # Rollback vers une version précédente
│   └── backup-db.sh          # Sauvegarde PostgreSQL
└── docs/
    └── ...                   # Documentation complémentaire
```

## Prérequis

- **Docker** 24+ et **Docker Compose** v2
- **Accès Docker Hub** (images backend et frontend publiées par les pipelines CI)
- Un serveur Linux avec les ports 80 et 5432 disponibles

## Déploiement rapide

```bash
# 1. Cloner le dépôt
git clone <url-deployment-cd>
cd deployment-cd

# 2. Configurer l'environnement
cp .env.example .env
# Éditer .env avec vos valeurs réelles (secrets, identifiants Docker Hub)

# 3. Déployer
chmod +x scripts/*.sh
./scripts/deploy.sh

# 4. Vérifier
./scripts/healthcheck.sh
```

L'application est accessible sur `http://localhost:80` (ou le port configuré dans `FRONTEND_PORT`).

## Commandes utiles

| Commande | Description |
|----------|-------------|
| `./scripts/deploy.sh [backend_tag] [frontend_tag]` | Déploie les versions spécifiées |
| `./scripts/healthcheck.sh` | Vérifie la santé des services |
| `./scripts/rollback.sh <backend_tag> <frontend_tag>` | Rollback vers des versions précédentes |
| `./scripts/backup-db.sh [répertoire]` | Sauvegarde la base PostgreSQL |
| `docker compose logs -f` | Consulter les logs en temps réel |
| `docker compose ps` | État des conteneurs |

## Pipeline CD Jenkins

Le `Jenkinsfile` permet un déploiement automatisé avec :
- Paramètres : tags backend/frontend, sauvegarde préalable
- Authentification Docker Hub via Jenkins Credentials (`dockerhub-credentials`)
- Sauvegarde de la base avant déploiement
- Vérification de santé post-déploiement
- Tests de disponibilité HTTP

## Persistance des données

Les données PostgreSQL sont stockées dans un volume Docker nommé `esante_pgdata`.
Ce volume survit aux redémarrages et aux mises à jour des conteneurs.

## Sécurité

- Le fichier `.env` contenant les secrets est exclu de Git (`.gitignore`)
- Les credentials Docker Hub sont gérés par Jenkins Credentials
- PostgreSQL n'est pas exposé sur l'hôte (réseau Docker interne uniquement)
- Le backend valide les secrets obligatoires au démarrage en production
