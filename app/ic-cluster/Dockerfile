# ─────────────────────────────────────────────────────────────────────────────
# IC Cluster — Single Container (Safety-Critical Domain)
#
# Contains all 4 IC apps as processes inside one container:
#   IC_Compositor → GearState_app + Speedometer_app + BatteryMeter_app
#
# Prerequisite: build ic-deps base image first:
#   docker build -f app/Dockerfile.deps -t ic-deps:latest .
#
# cgroups applied at container level (see docker-compose.cluster.yml):
#   cpuset: 0,1  │  cpu_shares: high  │  oom_score_adj: -1000
#
# Target: JetPack 6.2.1 (Ubuntu 22.04, arm64)
# ─────────────────────────────────────────────────────────────────────────────

# ── Stage 1: Builder ──────────────────────────────────────────────────────────
FROM ic-deps:latest AS builder

ENV DEBIAN_FRONTEND=noninteractive
ENV INSTALL_PREFIX=/opt/ic-deps

RUN apt-get update && apt-get install -y \
    cmake \
    qtbase5-dev \
    qtdeclarative5-dev \
    libqt5waylandcompositor5-dev \
    qtquickcontrols2-5-dev \
    qtwayland5 \
    && rm -rf /var/lib/apt/lists/*

# CommonAPI generated code (shared by all 3 apps)
COPY ./commonapi /build/commonapi/

# ── ic-compositor ─────────────────────────────────────────────────────────────
WORKDIR /build/ic-compositor
COPY ./app/ic-compositor/ .
RUN mkdir -p src && cp main.cpp src/
RUN cmake -B build -S . \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_PREFIX_PATH=/usr \
    && cmake --build build -j$(nproc)

# ── gearstate-app ─────────────────────────────────────────────────────────────
WORKDIR /build/gearstate-app
COPY ./app/gearstate-app/ .
RUN mkdir -p src && cp main.cpp vehiclecontrolclient.cpp vehiclecontrolclient.h src/
RUN DEPLOY_PREFIX=${INSTALL_PREFIX} \
    cmake -B build -S . \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_PREFIX_PATH="/usr;${INSTALL_PREFIX}" \
        -DCOMMONAPI_GEN_DIR=/build/commonapi/generated \
    && cmake --build build -j$(nproc)

# ── speedometer-app ───────────────────────────────────────────────────────────
WORKDIR /build/speedometer-app
COPY ./app/speedometer-app/ .
RUN mkdir -p src && cp main.cpp vehiclecontrolclient.cpp vehiclecontrolclient.h src/
RUN DEPLOY_PREFIX=${INSTALL_PREFIX} \
    cmake -B build -S . \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_PREFIX_PATH="/usr;${INSTALL_PREFIX}" \
        -DCOMMONAPI_GEN_DIR=/build/commonapi/generated \
    && cmake --build build -j$(nproc)

# ── batterymeter-app ──────────────────────────────────────────────────────────
WORKDIR /build/batterymeter-app
COPY ./app/batterymeter-app/ .
RUN mkdir -p src && cp main.cpp vehiclecontrolclient.cpp vehiclecontrolclient.h src/
RUN DEPLOY_PREFIX=${INSTALL_PREFIX} \
    cmake -B build -S . \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_PREFIX_PATH="/usr;${INSTALL_PREFIX}" \
        -DCOMMONAPI_GEN_DIR=/build/commonapi/generated \
    && cmake --build build -j$(nproc)

# ── Stage 2: Runtime ──────────────────────────────────────────────────────────
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    libqt5core5a \
    libqt5gui5 \
    libqt5qml5 \
    libqt5quick5 \
    libqt5waylandcompositor5 \
    qtwayland5 \
    qml-module-qtquick2 \
    qml-module-qtquick-window2 \
    qml-module-qtwayland-compositor \
    qml-module-qtquick-controls2 \
    qml-module-qtquick-layouts \
    libboost-system1.74.0 \
    libboost-thread1.74.0 \
    libboost-filesystem1.74.0 \
    libboost-log1.74.0 \
    fonts-dejavu-core \
    && rm -rf /var/lib/apt/lists/*

# Middleware libs
COPY --from=builder /opt/ic-deps/lib /opt/ic-deps/lib
RUN ldconfig

WORKDIR /app

# All 4 binaries
COPY --from=builder /build/ic-compositor/build/IC_Compositor        ./
COPY --from=builder /build/gearstate-app/build/GearState_app        ./
COPY --from=builder /build/speedometer-app/build/Speedometer_app    ./
COPY --from=builder /build/batterymeter-app/build/BatteryMeter_app  ./

# vsomeip configs per app
COPY --from=builder /build/gearstate-app/config    ./config/gearstate/
COPY --from=builder /build/speedometer-app/config  ./config/speedometer/
COPY --from=builder /build/batterymeter-app/config ./config/batterymeter/

# Startup script
COPY ./app/ic-cluster/entrypoint.sh ./
RUN chmod +x entrypoint.sh

ENV LD_LIBRARY_PATH=/opt/ic-deps/lib
ENV QT_QPA_PLATFORM=wayland
ENV QT_WAYLAND_DISABLE_WINDOWDECORATION=1
ENV QT_QUICK_BACKEND=software
ENV QSG_RENDER_LOOP=basic

ENTRYPOINT ["/app/entrypoint.sh"]
