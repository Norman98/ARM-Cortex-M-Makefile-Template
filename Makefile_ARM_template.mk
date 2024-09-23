#=============================================================================#
# ARM makefile
#
# Author: Norman Dryś
# Version: 1.0.0
# Last change: 2024-09-09
#
# This makefile is heavily based on various examples found online.
#=============================================================================#

#=============================================================================#
# Toolchain configuration
#=============================================================================#
export PATH := $(PATH):$(ARM_TOOLCHAIN_DIR)
TOOLCHAIN = $(ARM_TOOLCHAIN_DIR)/arm-none-eabi-

CXX 	= $(TOOLCHAIN)g++
CC 		= $(TOOLCHAIN)gcc
AS 		= $(TOOLCHAIN)gcc -x assembler-with-cpp
OBJCOPY = $(TOOLCHAIN)objcopy
OBJDUMP = $(TOOLCHAIN)objdump
SIZE 	= $(TOOLCHAIN)size
RM 		= rm -f

#=============================================================================#
# Default options settings (can be overriden via the command line e.g. "make DEBUG=1")
# DEBUG -> Debug compilation
# TRACE -> Enable SWO tracing capabilities
#=============================================================================#
DEBUG ?= 0
TRACE ?= 0

ifeq ($(DEBUG), 1)
	TRACE = 1
endif

#=============================================================================#
# Project configuration
#=============================================================================#
# Project name
PROJECT =

# Suffix to output files
SUFFIX = # e.g. _app

# Core type
CORE = # e.g. cortex-m3

# Bootloader hex file (if any)
BOOT_HEX = # e.g. build/boot/$(PROJECT)_boot.hex

# Linker script
LD_SCRIPT = # e.g. stm32_f103xB_app.ld

# Output directory settings based on compilation mode
ifeq ($(DEBUG), 1)
	OUT_DIR = # e.g. build/app/debug
else ifeq ($(TRACE), 1)
	OUT_DIR = # e.g. build/app/trace
else
	OUT_DIR = # e.g. build/app/release
endif

# Compiler definitions
CXX_DEFS = # e.g. -DSTM32F103xB -DDEVICE_MAGIC=0xDEAD
C_DEFS   = # e.g. $(CXX_DEFS)
AS_DEFS  =

# Include directories
INC_DIRS = # e.g. src/app libs/CMSIS ../../!key_framework/keybus

# Source directories
SRCS_DIRS = # e.g src/app libs/CMSIS ../../!key_framework/keybus

# Library directories
LIB_DIRS =

# Libraries to link
LIBS = # e.g. -lgcc -lg -lc -lnosys

# Additional settings
USES_CXX = 1
LTO = 0

# Language standards
CXX_STD = c++17
C_STD   = c99

# Warning flags for C++ and C
CXX_WARNINGS = -Wall -Wextra -Wno-strict-aliasing -Wno-multichar -Wdouble-promotion -Wundef
C_WARNINGS   = -Wall

# Source file extensions
CXX_EXT = cpp
C_EXT   = c
AS_EXT  = s

#=============================================================================#
# Compiler and Linker Flags
#=============================================================================#
CORE_FLAGS   = -mcpu=$(CORE) -mthumb -fshort-wchar
COMMON_FLAGS = $(CORE_FLAGS) -g3 -ggdb3 -ffunction-sections -fdata-sections -fno-common -fdebug-prefix-map=/= -fverbose-asm

CXX_FLAGS = $(COMMON_FLAGS) -std=$(CXX_STD) -fno-rtti -fno-exceptions
C_FLAGS   = $(COMMON_FLAGS) -std=$(C_STD)
AS_FLAGS  = $(CORE_FLAGS) -g3 -ggdb3
LD_FLAGS  = $(CORE_FLAGS) -g3 -Wl,--gc-sections,--cref,--no-warn-mismatch,--no-warn-rwx-segment

# Debugging and optimization
ifeq ($(DEBUG), 1)
	OPTIMIZATION += -O0
	CXX_DEFS += -DDEBUG
	C_DEFS += -DDEBUG
# 	CXX_FLAGS += -Wa,-ahlms=$(OUT_DIR_F)$(notdir $(<:.$(CXX_EXT)=.lst))
# 	C_FLAGS += -Wa,-ahlms=$(OUT_DIR_F)$(notdir $(<:.$(C_EXT)=.lst))
# 	AS_FLAGS += -Wa,-amhls=$(OUT_DIR_F)$(notdir $(<:.$(AS_EXT)=.lst))
else
	OPTIMIZATION += -Os
	CXX_DEFS += -DNDEBUG
	C_DEFS  += -DNDEBUG
	ifeq ($(LTO), 1)
		CXX_FLAGS += -flto
		C_FLAGS += -flto
		LD_FLAGS += -flto
	endif
endif

# Enable SWO tracing
ifeq ($(TRACE), 1)
	CXX_DEFS += -DTRACE
	C_DEFS += -DTRACE
endif

# Include C++ initialization (global/static constructors)
ifeq ($(USES_CXX), 1)
	AS_DEFS += -D__USES_CXX
else
	LD_FLAGS += -nostartfiles
endif

#=============================================================================#
# Output File Definitions
#=============================================================================#
VPATH = $(SRCS_DIRS)
OUT_DIR_F = $(strip $(if $(OUT_DIR),$(OUT_DIR)/))

