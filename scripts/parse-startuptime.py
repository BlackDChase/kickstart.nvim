#!/usr/bin/env python3
import re
import sys


LINE_RE = re.compile(r"^\s*([0-9.]+)\s+([0-9.]+)\s+([0-9.]+):\s*(.*)$")


def main() -> int:
    if len(sys.argv) < 2:
        print("usage: parse-startuptime.py /path/to/nvim-startuptime.log [N]", file=sys.stderr)
        return 2

    path = sys.argv[1]
    top_n = int(sys.argv[2]) if len(sys.argv) >= 3 else 25

    rows = []
    with open(path, "r", encoding="utf-8", errors="ignore") as f:
        for line in f:
            match = LINE_RE.match(line)
            if not match:
                continue
            total_ms = float(match.group(1))
            delta_ms = float(match.group(2))
            self_ms = float(match.group(3))
            msg = match.group(4).strip()
            rows.append((delta_ms, self_ms, total_ms, msg))

    rows.sort(key=lambda t: t[0], reverse=True)

    print(f"Top {min(top_n, len(rows))} by delta (ms):")
    for delta_ms, self_ms, total_ms, msg in rows[:top_n]:
        print(f"{delta_ms:9.3f}  self {self_ms:8.3f}  total {total_ms:9.3f}  {msg}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())

