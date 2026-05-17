import subprocess

FIRMWARE = "/workspace/stm32f411-baremetal/main.hex"
FIRMWARE_DIR = "/workspace/stm32f411-baremetal"


def pytest_sessionstart(session):
    subprocess.run(
        ["st-flash", "--reset", "--format", "ihex", "write", FIRMWARE],
        cwd=FIRMWARE_DIR,
        capture_output=True,
    )
