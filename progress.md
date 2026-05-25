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

## Iteration 5 — Test Suite & Environment Setup

**Goal:** Establish a reproducible test environment and automated loopback test.

**What was done:**
- Installed `stlink`, `python3`, `py3-usb`, `py3-pip`, `pyserial`, `uv` (new dependencies for this iteration)
- Created host udev rules (`MODE="0666"`) for ST-Link and FTDI device access
- Created `test/` directory as a uv-managed Python project
- Added `test/pyproject.toml` — uv project config with `pyserial` and `pytest`
- Added `test/conftest.py` — session-scoped `st-flash` before any tests
- Added `test/test_loopback.py` — resets target via `st-flash reset`, captures serial, asserts `hello world\n\r`
- Added `make test` target using `uv run --directory test`
- Documented hardware architecture (ASCII diagram), interconnections table, udev rules, and podman config in `SPEC.md`
- Updated `.gitignore` for test artifacts (`.venv/`, `uv.lock`, `__pycache__/`, `.pytest_cache/`)

**Files created/modified:**
- `test/pyproject.toml` — uv project (new)
- `test/conftest.py` — session flash fixture (new)
- `test/test_loopback.py` — loopback test (new)
- `Makefile` — added `test` target
- `SPEC.md` — added hardware architecture, interconnections, test suite, udev, podman sections
- `.gitignore` — added test artifacts
- `progress.md` — this entry

**Key decisions:**
- Use `uv` for Python dependency management (reproducible, fast, no system-wide installs)
- Flash once per session in `conftest.py`, then each test calls `st-flash reset` as a precondition
- Test opens serial port before reset to avoid missing the boot-time output (~800 ms window)

## Iteration 6 — UART Reception & CLI

**Goal:** Add UART RX support and a simple command-line interface.

**What was done:**
- Added `uart_getc()` to `uart.c` — polled RX with ORE/FE error handling
- Created `cli.c` / `cli.h` — line-based command processor with commands: `help`, `hello`, `led on`, `led off`, `echo <text>`
- Updated `main.c` to initialize CLI after boot and poll UART at 10 µs intervals (fast enough for 115200 baud)
- Fixed UART overrun bug: `uart_getc` clears error flags before reading, main loop polls every 10 µs instead of every 1 ms
- Added 6 test cases: boot message, hello, echo, led on/off, help, unknown command
- Documented CLI commands in `SPEC.md`

**Files created/modified:**
- `uart.h` — added `uart_getc()` declaration
- `uart.c` — added `uart_getc()` with ORE/FE handling
- `cli.c` — CLI implementation (new)
- `cli.h` — CLI header (new)
- `main.c` — CLI init and fast-poll loop
- `Makefile` — added `cli.o`
- `test/test_loopback.py` — 6 test cases
- `SPEC.md` — CLI command table
- `progress.md` — this entry

**Key decisions:**
- Poll UART every 10 µs in the main loop to avoid overrun at 115200 baud (87 µs per byte)
- Handle ORE/FE in `uart_getc` by reading SR+DR to clear error flags
- Line-based CLI with `\n` as terminator, `\r` silently ignored
- Commands return `\n`-terminated strings (expanded to `\n\r` by `uart_putc`)
- **Update:** Removed continuous LED blink from main loop to reduce visual noise during CLI use; only the 5 initial boot flashes remain

## Iteration 7 — Interrupt-Based UART with Ring Buffers & Newlib Integration

**Goal:** Upgrade UART from polling to interrupt-driven TX/RX with ring buffers and integrate newlib syscalls.

**What was done:**
- Created `ringbuf.h` — 256-byte ring buffer with inline accessors
- Rewrote `uart.c` — interrupt-based USART1 (TX via ring buffer + TXEIE, RX captures on RXNE)
- Added `USART1_Handler` to vector table in `startup.c`
- Created `syscall.c` — newlib stubs for `_write`, `_read`, `_sbrk`, and other required syscalls
- Updated `main.c` — removed polling loop, added `NVIC_EnableIRQ(USART1_IRQn)`
- Updated `Makefile` — added `syscall.o`, linked newlib (`-lc`)
- Fixed newline order: `uart_putc('\n')` now sends `\n\r` (not `\r\n`)

**Files created/modified:**
- `ringbuf.h` (new)
- `uart.h`, `uart.c` — interrupt-driven with buffers
- `startup.c` — vector table entry
- `syscall.c` (new)
- `main.c` — NVIC enable, removed polling
- `Makefile` — newlib link

**Testing:** All 6 tests passing ✓
- Boot message, hello, echo, led on/off, help, unknown command

## Iteration 8 — Fix pktsend Deadlock & Polled/Interrupt TX Race

**Goal:** Fix `pktsend` hang for payloads ≥ 255 bytes and data corruption for payloads < 256 bytes.

**What was done:**

### Bug 1: Deadlock in `uart_write`
`uart_write` set `TXEIE` only after completing the loop. When payload ≥ 255 bytes filled the ring buffer, the `while(free == 0)` spin-loop deadlocked because the ISR could never fire to drain it. Fixed by moving `TXEIE` enable inside the loop, after each byte queued.

### Bug 2: Polled vs Interrupt TX Race
`uart_putc` wrote directly to `USART1->DR` (polled), racing with the ISR which also writes `DR` for ring-buffer TX. For payloads < 256 bytes the for loop finished before the ISR fired, then `print_prompt()`'s polled `uart_putc` overwrote data bytes the ISR was transmitting, causing `> ` to appear mid-stream early. Fixed by converting `uart_putc` to queue through the ring buffer + TXEIE, matching `uart_write`.

### Bug 3: Missing `volatile` on Ring Buffer Head/Tail
`head`/`tail` in `struct Ringbuffer` were plain `uint16_t`. At `-O2` the compiler could cache them in registers, causing the ISR or main loop to read stale values. Added `volatile` to both fields.

**Files modified:**
- `uart.c` — moved TXEIE inside `uart_write` loop; rewrote `uart_putc` to use ring buffer
- `ringbuf.h` — added `volatile` to `head` and `tail`
- `test/test_loopback.py` — updated boot message expectation for Iteration 7's extra boot line

**Testing:** All 6 tests passing ✓, `pktsend` verified at sizes 100, 254, 255, 256, 300, 500, 1000.
