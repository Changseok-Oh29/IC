cmake_minimum_required(VERSION 3.16)

project(BatteryMeter_app VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Debug CACHE STRING "Build type" FORCE)
endif()

# ════════════════════════════════════════════════════════════
# 배포 환경별 경로 설정 (환경변수 우선)
# ════════════════════════════════════════════════════════════
if(DEFINED ENV{DEPLOY_PREFIX})
    set(INSTALL_PREFIX $ENV{DEPLOY_PREFIX})
    message(STATUS "Using DEPLOY_PREFIX from environment: ${INSTALL_PREFIX}")
else()
    set(INSTALL_PREFIX "${CMAKE_CURRENT_SOURCE_DIR}/../../install_folder")
    message(STATUS "Using default DEPLOY_PREFIX: ${INSTALL_PREFIX}")
endif()

# RPATH 설정 (vsomeip, CommonAPI 라이브러리 경로)
set(CMAKE_PREFIX_PATH "${CMAKE_PREFIX_PATH};${INSTALL_PREFIX}")
set(CMAKE_INSTALL_RPATH "${INSTALL_PREFIX}/lib")
set(CMAKE_BUILD_WITH_INSTALL_RPATH TRUE)
set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -Wl,--disable-new-dtags")

# Qt packages - use Qt5 from custom installation
set(CMAKE_PREFIX_PATH "${CMAKE_PREFIX_PATH};$ENV{HOME}/Qt/5.15.2/gcc_64")
find_package(Qt5 REQUIRED COMPONENTS Core Network Quick Qml)
message(STATUS "Using Qt5 from: $ENV{HOME}/Qt/5.15.2/gcc_64")
set(QT_VERSION 5)

# CommonAPI & vsomeip
find_package(CommonAPI 3.2 REQUIRED)
find_package(CommonAPI-SomeIP 3.2 REQUIRED)
find_package(vsomeip3 3.5 REQUIRED)

message(STATUS "Starting BatteryMeter_app with vSomeIP/CommonAPI integration")
# CommonAPI generated code path
if(NOT COMMONAPI_GEN_DIR)
    if(DEFINED ENV{COMMONAPI_GEN_DIR})
        set(COMMONAPI_GEN_DIR $ENV{COMMONAPI_GEN_DIR})
    else()
        set(COMMONAPI_GEN_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../../commonapi/generated")
    endif()
endif()

message(STATUS "CommonAPI generated code directory: ${COMMONAPI_GEN_DIR}")

# Include directories
include_directories(
    ${COMMONAPI_GEN_DIR}/core
    ${COMMONAPI_GEN_DIR}/someip
)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

# Source files
set(SOURCES
    src/main.cpp
    src/vehiclecontrolclient.cpp
)

set(HEADERS
    src/vehiclecontrolclient.h
)

# CommonAPI generated sources (SomeIP binding만 .cpp 파일 존재)
set(COMMONAPI_SOURCES
    ${COMMONAPI_GEN_DIR}/someip/v1/vehiclecontrol/VehicleControlSomeIPProxy.cpp
    ${COMMONAPI_GEN_DIR}/someip/v1/vehiclecontrol/VehicleControlSomeIPDeployment.cpp
)

# QML resources
set(QML_RESOURCES
    resources/BatteryMeter.qrc
)

# Executable
add_executable(BatteryMeter_app
    ${SOURCES}
    ${HEADERS}
    ${COMMONAPI_SOURCES}
    ${QML_RESOURCES}
)

target_link_libraries(BatteryMeter_app
    Qt5::Core
    Qt5::Network
    Qt5::Quick
    Qt5::Qml
    CommonAPI
    CommonAPI-SomeIP
    vsomeip3
)

# Install
install(TARGETS BatteryMeter_app
    RUNTIME DESTINATION bin
)
