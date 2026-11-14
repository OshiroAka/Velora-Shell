cmake_minimum_required(VERSION 3.21)

project(velora-native VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)
set(QT_QML_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/qml")

find_package(Qt6 6.5 REQUIRED COMPONENTS Core Gui Qml Quick)
find_package(PkgConfig REQUIRED)
pkg_check_modules(PulseSimple REQUIRED IMPORTED_TARGET libpulse-simple)
pkg_check_modules(FFTW REQUIRED IMPORTED_TARGET fftw3f)

qt_standard_project_setup(REQUIRES 6.5)

qt_add_qml_module(veloranative
    URI Velora.Native
    VERSION 1.0
    OUTPUT_DIRECTORY "${QT_QML_OUTPUT_DIRECTORY}/Velora/Native"
    SOURCES
        spectrumengine.cpp
        spectrumengine.hpp
        spectrumitem.cpp
        spectrumitem.hpp
)

set_target_properties(veloranative PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY "${QT_QML_OUTPUT_DIRECTORY}/Velora/Native"
    BUILD_RPATH "$ORIGIN"
)
set_target_properties(veloranativeplugin PROPERTIES BUILD_RPATH "$ORIGIN")

target_link_libraries(veloranative PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    PkgConfig::PulseSimple
    PkgConfig::FFTW
)

target_compile_options(veloranative PRIVATE -O3 -DNDEBUG)
