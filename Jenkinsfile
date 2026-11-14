pipeline {
    agent any

    parameters {
        string(
            name: "BACKEND_TAG",
            defaultValue: "latest",
            description: "Tag de image backend a deployer"
        )
        string(
            name: "FRONTEND_TAG",
            defaultValue: "latest",
            description: "Tag de image frontend a deployer"
        )
    }

    environment {
        DOCKERHUB_CREDENTIALS = credentials("dockerhub-credentials")
        DEPLOY_BACKEND_TAG    = "${params.BACKEND_TAG}"
        DEPLOY_FRONTEND_TAG   = "${params.FRONTEND_TAG}"
        NOTIFICATION_EMAIL    = "ndeyeamycoulibaly27@gmail.com"
    }

    options {
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: "10"))
        timeout(time: 15, unit: "MINUTES")
    }

    stages {

        stage("Checkout") {
            steps {
                checkout scm
            }
        }

        stage("Verification .env") {
            steps {
                sh """
                    if [ ! -f .env ]; then
                        echo "ERREUR : fichier .env absent."
                        exit 1
                    fi
                    echo "Fichier .env trouve."
                """
            }
        }

        stage("Docker Login") {
            steps {
                sh """
                    set +x
                    echo "\$DOCKERHUB_CREDENTIALS_PSW" | docker login -u "\$DOCKERHUB_CREDENTIALS_USR" --password-stdin
                """
            }
        }

        stage("Pull images") {
            steps {
                sh """
                    export BACKEND_TAG="\$DEPLOY_BACKEND_TAG"
                    export FRONTEND_TAG="\$DEPLOY_FRONTEND_TAG"
                    echo "Telechargement des images Docker..."
                    docker compose pull backend frontend
                """
            }
        }

        stage("Deploiement") {
            steps {
                sh """
                    export BACKEND_TAG="\$DEPLOY_BACKEND_TAG"
                    export FRONTEND_TAG="\$DEPLOY_FRONTEND_TAG"
                    echo "Arret des anciens services..."
                    docker compose stop backend frontend || true
                    echo "Demarrage des nouveaux services..."
                    docker compose up -d
                    echo "Deploiement termine."
                """
            }
        }

        stage("Healthcheck") {
            steps {
                sh """
                    echo "Attente du demarrage des services (30 secondes)..."
                    sleep 30
                    echo "Etat des conteneurs :"
                    docker compose ps
                    echo "Verification du backend..."
                    docker compose exec -T backend curl -sf http://localhost:5000/health || echo "Backend healthcheck en attente."
                    echo "Verification du frontend..."
                    curl -sf http://127.0.0.1:\${FRONTEND_PORT:-80}/healthz || echo "Frontend healthcheck en attente."
                """
            }
        }
    }

    post {

        always {
            script {
                sh "docker logout || true"
                def duration = currentBuild.durationString
                def status   = currentBuild.currentResult ?: "UNKNOWN"
                echo """
╔══════════════════════════════════════════════════════════╗
║         RAPPORT DE DEPLOIEMENT — e-Sante Senegal        ║
╠══════════════════════════════════════════════════════════╣
║  Statut    : ${status}
║  Backend   : ${env.DEPLOY_BACKEND_TAG}
║  Frontend  : ${env.DEPLOY_FRONTEND_TAG}
║  Build #   : ${env.BUILD_NUMBER}
║  Duree     : ${duration}
║  URL       : ${env.BUILD_URL}
╚══════════════════════════════════════════════════════════╝"""
            }
        }

        success {
            script {
                echo "Deploiement termine avec succes."
                try {
                    emailext(
                        to: env.NOTIFICATION_EMAIL,
                        subject: "[e-Sante] Deploiement #${env.BUILD_NUMBER} reussi",
                        mimeType: "text/html",
                        body: """<html><body>
<h2 style="color:green;">Deploiement reussi</h2>
<p>Le deploiement de e-Sante Senegal s est termine avec succes.</p>
<table border="1" cellpadding="8" cellspacing="0">
  <tr><td><strong>Statut</strong></td><td>SUCCESS</td></tr>
  <tr><td><strong>Backend</strong></td><td>${env.DEPLOY_BACKEND_TAG}</td></tr>
  <tr><td><strong>Frontend</strong></td><td>${env.DEPLOY_FRONTEND_TAG}</td></tr>
  <tr><td><strong>Build</strong></td><td>#${env.BUILD_NUMBER}</td></tr>
  <tr><td><strong>Duree</strong></td><td>${currentBuild.durationString}</td></tr>
</table>
<p><a href="${env.BUILD_URL}">Consulter le build Jenkins</a></p>
</body></html>"""
                    )
                    echo "Notification succes envoyee."
                } catch (Exception e) {
                    echo "Notification non envoyee : ${e.message}"
                }
            }
        }

        failure {
            script {
                echo "Deploiement en echec."
                try {
                    emailext(
                        to: env.NOTIFICATION_EMAIL,
                        subject: "[e-Sante] Deploiement #${env.BUILD_NUMBER} en echec",
                        mimeType: "text/html",
                        body: """<html><body>
<h2 style="color:red;">Echec du deploiement</h2>
<p>Le deploiement de e-Sante Senegal a echoue.</p>
<table border="1" cellpadding="8" cellspacing="0">
  <tr><td><strong>Statut</strong></td><td>FAILURE</td></tr>
  <tr><td><strong>Backend</strong></td><td>${env.DEPLOY_BACKEND_TAG}</td></tr>
  <tr><td><strong>Frontend</strong></td><td>${env.DEPLOY_FRONTEND_TAG}</td></tr>
  <tr><td><strong>Build</strong></td><td>#${env.BUILD_NUMBER}</td></tr>
  <tr><td><strong>Duree</strong></td><td>${currentBuild.durationString}</td></tr>
</table>
<p><a href="${env.BUILD_URL}console">Consulter les logs Jenkins</a></p>
</body></html>"""
                    )
                    echo "Notification echec envoyee."
                } catch (Exception e) {
                    echo "Notification non envoyee : ${e.message}"
                }
            }
        }

        aborted {
            script {
                echo "Deploiement interrompu."
                try {
                    emailext(
                        to: env.NOTIFICATION_EMAIL,
                        subject: "[e-Sante] Deploiement #${env.BUILD_NUMBER} interrompu",
                        mimeType: "text/html",
                        body: """<html><body>
<h2 style="color:orange;">Deploiement interrompu</h2>
<p>Le deploiement de e-Sante Senegal a ete interrompu.</p>
<ul>
  <li>Backend : ${env.DEPLOY_BACKEND_TAG}</li>
  <li>Frontend : ${env.DEPLOY_FRONTEND_TAG}</li>
  <li>Build : #${env.BUILD_NUMBER}</li>
  <li>Duree : ${currentBuild.durationString}</li>
</ul>
<p><a href="${env.BUILD_URL}">Consulter le build Jenkins</a></p>
</body></html>"""
                    )
                    echo "Notification interruption envoyee."
                } catch (Exception e) {
                    echo "Notification non envoyee : ${e.message}"
                }
            }
        }
    }
}
