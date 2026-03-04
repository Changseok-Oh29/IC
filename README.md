# IC — Instrument Cluster

Qt/QML-based Instrument Cluster for SEA:ME PDC project, running as a Docker container on Jetson Orin Nano (ECU2).
Receives live vehicle data (speed, gear, battery) from ECU1 (Raspberry Pi) via SOME/IP over Ethernet.

---

## Architecture Overview

```
┌──────────────────────────────────────────────────────────────────┐
│  ECU1 — Raspberry Pi (192.168.1.100)                             │
│                                                                  │
│  VehicleControlECU  ←── CAN ←── Arduino (speed sensor)          │
│       │  gamepad input, battery monitor (INA219)                 │
│       │                                                          │
│       └── SOME/IP service provider  (service 0x1234:0x5678)     │
│              UDP 30501 / TCP 30502                               │
└──────────────────────────────────┬───────────────────────────────┘
                                   │ Ethernet (192.168.1.0/24)
                                   │ SOME/IP SD multicast 224.244.224.245:30490
┌──────────────────────────────────▼───────────────────────────────┐
│  ECU2 — Jetson Orin Nano (192.168.1.101)                         │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐     │
│  │  HOST                                                   │     │
│  │                                                         │     │
│  │  systemd: vsomeip-routing  (/tmp/vsomeip-0 socket)      │     │
│  │  GNOME Wayland session     (wayland-0)                  │     │
│  └────────────────┬────────────────────────────────────────┘     │
│       /tmp + /run/user/1000 bind mounts │ network_mode: host     │
│  ┌────────────────▼────────────────────────────────────────┐     │
│  │  ic-cluster  (Docker container)                         │     │
│  │                                                         │     │
│  │  cgroups:  cpuset=0,1  │  cpu_shares=1024              │     │
│  │            oom_score_adj=-1000                          │     │
│  │                                                         │     │
│  │  IC_Compositor ──────────────► wayland-2               │     │
│  │       ▲                                                 │     │
│  │  GearState_app   ──┐                                    │     │
│  │  Speedometer_app ──┼──► renders into wayland-2          │     │
│  │  BatteryMeter_app ─┘                                    │     │
│  │                                                         │     │
│  │  All 3 apps subscribe to 0x1234:0x5678 via vsomeip      │     │
│  └─────────────────────────────────────────────────────────┘     │
└──────────────────────────────────────────────────────────────────┘
```

### Wayland Display Chain

```
GNOME Shell (wayland-0)
    └── IC_Compositor nested compositor (wayland-2)
            ├── GearState_app    → gear panel
            ├── Speedometer_app  → speed panel
            └── BatteryMeter_app → battery panel
```

The IC compositor creates its own Wayland socket (`wayland-2`) inside the GNOME session (`wayland-0`). The three gauge apps connect to `wayland-2` and are composited into a single full-screen IC display.

### SOME/IP Communication

```
RPi VehicleControlECU
  │  is its own vsomeip routing manager
  │  sends SD offer → multicast 224.244.224.245:30490
  │
  ▼
Jetson vsomeip-routing (host systemd service)
  │  receives SD offer, notifies registered clients
  │  communicates with IC apps via /tmp/vsomeip-0 Unix socket
  │
  ▼
GearState_app / Speedometer_app / BatteryMeter_app
  │  subscribe to service 0x1234:0x5678
  │  receive vehicleStateChanged + gearStateChanged events
  ▼
IC_Compositor renders live data on screen
```

---

## Repository Structure

