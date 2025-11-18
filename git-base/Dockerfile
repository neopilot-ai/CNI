# Modern Git container with essential tools
FROM debian:bookworm-slim

# Current stable versions
ARG GIT_VERSION=2.43.0
ARG USER_UID=65534

# Environment variables
ENV GIT_VERSION=${GIT_VERSION}
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
ENV DEBIAN_FRONTEND=noninteractive

# Install runtime dependencies
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        gnupg \
        openssh-client \
        openssl \
        less \
        && rm -rf /var/lib/apt/lists/*

# Download and install Git from source for latest version
RUN buildDeps=' \
        build-essential \
        autoconf \
        gettext \
        libcurl4-openssl-dev \
        libexpat1-dev \
        libssl-dev \
        libz-dev \
        perl \
        unzip \
        zlib1g-dev \
    ' && \
    apt-get update && \
    apt-get install -y --no-install-recommends $buildDeps && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /tmp/build && \
    cd /tmp/build && \
    curl -fsSL "https://github.com/git/git/archive/v${GIT_VERSION}.tar.gz" -o git.tar.gz && \
    curl -fsSL "https://github.com/git/git/archive/v${GIT_VERSION}.tar.gz.sha256" -o git.tar.gz.sha256 && \
    sha256sum -c git.tar.gz.sha256 && \
    tar -xzf git.tar.gz && \
    rm git.tar.gz git.tar.gz.sha256 && \
    cd git-${GIT_VERSION} && \
    make configure && \
    ./configure --prefix=/usr/local --with-curl --with-openssl --without-tcltk && \
    make -j "$(nproc)" all && \
    make -j "$(nproc)" install && \
    cd / && \
    rm -rf /tmp/build && \
    apt-get purge -y --auto-remove $buildDeps && \
    git --version

# Install additional useful Git-related tools
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git-lfs \
        git-secret \
        && rm -rf /var/lib/apt/lists/*

# Create non-root user for security
RUN groupadd -r -g ${USER_UID} gituser && \
    useradd -r -m -g gituser -u ${USER_UID} gituser && \
    mkdir -p /home/gituser/.ssh /home/gituser/.gitconfig && \
    chown -R gituser:gituser /home/gituser/.ssh /home/gituser/.gitconfig && \
    chmod 700 /home/gituser/.ssh

# Switch to non-root user
USER gituser

# Set working directory
WORKDIR /home/gituser

# Add Git to PATH
ENV PATH="/usr/local/bin:$PATH"

# Configure Git defaults
RUN git config --global init.defaultBranch main && \
    git config --global pull.rebase false && \
    git config --global user.name "Git User" && \
    git config --global user.email "gituser@example.com"

# Add health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD git --version && ssh -V || exit 1

# Expose SSH port for Git operations
EXPOSE 22

# Set volumes
VOLUME ["/home/gituser/.ssh", "/home/gituser/.gitconfig"]

# Default command
CMD ["/bin/bash"]
