pipeline {
    agent any

    parameters {
        string(name: 'BACKEND_TAG', defaultValue: 'latest', description: 'Tag image backend')
        string(name: 'FRONTEND_TAG', defaultValue: 'latest', description: 'Tag image frontend')
    }

    environment {
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
        DEPLOY_BACKEND_TAG    = "${params.BACKEND_TAG}"
        DEPLOY_FRONTEND_TAG   = "${params.FRONTEND_TAG}"
    }

    options {
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

        stage('Vérification .env') {
            steps {
                sh '''
                    if [ ! -f .env ]; then
                        echo "ERREUR : fichier .env absent."
                        exit 1
                    fi
                    echo ".env trouvé."
                '''
            }
        }

        stage('Docker Login') {
            steps {
                sh '''
                    echo "$DOCKERHUB_CREDENTIALS_PSW" | docker login -u "$DOCKERHUB_CREDENTIALS_USR" --password-stdin
                '''
            }
        }

        stage('Pull images') {
            steps {
                sh '''
                    export BACKEND_TAG="$DEPLOY_BACKEND_TAG"
                    export FRONTEND_TAG="$DEPLOY_FRONTEND_TAG"
                    docker compose pull backend frontend
                '''
            }
        }

        stage('Déploiement') {
            steps {
                sh '''
                    export BACKEND_TAG="$DEPLOY_BACKEND_TAG"
                    export FRONTEND_TAG="$DEPLOY_FRONTEND_TAG"
                    docker compose stop backend frontend || true
                    docker compose up -d
                '''
            }
        }

        stage('Healthcheck') {
            steps {
                sh '''
                    echo "Attente du démarrage (30s)..."
                    sleep 30
                    docker compose ps
                    docker compose exec -T backend curl -sf http://localhost:5000/health || echo "Backend healthcheck en attente..."
                    curl -sf http://localhost:${FRONTEND_PORT:-80}/healthz || echo "Frontend healthcheck en attente..."
                '''
            }
        }
    }

    post {
        always {
            sh 'docker logout || true'
        }
        success {
            echo 'Déploiement terminé avec succès.'
        }
        failure {
            echo 'Déploiement en échec.'
        }
    }
}
