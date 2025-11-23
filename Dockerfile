FROM ubuntu:jammy

ENV UID=1100 GID=1100 IP=0.0.0.0 IPv6=no PORT=53 VERBOSITY=0 MANAGED=true

COPY rootfs /

RUN apt-get update -y && \
    apt-get upgrade -y && \
    apt-get install -y unbound unbound-anchor dnsutils ca-certificates && \
    apt-get clean all && \
    rm -rf /var/lib/apt/lists/* && \
    chmod +x /entry.sh && \
    groupadd --gid ${GID} dns && \
    useradd --gid ${GID} --uid ${UID} dns && \
    chown -vR dns: /etc/unbound

ENTRYPOINT ["/entry.sh"]