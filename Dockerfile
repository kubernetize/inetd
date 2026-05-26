FROM debian:trixie-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends netbase openbsd-inetd && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY assets/ /

USER 65534

ENTRYPOINT ["/entrypoint.sh"]
