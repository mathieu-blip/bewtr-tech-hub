#!/usr/bin/env python3
"""Vérifie que le compilateur sait refaire le hub à l'identique.

C'est la garantie sur laquelle tout repose : tant que `build_guide.py` rend,
à partir de l'instantané du dépôt, exactement la constante `PORTAL_GUIDE`
qu'`index.html` contient, la mise à jour automatique ne peut rien effacer.

    python3 tools/portal-sync/test_build.py
"""

import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, HERE)
from build_guide import build  # noqa: E402

PREFIX = "const PORTAL_GUIDE = "


def main():
    with open(os.path.join(ROOT, "docs", "portal-snapshot", "guide.json"),
              encoding="utf-8") as f:
        snapshot = json.load(f)
    wanted = None
    with open(os.path.join(ROOT, "index.html"), encoding="utf-8") as f:
        for line in f:
            if line.startswith(PREFIX):
                wanted = line.rstrip("\n")[len(PREFIX):-1]
                break
    if wanted is None:
        print("index.html ne contient plus la constante PORTAL_GUIDE")
        return 1
    got = json.dumps(build(snapshot), ensure_ascii=False, separators=(",", ":"))
    if got == wanted:
        print("le hub est bien celui que l'instantané donne (%d caractères)"
              % len(got))
        return 0
    print("le compilateur ne rend plus le hub à l'identique :")
    print("  attendu %d caractères, obtenu %d" % (len(wanted), len(got)))
    for i, (a, b) in enumerate(zip(wanted, got)):
        if a != b:
            print("  première différence au caractère %d" % i)
            print("  index.html : …%s…" % wanted[max(0, i - 60):i + 60])
            print("  recomposé  : …%s…" % got[max(0, i - 60):i + 60])
            break
    return 1


if __name__ == "__main__":
    sys.exit(main())
