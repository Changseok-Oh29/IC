#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# Install vsomeip routing manager on Jetpack host
#
# Extracts the routingmanagerd binary and libs from the ic-deps Docker image.
#
# Run once from the IC repo root:
#   bash host/install-vsomeip-routing.sh
#
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

# ── 3. Enable vsomeip-routing service ────────────────────────────────────────
sudo systemctl daemon-reload
sudo systemctl enable vsomeip-routing

echo ""
echo "[install] Done. vsomeip-routing config: ${REPO_PATH}/host/vsomeip-routing.json"
echo "[install] Before starting the Docker container, run:"
echo "  sudo ip addr add 192.168.1.101/24 dev enP8p1s0"
echo "  sudo ip route add 224.0.0.0/4 dev enP8p1s0"
echo "  sudo cp ~/IC/host/vsomeip-routing.json /etc/vsomeip/vsomeip-routing.json"
echo "  sudo systemctl restart vsomeip-routing"
