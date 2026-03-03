# ─────────────────────────────────────────────────────────────────────────────
# IC Compositor — Nested Wayland Compositor
#
# Role: Connects to host Weston/GNOME Wayland (wayland-0)
#       Creates wayland-2 socket for gearstate/speedometer/batterymeter apps
#
# No vsomeip/CommonAPI — display only
# Target: JetPack 6.2.1 (Ubuntu 22.04, arm64)
# ─────────────────────────────────────────────────────────────────────────────

# ── Stage 1: Builder ──────────────────────────────────────────────────────────
FROM ubuntu:22.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    pkg-config \
    qtbase5-dev \
    qtdeclarative5-dev \
    libqt5waylandcompositor5-dev \
    qtquickcontrols2-5-dev \
    qtwayland5 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build/ic-compositor
COPY ./app/ic-compositor/ .

# CMakeLists.txt references src/main.cpp — move file into src/
RUN mkdir -p src && cp main.cpp src/

RUN cmake -B build -S . \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_PREFIX_PATH=/usr \
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
    fonts-dejavu-core \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=builder /build/ic-compositor/build/IC_Compositor ./

# QML/resources are compiled into the binary via Qt resource system (AUTORCC)
# No extra files needed at runtime

ENV QT_QPA_PLATFORM=wayland
ENV QT_WAYLAND_DISABLE_WINDOWDECORATION=1
ENV QT_QUICK_BACKEND=software
ENV QSG_RENDER_LOOP=basic

CMD ["/app/IC_Compositor"]
