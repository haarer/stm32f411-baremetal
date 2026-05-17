import serial
import subprocess

SERIAL_PORT = "/dev/ttyUSB0"
BAUDRATE = 115200
TIMEOUT = 5
EXPECTED = b"hello world\n\r"


def reset_target():
    subprocess.run(["st-flash", "reset"], capture_output=True)


def test_loopback():
    reset_target()
    ser = serial.Serial(SERIAL_PORT, BAUDRATE, timeout=TIMEOUT)
    data = bytearray()
    while len(data) < len(EXPECTED):
        chunk = ser.read(len(EXPECTED) - len(data))
        if not chunk:
            break
        data.extend(chunk)
    ser.close()
    assert data == EXPECTED, f"Expected {EXPECTED!r}, got {data!r}"
