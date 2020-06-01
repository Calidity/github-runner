FROM node:current-stretch-slim

ARG GITHUB_RUNNER_VERSION="2.263.0"
ARG KUBECTL_VERSION="v1.16.9"

ENV RUNNER_NAME "runner"
ENV GITHUB_PAT ""
ENV GITHUB_OWNER ""
ENV GITHUB_APP_ID ""
ENV RUNNER_WORKDIR "_work"

RUN apt-get update
RUN apt-get install -y \
        curl \
        sudo \
        git \
        jq \
        ruby \
        ssh \
        wget \
        curl \
        file \
        iputils-ping
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/*
RUN useradd -u 1001 -m github
RUN usermod -aG sudo github
RUN echo "%sudo ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
RUN gem install jwt faraday --no-doc

USER 1001
WORKDIR /home/github

RUN curl -Ls https://github.com/actions/runner/releases/download/v${GITHUB_RUNNER_VERSION}/actions-runner-linux-x64-${GITHUB_RUNNER_VERSION}.tar.gz | tar xz \
    && sudo ./bin/installdependencies.sh

# Install kubectl for managing Kubernetes clusters/deployments etc
RUN sudo curl -L -o /usr/local/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl
RUN sudo chmod +x /usr/local/bin/kubectl

COPY --chown=github:github entrypoint.rb ./entrypoint.rb
RUN sudo chmod u+x ./entrypoint.rb

ENTRYPOINT ["/home/github/entrypoint.rb"]
