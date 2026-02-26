FROM ubuntu:24.04

ARG IMAGE_ROLE_PROFILE=implementation-specialist
ARG NODE_VERSION=20.19.0

RUN set -eux; \
    APT_OPTIONS="-o Acquire::Retries=5 -o Acquire::http::No-Cache=true -o Acquire::http::Pipeline-Depth=0"; \
    for attempt in 1 2 3 4 5; do \
      if apt-get ${APT_OPTIONS} update && \
         apt-get ${APT_OPTIONS} install -y --no-install-recommends \
           git curl ca-certificates openssh-client gnupg jq unzip \
           poppler-utils mupdf-tools python3 python3-pip python3-venv docker.io; then \
        break; \
      fi; \
      if [ "${attempt}" -eq 5 ]; then \
        exit 1; \
      fi; \
      rm -rf /var/lib/apt/lists/*; \
      sleep $((attempt * 3)); \
    done; \
    rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    arch="$(dpkg --print-architecture)"; \
    case "${arch}" in \
      amd64) node_arch="x64" ;; \
      arm64) node_arch="arm64" ;; \
      *) echo "Unsupported architecture: ${arch}" >&2; exit 1 ;; \
    esac; \
    curl -fsSLO "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${node_arch}.tar.gz"; \
    tar -xzf "node-v${NODE_VERSION}-linux-${node_arch}.tar.gz" -C /usr/local --strip-components=1 --no-same-owner; \
    rm "node-v${NODE_VERSION}-linux-${node_arch}.tar.gz"; \
    node --version; \
    npm --version

RUN npm i -g @openai/codex


# TODO: Candidate packages discovered by agents
#
# When an agent installs a new package interactively using apt-get, it MUST also
# add a commented "candidate" line below so a human can decide whether to bake
# it into the image. Use the exact apt-get install line that was used.
#
# Examples:
# RUN apt-get update && apt-get install -y --no-install-recommends \
#     tree ripgrep \
#   && rm -rf /var/lib/apt/lists/*
#
# Candidate lines (append below):


# Install GitHub CLI (gh)
RUN mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      | dd of=/etc/apt/keyrings/githubcli-archive-keyring.gpg && \
    chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      > /etc/apt/sources.list.d/github-cli.list && \
    apt-get update && apt-get install -y gh \
  && rm -rf /var/lib/apt/lists/*

COPY .devcontainer-workstation/codex/config.toml /etc/codex/config.toml
COPY .devcontainer-workstation/codex/role-profiles /etc/codex/role-profiles
COPY 10-templates/agent-instructions /etc/codex/agent-instructions
COPY 10-templates/compliance-officer-pr-review-brief.md /etc/codex/agent-instructions/references/compliance-officer-pr-review-brief.md
COPY .devcontainer-workstation/generated/runtime-role-instructions /tmp/generated/runtime-role-instructions
RUN set -eux; \
    base_file="/etc/codex/agent-instructions/base.md"; \
    role_file="/etc/codex/agent-instructions/roles/${IMAGE_ROLE_PROFILE}.md"; \
    compliance_brief_file="/etc/codex/agent-instructions/references/compliance-officer-pr-review-brief.md"; \
    generated_role_file="/tmp/generated/runtime-role-instructions/${IMAGE_ROLE_PROFILE}.md"; \
    target_dir="/etc/codex/runtime-role-instructions"; \
    target_file="${target_dir}/${IMAGE_ROLE_PROFILE}.md"; \
    test -f "$base_file"; \
    test -f "$role_file"; \
    mkdir -p "$target_dir"; \
    { \
      echo "# Runtime Role Instructions"; \
      echo; \
      echo "Generated at image build time by .devcontainer-workstation/Dockerfile"; \
      echo "Role profile: ${IMAGE_ROLE_PROFILE}"; \
      echo "Source: image:/etc/codex/agent-instructions"; \
      echo; \
      cat "$base_file"; \
      echo; \
      cat "$role_file"; \
      if [ "$IMAGE_ROLE_PROFILE" = "compliance-officer" ]; then \
        test -f "$compliance_brief_file"; \
        echo; \
        echo "# Embedded Compliance Review Brief"; \
        echo; \
        cat "$compliance_brief_file"; \
      fi; \
    } > "$target_file"; \
    if [ -f "$generated_role_file" ]; then \
      cp "$generated_role_file" "$target_file"; \
      echo "Overrode runtime role instructions from generated role-repo source: ${generated_role_file}"; \
    fi; \
    chmod 644 "$target_file"
COPY .devcontainer-workstation/scripts/init-workstation.sh /usr/local/bin/init-workstation.sh
COPY .devcontainer-workstation/scripts/setup-role-github-app-auth.sh /usr/local/bin/setup-role-github-app-auth.sh
COPY .devcontainer-workstation/scripts/remint-role-github-app-auth.sh /usr/local/bin/remint-role-github-app-auth.sh
COPY .devcontainer-workstation/scripts/gh-role.sh /usr/local/bin/gh-role
COPY .devcontainer-workstation/scripts/verify-runtime-policy.sh /usr/local/bin/verify-runtime-policy
RUN chmod +x /usr/local/bin/init-workstation.sh /usr/local/bin/setup-role-github-app-auth.sh /usr/local/bin/remint-role-github-app-auth.sh /usr/local/bin/gh-role /usr/local/bin/verify-runtime-policy
ENV IMAGE_ROLE_PROFILE=${IMAGE_ROLE_PROFILE}

WORKDIR /workspace
