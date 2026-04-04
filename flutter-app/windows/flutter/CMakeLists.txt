cmake_minimum_required(VERSION 3.14)

add_custom_target(install_bundle
  DEPENDS ${BINARY_NAME}
  COMMAND
    ${CMAKE_COMMAND} -E rm -rf "${CMAKE_BINARY_DIR}\\build"
    && ${CMAKE_COMMAND} -E make_directory "${CMAKE_BINARY_DIR}\\build"
    && ${CMAKE_COMMAND} -E copy_directory
      "${CMAKE_SOURCE_DIR}\\..\\build\\windows\\x64\\runner\\Release"
      "${CMAKE_BINARY_DIR}\\build"
  VERBATIM
)
