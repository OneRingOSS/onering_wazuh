#!/usr/bin/env python3
"""
Simple adb logcat -> UDP forwarder for PACKAGE_ADDED events.

Usage:
    ./test/forward_logcat.py [DEST_HOST] [DEST_PORT] [DEVICE_ID]

Defaults:
    DEST_HOST = 127.0.0.1
    DEST_PORT = 10009
    DEVICE_ID = output of `adb get-serialno`

This script runs `adb logcat -d -v brief` (dump mode) to read all existing logs,
finds all lines containing "android.intent.action.PACKAGE_ADDED", and sends only
the LAST occurrence as a UDP packet with the format: "<DEVICE_ID>: <log line>\n"
(if DEVICE_ID is set).

The script exits after sending the last PACKAGE_ADDED event (or immediately if
none are found).
"""

import sys
import socket
import subprocess
import argparse


def run_forwarder(dest_host, dest_port, device_id, adb_args=None):
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    # Use -d flag to dump existing logs and exit (instead of continuous streaming)
    adb_cmd = ["adb"] + (adb_args or ["logcat", "-d", "-v", "brief"])

    try:
        proc = subprocess.Popen(adb_cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, bufsize=1)
        print(f"Started: {' '.join(adb_cmd)} (pid={proc.pid})")

        # Collect all PACKAGE_ADDED lines
        package_added_lines = []

        # read lines and collect PACKAGE_ADDED events
        for raw_line in proc.stdout:
            # proc.stdout yields lines including trailing \n
            if raw_line is None:
                break
            line = raw_line.rstrip('\n')

            # Check if this line contains PACKAGE_ADDED from BackupManagerService
            # (this matches the Wazuh decoder which requires BackupManagerService)
            if "android.intent.action.PACKAGE_ADDED" in line and "BackupManagerService" in line:
                package_added_lines.append(line)
                print(f"📦 Found PACKAGE_ADDED event ({len(package_added_lines)}): {line}")

        # Wait for process to complete
        proc.wait()

        # If we found any PACKAGE_ADDED events, send the last one
        if package_added_lines:
            last_line = package_added_lines[-1]
            if device_id:
                out = f"{device_id}: {last_line}\n"
            else:
                out = f"{last_line}\n"

            try:
                sock.sendto(out.encode('utf-8'), (dest_host, dest_port))
                print(f"✅ Sent last PACKAGE_ADDED event (out of {len(package_added_lines)} total)")
                print(f"   Package: {last_line}")
                return
            except Exception as e:
                print(f"UDP send error: {e}", file=sys.stderr)
                return
        else:
            print(f"⚠️  No PACKAGE_ADDED events found in logcat")
            return

    except KeyboardInterrupt:
        print("Interrupted by user")
    except Exception as e:
        print(f"Failed to start adb/logcat: {e}", file=sys.stderr)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='adb logcat -> UDP forwarder')
    parser.add_argument('dest_host', nargs='?', default='127.0.0.1', help='destination host for UDP packets')
    parser.add_argument('dest_port', nargs='?', default=10009, type=int, help='destination UDP port')
    parser.add_argument('device_id', nargs='?', default=None, help='device id prefix to add to each line (default uses adb get-serialno)')
    args = parser.parse_args()

    device_id = args.device_id
    if device_id is None:
        # try to get a sensible default
        try:
            sp = subprocess.run(["adb", "get-serialno"], stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True, timeout=2)
            device_id = sp.stdout.strip()
            if not device_id:
                device_id = None
        except Exception:
            device_id = None

    try:
        run_forwarder(args.dest_host, args.dest_port, device_id)
    except KeyboardInterrupt:
        pass

