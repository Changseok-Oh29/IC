#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# Install vsomeip routing manager on JetPack host
#
# Extracts routingmanagerd + libs from the already-built ic-deps Docker image.
# Run once from the IC repo root:
#   bash host/install-vsomeip-routing.sh
# ─────────────────────────────────────────────────────────────────────────────

set -e

echo "[install] Creating directories..."
sudo mkdir -p /opt/ic-deps/bin /opt/ic-deps/lib /etc/vsomeip

echo "[install] Extracting routingmanagerd from ic-deps image..."
docker run --rm \
    -v /opt/ic-deps:/target \
    ic-deps:latest \
    sh -c "cp /opt/ic-deps/bin/routingmanagerd /target/bin/ && \
           cp -r /opt/ic-deps/lib/. /target/lib/"

echo "[install] Setting up library path..."
echo "/opt/ic-deps/lib" | sudo tee /etc/ld.so.conf.d/ic-deps.conf
sudo ldconfig

echo "[install] Installing vsomeip routing config..."
sudo cp host/vsomeip-routing.json /etc/vsomeip/vsomeip-routing.json

echo "[install] Installing systemd service..."
sudo cp host/vsomeip-routing.service /etc/systemd/system/vsomeip-routing.service
sudo systemctl daemon-reload
sudo systemctl enable vsomeip-routing

echo ""
echo "[install] Done. Start with:"
echo "  sudo systemctl start vsomeip-routing"
echo "  systemctl status vsomeip-routing"
