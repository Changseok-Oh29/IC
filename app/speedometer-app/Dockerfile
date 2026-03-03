# ─────────────────────────────────────────────────────────────────────────────
# Speedometer App
#
# Prerequisite: build ic-deps base image first:
#   docker build -f app/Dockerfile.deps -t ic-deps:latest .
#
# Target: JetPack 6.2.1 (Ubuntu 22.04, arm64)
# ─────────────────────────────────────────────────────────────────────────────

# ── Stage 1: Builder (inherits pre-built vsomeip + CommonAPI) ─────────────────
FROM ic-deps:latest AS builder

ENV DEBIAN_FRONTEND=noninteractive
ENV INSTALL_PREFIX=/opt/ic-deps

RUN apt-get update && apt-get install -y \
    cmake \
    qtbase5-dev \
    qtdeclarative5-dev \
    qtquickcontrols2-5-dev \
    qtwayland5 \
    && rm -rf /var/lib/apt/lists/*

# CommonAPI generated code
COPY ./commonapi /build/commonapi/

# App source
WORKDIR /build/speedometer-app
COPY ./app/speedometer-app/ .

# CMakeLists.txt references src/main.cpp — move files into src/
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
    qtwayland5 \
    qml-module-qtquick2 \
    qml-module-qtquick-window2 \
    qml-module-qtquick-controls2 \
    qml-module-qtquick-layouts \
    libboost-system1.74.0 \
    libboost-thread1.74.0 \
    libboost-filesystem1.74.0 \
    libboost-log1.74.0 \
    && rm -rf /var/lib/apt/lists/*

# Copy middleware libs (vsomeip + CommonAPI)
COPY --from=builder /opt/ic-deps/lib /opt/ic-deps/lib
RUN ldconfig

WORKDIR /app
COPY --from=builder /build/speedometer-app/build/Speedometer_app ./
COPY --from=builder /build/speedometer-app/config ./config/

ENV LD_LIBRARY_PATH=/opt/ic-deps/lib
ENV VSOMEIP_CONFIGURATION=/app/config/vsomeip_speedometer.json
ENV VSOMEIP_APPLICATION_NAME=Speedometer
ENV COMMONAPI_CONFIG=/app/config/commonapi_speedometer.ini

ENV QT_QPA_PLATFORM=wayland
ENV QT_WAYLAND_DISABLE_WINDOWDECORATION=1
ENV QT_QUICK_BACKEND=software
ENV QSG_RENDER_LOOP=basic

CMD ["/app/Speedometer_app"]
