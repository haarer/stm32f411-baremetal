PREFIX = arm-none-eabi-
CC     = $(PREFIX)gcc
OBJCOPY = $(PREFIX)objcopy
SIZE   = $(PREFIX)size

ARCH_FLAGS  = -mthumb -mcpu=cortex-m4 -mfloat-abi=hard -mfpu=fpv4-sp-d16
OPT_FLAGS   = -O2 -ffunction-sections -fdata-sections
WARN_FLAGS  = -Wall -Wextra -Werror
CFLAGS      = -std=gnu11 $(ARCH_FLAGS) $(OPT_FLAGS) $(WARN_FLAGS) -ggdb3
LDFLAGS     = -nostartfiles -nodefaultlibs $(ARCH_FLAGS) $(OPT_FLAGS) $(WARN_FLAGS) -ggdb3 \
              -Wl,-gc-sections,-Map,main.map -Wl,--cref -Tstm32f411.ld -lgcc

INCLUDES = -I STM32CubeF4/Drivers/CMSIS/Include \
           -I STM32CubeF4/Drivers/CMSIS/Device/ST/STM32F4xx/Include

.DEFAULT_GOAL := main.hex

OBJS = startup.o main.o delay.o uart.o

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

STM32CubeF4/Drivers/CMSIS/Device/ST/STM32F4xx/Include/stm32f4xx.h:
	git clone --depth 1 https://github.com/STMicroelectronics/STM32CubeF4.git STM32CubeF4
	git -C STM32CubeF4 submodule update --init --depth 1 \
		Drivers/CMSIS/Device/ST/STM32F4xx

cube: STM32CubeF4/Drivers/CMSIS/Device/ST/STM32F4xx/Include/stm32f4xx.h

clean:
	rm -f *.o *.hex *.elf *.map

test:
	uv run --directory test python -m pytest -v

.PHONY: clean cube flash test
