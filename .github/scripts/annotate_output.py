#!/usr/bin/env python3
"""Turn tool output into GitHub annotations so failures are visible in the
checks API, not only in the raw job log.

Usage: annotate_output.py FILE [MAX_LINES]
Prints `::error::` workflow commands for diagnostic lines. Never fails the job;
the calling step decides the exit code.
"""
import re
import sys

ANALYZER = re.compile(
    r"^\s*(error|warning|info)\s+•\s+(?P<msg>.*?)\s+•\s+(?P<path>[^:]+):(?P<line>\d+):\d+\s+•")
KEYWORDS = re.compile(
    r"(^e: |What went wrong|Could not|FAILURE|BUILD FAILED|Exception|Error:|"
    r"Expected:|Actual:|Which:|\[E\]|Some tests failed|FAILED|Unhandled|"
    r"Null check|No such file|not found|\bERROR\b)")


def escape(text: str) -> str:
    return text.replace("%", "%25").replace("\r", "").replace("\n", " ")


def main() -> int:
    path = sys.argv[1]
    limit = int(sys.argv[2]) if len(sys.argv) > 2 else 60
    count = 0
    with open(path, encoding="utf-8", errors="replace") as fh:
        for raw in fh:
            line = raw.rstrip("\n")
            if count >= limit:
                break
            m = ANALYZER.match(line)
            if m:
                level = "error" if m.group(1) == "error" else "warning"
                print(f"::{level} file={m.group('path')},line={m.group('line')}::"
                      f"{escape(m.group('msg'))}")
                count += 1
            elif KEYWORDS.search(line):
                print(f"::error::{escape(line.strip())[:500]}")
                count += 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