ELF = $(OUT_DIR_F)$(PROJECT)$(SUFFIX).elf
HEX = $(OUT_DIR_F)$(PROJECT)$(SUFFIX).hex
BIN = $(OUT_DIR_F)$(PROJECT)$(SUFFIX).bin
LSS = $(OUT_DIR_F)$(PROJECT)$(SUFFIX).lss
DMP = $(OUT_DIR_F)$(PROJECT)$(SUFFIX).dmp

ifeq ($(BOOT_HEX),)
	HEX_F = $(HEX)
else
	HEX_F = $(OUT_DIR_F)$(PROJECT).hex
endif

#=============================================================================#
# Phony Targets
#=============================================================================#
.PHONY: all create_out_dir print_size upload clean

# Build targets
all: create_out_dir $(HEX_F) $(LSS) $(DMP) print_size

# Create output directory if it doesn't exist
create_out_dir:
	@if not exist "$(OUT_DIR_F)" ( \
		echo Creating directory: $(OUT_DIR_F) & \
		md "$(OUT_DIR_F)" \
	)

# Print size of the compiled ELF and object files
print_size: $(OBJS) $(ELF)
	@echo .
	@echo "Size of compiled modules:"
	$(SIZE) -B -t --common $(OBJS)
	@echo .
	@echo "Size of target .elf file:"
	$(SIZE) -B $(ELF)

# Upload to device
upload: $(HEX_F)
	@echo .
	@echo "---- Programming via ST-LINK ----"
	$(ST_LINK_DIR)/stlink -c SWD UR -OB RDP=0 WRP=0xFFFFFFFF -ME -P $(HEX_F) 0x08000000 -V after_programming -Rst

# Clean output directory
clean:
	@echo .
	@echo "Removing all generated output files from: $(OUT_DIR_F)"
	$(RM) $(OUT_DIR_F)*

#=============================================================================#
# File and Dependency Handling
#=============================================================================#
CXX_SRCS = $(wildcard $(patsubst %, %/*.$(CXX_EXT), . $(SRCS_DIRS)))
C_SRCS   = $(wildcard $(patsubst %, %/*.$(C_EXT), . $(SRCS_DIRS)))
AS_SRCS  = $(wildcard $(patsubst %, %/*.$(AS_EXT), . $(SRCS_DIRS)))

CXX_OBJS = $(addprefix $(OUT_DIR_F), $(notdir $(CXX_SRCS:.$(CXX_EXT)=.o)))
C_OBJS   = $(addprefix $(OUT_DIR_F), $(notdir $(C_SRCS:.$(C_EXT)=.o)))
AS_OBJS  = $(addprefix $(OUT_DIR_F), $(notdir $(AS_SRCS:.$(AS_EXT)=.o)))
OBJS     = $(AS_OBJS) $(C_OBJS) $(CXX_OBJS)
DEPS     = $(OBJS:.o=.d)

INC_DIRS_F = -I. $(patsubst %, -I%, $(INC_DIRS))
LIB_DIRS_F = $(patsubst %, -L%, $(LIB_DIRS))

$(OBJS) : Makefile
$(ELF) : $(LD_SCRIPT)

-include $(DEPS)

#=============================================================================#
# Compilation Rules
#=============================================================================#
# Rule to compile C++ files
$(OUT_DIR_F)%.o : %.$(CXX_EXT)
	@echo "Compiling C++ source file: $<"
	$(CXX) -c $(CXX_FLAGS) $(OPTIMIZATION) $(CXX_DEFS) $(CXX_WARNINGS) $(INC_DIRS_F) -MD -MP -MF $(OUT_DIR_F)$(@F:.o=.d) $< -o $@

# Rule to compile C files
$(OUT_DIR_F)%.o : %.$(C_EXT)
	@echo "Compiling C source file: $<"
	$(CC) -c $(C_FLAGS) $(OPTIMIZATION) $(C_DEFS) $(C_WARNINGS) $(INC_DIRS_F) -MD -MP -MF $(OUT_DIR_F)$(@F:.o=.d) $< -o $@

# Rule to assembly files
$(OUT_DIR_F)%.o : %.$(AS_EXT)
	@echo "Assembling source file: $<"
	$(AS) -c $(AS_FLAGS) $(AS_DEFS) $(INC_DIRS_F) -MD -MP -MF $(OUT_DIR_F)$(@F:.o=.d) $< -o $@

#=============================================================================#
# Linking and File Generation
#=============================================================================#
# Rule to link ELF file
$(ELF) : $(OBJS)
	@echo "Linking ELF file: $@"
	$(CXX) $(OBJS) $(LIBS) $(LD_FLAGS) $(LIB_DIRS_F) -T$(LD_SCRIPT) -Wl,-Map=$(OUT_DIR_F)$(PROJECT)$(SUFFIX).map -o $@

# Rules for generating additional files
%.hex : %.elf
	@echo "Generating HEX file: $@"
	$(OBJCOPY) -O ihex $< $@

%.lss : %.elf
	@echo "Generating LSS file: $@"
	$(OBJDUMP) -S $< > $@

%.dmp : %.elf
	@echo "Generating DMP file: $@"
	$(OBJDUMP) -x --syms $< > $@

# Handle bootloader hex merging
ifneq ($(BOOT_HEX),)
$(HEX_F) : $(BOOT_HEX) $(HEX)
	@echo "Generating final HEX file: $@"
	srec_cat $(BOOT_HEX) -Intel $(HEX) -Intel -o $@ -Intel -Line_Length 43
endif