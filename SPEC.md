# Specification — STM32F411 Blackpill Bare Metal Firmware

## Goal

A minimal bare-metal firmware image that configures the necessary hardware
and prints "hello world" on the serial console.

## Hardware

- **Board:** Blackpill V3.1 (WeAct Studio)
  - [WeActTC/MiniF4-STM32F4x1](https://github.com/WeActTC/MiniF4-STM32F4x1)
  - Pinout is identical to V2.0
  - PCB: 20.78 × 52.81 mm, black, breadboard-friendly
- **MCU:** STM32F411CEU6 (Cortex-M4F, 512K flash, 128K SRAM, UFQFPN48)
  - Reference manual: RM0383 (see `docs/`)
- **Oscillators:** HSE 25 MHz, HSI 16 MHz, LSE 32.768 kHz, LSI 32 kHz
- **Regulator:** AP7343 (+3.3V @ 300 mA)
- **LEDs:** PC13 (user, active-low sink), power LED
- **Button:** PA0 (KEY, active-low)
- **Programmer:** ST-Link V2 via SWD header (bottom edge)
- **Serial:** FTDI adapter connected to PB6/PB7 (USART1)
- **USB:** USB-C connector (PA11 DM, PA12 DP)

### Pinout

Orientation: USB-C at top, SWD at bottom, components facing up.

#### Right header (Header 1)

| # | Label | MCU pin | Notes |
|---|-------|---------|-------|
| 1 | 5V    | —       | +5V rail (USB, no protection) |
| 2 | G     | —       | Ground |
| 3 | 3.3   | —       | +3.3V rail (regulated) |
| 4 | B10   | PB10    | |
| 5 | B2    | PB2     | |
| 6 | B1    | PB1     | |
| 7 | B0    | PB0     | |
| 8 | A7    | PA7     | |
| 9 | A6    | PA6     | |
| 10 | A5   | PA5     | |
| 11 | A4   | PA4     | EEPROM /CS |
| 12 | A3   | PA3     | |
| 13 | A2   | PA2     | |
| 14 | A1   | PA1     | |
| 15 | A0   | PA0     | KEY button (active low) |
| 16 | R    | NRST    | Reset (active low) |
| 17 | C15  | PC15    | |
| 18 | C14  | PC14    | |
| 19 | C13  | PC13    | User LED (sink, active low) |
| 20 | VB   | VBAT    | Backup battery |

#### Left header (Header 2)

| # | Label | MCU pin | Notes |
|---|-------|---------|-------|
| 1 | B12   | PB12    | |
| 2 | B13   | PB13    | |
| 3 | B14   | PB14    | |
| 4 | B15   | PB15    | |
| 5 | A8    | PA8     | |
| 6 | A9    | PA9     | USART1_TX (AF7) |
| 7 | A10   | PA10    | USART1_RX (AF7) |
| 8 | A11   | PA11    | USB_DM |
| 9 | A12   | PA12    | USB_DP |
| 10 | A15  | PA15    | |
| 11 | B3   | PB3     | |
| 12 | B4   | PB4     | EEPROM DO |
| 13 | B5   | PB5     | |
| 14 | B6   | PB6     | **USART1_TX** (AF7) — connected to FTDI RX |
| 15 | B7   | PB7     | **USART1_RX** (AF7) — connected to FTDI TX |
| 16 | B8   | PB8     | |
| 17 | B9   | PB9     | |
| 18 | 5V   | —       | +5V rail |
| 19 | G    | —       | Ground |
| 20 | 3.3  | —       | +3.3V rail |

#### SWD header (bottom edge)

| # | Label | MCU pin | Notes |
|---|-------|---------|-------|
| 1 | 3.3V  | —       | +3.3V |
| 2 | SWDIO | PA13    | |
| 3 | SWCLK | PA14    | |
| 4 | GND   | —       | Ground |

## Software Constraints

- **Bare metal** — no STM HAL libraries
- **CMSIS only** — clone from https://github.com/STMicroelectronics/STM32CubeF4
- **UART1** on PB6 (TX) / PB7 (RX), 115200 8N1, via AF7
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
- Connected hardware: ST-Link V2 programmer, FTDI adapter on PB6/PB7 (USART1)
