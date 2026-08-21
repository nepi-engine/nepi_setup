#!/usr/bin/env python3
"""Raise cmake_minimum_required() to the floor CMake 4.x still accepts.

CMake 4.0 removed compatibility with cmake_minimum_required(VERSION <3.5) and
hard-errors on it. This walks a source tree and raises only those declarations,
leaving everything at or above the floor untouched.

Never lower a declared minimum. The declared version is also the policy
baseline: every policy introduced after it defaults to OLD. Lowering Open3D's
top-level 3.20 to 3.6, for example, puts CMP0076 (CMake 3.13) back to OLD, so
target_sources() relative paths resolve against the target's directory instead
of the calling one and the build dies with "Cannot find source file".

Usage:
    update_min_cmake_ver.py [ROOT] [--floor 3.5] [--dry-run]
"""

import argparse
import os
import re
import sys

DEFAULT_FLOOR = "3.5"

# group 1: 'cmake_minimum_required ( VERSION '   (spacing preserved)
# group 2: the lower-bound version
# group 3: everything through the closing paren -- range upper bound ('...3.15'),
#          FATAL_ERROR, etc. -- preserved verbatim
PATTERN = re.compile(
    r"(cmake_minimum_required\s*\(\s*VERSION\s+)([0-9]+(?:\.[0-9]+)*)(.*?\))",
    re.IGNORECASE | re.DOTALL,
)


def as_tuple(version):
    parts = [int(p) for p in version.split(".")]
    return tuple(parts + [0] * (3 - len(parts)))


def update_cmakelists(filepath, floor, floor_tuple, dry_run):
    with open(filepath, "r", encoding="utf-8", errors="ignore") as f:
        content = f.read()

    raised = []
    kept = []

    def repl(match):
        declared = match.group(2)
        if as_tuple(declared) >= floor_tuple:
            kept.append(declared)
            return match.group(0)
        raised.append(declared)
        return match.group(1) + floor + match.group(3)

    new_content = PATTERN.sub(repl, content)

    if raised and not dry_run:
        with open(filepath, "w", encoding="utf-8") as f:
            f.write(new_content)

    return raised, kept


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("root", nargs="?", default=".", help="tree to walk (default: .)")
    ap.add_argument("--floor", default=DEFAULT_FLOOR,
                    help=f"minimum to raise to (default: {DEFAULT_FLOOR})")
    ap.add_argument("--dry-run", action="store_true",
                    help="report what would change, write nothing")
    args = ap.parse_args()

    floor_tuple = as_tuple(args.floor)
    n_files = n_raised = n_kept = 0

    for dirpath, _, filenames in os.walk(args.root):
        for filename in filenames:
            if filename.lower() != "cmakelists.txt":
                continue
            path = os.path.join(dirpath, filename)
            raised, kept = update_cmakelists(path, args.floor, floor_tuple, args.dry_run)
            n_kept += len(kept)
            if raised:
                n_files += 1
                n_raised += len(raised)
                verb = "would raise" if args.dry_run else "raised"
                print(f"{verb} {', '.join(raised)} -> {args.floor}: {path}")

    print(f"\n{n_raised} declaration(s) below {args.floor} in {n_files} file(s); "
          f"{n_kept} already at or above {args.floor} left untouched.")
    if args.dry_run:
        print("dry run -- nothing written.")


if __name__ == "__main__":
    sys.exit(main())
