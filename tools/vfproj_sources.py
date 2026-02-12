#!/usr/bin/env python3
import os
import sys
import xml.etree.ElementTree as ET

EXTS = {".for", ".f", ".f90", ".f95", ".fpp", ".ftn", ".f03", ".f08"}


def main() -> int:
    if len(sys.argv) != 2:
        print("Usage: vfproj_sources.py <path-to-vfproj>", file=sys.stderr)
        return 2

    vfproj = sys.argv[1]
    tree = ET.parse(vfproj)
    root = tree.getroot()
    base = os.path.dirname(os.path.abspath(vfproj))

    seen = set()
    sources = []
    for file_node in root.iter("File"):
        rel = file_node.attrib.get("RelativePath")
        if not rel:
            continue
        rel = rel.replace("\\", os.sep)
        path = os.path.normpath(os.path.join(base, rel))
        ext = os.path.splitext(path)[1].lower()
        if ext not in EXTS:
            continue
        if path in seen:
            continue
        seen.add(path)
        sources.append(path)

    for src in sources:
        print(src)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
