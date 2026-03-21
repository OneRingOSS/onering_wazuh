#!/usr/bin/env python3
"""
Simple adb logcat -> UDP forwarder.

Usage:
    ./test/forward_logcat.py [DEST_HOST] [DEST_PORT] [DEVICE_ID]

Defaults:
    DEST_HOST = 127.0.0.1
    DEST_PORT = 10009
    DEVICE_ID = output of `adb get-serialno`

This script runs `adb logcat -v brief` and forwards each log line as a UDP packet
with the format the app expects: "<DEVICE_ID>: <log line>\n" (if DEVICE_ID is set).

It keeps attempting to restart adb if it exits.
"""

import sys
import socket
import subprocess
import time
import argparse


def run_forwarder(dest_host, dest_port, device_id, adb_args=None):
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    adb_cmd = ["adb"] + (adb_args or ["logcat", "-v", "brief"]) 

    while True:
        try:
            proc = subprocess.Popen(adb_cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, bufsize=1)
            print(f"Started: {' '.join(adb_cmd)} (pid={proc.pid})")

            # read lines and forward
            for raw_line in proc.stdout:
                # proc.stdout yields lines including trailing \n
                if raw_line is None:
                    break
                line = raw_line.rstrip('\n')
                if device_id:
                    out = f"{device_id}: {line}\n"
                else:
                    out = f"{line}\n"

                try:
                    sock.sendto(out.encode('utf-8'), (dest_host, dest_port))

                    # Check if this line contains PACKAGE_ADDED and exit if so
                    if "android.intent.action.PACKAGE_ADDED" in line:
                        print(f"✅ Detected PACKAGE_ADDED event, exiting after sending message")
                        print(f"   Package: {line}")
                        proc.kill()
                        return
                except Exception as e:
                    # Non-fatal, report and continue
                    print(f"UDP send error: {e}", file=sys.stderr)

            # If we reach here, adb process ended (EOF)
            rc = proc.poll()
            print(f"adb process exited (rc={rc}), will restart in 1s...", file=sys.stderr)
            try:
                proc.kill()
            except Exception:
                pass

        except KeyboardInterrupt:
            print("Interrupted by user")
            break
        except Exception as e:
            print(f"Failed to start adb/logcat: {e}", file=sys.stderr)

        # wait a bit before restarting to avoid tight loop
        time.sleep(1)


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

