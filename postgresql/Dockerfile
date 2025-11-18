# Multi-stage build for PostgreSQL
FROM debian:bookworm-slim as builder

ARG BUILD_DIR=/tmp/build
ARG PG_VERSION=16.1
ARG PG_USER=postgres
ARG PG_UID=999

ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
ENV DEBIAN_FRONTEND=noninteractive

# Install build dependencies
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
        build-essential \
        autoconf \
        bison \
        flex \
        libbison-dev \
        libreadline-dev \
        libssl-dev \
        libxml2-dev \
        libxslt1-dev \
        libz-dev \
        libicu-dev \
        libossp-uuid-dev \
        libsystemd-dev \
        pkg-config \
        curl \
        ca-certificates \
        gnupg2 \
        && rm -rf /var/lib/apt/lists/* \
    && mkdir -p ${BUILD_DIR}

# Build PostgreSQL from source
RUN cd ${BUILD_DIR} && \
    curl -fsSL https://ftp.postgresql.org/pub/source/v${PG_VERSION}/postgresql-${PG_VERSION}.tar.gz -o postgresql.tar.gz && \
    curl -fsSL https://ftp.postgresql.org/pub/source/v${PG_VERSION}/postgresql-${PG_VERSION}.tar.gz.sha256 -o postgresql.tar.gz.sha256 && \
    sha256sum -c postgresql.tar.gz.sha256 && \
    tar -xzf postgresql.tar.gz && \
    rm postgresql.tar.gz postgresql.tar.gz.sha256 && \
    cd postgresql-${PG_VERSION} && \
    ./configure \
        --prefix=/usr/local/pgsql \
        --with-openssl \
        --with-libedit-preferred \
        --with-uuid=ossp \
        --with-icu \
        --with-systemd \
        --enable-thread-safety \
        --enable-debug \
        --disable-rpath && \
    make -j "$(nproc)" world && \
    make -j "$(nproc)" install-world && \
    cd / && \
    rm -rf ${BUILD_DIR}

# Runtime stage
FROM debian:bookworm-slim

ARG PG_USER=postgres
ARG PG_UID=999
ARG PG_DATA_DIR=/var/lib/postgresql/data

ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
ENV PGDATA=${PG_DATA_DIR}
ENV PATH=/usr/local/pgsql/bin:$PATH

# Install runtime dependencies
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
        libssl3 \
        libxml2 \
        libxslt1.1 \
        libicu72 \
        libreadline8 \
        libossp-uuid16 \
        ca-certificates \
        curl \
        gnupg2 \
        && rm -rf /var/lib/apt/lists/*

# Create postgres user and directories
RUN groupadd -r -g ${PG_UID} ${PG_USER} && \
    useradd -r -m -g ${PG_USER} -u ${PG_UID} ${PG_USER} && \
    mkdir -p ${PG_DATA_DIR} /var/run/postgresql && \
    chown -R ${PG_USER}:${PG_USER} ${PG_DATA_DIR} /var/run/postgresql

# Copy PostgreSQL from builder
COPY --from=builder /usr/local/pgsql /usr/local/pgsql

# Copy initialization scripts
COPY --chown=${PG_USER}:${PG_USER} scripts/ /docker-entrypoint-initdb.d/
RUN chmod +x /docker-entrypoint-initdb.d/*.sh

# Switch to postgres user
USER ${PG_USER}

# Expose PostgreSQL port
EXPOSE 5432

# Add health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD pg_isready -U ${PG_USER} -d ${PGDATA}

# Set volumes
VOLUME ["${PG_DATA_DIR}"]

# Default command
CMD ["/usr/local/pgsql/bin/postgres"]
