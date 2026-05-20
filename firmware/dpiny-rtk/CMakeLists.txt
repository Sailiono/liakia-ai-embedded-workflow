cmake_minimum_required(VERSION 3.22)

#
# This file is generated only once,
# and is not re-generated if converter is called multiple times.
#
# User is free to modify the file as much as necessary
#

# Setup compiler settings
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_EXTENSIONS ON)


# Define the build type
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE "Debug")
endif()

# Set the project name
set(CMAKE_PROJECT_NAME dpiny-RTK)

# Enable compile command to ease indexing with e.g. clangd
set(CMAKE_EXPORT_COMPILE_COMMANDS TRUE)

# Core project settings
project(${CMAKE_PROJECT_NAME})
message("Build type: " ${CMAKE_BUILD_TYPE})

# Enable CMake support for ASM and C languages
enable_language(C ASM)

# Create an executable object type
add_executable(${CMAKE_PROJECT_NAME})
set_target_properties(${CMAKE_PROJECT_NAME} PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}"
)

# Add STM32CubeMX generated sources
add_subdirectory(cmake/stm32cubemx)

# Link directories setup
target_link_directories(${CMAKE_PROJECT_NAME} PRIVATE
    # Add user defined library search paths
)

# Add sources to executable
target_sources(${CMAKE_PROJECT_NAME} PRIVATE
    Core/Src/passthrough.c
    Core/Src/gnss.c
    Core/Src/config.c
    Core/Src/iwdg.c
    Core/Src/shell.c
)

# Add include paths
target_include_directories(${CMAKE_PROJECT_NAME} PRIVATE
    # Add user defined include paths
)

# Add project symbols (macros)
target_compile_definitions(${CMAKE_PROJECT_NAME} PRIVATE
    # Add user defined symbols
)

# Enable newlib-nano floating-point printf support
target_link_options(${CMAKE_PROJECT_NAME} PRIVATE
    -u_printf_float
)

# Remove wrong libob.a library dependency when using cpp files
list(REMOVE_ITEM CMAKE_C_IMPLICIT_LINK_LIBRARIES ob)

# Add linked libraries
target_link_libraries(${CMAKE_PROJECT_NAME}
    stm32cubemx

    # Add user defined libraries
)

if(CMAKE_HOST_WIN32)
    find_program(DPINY_PWSH_EXECUTABLE NAMES pwsh powershell)

    if(DPINY_PWSH_EXECUTABLE)
        if(EXISTS "${CMAKE_SOURCE_DIR}/tools/functional_test.ps1")
            set(DPINY_REPO_ROOT "${CMAKE_SOURCE_DIR}")
        else()
            get_filename_component(DPINY_REPO_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/../.." ABSOLUTE)
        endif()

        set(DPINY_COM_PORT "" CACHE STRING "Target COM port for functional_test (e.g. COM11)")
        set(DPINY_PROGRAMMER_CLI "" CACHE STRING "Path to STM32_Programmer_CLI.exe (optional if in PATH)")
        set(DPINY_PROGRAMMER_CONNECT "port=SWD freq=4000" CACHE STRING "Programmer connect args (passed to -c)")

        add_custom_target(functional_test
            DEPENDS ${CMAKE_PROJECT_NAME}
            COMMAND ${DPINY_PWSH_EXECUTABLE}
                -NoProfile
                -ExecutionPolicy Bypass
                -File "${DPINY_REPO_ROOT}/tools/functional_test.ps1"
                -BuildPreset "${CMAKE_BUILD_TYPE}"
                -ElfPath "$<TARGET_FILE:${CMAKE_PROJECT_NAME}>"
                -ComPort "${DPINY_COM_PORT}"
                -ProgrammerCliPath "${DPINY_PROGRAMMER_CLI}"
                -ConnectArgs "${DPINY_PROGRAMMER_CONNECT}"
                -SkipBuild
            WORKING_DIRECTORY "${DPINY_REPO_ROOT}"
            COMMENT "Build + flash + COM functional test (set DPINY_COM_PORT / DPINY_PROGRAMMER_CLI if needed)"
            VERBATIM
        )
    else()
        message(WARNING "pwsh/powershell not found; functional_test target will not be available")
    endif()
endif()
