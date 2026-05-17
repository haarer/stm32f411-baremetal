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
