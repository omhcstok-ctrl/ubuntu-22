# ============================================================
# ARA TM — Railway Ubuntu 22.04 SSH Server (Singapore)
# Modified for: Ubuntu 22.04 LTS + Asia/Singapore timezone
# ============================================================
# A Docker image that provides Ubuntu 22.04 base with SSH server
# (SSHD) enabled, so you can connect to your Railway container via SSH.

FROM ubuntu:22.04

# Remove default "ubuntu" user if it exists (22.04 base doesn't have it, safe with || true)
RUN userdel -r ubuntu 2>/dev/null || true

# Enable universe + multiverse for Ubuntu 22.04 (uses classic sources.list format)
RUN sed -i 's/^\(deb .*jammy.*\) main restricted$/\1 main restricted universe multiverse/' /etc/apt/sources.list 2>/dev/null || true

# Install dependencies (Ubuntu 22.04 compatible)
RUN apt-get update \
    && apt-get install -y \
        ca-certificates gnupg apt-transport-https software-properties-common \
        openssh-server \
        curl wget \
        iproute2 iputils-ping net-tools dnsutils traceroute whois telnet nmap \
        vim nano micro \
        htop btop ncdu neofetch \
        tmux screen less tree bat ripgrep fd-find jq zsh \
        unzip zip tar gzip bzip2 xz-utils p7zip-full \
        git build-essential cmake pkg-config autoconf automake libtool gcc g++ \
        python3 python3-pip python3-venv python3-dev \
        locales ncurses-term language-pack-en language-pack-fa \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && mkdir -p /run/sshd \
    && chmod 755 /run/sshd \
    && ssh-keygen -A \
    && echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config \
    && echo "PermitRootLogin yes" >> /etc/ssh/sshd_config

# ------------------------------------------------------------
# Node.js 20 LTS via NodeSource
# Ubuntu 22.04 apt ships Node v12 → too old for Claude Code (needs >=18)
# ------------------------------------------------------------
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Generate English + Persian locales
RUN locale-gen en_US.UTF-8 fa_IR.UTF-8

# Set timezone Asia/Singapore
RUN ln -sf /usr/share/zoneinfo/Asia/Singapore /etc/localtime \
    && echo "Asia/Singapore" > /etc/timezone

# ARA TM welcome banner
COPY ara-welcome.sh /etc/profile.d/ara-welcome.sh
RUN chmod +x /etc/profile.d/ara-welcome.sh

# Locale + terminal env
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8
ENV TERM=xterm-256color
ENV TZ=Asia/Singapore

# Claude Code settings
ARG ANTHROPIC_AUTH_TOKEN=""
COPY claude-settings.json /root/.claude/settings.json
RUN sed -i "s|__ANTHROPIC_AUTH_TOKEN__|${ANTHROPIC_AUTH_TOKEN}|g" /root/.claude/settings.json

# Install Claude Code globally
RUN npm install -g @anthropic-ai/claude-code

# SSH user config script
COPY ssh-user-config.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/ssh-user-config.sh

# "cl" helper (tmux + Claude Code)
COPY cl /usr/local/bin/cl
RUN chmod +x /usr/local/bin/cl \
    && ln -sf /usr/local/bin/cl /usr/local/bin/زم

# "usage" command
COPY usage /usr/local/bin/usage
RUN chmod +x /usr/local/bin/usage

# "src-sync" command
COPY src-sync.sh /usr/local/bin/src-sync
RUN chmod +x /usr/local/bin/src-sync \
    && mkdir -p /root/src

# Expose SSH port
EXPOSE 22

# Start SSH
CMD ["/usr/local/bin/ssh-user-config.sh"]