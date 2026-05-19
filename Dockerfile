FROM ubuntu:26.04 AS runtime

ARG NVM_VERSION=0.40.4
ARG NODE_VERSION=25

ARG DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-c"]

WORKDIR /root
USER root

RUN apt-get update
RUN apt-get install -y build-essential
RUN apt-get install -y unzip zip bzip2 xz-utils tar
RUN apt-get install -y pkg-config libssl-dev libffi-dev zlib1g-dev
RUN apt-get install -y libicu-dev
RUN apt-get install -y sudo gnupg2
RUN apt-get install -y ca-certificates bash curl less wget openssh-client
RUN apt-get install -y ripgrep fd-find tree procps jq yq lsof iproute2 netcat-openbsd
RUN apt-get install -y git gh

# Python
RUN curl -LsSf https://astral.sh/uv/install.sh | bash
ENV PATH="/root/.local/bin/:$PATH"
RUN uv python install 3.11 3.12 3.13 3.14
RUN uv python install --default

# NODE
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v$NVM_VERSION/install.sh | bash
ENV NVM_DIR=/root/.nvm
RUN . $NVM_DIR/nvm.sh && \
    nvm install $NODE_VERSION && \
    nvm alias default $NODE_VERSION && \
    nvm use default && \
    ln -s $(which node) /usr/local/bin/node && \
    ln -s $(which npm) /usr/local/bin/npm && \
    ln -s $(which npx) /usr/local/bin/npx

# Bun
RUN curl -fsSL https://bun.com/install | bash
ENV PATH="/root/.bun/bin:${PATH}"

# Vite Plus
RUN curl -fsSL https://vite.plus | bash
ENV PATH="/root/.vite-plus:${PATH}"

RUN bun add -g opencode-ai
RUN curl -fsSL https://raw.githubusercontent.com/openchamber/openchamber/main/scripts/install.sh | bash

# Go
RUN wget -O /tmp/go.tgz "https://go.dev/dl/$(curl "https://go.dev/VERSION?m=text" | head -n1).linux-amd64.tar.gz"
RUN rm -rf /usr/local/go
RUN tar -C /usr/local -xzf /tmp/go.tgz
RUN rm /tmp/go.tgz
ENV PATH="/usr/local/go/bin:${PATH}"

RUN mkdir -p /root/.local /root/.config /root/.ssh

EXPOSE 3000

ENV OPENCODE_CONFIG_DIR="${HOME}/.config/opencode"
ENV OPENCHAMBER_OPENCODE_HOSTNAME=0.0.0.0
ENV OPENCHAMBER_HOST=0.0.0.0
ENV UI_PASSWORD=""
ENTRYPOINT ["openchamber", "--foreground"]