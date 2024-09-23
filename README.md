# ARM Cortex-M Makefile Template

This repository provides a versatile Makefile template for ARM Cortex-M based projects, designed to simplify the build process for C and C++ projects. It supports various project configurations, including debugging, tracing, and more. The Makefile can be easily customized for different microcontroller projects, making it suitable for embedded systems development.

## Features

- **Support for ARM Toolchain**: Automatically configures toolchain paths for `gcc`, `g++`, and other necessary tools.
- **C and C++ support**: Allows building both C and C++ source files, with customizable language standards.
- **Debug and Release Modes**: Easy switch between debug and optimized release builds.
- **Optional SWO Tracing**: Enable SWO tracing for real-time debugging and performance analysis.
- **Bootloader Support**: Includes optional bootloader hex merging during the build process.
- **Extensible**: Simple modification options for include directories, source files, libraries, and more.
- **Clean and Upload Targets**: Includes commands to clean the build output and upload the generated binary to the target device.

## Prerequisites

- **ARM Toolchain**: Ensure the [ARM GCC Toolchain](https://developer.arm.com/tools-and-software/open-source-software/developer-tools/gnu-toolchain/gnu-rm) is installed and available in your system.
- **ST-Link Utility (optional)**: For uploading the binary to an STM32 microcontroller, you can use the ST-Link command-line interface.

## Getting Started

1. Clone the repository:
    ```bash
    git clone https://github.com/Norman98/ARM-Cortex-M-Makefile-Template.git
    cd ARM-Cortex-M-Makefile-Template
    ```

2. Configure the `Makefile`:
   - Update the toolchain path by setting `ARM_TOOLCHAIN_DIR`.
   - Define project-specific variables like `PROJECT`, `CORE`, `SRCS_DIRS`, `INC_DIRS`, `LIBS`, etc.
   - Set the desired build options for `DEBUG`, `TRACE`, and `USES_CXX`.

3. Build the project:
   ```bash
   make
   ```
   
4. Clean the project:

  ```bash
  make clean
  ```
5. Upload the binary (optional, requires ST-Link):

  ```bash
  make upload
  ```

## Configuration Options

### Toolchain Configuration

- Set the path to your ARM toolchain in the ARM_TOOLCHAIN_DIR variable.
- The Makefile uses gcc, g++, objcopy, objdump, size, and other ARM tools for compiling and linking.

### Build Options
- DEBUG: Set to 1 to enable debugging symbols and disable optimizations. This will also enable SWO tracing if supported.
- TRACE: Enable tracing functionality by setting TRACE=1.

### Project Configuration
- PROJECT: Define the project name.
- CORE: Specify the ARM Cortex core (e.g., cortex-m3).
- SUFFIX: Optional suffix for output files.
- BOOT_HEX: Define a bootloader hex file to merge with the project’s hex file.
 
### Output Directory
Output directories are dynamically set based on the compilation mode (debug, trace, release).

## License
This project is licensed under the MIT License - see the LICENSE file for details.

Made by Norman Dryś, based on various Makefile examples found online.
