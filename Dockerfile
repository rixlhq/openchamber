# syntax=docker/dockerfile:1
FROM oven/bun:1 AS base
WORKDIR /app

FROM base AS deps
WORKDIR /app
COPY package.json bun.lock ./
COPY packages/ui/package.json ./packages/ui/
COPY packages/web/package.json ./packages/web/
COPY packages/desktop/package.json ./packages/desktop/
COPY packages/vscode/package.json ./packages/vscode/
RUN bun install --ignore-scripts

FROM deps AS builder
WORKDIR /app
COPY . .
RUN bun run build:web

FROM mcr.microsoft.com/devcontainers/universal:6 AS runtime
WORKDIR /root

RUN apt-get update && apt-get install -y --no-install-recommends \
  bash ca-certificates git less openssh-client python3 sudo \
  && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://bun.com/install | bash
RUN curl -fsSL https://vite.plus | bash
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# Go
RUN wget -O /tmp/go.tgz "https://go.dev/dl/$(curl "https://go.dev/VERSION?m=text" | head -n1).linux-amd64.tar.gz"
RUN rm -rf /usr/local/go \
    && tar -C /usr/local -xzf /tmp/go.tgz \
    && rm /tmp/go.tgz \

ENV PATH="/root/.bun/bin:/root/.vite-plus/bin:/root/.local/bin:/usr/local/go/bin:${PATH}"

RUN mkdir -p /root/.local /root/.config /root/.ssh && \
  bun add -g opencode-ai

# cloudflared 2026.3.0 - update digest explicitly when upgrading
COPY --from=cloudflare/cloudflared@sha256:6b599ca3e974349ead3286d178da61d291961182ec3fe9c505e1dd02c8ac31b0 /usr/local/bin/cloudflared /usr/local/bin/cloudflared

ENV NODE_ENV=production

COPY scripts/docker-entrypoint.sh /root/openchamber-entrypoint.sh

COPY --from=deps /app/node_modules ./node_modules
COPY --from=deps /app/packages/web/node_modules ./packages/web/node_modules
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/packages/web/package.json ./packages/web/package.json
COPY --from=builder /app/packages/web/bin ./packages/web/bin
COPY --from=builder /app/packages/web/server ./packages/web/server
COPY --from=builder /app/packages/web/dist ./packages/web/dist

EXPOSE 3000

ENTRYPOINT ["sh", "/root/openchamber-entrypoint.sh"]