```
IC/
├── app/                          # IC applications
│   ├── Dockerfile.deps           # Builds vsomeip middleware base image
│   ├── docker-compose.cluster.yml# Runs the IC cluster container
│   ├── ic-cluster/
│   │   ├── Dockerfile            # Multi-stage build: compiles all 4 IC apps
│   │   └── entrypoint.sh         # Container startup orchestration
│   ├── ic-compositor/            # Wayland nested compositor (Qt Wayland Compositor)
│   │   ├── CMakeLists.txt
│   │   ├── main.cpp
│   │   └── qml/main.qml          # Surface routing: assigns apps to display regions
│   ├── gearstate-app/            # Gear state display (P/R/N/D)
│   │   ├── config/
│   │   │   ├── vsomeip_gearstate.json
│   │   │   └── commonapi_gearstate.ini
│   │   └── ...
│   ├── speedometer-app/          # Speed display
│   │   ├── config/
│   │   │   ├── vsomeip_speedometer.json
│   │   │   └── commonapi_speedometer.ini
│   │   └── ...
│   └── batterymeter-app/         # Battery percentage display
│       ├── config/
│       │   ├── vsomeip_batterymeter.json
│       │   └── commonapi_batterymeter.ini
│       └── ...
├── commonapi/
│   ├── fidl/VehicleControl.fidl  # Service interface definition
│   └── generated/                # Auto-generated CommonAPI proxy/stub code
├── deps/                         # Source code of middleware (git submodules)
│   ├── vsomeip/                  # vsomeip 3.5.8
│   ├── capicxx-core-runtime/     # CommonAPI Core runtime
│   └── capicxx-someip-runtime/   # CommonAPI SOME/IP binding
└── host/
    ├── vsomeip-routing.json      # routingmanagerd config (unicast: 192.168.1.101)
    ├── vsomeip-routing.service   # systemd unit for host routing manager
    └── install-vsomeip-routing.sh# Installs routingmanagerd from Docker image to host
```

---

## File Roles

### `app/Dockerfile.deps`
Builds the `ic-deps:latest` base image. Compiles three middleware libraries from source into `/opt/ic-deps/`:

| Component | Version | Purpose |
|-----------|---------|---------|
| vsomeip | 3.5.8 | SOME/IP protocol stack + `routingmanagerd` binary |
| capicxx-core-runtime | 3.2.x | CommonAPI abstraction layer |
| capicxx-someip-runtime | 3.2.x | CommonAPI SOME/IP binding |

This image is built **once** and reused as the builder stage for all IC apps.

### `app/ic-cluster/Dockerfile`
Two-stage build:

**Stage 1 (builder)** — `FROM ic-deps:latest`
- Installs Qt5 dev libraries
- Compiles all 4 apps: `IC_Compositor`, `GearState_app`, `Speedometer_app`, `BatteryMeter_app`
- Uses CommonAPI generated code from `commonapi/generated/`

**Stage 2 (runtime)** — `FROM ubuntu:22.04`
- Copies only compiled binaries + Qt5/Boost runtime libs
- No build tools → lean image
- Sets `LD_LIBRARY_PATH=/opt/ic-deps/lib`

### `app/ic-cluster/entrypoint.sh`
Controls the startup order inside the container:

```
1. Start IC_Compositor  → creates /run/user/1000/wayland-2
2. Poll for wayland-2 socket (up to 10s timeout)
3. sleep 5s  → wait for compositor to be fully ready to accept clients
4. export WAYLAND_DISPLAY=wayland-2
5. Start GearState_app, Speedometer_app, BatteryMeter_app (in parallel)
6. wait $COMPOSITOR_PID  → container lifetime tied to compositor
```

If `IC_Compositor` crashes, the container exits immediately, triggering the restart policy.

### `app/docker-compose.cluster.yml`
Defines the IC cluster container with resource isolation:

| Parameter | Value | Effect |
|-----------|-------|--------|
| `cpuset` | `"0,1"` | Pins IC to CPU cores 0 and 1 exclusively |
| `cpu_shares` | `1024` | High scheduling weight (HU container will use 512) |
| `oom_score_adj` | `-1000` | Kernel will never OOM-kill IC — maximum protection |
| `network_mode` | `host` | Direct access to host network for SOME/IP multicast |
| `user` | `1000:1000` | Runs as `seame` user, not root |

**Volume mounts:**

| Mount | Purpose |
|-------|---------|
| `/run/user/1000:/run/user/1000` | Access to host Wayland socket (`wayland-0`) |
| `/tmp:/tmp` | Shares `vsomeip-0` Unix socket with host `routingmanagerd` |

### `app/*/config/vsomeip_*.json`
Per-app vsomeip configuration. All three apps use:
- `unicast: 192.168.1.101` — Jetson's ethernet IP
- `routing: routingmanagerd` — connect to host routing manager via `/tmp/vsomeip-0`
- `service-discovery: multicast 224.244.224.245:30490`
- Subscribe to service `0x1234` instance `0x5678`

### `host/vsomeip-routing.json`
Configuration for the host `routingmanagerd`. Binds to `192.168.1.101` and handles SOME/IP service discovery on behalf of all IC apps.

### `host/install-vsomeip-routing.sh`
One-time setup script. Extracts `routingmanagerd` binary and libs from the `ic-deps` Docker image and installs them to `/opt/ic-deps/` on the host. Also installs the systemd service.

