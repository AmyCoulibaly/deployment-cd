pipeline {
    agent any

    parameters {
        string(name: 'BACKEND_TAG', defaultValue: 'latest', description: 'Tag de l\'image backend à déployer')
        string(name: 'FRONTEND_TAG', defaultValue: 'latest', description: 'Tag de l\'image frontend à déployer')
        booleanParam(name: 'BACKUP_BEFORE_DEPLOY', defaultValue: true, description: 'Sauvegarder la base avant le déploiement')
    }

    environment {
        DOCKERHUB_CREDENTIALS  = credentials('dockerhub-credentials')
        COMPOSE_PROJECT_NAME   = 'esante'
        DEPLOY_BACKEND_TAG     = "${params.BACKEND_TAG}"
        DEPLOY_FRONTEND_TAG    = "${params.FRONTEND_TAG}"
    }

    options {
        timestamps()
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '20'))
        timeout(time: 15, unit: 'MINUTES')
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Validation de la configuration') {
            steps {
                sh '''
                    if [ ! -f .env ]; then
                        echo "ERREUR : fichier .env absent. Copiez .env.example et renseignez les valeurs."
                        exit 1
                    fi
                    docker compose config --quiet
                    echo "Configuration Docker Compose valide."
                '''
            }
        }

        stage('Authentification Docker Hub') {
            steps {
                sh '''
                    echo "${DOCKERHUB_CREDENTIALS_PSW}" | docker login -u "${DOCKERHUB_CREDENTIALS_USR}" --password-stdin
                '''
            }
        }

        stage('Sauvegarde de la base de données') {
            when {
                expression { return params.BACKUP_BEFORE_DEPLOY }
            }
            steps {
                sh '''
                    chmod +x scripts/backup-db.sh
                    ./scripts/backup-db.sh || echo "Avertissement : sauvegarde impossible (base inexistante ou arrêtée)."
                '''
            }
            post {
                always {
                    archiveArtifacts artifacts: 'backups/*.sql.gz', allowEmptyArchive: true
                }
            }
        }

        stage('Récupération des images') {
            steps {
                sh '''
                    export BACKEND_TAG="${DEPLOY_BACKEND_TAG}"
                    export FRONTEND_TAG="${DEPLOY_FRONTEND_TAG}"
                    docker compose pull backend frontend
                '''
            }
        }

        stage('Déploiement') {
            steps {
                sh '''
                    export BACKEND_TAG="${DEPLOY_BACKEND_TAG}"
                    export FRONTEND_TAG="${DEPLOY_FRONTEND_TAG}"

                    echo "==> Arrêt des services applicatifs..."
                    docker compose stop backend frontend || true

                    echo "==> Démarrage de l'application..."
                    docker compose up -d
                '''
            }
        }

        stage('Vérification de santé') {
            steps {
                sh '''
                    chmod +x scripts/healthcheck.sh
                    ./scripts/healthcheck.sh
                '''
            }
        }

        stage('Tests de disponibilité HTTP') {
            steps {
                sh '''
                    set -a
                    source .env
                    set +a

                    FRONTEND_PORT="${FRONTEND_PORT:-80}"

                    echo "==> Test du frontend..."
                    curl -sf "http://localhost:${FRONTEND_PORT}/healthz" > /dev/null
                    echo "  Frontend OK"

                    echo "==> Test de l'API via le reverse proxy nginx..."
                    STATUS=$(curl -sf -o /dev/null -w "%{http_code}" "http://localhost:${FRONTEND_PORT}/api/medecins" || echo "000")
                    if [ "$STATUS" = "200" ]; then
                        echo "  API accessible via nginx OK (HTTP $STATUS)"
                    else
                        echo "  ÉCHEC : API retourne HTTP $STATUS"
                        exit 1
                    fi
                '''
            }
        }
    }

    post {
        always {
            sh 'docker logout || true'
        }
        success {
            echo "Déploiement réussi : backend:${params.BACKEND_TAG}, frontend:${params.FRONTEND_TAG}"
        }
        failure {
            echo "ÉCHEC du déploiement. Pour un rollback, relancez avec les tags de la version précédente."
        }
    }
}
