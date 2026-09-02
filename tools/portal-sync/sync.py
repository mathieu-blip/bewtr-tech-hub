#!/usr/bin/env python3
"""Va voir le portail technicien et met le hub à jour de ce qui a changé.

Le portail `tec-portal` enregistre son contenu sur un second service Cloudflare,
`tec-data`, canal par canal. Ce script ne regarde que le guide technique — le
planning des congés, le parc véhicules et les retours sont de l'organisation
interne, et le hub ne les reprend pas. Il compare le guide à la copie du dépôt
(`docs/portal-snapshot/guide.json`), et quand elle a bougé :

  * il enregistre la nouvelle copie ;
  * il rapatrie les photos qui manquent au dépôt ;
  * il recompose la constante `PORTAL_GUIDE` de `index.html` ;
  * il écrit un compte rendu de ce qui a changé, en français.

Le hub n'est retouché que si le script sait le refaire à l'identique : avant
d'écrire, il recompose `PORTAL_GUIDE` à partir de l'ancienne copie et vérifie
que le résultat est exactement ce que `index.html` contient déjà. Si ce n'est
pas le cas, c'est que la page a été retouchée à la main depuis, et le script
laisse le hub tranquille : il rapporte le changement, mais ne l'applique pas.

    python3 tools/portal-sync/sync.py --report rapport.md --summary resume.json
    python3 tools/portal-sync/sync.py --check     # ne touche à rien
"""

import argparse
import base64
import hashlib
import json
import os
import re
import sys
import time
import urllib.error
import urllib.request

DATA_URL = "https://tec-data.tec-bewtr.workers.dev/state/%s"
PORTAL_URL = "https://tec-portal.tec-bewtr.workers.dev/"
# Le hub ne suit que la donnée technique. Les canaux `planning`, `fleet` et
# `suggestions` du portail sont de l'organisation interne : l'agent n'y touche
# pas, et leur copie du 1er septembre reste telle quelle dans le dépôt.
CHANNELS = ("guide",)
# Cloudflare renvoie 403 aux agents anonymes : on dit qui appelle.
USER_AGENT = "bewtr-tech-hub portal-sync (+https://github.com/mathieu-blip/bewtr-tech-hub)"

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SNAPSHOT_DIR = os.path.join(ROOT, "docs", "portal-snapshot")
IMG_DIR = os.path.join(ROOT, "img")
INDEX = os.path.join(ROOT, "index.html")

GUIDE_PREFIX = "const PORTAL_GUIDE = "

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from build_guide import LANGS, build  # noqa: E402


# --- Aller chercher --------------------------------------------------------

def fetch(url, tries=4):
    """Le contenu d'une adresse, avec quelques secondes de patience."""
    request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    for attempt in range(tries):
        try:
            with urllib.request.urlopen(request, timeout=120) as r:
                return r.read()
        except (urllib.error.URLError, OSError) as err:
            if attempt == tries - 1:
                raise SystemExit("impossible de lire %s : %s" % (url, err))
            time.sleep(2 ** attempt)


def image_map():
    """L'empreinte de chaque photo du portail, et le fichier qui va avec."""
    page = fetch(PORTAL_URL).decode("utf-8", "replace")
    names = re.search(r"^const IMGS = (\[.*?\]);", page, re.M)
    refs = re.search(r"^const IMG_REFS = (\[.*?\]);", page, re.M)
    if not names or not refs:
        raise SystemExit("la page du portail ne contient plus IMGS / IMG_REFS")
    return dict(zip(json.loads(refs.group(1)), json.loads(names.group(1))))


# --- Remettre les photos à leur place --------------------------------------

def inline_name(uri):
    """Le nom de fichier d'une photo que le portail a gardée en clair."""
    return "img/inline-%s.jpg" % hashlib.sha1(uri.encode("utf-8")).hexdigest()[:10]


def normalise(value, refs, sources):
    """La copie du portail, empreintes de photos remplacées par leur fichier.

    `sources` se remplit au passage : pour chaque fichier cité, d'où le tirer.
    """
    if isinstance(value, str):
        if value in refs:
            path = refs[value]
            sources.setdefault(path, ("portal", path))
            return path
        if value.startswith("data:image/"):
            path = inline_name(value)
            sources.setdefault(path, ("inline", value))
            return path
        if value.startswith("##") and "|" in value:
            raise SystemExit(
                "une photo du portail n'a pas de fichier : %s…" % value[:30])
        return value
    if isinstance(value, list):
        return [normalise(v, refs, sources) for v in value]
    if isinstance(value, dict):
        return {k: normalise(v, refs, sources) for k, v in value.items()}
    return value


