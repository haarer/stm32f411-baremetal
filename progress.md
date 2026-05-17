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

## Pinout Validation

After fetching the pinout from [stm32-base.org](https://stm32-base.org/boards/STM32F411CEU6-WeAct-Black-Pill-V2.0.html),
the pin assignments were confirmed and added to `SPEC.md`:

- **User LED** — PC13 (right header pin 19, active-low sink)
- **USART1** — PB6 (TX) / PB7 (RX), left header pins 14/15, AF7
- **USB** — PA11 (DM) / PA12 (DP)
- **SWD** — PA13 (SWDIO) / PA14 (SWCLK) on bottom-edge header
- **KEY button** — PA0 (right header pin 15, active low)

The board is a Blackpill V3.1; pinout is identical to V2.0.

## Iteration 3 — Clock Stability & SysTick Timing

**Goal:** Move from guessed-cycle delay loops to a deterministic SysTick-based delay,
add HSE failure fallback, and follow CMSIS clock conventions.

**What was done:**
- Renamed `system_clock_init` → `SystemInit` (CMSIS convention)
- Exported `SystemCoreClock` (extern `uint32_t` matching `system_stm32f4xx.h`)
- Added HSE startup timeout (50K iterations); falls back to PLL from HSI (M=16)
  at 100 MHz if the crystal fails to start
- Created `delay.h` / `delay.c` — `delay_us()` and `delay_ms()` using SysTick
  in polling mode (24-bit counter, chunked for long delays)
- Replaced `delay(5000000)` in `main.c` with `delay_ms(100)`
- Updated `Makefile` to include `delay.o`

**Files created/modified:**
- `startup.c` — `SystemInit` with HSE fallback, `SystemCoreClock` export
- `delay.c` / `delay.h` — SysTick-based delay functions (new)
- `main.c` — uses `delay_ms(100)` instead of guessed loop

**Key decisions:**
- SysTick clocked from AHB (no division) for microsecond-level resolution
- HSE timeout prevents board lockup on dead crystal; reverts to HSI+PLL silently
- Delay functions chunk at 24-bit SysTick max so they work at any clock speed
- Kept `SystemInit` name to match CMSIS expectations (though no `system_stm32f4xx.c` is linked)

## Iteration 4 — UART Driver & Hello World

**Goal:** Implement USART1 on PB6 (TX) / PB7 (RX) at 115200 8N1 and print "hello world".

**What was done:**
- Created `uart.h` / `uart.c` — USART1 driver with polled TX
  - Enables GPIOB clock, configures PB6/PB7 as AF7 push-pull
  - Enables USART1 clock on APB2
  - Baud rate: 115200 (BRR = 868 = 100 MHz / (16 × 115200))
  - Newline handling: `\n` emits `\r\n`
  - Provides `uart_putc`, `uart_puts`, `uart_write`
- Updated `main.c` — 5 quick blinks (80 ms) before UART init to verify basic
  function, then prints "hello world", then slow 500 ms blink loop
- Added `uart.o` to Makefile OBJS

**Files created/modified:**
- `uart.h` — UART API (new)
- `uart.c` — USART1 implementation (new)
- `main.c` — 5 pre-init blinks + hello world output
- `Makefile` — added `uart.o`

**Key decisions:**
- Polled TX (no interrupts) keeps it simple at this stage
- `\n` → `\r\n` translation so output works on any terminal
- 5 quick blinks before UART serve as a visual "alive" check independent of serial
