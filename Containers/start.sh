#!/bin/sh
echo "Starting Xray container, please wait..."
sleep 1

SERVER_IP_ADDRESS=$(ping -c 1 $SERVER_ADDRESS | awk -F'[()]' '{print $2}')

if [ -z "$SERVER_IP_ADDRESS" ]; then
  echo "Failed to resolve $SERVER_ADDRESS — configure DNS on MikroTik"
  exit 1
fi

ip tuntap del mode tun dev tun0 2>/dev/null || true
ip tuntap add mode tun dev tun0
ip addr add 172.31.200.10/30 dev tun0
ip link set dev tun0 up
ip route del default via 172.18.20.5
ip route add default via 172.31.200.10
ip route add $SERVER_IP_ADDRESS/32 via 172.18.20.5

rm -f /etc/resolv.conf
tee /etc/resolv.conf <<< "nameserver 172.18.20.5"

PQV_JSON=""
if [ -n "$PQV" ]; then
  PQV_JSON=",\"postQuantumKey\": \"$PQV\""
fi

cat <<EOF > /opt/xray/config/config.json
{
  "log": {
    "loglevel": "silent"
  },
  "inbounds": [
    {
      "port": 10800,
      "listen": "0.0.0.0",
      "protocol": "socks",
      "settings": {
        "udp": true
      },
      "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls", "quic"],
        "routeOnly": true
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "vless",
      "settings": {
        "vnext": [
          {
            "address": "$SERVER_ADDRESS",
            "port": $SERVER_PORT,
            "users": [
              {
                "id": "$USER_ID",
                "encryption": "$ENCRYPTION",
                "alterId": 0
              }
            ]
          }
        ]
      },
      "streamSettings": {
        "network": "xhttp",
        "security": "reality",
        "realitySettings": {
          "fingerprint": "$FINGERPRINT_FP",
          "serverName": "$SERVER_NAME_SNI",
          "publicKey": "$PUBLIC_KEY_PBK",
          "spiderX": "$SPIDER_X",
          "shortId": "$SHORT_ID_SID"${PQV_JSON}
        },
        "xhttpSettings": {
          "path": "$XHTTP_PATH",
          "host": "$XHTTP_HOST",
          "mode": "$XHTTP_MODE"
        }
      },
      "tag": "proxy"
    }
  ]
}
EOF

echo "Starting Xray core"
/opt/xray/xray run -config /opt/xray/config/config.json &

echo "Starting tun2socks"
/opt/tun2socks/tun2socks \
  -loglevel silent \
  -tcp-sndbuf 3m \
  -tcp-rcvbuf 3m \
  -device tun0 \
  -proxy socks5://127.0.0.1:10800 &

echo "Container is ready"