def collect_images(data):
    """Tous les fichiers photo cités par un arbre."""
    found = set()
    def walk(v):
        if isinstance(v, str):
            if v.startswith("img/"):
                found.add(v)
        elif isinstance(v, list):
            for x in v:
                walk(x)
        elif isinstance(v, dict):
            for x in v.values():
                walk(x)
    walk(data)
    return found


def download_images(paths, sources):
    """Rapatrie les photos que le dépôt n'a pas encore. Rend la liste des noms."""
    added = []
    for path in sorted(paths):
        target = os.path.join(ROOT, path)
        if os.path.exists(target):
            continue
        kind, source = sources.get(path, ("portal", path))
        if kind == "inline":
            blob = base64.b64decode(
                source.split(",", 1)[1] + "=" * (-len(source.split(",", 1)[1]) % 4))
        else:
            blob = fetch(PORTAL_URL + source)
        os.makedirs(os.path.dirname(target), exist_ok=True)
        with open(target, "wb") as f:
            f.write(blob)
        added.append(path)
    return added


# --- Lire et écrire le dépôt ------------------------------------------------

def snapshot_path(name):
    return os.path.join(SNAPSHOT_DIR, "%s.json" % name)


def read_snapshot(name):
    try:
        with open(snapshot_path(name), encoding="utf-8") as f:
            return json.load(f)
    except FileNotFoundError:
        return None


