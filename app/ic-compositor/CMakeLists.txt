cmake_minimum_required(VERSION 3.16)
project(IC_Compositor VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

# Set Qt5 path
set(CMAKE_PREFIX_PATH "$ENV{HOME}/Qt/5.15.2/gcc_64" CACHE PATH "Qt5 installation path")

# Find Qt5 packages
find_package(Qt5 5.15 REQUIRED COMPONENTS
    Core
    Gui
    Qml
    Quick
    WaylandCompositor
)

# Source files
set(SOURCES
    src/main.cpp
)

# QML Resources
set(RESOURCES
    resources/compositor.qrc
)

# Create executable
add_executable(${PROJECT_NAME}
    ${SOURCES}
    ${RESOURCES}
)

# Link libraries
target_link_libraries(${PROJECT_NAME} PRIVATE
    Qt5::Core
    Qt5::Gui
    Qt5::Qml
    Qt5::Quick
    Qt5::WaylandCompositor
)

# Installation
install(TARGETS ${PROJECT_NAME}
    RUNTIME DESTINATION bin
)

message(STATUS "==========================================")
message(STATUS "IC Compositor Configuration")
message(STATUS "==========================================")
message(STATUS "Project: ${PROJECT_NAME}")
message(STATUS "Qt Version: ${Qt5_VERSION}")
message(STATUS "Qt Path: ${CMAKE_PREFIX_PATH}")
message(STATUS "Build Type: ${CMAKE_BUILD_TYPE}")
message(STATUS "==========================================")
