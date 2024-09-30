# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

project(vanilla_dart_library VERSION 0.0.1 LANGUAGES C)

add_library(vanilla_dart SHARED
  "vanilla_dart.c"
)

set_target_properties(vanilla_dart PROPERTIES
  PUBLIC_HEADER vanilla_dart.h
  OUTPUT_NAME "vanilla_dart"
)

target_compile_definitions(vanilla_dart PUBLIC DART_SHARED_LIB)
