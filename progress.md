# Progress

## Iteration 1 — Blink

**Goal:** Verify the development environment (toolchain, CMSIS, stlink, probe) with a minimal 100ms LED blink.

**What was done:**
- Installed `arm-none-eabi` GCC 15.2.0 toolchain via `tcman`
- Installed `make`, `curl`, `git`, `bash` (Alpine apk)
- Cloned `STM32CubeF4` (CMSIS headers only, using git submodules)
- Created linker script (`stm32f411.ld`) for the STM32F411CE (512K flash, 128K RAM)
- Created `startup.c` — vector table, Reset_Handler (data copy, BSS clear, VTOR relocation, HSI clock init at 16MHz), weak default handlers
- Created `main.c` — enable GPIOC, configure PC13 as push-pull output, busy-wait toggle loop
- Created `Makefile` — compile, link, `make flash` target using `st-flash`, and `make cube` to fetch CMSIS from GitHub
- Added `.gitignore` for build artifacts
- Verified build and flashed via ST-Link V2
- LED on PC13 blinks at ~100ms intervals

**Files created:**
- `stm32f411.ld`
- `startup.c`
- `main.c`
- `Makefile`
- `progress.md`
- `.gitignore`

**Key decisions:**
- Use CMSIS headers from STM32CubeF4 (git submodule) rather than custom register headers
- Use HSI (16 MHz) for simplicity — no external crystal dependency
- Busy-wait delay instead of SysTick to avoid interrupt complexity at this stage
- PC13 LED (active low, push-pull) per Blackpill v3.1 schematic

## Iteration 2 — Proper Clock & Flash Setup

**Goal:** Run the MCU at full speed (100 MHz) using the 25 MHz HSE crystal and PLL, with best-practice flash and power configuration.

**What was done:**
- Replaced HSI-based `system_clock_init` with a full HSE + PLL sequence (RM0383 §6.2–§6.4)
- PLL config: M=25, N=200, P=/2 → SYSCLK = 100 MHz, Q=/7 → 48 MHz for USB/SDIO
- Set power regulator to Scale 1 mode (PWR_CR VOS = 0b11) for 100 MHz operation (§3.3.1)
- Configured flash with 3 wait states + prefetch + icache + dcache (§3.5.1)
- AHB = /1 (100 MHz), APB1 = /2 (50 MHz), APB2 = /1 (100 MHz) per max bus limits
- Scaled busy-wait delay from 800K → 5M iterations for ~100ms at 100 MHz
- Added RM0383 section references as inline documentation in `startup.c`

**Files modified:**
- `startup.c` — rewrote `system_clock_init` with proper HSE→PLL→SYSCLK chain
- `main.c` — adjusted delay value for 100 MHz clock
- `SPEC.md` — reformatted, added development workflow section
- `progress.md` — this entry

**Key decisions:**
- 100 MHz chosen over 96 MHz to run at the chip's maximum rated speed
- PLLQ = 7 reserves the 48 MHz output so USB can be added later without re-tuning the PLL
- VCO = 200 MHz (minimum of valid range) keeps PLL power consumption low
- All timing references point to RM0383 sections for traceability
