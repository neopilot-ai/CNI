# alpine-certificates:
# - Alpine, with ca-certificates installed. We can't assume that we'll be able
#   operate as root, or access the internet to install the package.
# - This image is intended to be based on alpine:latest, which is currently 3.19.
#   We're doing this to ensure the latest ca-certificates package.
ARG ALPINE_VERSION=3.19
FROM alpine:$ALPINE_VERSION

# Install ca-certificates and security updates
RUN apk update && \
    apk upgrade && \
    apk add --no-cache ca-certificates=20240226-r0 && \
    rm -rf /var/cache/apk/*

# Create non-root user for security
RUN addgroup -g 1001 -S certuser && \
    adduser -S -D -H -u 1001 -h /tmp -s /sbin/nologin -G certuser certuser

# Copy scripts and set permissions
COPY --chown=certuser:certuser scripts/ /scripts/
RUN chmod +x /scripts/bundle-certificates

# Create directories with proper permissions
RUN mkdir -p /etc/ssl/certs /usr/local/share/ca-certificates && \
    chown -R certuser:certuser /etc/ssl/certs /usr/local/share/ca-certificates

VOLUME ["/etc/ssl/certs", "/usr/local/share/ca-certificates"]

# Switch to non-root user
USER certuser

# Add health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD test -f /etc/ssl/certs/ca-certificates.crt || exit 1

CMD ["/scripts/bundle-certificates"]