def write_snapshot(name, data):
    with open(snapshot_path(name), "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=1)


def guide_literal(guide):
    return json.dumps(build(guide), ensure_ascii=False, separators=(",", ":"))


def index_lines():
    with open(INDEX, encoding="utf-8") as f:
        return f.readlines()


def guide_line_number(lines):
    """La ligne d'`index.html` qui porte PORTAL_GUIDE."""
    for i, line in enumerate(lines):
        if line.startswith(GUIDE_PREFIX):
            return i
    raise SystemExit("index.html ne contient plus la constante PORTAL_GUIDE")


def hub_matches(lines, i, guide):
    """Le hub est-il encore exactement ce que l'ancienne copie donne ?"""
    return lines[i].rstrip("\n") == GUIDE_PREFIX + guide_literal(guide) + ";"


def write_hub(lines, i, guide):
    lines[i] = GUIDE_PREFIX + guide_literal(guide) + ";\n"
    with open(INDEX, "w", encoding="utf-8") as f:
        f.writelines(lines)


# --- Raconter ce qui a changé ----------------------------------------------

def label(node, keys=("title", "heading", "problem", "name", "label")):
    for key in keys:
        v = node.get(key)
        if isinstance(v, str) and v:
            return v
    return node.get("id") or "sans titre"


def by_key(items, keys):
    """Une liste indexée par le nom de ses entrées, l'ordre gardé."""
    out = {}
    for i, item in enumerate(items or []):
        name = item.get("id") if "id" in item else label(item, keys)
        out.setdefault(name, (i, item))
    return out


def fiche_changed(old, new):
    """Ce qui a bougé dans une fiche, dit simplement."""
    notes = []
    if json.dumps(old.get("chapters"), sort_keys=True) != \
            json.dumps(new.get("chapters"), sort_keys=True):
        notes.append("la procédure")
    if json.dumps(old.get("materialSections"), sort_keys=True) != \
            json.dumps(new.get("materialSections"), sort_keys=True):
        notes.append("le matériel")
    if json.dumps(old.get("measureBlocks"), sort_keys=True) != \
            json.dumps(new.get("measureBlocks"), sort_keys=True):
        notes.append("les cotes")
    if old.get("solution") != new.get("solution"):
        notes.append("la solution")
    if old.get("consequence") != new.get("consequence"):
        notes.append("la conséquence")
    if old.get("coverImage") != new.get("coverImage"):
        notes.append("la photo")
    if old.get("link") != new.get("link"):
        notes.append("la vidéo")
    rest = [k for k in set(old) | set(new)
            if k not in ("chapters", "materialSections", "measureBlocks",
                         "solution", "consequence", "coverImage", "link")
            and json.dumps(old.get(k), sort_keys=True)
            != json.dumps(new.get(k), sort_keys=True)]
    if rest and not notes:
        notes.append("le détail")
    return notes


def describe_guide(old, new):
    """Le compte rendu des changements du guide, et ce qui demande une main."""
    lines, hand = [], []
    old_fr = (old or {}).get("fr") or {}
    new_fr = new.get("fr") or {}

    old_cats = by_key(old_fr.get("categories"), ())
    new_cats = by_key(new_fr.get("categories"), ())
    for name, (_, cat) in new_cats.items():
        if name not in old_cats:
            lines.append("Nouvelle catégorie « %s »." % label(cat))
            hand.append("La catégorie « %s » n'a pas encore sa place dans le hub :"
                        " à ajouter à GUIDE_PLACEMENT d'index.html." % label(cat))
    for name, (_, cat) in old_cats.items():
        if name not in new_cats:
            lines.append("Catégorie retirée : « %s »." % label(cat))
            hand.append("La catégorie « %s » a disparu du portail :"
                        " à retirer de GUIDE_PLACEMENT d'index.html." % label(cat))

    for name, (_, cat) in new_cats.items():
        if name not in old_cats:
            continue
        before = old_cats[name][1]
        title = label(cat)
        old_groups = by_key(before.get("groups"), ("heading",))
        new_groups = by_key(cat.get("groups"), ("heading",))
        for gname, (_, group) in new_groups.items():
            old_fiches = by_key((old_groups.get(gname) or (0, {}))[1].get("problems"),
                                ("problem",))
            new_fiches = by_key(group.get("problems"), ("problem",))
            if gname not in old_groups:
                lines.append("%s : nouveau groupe « %s », %d fiche(s)."
                             % (title, gname, len(new_fiches)))
                continue
            for fname, (_, fiche) in new_fiches.items():
                if fname not in old_fiches:
                    lines.append("%s › %s : nouvelle fiche « %s »."
                                 % (title, gname, fname))
                    continue
                notes = fiche_changed(old_fiches[fname][1], fiche)
                if notes:
                    lines.append("%s › %s › %s : du neuf dans %s."
                                 % (title, gname, fname, ", ".join(notes)))
            for fname in old_fiches:
                if fname not in new_fiches:
                    lines.append("%s › %s : fiche retirée « %s »."
                                 % (title, gname, fname))
        for gname in old_groups:
            if gname not in new_groups:
                lines.append("%s : groupe retiré « %s »." % (title, gname))
        for key, what in (("refGroups", "les références produits"),
                          ("videos", "les vidéos"),
                          ("blocks", "le mémo"),
                          ("treeOverrides", "l'arbre des pannes")):
            if json.dumps(before.get(key), sort_keys=True) != \
                    json.dumps(cat.get(key), sort_keys=True):
                lines.append("%s : %s." % (title, what))

    old_tools = by_key(old_fr.get("tools"), ("name",))
    new_tools = by_key(new_fr.get("tools"), ("name",))
    for name, (_, tool) in new_tools.items():
        if name not in old_tools:
            lines.append("Nouvel outil au catalogue : « %s »." % label(tool))
    for name, (_, tool) in old_tools.items():
        if name not in new_tools:
            lines.append("Outil retiré du catalogue : « %s »." % label(tool))

    known = ("ui", "categories", "home", "tools")
    for key in sorted(set(new_fr) - set(old_fr) - set(known)):
        lines.append("Nouvelle rubrique « %s » dans le guide du portail." % key)
        hand.append("La rubrique « %s » est nouvelle : le hub ne sait pas encore"
                    " l'afficher, il faut lui écrire son bout de page." % key)

    old_ui = old_fr.get("ui") or {}
    new_ui = new_fr.get("ui") or {}
    added_ui = sorted(set(new_ui) - set(old_ui))
    if added_ui:
        lines.append("Nouveaux textes d'interface : %s." % ", ".join(added_ui))
    changed_ui = sorted(k for k in set(old_ui) & set(new_ui) if old_ui[k] != new_ui[k])
    if changed_ui:
        lines.append("Textes d'interface retouchés : %s." % ", ".join(changed_ui))

    for lang in LANGS[1:]:
        before = json.dumps((old or {}).get(lang), sort_keys=True, ensure_ascii=False)
        after = json.dumps(new.get(lang), sort_keys=True, ensure_ascii=False)
        if before != after and not lines:
            lines.append("La version %s a changé, sans que le français bouge." % lang)
    return lines, hand


# --- Le compte rendu --------------------------------------------------------

def french_date(stamp):
    """La date d'enregistrement du portail, dite à la française."""
    if not stamp or len(stamp) < 10:
        return "?"
    return "%s/%s/%s" % (stamp[8:10], stamp[5:7], stamp[0:4])


def report(changes, revisions, images, hub, hand, check=False):
    if not any(r["changed"] for r in revisions.values()):
        return ("# Le guide du portail n'a pas bougé\n\n"
                "Rien à reprendre aujourd'hui.\n")
    rev = revisions["guide"]
    out = ["# Le guide du portail a bougé", "",
           "Révision %s, enregistrée sur le portail le %s."
           % (rev["rev"], french_date(rev["at"])), ""]
    if changes:
        out.append("## Ce qui a changé")
        out.append("")
        out += ["- %s" % c for c in changes]
        out.append("")
    if images:
        out.append("## Photos rapatriées")
        out.append("")
        out += ["- `%s`" % i for i in images]
        out.append("")
    out.append("## Le hub")
    out.append("")
    if hub == "updated" and check:
        out.append("`PORTAL_GUIDE` d'`index.html` peut être recomposé sans rien"
                   " perdre : le script sait refaire la constante à l'identique.")
    elif hub == "updated":
        out.append("`PORTAL_GUIDE` d'`index.html` a été recomposé : le hub montre"
                   " le guide du portail tel qu'il est aujourd'hui.")
    elif hub == "same":
        out.append("Le guide que le hub affiche est le même qu'hier : la nouveauté"
                   " du portail est ailleurs — le glossaire, les textes"
                   " d'interface, une rubrique que le hub ne reprend pas encore."
                   " `index.html` reste tel quel.")
    elif hub == "unchanged":
        out.append("Le guide du portail n'a pas bougé : `index.html` reste tel quel.")
    else:
        out.append("**`index.html` n'a pas été touché.** La constante"
                   " `PORTAL_GUIDE` de la page n'est plus exactement celle que"
                   " l'instantané donne — elle a été retouchée à la main depuis."
                   " Le report du portail vers le hub est donc à refaire à la"
                   " main, sans quoi ces retouches seraient perdues."
                   " `python3 tools/portal-sync/test_build.py` montre où la page"
                   " et l'instantané ont divergé.")
    out.append("")
    if hand:
        out.append("## À reprendre à la main")
        out.append("")
        out += ["- %s" % h for h in hand]
        out.append("")
    return "\n".join(out).rstrip() + "\n"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true",
                        help="regarde et raconte, sans rien écrire")
    parser.add_argument("--report", help="où écrire le compte rendu (markdown)")
    parser.add_argument("--summary", help="où écrire le résumé (json)")
    args = parser.parse_args()

    refs = image_map()
    revisions, fresh, changes, hand = {}, {}, [], []
    for name in CHANNELS:
        payload = json.loads(fetch(DATA_URL % name).decode("utf-8"))
        sources = {}
        data = normalise(payload.get("data"), refs, sources)
        before = read_snapshot(name)
        fresh[name] = (data, sources, before)
        revisions[name] = {"rev": payload.get("rev"), "at": payload.get("at"),
                           "changed": data != before}
        if data == before:
            continue
        notes, needs = describe_guide(before, data)
        changes += notes
        hand += needs

    changed = [n for n in CHANNELS if revisions[n]["changed"]]
    guide_data, guide_sources, guide_before = fresh["guide"]
    images, hub = [], "unchanged"

    if revisions["guide"]["changed"]:
        lines = index_lines()
        i = guide_line_number(lines)
        wanted = GUIDE_PREFIX + guide_literal(guide_data) + ";"
        if lines[i].rstrip("\n") == wanted:
            # Le portail a bougé ailleurs que dans ce que le hub reprend :
            # le glossaire, les textes d'interface, une rubrique à lui.
            hub = "same"
        elif guide_before and hub_matches(lines, i, guide_before):
            hub = "updated"
        else:
            hub = "conflict"
            hand.append("`index.html` a été retouché à la main depuis le dernier"
                        " report : reprendre le guide à la main, sans quoi ces"
                        " retouches seraient perdues.")

    if changed and not args.check:
        # Le dépôt ne garde que les photos que le hub montre.
        images = download_images(collect_images(build(guide_data)), guide_sources)
        for name in changed:
            write_snapshot(name, fresh[name][0])
        if hub == "updated":
            write_hub(lines, i, guide_data)

    text = report(changes, revisions, images, hub, hand, args.check)
    if args.report:
        with open(args.report, "w", encoding="utf-8") as f:
            f.write(text)
    else:
        sys.stdout.write(text)
    if args.summary:
        with open(args.summary, "w", encoding="utf-8") as f:
            json.dump({"changed": bool(changed), "channels": changed,
                       "hub": hub, "images": images, "notes": changes,
                       "hand": hand,
                       "revisions": {n: revisions[n]["rev"] for n in CHANNELS}},
                      f, ensure_ascii=False, indent=2)
    return 0


if __name__ == "__main__":
    sys.exit(main())
