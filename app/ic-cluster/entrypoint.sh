#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# IC Cluster Entrypoint
#
# Start order:
#   1. IC_Compositor  (creates wayland-2 socket)
#   2. GearState_app  (connects to wayland-2)
#   3. Speedometer_app
#   4. BatteryMeter_app
#
# If IC_Compositor dies, the whole container exits (restart policy handles it)
# ─────────────────────────────────────────────────────────────────────────────

set -e

WAYLAND_SOCKET="${XDG_RUNTIME_DIR}/wayland-2"
WAIT_TIMEOUT=10

echo "[IC] XDG_RUNTIME_DIR = $XDG_RUNTIME_DIR"
echo "[IC] Parent display   = $WAYLAND_DISPLAY"

# ── 1. Start IC Compositor ────────────────────────────────────────────────────
echo "[IC] Starting IC_Compositor..."
/app/IC_Compositor &
COMPOSITOR_PID=$!

# ── 2. Wait for wayland-2 socket ──────────────────────────────────────────────
echo "[IC] Waiting for wayland-2 socket..."
COUNT=0
while [ ! -S "$WAYLAND_SOCKET" ]; do
    sleep 0.5
    COUNT=$((COUNT + 1))
    if [ $COUNT -ge $((WAIT_TIMEOUT * 2)) ]; then
        echo "[IC] ERROR: wayland-2 not created after ${WAIT_TIMEOUT}s — compositor failed"
        exit 1
    fi
done

# Socket file exists but compositor needs more time to accept connections
echo "[IC] wayland-2 socket appeared, waiting for compositor to be ready..."
sleep 5
echo "[IC] wayland-2 ready"

# ── 3. Start IC Apps (all connect to wayland-2) ───────────────────────────────
export WAYLAND_DISPLAY=wayland-2

echo "[IC] Starting GearState_app..."
VSOMEIP_CONFIGURATION=/app/config/gearstate/vsomeip_gearstate.json \
VSOMEIP_APPLICATION_NAME=GearState \
COMMONAPI_CONFIG=/app/config/gearstate/commonapi_gearstate.ini \
/app/GearState_app &

echo "[IC] Starting Speedometer_app..."
VSOMEIP_CONFIGURATION=/app/config/speedometer/vsomeip_speedometer.json \
VSOMEIP_APPLICATION_NAME=Speedometer \
COMMONAPI_CONFIG=/app/config/speedometer/commonapi_speedometer.ini \
/app/Speedometer_app &

echo "[IC] Starting BatteryMeter_app..."
VSOMEIP_CONFIGURATION=/app/config/batterymeter/vsomeip_batterymeter.json \
VSOMEIP_APPLICATION_NAME=BatteryMeter \
COMMONAPI_CONFIG=/app/config/batterymeter/commonapi_batterymeter.ini \
/app/BatteryMeter_app &

echo "[IC] All apps running. Compositor PID=$COMPOSITOR_PID"

# Container stays alive as long as compositor runs
wait $COMPOSITOR_PID
echo "[IC] Compositor exited — shutting down IC cluster"
