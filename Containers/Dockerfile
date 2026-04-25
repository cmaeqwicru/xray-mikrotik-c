# Этап 1: скачать и распаковать бинари под нужную архитектуру
FROM alpine AS downloader

ARG TARGETARCH
ARG TARGETVARIANT
ARG XRAY_VERSION
ARG TUN2SOCKS_VERSION

RUN apk add --no-cache curl unzip

# Xray-core
RUN set -ex; \
    case "${TARGETARCH}" in \
      amd64) FILE="Xray-linux-64.zip" ;; \
      arm64) FILE="Xray-linux-arm64-v8a.zip" ;; \
      arm)   FILE="Xray-linux-arm32-v7a.zip" ;; \
      *)     echo "Unsupported arch: ${TARGETARCH}"; exit 1 ;; \
    esac; \
    curl -fL "https://github.com/XTLS/Xray-core/releases/download/${XRAY_VERSION}/${FILE}" \
         -o /tmp/xray.zip; \
    mkdir -p /opt/xray; \
    unzip /tmp/xray.zip xray -d /opt/xray/; \
    chmod +x /opt/xray/xray

# tun2socks
RUN set -ex; \
    case "${TARGETARCH}${TARGETVARIANT}" in \
      amd64)  FILE="tun2socks-linux-amd64.zip" ;; \
      arm64)  FILE="tun2socks-linux-arm64.zip" ;; \
      armv7)  FILE="tun2socks-linux-arm7.zip" ;; \
      *)      echo "Unsupported arch+variant: ${TARGETARCH}${TARGETVARIANT}"; exit 1 ;; \
    esac; \
    curl -fL "https://github.com/xjasonlyu/tun2socks/releases/download/${TUN2SOCKS_VERSION}/${FILE}" \
         -o /tmp/tun2socks.zip; \
    mkdir -p /opt/tun2socks; \
    unzip /tmp/tun2socks.zip -d /tmp/t2s/; \
    find /tmp/t2s/ -type f -name 'tun2socks*' -exec mv {} /opt/tun2socks/tun2socks \;; \
    chmod +x /opt/tun2socks/tun2socks

# Этап 2: минимальный рантайм
FROM alpine:3.21

RUN apk add --no-cache bash openrc openresolv iproute2 ca-certificates

COPY --from=downloader /opt/xray/xray          /opt/xray/xray
COPY --from=downloader /opt/tun2socks/tun2socks /opt/tun2socks/tun2socks

RUN mkdir -p /opt/xray/config

COPY start.sh /opt/start.sh
RUN chmod +x /opt/start.sh && sed -i 's/\r//' /opt/start.sh

RUN sed -i 's/^tty/#tty/' /etc/inittab

ENTRYPOINT ["sh", "-c"]
CMD ["/bin/bash /opt/start.sh && /sbin/init"]

# https://github.com/XTLS/Xray-core
# https://github.com/xjasonlyu/tun2socks
