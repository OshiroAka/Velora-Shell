cmake_minimum_required(VERSION 3.19)

project(velora-blur LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

find_package(PkgConfig REQUIRED)
pkg_check_modules(HYPRLAND REQUIRED IMPORTED_TARGET hyprland)

add_library(velora-blur SHARED plugin.cpp)
target_link_libraries(velora-blur PRIVATE PkgConfig::HYPRLAND)
target_compile_options(velora-blur PRIVATE
    -Wall
    -Wextra
    -Wpedantic
    -fno-gnu-unique
)

set_target_properties(velora-blur PROPERTIES
    PREFIX ""
    OUTPUT_NAME "velora-blur"
)
