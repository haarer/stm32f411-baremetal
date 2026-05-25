PREFIX = /opt/toolchain-arm-none-eabi-current/bin/arm-none-eabi-
CC     = $(PREFIX)gcc
OBJCOPY = $(PREFIX)objcopy
SIZE   = $(PREFIX)size

ARCH_FLAGS  = -mthumb -mcpu=cortex-m4 -mfloat-abi=hard -mfpu=fpv4-sp-d16
OPT_FLAGS   = -O2 -ffunction-sections -fdata-sections
WARN_FLAGS  = -Wall -Wextra -Werror
CFLAGS      = -std=gnu11 $(ARCH_FLAGS) $(OPT_FLAGS) $(WARN_FLAGS) -ggdb3
LDFLAGS     = -nostartfiles $(ARCH_FLAGS) $(OPT_FLAGS) $(WARN_FLAGS) -ggdb3 \
              -Wl,-gc-sections,-Map,main.map -Wl,--cref -Tstm32f411.ld -lc -lgcc

INCLUDES = -I STM32CubeF4/Drivers/CMSIS/Include \
           -I STM32CubeF4/Drivers/CMSIS/Device/ST/STM32F4xx/Include

.DEFAULT_GOAL := main.hex

OBJS = startup.o main.o delay.o uart.o cli.o syscall.o

$(OBJS): Makefile stm32f411.ld

%.o: %.c
	$(CC) -c -o $@ $(CFLAGS) $(INCLUDES) $<

main.elf: $(OBJS)
	$(CC) -o $@ $^ $(LDFLAGS)
	$(SIZE) $@

main.hex: main.elf
	$(OBJCOPY) -O ihex --set-start 0x08000000 $< $@

flash: main.hex
	st-flash --reset --format ihex write main.hex

# --- Build variants for ABI / float-printf comparison ---
BUILD_DIR = build
OBJ_FILES = startup.o main.o delay.o uart.o cli.o syscall.o

ARCH_soft-nofp  := -mthumb -mcpu=cortex-m4 -mfloat-abi=soft
ARCH_soft-fp    := -mthumb -mcpu=cortex-m4 -mfloat-abi=soft
ARCH_hard-nofp  := -mthumb -mcpu=cortex-m4 -mfloat-abi=hard -mfpu=fpv4-sp-d16
ARCH_hard-fp    := -mthumb -mcpu=cortex-m4 -mfloat-abi=hard -mfpu=fpv4-sp-d16

DEFS_soft-nofp  :=
DEFS_soft-fp    := -DUSE_FLOAT
DEFS_hard-nofp  :=
DEFS_hard-fp    := -DUSE_FLOAT

EXTRA_soft-nofp :=
EXTRA_soft-fp   := -u _printf_float
EXTRA_hard-nofp :=
EXTRA_hard-fp   := -u _printf_float

define variant_rule =
build/$1/%.o: %.c | build/$1/
	$$(CC) -c -o $$@ $$(ARCH_$1) $$(OPT_FLAGS) $$(WARN_FLAGS) -ggdb3 $$(DEFS_$1) $$(INCLUDES) $$<

build/$1/main.elf: $$(addprefix build/$1/,$$(OBJ_FILES))
	$$(CC) -o $$@ $$^ -nostartfiles $$(ARCH_$1) $$(OPT_FLAGS) $$(WARN_FLAGS) -ggdb3 \
		$$(EXTRA_$1) -Wl,-gc-sections,-Map,build/$1/main.map -Wl,--cref -Tstm32f411.ld -lc -lgcc
	$$(SIZE) $$@

build/$1/main.hex: build/$1/main.elf
	$$(OBJCOPY) -O ihex --set-start 0x08000000 $$< $$@

build/$1/:
	mkdir -p $$@
endef

$(eval $(call variant_rule,soft-nofp))
$(eval $(call variant_rule,soft-fp))
$(eval $(call variant_rule,hard-nofp))
$(eval $(call variant_rule,hard-fp))

VARIANT_HEXES = $(addprefix $(BUILD_DIR)/,soft-nofp/main.hex soft-fp/main.hex \
                                        hard-nofp/main.hex hard-fp/main.hex)

variants: $(VARIANT_HEXES)
	$(SIZE) $(BUILD_DIR)/*/main.elf

soft-nofp: build/soft-nofp/main.hex
soft-fp:   build/soft-fp/main.hex
hard-nofp: build/hard-nofp/main.hex
hard-fp:   build/hard-fp/main.hex

flash-hard-fp: build/hard-fp/main.hex
	st-flash --reset --format ihex write $<

flash-soft-fp: build/soft-fp/main.hex
	st-flash --reset --format ihex write $<

STM32CubeF4/Drivers/CMSIS/Device/ST/STM32F4xx/Include/stm32f4xx.h:
	git clone --depth 1 https://github.com/STMicroelectronics/STM32CubeF4.git STM32CubeF4
	git -C STM32CubeF4 submodule update --init --depth 1 \
		Drivers/CMSIS/Device/ST/STM32F4xx

cube: STM32CubeF4/Drivers/CMSIS/Device/ST/STM32F4xx/Include/stm32f4xx.h

clean:
	rm -rf *.o *.hex *.elf *.map $(BUILD_DIR)

test:
	uv sync --directory test
	uv run --directory test python -m pytest -v

.PHONY: clean cube flash test variants soft-nofp soft-fp hard-nofp hard-fp flash-hard-fp flash-soft-fp
