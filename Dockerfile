# ============================================================
# ARA TM — Railway Debian 12 SSH Server (Singapore)
# Modified for: Debian 12 Bookworm + Asia/Singapore timezone
# ============================================================
# A Docker image that provides Debian 12 base with SSH server
# (SSHD) enabled, so you can connect to your Railway container via SSH.

FROM debian:12

# Install dependencies (Debian 12 compatible)
RUN apt-get update \
    && apt-get install -y \
        ca-certificates gnupg curl wget \
        openssh-server \
        iproute2 iputils-ping net-tools dnsutils traceroute whois telnet nmap \
        vim nano \
        htop ncdu \
        tmux screen less tree bat ripgrep fd-find jq zsh \
        unzip zip tar gzip bzip2 xz-utils p7zip-full \
        git build-essential cmake pkg-config autoconf automake libtool gcc g++ \
        python3 python3-pip python3-venv python3-dev \
        locales ncurses-term \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && mkdir -p /run/sshd \
    && chmod 755 /run/sshd \
    && ssh-keygen -A \
    && echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config \
    && echo "PermitRootLogin yes" >> /etc/ssh/sshd_config

# ------------------------------------------------------------
# Node.js 20 LTS via NodeSource
# ------------------------------------------------------------
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Generate English locale (Debian tidak punya language-pack)
RUN sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
    && locale-gen

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

# Set default hostname
RUN echo "OmhcServer" > /etc/hostname && \
    echo "127.0.1.1 OmhcServer" >> /etc/hosts

# Expose SSH port
EXPOSE 22

# Start SSH
CMD ["/usr/local/bin/ssh-user-config.sh"]
