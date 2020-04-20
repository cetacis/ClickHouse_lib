if (NOT EXISTS "${ClickHouse_SOURCE_DIR}/contrib/cpython-cmake/CMakeLists.txt")
    message (WARNING "submodule contrib/cpython-cmake is missing. to fix try run: \n git submodule update --init --recursive")
    return()
endif ()

option (USE_PYTHON "Use python" ON)
set (Python_INCLUDE_DIRS)
message(STATUS "Using python=${USE_PYTHON}")
