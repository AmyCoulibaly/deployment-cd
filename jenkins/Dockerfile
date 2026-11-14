FROM jenkins/jenkins:lts-jdk21

USER root

# Docker CLI + Compose (pour builder/pusher les images)
RUN apt-get update && apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    && curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list \
    && apt-get update && apt-get install -y docker-ce-cli docker-compose-plugin \
    && rm -rf /var/lib/apt/lists/*

# Trivy (scanner de vulnérabilités)
RUN curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin

# Permissions Docker socket — jenkins dans le groupe docker
RUN groupadd -g 999 docker || true && usermod -aG docker jenkins

USER jenkins

# Plugins Jenkins pré-installés
RUN jenkins-plugin-cli --plugins \
    git \
    workflow-aggregator \
    pipeline-stage-view \
    docker-workflow \
    credentials-binding \
    github \
    github-branch-source
