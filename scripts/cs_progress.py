#!/usr/bin/env python3
"""
Filter for ChampSim output that adds a progress bar with ETA.
Reads stdin, passes all lines to stdout, and renders progress on stderr.

Usage: champsim ... | cs_progress.py <total_instructions>
"""
import sys
import re
import time

COLS = 50

def format_time(secs):
    if secs < 60:
        return f"{secs:.0f}s"
    elif secs < 3600:
        return f"{secs // 60:.0f}m{secs % 60:02.0f}s"
    else:
        return f"{secs // 3600:.0f}h{(secs % 3600) // 60:02.0f}m"

def main():
    total = int(sys.argv[1]) if len(sys.argv) > 1 else 0
    if total <= 0:
        # No total known, just pass through
        for line in sys.stdin:
            sys.stdout.write(line)
        return

    heartbeat_re = re.compile(r'instructions:\s*(\d+)')
    start = time.time()
    last_instr = 0

    while True:
        line = sys.stdin.readline()
        if not line:
            break
        sys.stdout.write(line)
        sys.stdout.flush()

        m = heartbeat_re.search(line)
        if not m:
            continue

        last_instr = int(m.group(1))
        frac = min(last_instr / total, 1.0)
        elapsed = time.time() - start

        if frac > 0:
            eta = elapsed / frac * (1 - frac)
            eta_str = format_time(eta)
        else:
            eta_str = "?"

        filled = int(COLS * frac)
        bar = "█" * filled + "░" * (COLS - filled)
        pct = frac * 100
        sys.stderr.write(f"\r  [{bar}] {pct:5.1f}%  {format_time(elapsed)} elapsed, ~{eta_str} remaining ")
        sys.stderr.flush()

    elapsed = time.time() - start
    sys.stderr.write(f"\r  [{'█' * COLS}] 100.0%  {format_time(elapsed)} total{' ' * 20}\n")
    sys.stderr.flush()

if __name__ == "__main__":
    main()
