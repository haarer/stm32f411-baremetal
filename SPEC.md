# Specification — STM32F411 Blackpill Bare Metal Firmware

## Goal

A minimal bare-metal firmware image that configures the necessary hardware
and prints "hello world" on the serial console.

## Hardware

- **Board:** Blackpill v3.1 (WeAct Studio)
  - [WeActStudio.MiniSTM32F4x1](https://github.com/WeActStudio/WeActStudio.MiniSTM32F4x1)
- **MCU:** STM32F411V CEU6 (Cortex-M4F, 512K flash, 128K SRAM)
  - Reference manual: RM0383 (see `docs/`)
- **Programmer:** ST-Link V2 (SWD)
- **Serial:** FTDI adapter connected to PB6
- **USB:** Blackpill main USB port (no endpoints unless USB stack is running)

## Software Constraints

- **Bare metal** — no STM HAL libraries
- **CMSIS only** — clone from https://github.com/STMicroelectronics/STM32CubeF4
- **UART1** on pins PA9 (TX) / PA10 (RX), 115200 8N1
- **Toolchain:** `arm-none-eabi` via `tcman` (see toolchain skill)
- **Makefile** — maintain a `Makefile` for building and flashing

## Development Workflow

- The workspace (`/workspace`) is shared with the host
- The user validates and commits; I do not commit
- Each development iteration is recorded in `progress.md`
  - Includes goal, what was done, files created/modified, and key decisions

## Environment

- Running inside a Podman container
- Install any needed tools via `apk` (Alpine Linux)
- Connected hardware: ST-Link V2 programmer, FTDI adapter on PB6
