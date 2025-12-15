FROM ubuntu:jammy AS builder

WORKDIR /

ENV version=1.24.2 CFLAGS="-O2"

RUN apt-get update -y && \
    apt-get install -y build-essential libssl-dev libexpat1-dev bison flex curl pkg-config libevent-dev libhiredis-dev libnghttp2-dev libprotobuf-c-dev protobuf-c-compiler python3-dev swig python3 && \
    ln -s /usr/bin/python3 /usr/bin/python

RUN curl -o /unbound-${version}.tar.gz https://nlnetlabs.nl/downloads/unbound/unbound-${version}.tar.gz && \
    tar xzvf /unbound-${version}.tar.gz && \
    mv /unbound-${version} /unbound

WORKDIR /unbound

RUN ./configure --build=x86_64-linux-gnu --prefix=/usr --includedir=${prefix}/include --mandir=${prefix}/share/man --infodir=${prefix}/share/info --sysconfdir=/etc --localstatedir=/var --disable-option-checking \
    --disable-silent-rules --libdir=${prefix}/lib/x86_64-linux-gnu --libexecdir=${prefix}/lib/x86_64-linux-gnu --disable-maintainer-mode --disable-dependency-tracking --disable-rpath \
    --with-pidfile=/run/unbound.pid --with-rootkey-file=/var/lib/unbound/root.key --with-libevent --with-libnghttp2 --with-pythonmodule --enable-subnet --enable-dnstap --with-chroot-dir= \
    --with-dnstap-socket-path=/run/dnstap.sock --libdir=/usr/lib --enable-cachedb --with-libhiredis && \
    make

FROM ubuntu:jammy

COPY --from=builder /unbound /unbound
COPY rootfs /

ENV UID=1100 GID=1100 IP=0.0.0.0 IPv6=no PORT=53 VERBOSITY=0 MANAGED=true

WORKDIR /unbound

RUN apt-get update -y && \
    apt-get upgrade -y && \
    apt-get install -y make binutils dnsutils ca-certificates dns-root-data libexpat1 libmpdec3 libprotobuf-c1 libpython3.10 libpython3.10-minimal libpython3.10-stdlib libreadline8 libsqlite3-0 libunbound8 libhiredis0.14 media-types readline-common && \
    apt-get clean all && \
    rm -rf /var/lib/apt/lists/* && \
    make install && \
    chmod +x /entry.sh && \
    groupadd --gid ${GID} dns && \
    useradd --gid ${GID} --uid ${UID} dns && \
    chown -vR dns: /etc/unbound

ENTRYPOINT ["/entry.sh"]