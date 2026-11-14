pipeline {
    agent any

    parameters {
        string(
            name: 'BACKEND_TAG',
            defaultValue: 'latest',
            description: 'Tag de l’image backend à déployer'
        )

        string(
            name: 'FRONTEND_TAG',
            defaultValue: 'latest',
            description: 'Tag de l’image frontend à déployer'
        )
    }

    environment {
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')

        DEPLOY_BACKEND_TAG  = "${params.BACKEND_TAG}"
        DEPLOY_FRONTEND_TAG = "${params.FRONTEND_TAG}"

        NOTIFICATION_EMAIL = 'ndeyeamycoulibaly1@gmail.com'
    }

    options {
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '20'))
        timeout(time: 15, unit: 'MINUTES')
        timestamps()
    }

    stages {

        // =========================================================
        // 1. RÉCUPÉRATION DU CODE
        // =========================================================

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        // =========================================================
        // 2. VÉRIFICATION DE LA CONFIGURATION
        // =========================================================

        stage('Vérification .env') {
            steps {
                sh '''
                    if [ ! -f .env ]; then
                        echo "ERREUR : fichier .env absent."
                        exit 1
                    fi

                    echo "Fichier .env trouvé."
                '''
            }
        }

        // =========================================================
        // 3. AUTHENTIFICATION DOCKER HUB
        // =========================================================

        stage('Docker Login') {
            steps {
                sh '''
                    set +x

                    echo "$DOCKERHUB_CREDENTIALS_PSW" | \
                    docker login \
                        -u "$DOCKERHUB_CREDENTIALS_USR" \
                        --password-stdin
                '''
            }
        }

        // =========================================================
        // 4. RÉCUPÉRATION DES IMAGES
        // =========================================================

        stage('Pull images') {
            steps {
                sh '''
                    export BACKEND_TAG="$DEPLOY_BACKEND_TAG"
                    export FRONTEND_TAG="$DEPLOY_FRONTEND_TAG"

                    echo "Téléchargement des images Docker..."

                    docker compose pull backend frontend
                '''
            }
        }

        // =========================================================
        // 5. DÉPLOIEMENT
        // =========================================================

        stage('Déploiement') {
            steps {
                sh '''
                    export BACKEND_TAG="$DEPLOY_BACKEND_TAG"
                    export FRONTEND_TAG="$DEPLOY_FRONTEND_TAG"

                    echo "Arrêt des anciens services..."

                    docker compose stop backend frontend || true

                    echo "Démarrage des nouveaux services..."

                    docker compose up -d

                    echo "Déploiement terminé."
                '''
            }
        }

        // =========================================================
        // 6. VÉRIFICATION DE LA SANTÉ DES SERVICES
        // =========================================================

        stage('Healthcheck') {
            steps {
                sh '''
                    export BACKEND_TAG="$DEPLOY_BACKEND_TAG"
                    export FRONTEND_TAG="$DEPLOY_FRONTEND_TAG"

                    echo "Attente du démarrage des services (30 secondes)..."

                    sleep 30

                    echo "État des conteneurs :"

                    docker compose ps

                    echo "Vérification du backend..."

                    docker compose exec -T backend \
                        curl -sf http://localhost:5000/health \
                        || echo "Backend healthcheck en attente."

                    echo "Vérification du frontend..."

                    curl -sf http://127.0.0.1:${FRONTEND_PORT:-80}/healthz \
                        || echo "Frontend healthcheck en attente."
                '''
            }
        }
    }

    // =============================================================
    // 7. ACTIONS POST-EXÉCUTION
    // =============================================================

    post {

        // ---------------------------------------------------------
        // TOUJOURS EXÉCUTÉ
        // ---------------------------------------------------------

        always {
            script {
                sh 'docker logout || true'

                def duration = currentBuild.durationString
                def status = currentBuild.currentResult ?: 'UNKNOWN'

                echo """
╔══════════════════════════════════════════════════════════╗
║             RAPPORT DE DÉPLOIEMENT — e-Santé Sénégal    ║
╠══════════════════════════════════════════════════════════╣
║  Statut    : ${status}
║  Backend   : ${env.DEPLOY_BACKEND_TAG}
║  Frontend  : ${env.DEPLOY_FRONTEND_TAG}
║  Build #   : ${env.BUILD_NUMBER}
║  Durée     : ${duration}
║  URL       : ${env.BUILD_URL}
╚══════════════════════════════════════════════════════════╝
"""
            }
        }

        // ---------------------------------------------------------
        // DÉPLOIEMENT RÉUSSI
        // ---------------------------------------------------------

        success {
            script {
                echo 'Déploiement terminé avec succès.'

                try {
                    emailext(
                        to: env.NOTIFICATION_EMAIL,

                        subject: "[e-Santé] Déploiement #${env.BUILD_NUMBER} réussi",

                        mimeType: 'text/html',

                        body: """
                            <html>
                            <body>
                                <h2 style="color:green;">
                                    Déploiement réussi
                                </h2>

                                <p>
                                    Le déploiement de e-Santé Sénégal
                                    s'est terminé avec succès.
                                </p>

                                <table border="1" cellpadding="8" cellspacing="0">
                                    <tr>
                                        <td><strong>Statut</strong></td>
                                        <td>SUCCESS</td>
                                    </tr>
                                    <tr>
                                        <td><strong>Backend</strong></td>
                                        <td>${env.DEPLOY_BACKEND_TAG}</td>
                                    </tr>
                                    <tr>
                                        <td><strong>Frontend</strong></td>
                                        <td>${env.DEPLOY_FRONTEND_TAG}</td>
                                    </tr>
                                    <tr>
                                        <td><strong>Build</strong></td>
                                        <td>#${env.BUILD_NUMBER}</td>
                                    </tr>
                                    <tr>
                                        <td><strong>Durée</strong></td>
                                        <td>${currentBuild.durationString}</td>
                                    </tr>
                                </table>

                                <p>
                                    <a href="${env.BUILD_URL}">
                                        Consulter le build Jenkins
                                    </a>
                                </p>

                            </body>
                            </html>
                        """
                    )

                    echo 'Notification de succès envoyée.'

                } catch (Exception e) {
                    echo "Échec de la notification : ${e.message}"
                }
            }
        }

        // ---------------------------------------------------------
        // DÉPLOIEMENT EN ÉCHEC
        // ---------------------------------------------------------

        failure {
            script {
                echo 'Déploiement en échec.'

                try {
                    emailext(
                        to: env.NOTIFICATION_EMAIL,

                        subject: "[e-Santé] Déploiement #${env.BUILD_NUMBER} en échec",

                        mimeType: 'text/html',

                        body: """
                            <html>
                            <body>
                                <h2 style="color:red;">
                                    Échec du déploiement
                                </h2>

                                <p>
                                    Le déploiement de e-Santé Sénégal
                                    a échoué.
                                </p>

                                <table border="1" cellpadding="8" cellspacing="0">
                                    <tr>
                                        <td><strong>Statut</strong></td>
                                        <td>FAILURE</td>
                                    </tr>
                                    <tr>
                                        <td><strong>Backend</strong></td>
                                        <td>${env.DEPLOY_BACKEND_TAG}</td>
                                    </tr>
                                    <tr>
                                        <td><strong>Frontend</strong></td>
                                        <td>${env.DEPLOY_FRONTEND_TAG}</td>
                                    </tr>
                                    <tr>
                                        <td><strong>Build</strong></td>
                                        <td>#${env.BUILD_NUMBER}</td>
                                    </tr>
                                    <tr>
                                        <td><strong>Durée</strong></td>
                                        <td>${currentBuild.durationString}</td>
                                    </tr>
                                </table>

                                <p>
                                    <a href="${env.BUILD_URL}console">
                                        Consulter les logs Jenkins
                                    </a>
                                </p>

                            </body>
                            </html>
                        """
                    )

                    echo 'Notification d'échec envoyée.'

                } catch (Exception e) {
                    echo "Échec de la notification : ${e.message}"
                }
            }
        }

        // ---------------------------------------------------------
        // DÉPLOIEMENT INTERROMPU
        // ---------------------------------------------------------

        aborted {
            script {
                echo 'Déploiement interrompu.'

                try {
                    emailext(
                        to: env.NOTIFICATION_EMAIL,

                        subject: "[e-Santé] Déploiement #${env.BUILD_NUMBER} interrompu",

                        mimeType: 'text/html',

                        body: """
                            <html>
                            <body>
                                <h2 style="color:orange;">
                                    Déploiement interrompu
                                </h2>

                                <p>
                                    Le déploiement de e-Santé Sénégal
                                    a été interrompu.
                                </p>

                                <ul>
                                    <li>Backend : ${env.DEPLOY_BACKEND_TAG}</li>
                                    <li>Frontend : ${env.DEPLOY_FRONTEND_TAG}</li>
                                    <li>Build : #${env.BUILD_NUMBER}</li>
                                    <li>Durée : ${currentBuild.durationString}</li>
                                </ul>

                                <p>
                                    <a href="${env.BUILD_URL}">
                                        Consulter le build Jenkins
                                    </a>
                                </p>
                            </body>
                            </html>
                        """
                    )

                    echo 'Notification d'interruption envoyée.'

                } catch (Exception e) {
                    echo "Échec de la notification : ${e.message}"
                }
            }
        }
    }
}