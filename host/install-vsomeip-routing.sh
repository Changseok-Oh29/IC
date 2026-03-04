#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# One-time host setup for IC cluster on Jetson Orin Nano (JetPack 6.2.1)
#
# Run once from the IC repo root:
#   bash host/install-vsomeip-routing.sh
#
# What this does:
#   1. Extracts routingmanagerd from ic-deps Docker image to host
#   2. Installs vsomeip-routing systemd service
#   3. Sets static IP 192.168.1.101 on enP8p1s0 (netplan)
#   4. Installs SOME/IP multicast route as a systemd service
# ─────────────────────────────────────────────────────────────────────────────

set -e

REPO_PATH="$(cd "$(dirname "$0")/.." && pwd)"

# ── 1. routingmanagerd binary + libs ─────────────────────────────────────────
echo "[install] Creating directories..."
sudo mkdir -p /opt/ic-deps/bin /opt/ic-deps/lib

echo "[install] Stopping vsomeip-routing if running..."
sudo systemctl stop vsomeip-routing 2>/dev/null || true

echo "[install] Extracting routingmanagerd from ic-deps image..."
docker run --rm \
    -v /opt/ic-deps:/target \
    ic-deps:latest \
    sh -c "cp /opt/ic-deps/bin/routingmanagerd /target/bin/ && \
           cp -r /opt/ic-deps/lib/. /target/lib/"

echo "[install] Setting up library path..."
echo "/opt/ic-deps/lib" | sudo tee /etc/ld.so.conf.d/ic-deps.conf
sudo ldconfig

# ── 2. vsomeip-routing systemd service ───────────────────────────────────────
echo "[install] Installing vsomeip-routing service..."
sed "s|__REPO_PATH__|${REPO_PATH}|g" host/vsomeip-routing.service | \
    sudo tee /etc/systemd/system/vsomeip-routing.service > /dev/null

# ── 3. Static ethernet IP via netplan ────────────────────────────────────────
echo "[install] Setting static IP 192.168.1.101 on enP8p1s0..."
sudo mkdir -p /etc/netplan
sudo tee /etc/netplan/10-ic-eth.yaml > /dev/null << 'EOF'
network:
  version: 2
  ethernets:
    enP8p1s0:
      addresses:
        - 192.168.1.101/24
EOF
sudo chmod 600 /etc/netplan/10-ic-eth.yaml
sudo netplan apply

# ── 4. SOME/IP multicast route systemd service ────────────────────────────────
echo "[install] Installing multicast route service..."
sudo tee /etc/systemd/system/ic-multicast-route.service > /dev/null << 'EOF'
[Unit]
Description=SOME/IP multicast route for IC cluster
After=network.target

[Service]
Type=oneshot
ExecStart=/sbin/ip route add 224.0.0.0/4 dev enP8p1s0
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# ── 5. Enable all services ────────────────────────────────────────────────────
sudo systemctl daemon-reload
sudo systemctl enable --now ic-multicast-route.service
sudo systemctl enable vsomeip-routing

echo ""
echo "[install] Done. vsomeip-routing config: ${REPO_PATH}/host/vsomeip-routing.json"
echo "[install] Start routing manager with:"
echo "  sudo systemctl start vsomeip-routing"
