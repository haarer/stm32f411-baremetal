import os
import serial
import subprocess

SERIAL_PORT = os.environ.get("TEST_SERIAL_PORT", "/dev/ttyUSB0")
BAUDRATE = 115200
TIMEOUT = 5
EXPECTED_BOOT = b"hello world\n\r> "


def reset_target():
    subprocess.run(["st-flash", "reset"], capture_output=True)


def send_cmd(ser, cmd):
    ser.reset_input_buffer()
    ser.write(cmd + b"\n")
    resp = ser.read_until(b"> ")
    if resp.endswith(b"> "):
        resp = resp[:-2]
    # Strip local echo of the sent command
    echo_prefix = cmd + b"\n\r"
    if resp.startswith(echo_prefix):
        resp = resp[len(echo_prefix):]
    return resp


def test_boot_message():
    reset_target()
    ser = serial.Serial(SERIAL_PORT, BAUDRATE, timeout=TIMEOUT)
    data = ser.read_until(b"> ")
    ser.close()
    assert data == EXPECTED_BOOT, f"Expected {EXPECTED_BOOT!r}, got {data!r}"


def test_hello_command():
    reset_target()
    ser = serial.Serial(SERIAL_PORT, BAUDRATE, timeout=TIMEOUT)
    ser.read_until(b"> ")
    resp = send_cmd(ser, b"hello")
    ser.close()
    assert resp == b"hello world\n\r", f"Expected hello world, got {resp!r}"


def test_echo_command():
    reset_target()
    ser = serial.Serial(SERIAL_PORT, BAUDRATE, timeout=TIMEOUT)
    ser.read_until(b"> ")
    resp = send_cmd(ser, b"echo HELLOCLI")
    ser.close()
    assert resp == b"HELLOCLI\n\r", f"Expected HELLOCLI, got {resp!r}"


def test_led_on_off():
    reset_target()
    ser = serial.Serial(SERIAL_PORT, BAUDRATE, timeout=TIMEOUT)
    ser.read_until(b"> ")
    resp = send_cmd(ser, b"led on")
    assert resp == b"ok\n\r"
    resp = send_cmd(ser, b"led off")
    assert resp == b"ok\n\r"
    ser.close()


def test_help_command():
    reset_target()
    ser = serial.Serial(SERIAL_PORT, BAUDRATE, timeout=TIMEOUT)
    ser.read_until(b"> ")
    resp = send_cmd(ser, b"help")
    ser.close()
    assert b"available commands:" in resp
    assert b"help" in resp
    assert b"hello" in resp
    assert b"led on" in resp
    assert b"led off" in resp
    assert b"echo" in resp


def test_unknown_command():
    reset_target()
    ser = serial.Serial(SERIAL_PORT, BAUDRATE, timeout=TIMEOUT)
    ser.read_until(b"> ")
    resp = send_cmd(ser, b"notacommand")
    ser.close()
    assert b"error: unknown command" in resp