---

## Setup & Run

### Prerequisites
- Jetson Orin Nano with JetPack 6.2.1 (Ubuntu 22.04, arm64)
- GNOME Wayland session active (`wayland-0` socket must exist)
- Docker installed and running
- ECU1 (Raspberry Pi) connected via Ethernet

### 1. Populate submodules
```bash
git submodule update --init --recursive
```

### 2. Build the middleware base image
```bash
cd ~/IC
docker build -f app/Dockerfile.deps -t ic-deps:latest .
```
> This takes ~15–20 minutes (compiles vsomeip + CommonAPI from source).

### 3. Install host vsomeip routing manager (once)
```bash
bash host/install-vsomeip-routing.sh
```

### 4. Configure network (required after every reboot until made persistent)
```bash
# Set Jetson ethernet IP
sudo ip addr add 192.168.1.101/24 dev enP8p1s0

# Add multicast route so vsomeip SD joins the right interface
sudo ip route add 224.0.0.0/4 dev enP8p1s0

# Copy routing config and start routingmanagerd
sudo cp host/vsomeip-routing.json /etc/vsomeip/vsomeip-routing.json
sudo systemctl restart vsomeip-routing
```

> On Raspberry Pi (ECU1): `ip addr add 192.168.1.100/24 dev eth0` (also required after reboot)

### 5. Start the IC cluster
```bash
cd ~/IC/app
docker compose -f docker-compose.cluster.yml up --build
```

For subsequent runs (no source changes):
```bash
docker compose -f docker-compose.cluster.yml up
```

### 6. Verify live data
```bash
docker logs ic-cluster 2>&1 | grep "Event\|available"
```
Expected output:
```
📡 [Event] vehicleStateChanged: Gear: "D" Speed: 0 km/h Battery: 88 %
📡 [Event] gearStateChanged: Gear: "D"
qml: 📡 Gear changed: D
```

---

## Isolation Design

The IC domain is treated as **safety-critical** and isolated from other software:

```
                  CPU cores
         ┌────────┬────────┬────────┬────────┐
         │ Core 0 │ Core 1 │ Core 2 │ Core 3 │
         │  IC    │  IC    │  HU /  │  HU /  │
         │(cpuset)│(cpuset)│  OS    │  OS    │
         └────────┴────────┴────────┴────────┘

         Memory
         ├── ic-cluster:  oom_score_adj = -1000  (protected)
         └── hu-container: oom_score_adj = 0      (default)

         Scheduling
         ├── ic-cluster:  cpu_shares = 1024  (high)
         └── hu-container: cpu_shares = 512   (low)
```

| Isolation mechanism | IC cluster | HU container (planned) |
|--------------------|-----------|----------------------|
| CPU cores | 0, 1 (exclusive) | 2, 3 (shared with OS) |
| Scheduling weight | 1024 (high) | 512 (low) |
| OOM protection | -1000 (never killed) | 0 (default) |
| vsomeip | Client of host routingmanagerd | Client of host routingmanagerd |
| Wayland | Nested compositor on wayland-2 | Nested compositor on wayland-3 |

---

## Middleware Stack

```
IC Apps (Qt/QML + CommonAPI Proxy)
    │
    ▼
capicxx-someip-runtime  (CommonAPI SOME/IP binding)
    │
    ▼
capicxx-core-runtime    (CommonAPI abstraction)
    │
    ▼
vsomeip 3.5.8           (SOME/IP protocol implementation)
    │
    ├── /tmp/vsomeip-0  → host routingmanagerd (Unix socket)
    └── enP8p1s0        → ECU1 over Ethernet (UDP/TCP)
```

CommonAPI generated code (`commonapi/generated/`) is produced from `VehicleControl.fidl` and provides type-safe C++ proxy classes that the gauge apps use to subscribe to vehicle events.

---

## Known Issues & Notes

- **IP and multicast route are lost on reboot** — must be re-applied each time until netplan + systemd service are configured for persistence.
- **`restart: no`** — IC cluster container does not auto-start at boot because Docker starts before the Wayland session is ready. Start manually after logging in.
- **Software rendering** — `QT_QUICK_BACKEND=software` / `LIBGL_ALWAYS_SOFTWARE=1` are set because the container does not have access to Jetson GPU (`/dev/dri`). Will be resolved in the Yocto target.
- **`version` warning** — `version: '3.8'` in docker-compose.cluster.yml is obsolete in recent Docker versions. Non-breaking.
