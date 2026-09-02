#!/usr/bin/env python3
"""Recompose la constante PORTAL_GUIDE du hub à partir de l'instantané du portail.

Le portail garde son guide une fois par langue (`fr`, `en`, `de`) ; le hub, lui,
veut un seul arbre où chaque texte porte ses trois langues d'un coup. Ce module
fait cette traduction, et rien d'autre : il ne va pas sur le réseau et n'écrit
aucun fichier.

La version française fait foi : c'est elle qui donne le nombre de catégories,
de fiches et d'étapes ; l'anglais et l'allemand ne fournissent que leurs mots.
"""

LANGS = ("fr", "en", "de")


def _langs(snapshot):
    return [snapshot.get(l) or {} for l in LANGS]


def _tr(nodes, key):
    """Le champ `key` des trois langues, ou None s'il est vide partout."""
    out = {}
    for lang, node in zip(LANGS, nodes):
        v = node.get(key) if isinstance(node, dict) else None
        if v not in (None, "", []):
            out[lang] = v
    return out or None


def _aligned(nodes, key):
    """Aligne la liste `key` des trois langues, rang par rang."""
    lists = [(n.get(key) or []) if isinstance(n, dict) else [] for n in nodes]
    for i in range(len(lists[0])):
        yield [(l[i] if i < len(l) else {}) for l in lists]


def _put(dst, key, value):
    """N'ajoute la clé que si elle porte quelque chose."""
    if value not in (None, "", [], {}):
        dst[key] = value


def _image_rows(rows):
    """Les photos rang par rang ; le portail laisse un trou là où il n'y en a pas."""
    return [row or [] for row in rows or []]


def _steps(nodes):
    """Les étapes d'un chapitre : le texte dans les trois langues, ses photos."""
    texts = [(n.get("steps") or []) for n in nodes]
    images = _image_rows(nodes[0].get("stepImages"))
    out = []
    for i in range(max(len(texts[0]), len(images))):
        step = {}
        d = {}
        for lang, t in zip(LANGS, texts):
            if i < len(t) and t[i]:
                d[lang] = t[i]
        _put(step, "d", d)
        _put(step, "imgs", images[i] if i < len(images) else None)
        if step:
            out.append(step)
    return out


def _materials(nodes, tools):
    """Les blocs outillage / matériel, références résolues dans le catalogue."""
    out = []
    for secs in _aligned(nodes, "materialSections"):
        sec = {}
        _put(sec, "h", _tr(secs, "heading"))
        items = []
        for its in _aligned(secs, "items"):
            ref = its[0].get("ref")
            if ref:
                entries = [tools[l].get(ref, {}) for l in LANGS]
                name = _tr(entries, "name")
                image = entries[0].get("image")
            else:
                name = _tr(its, "name")
                image = its[0].get("image")
            item = {}
            _put(item, "n", name)
            _put(item, "img", image)
            if item:
                items.append(item)
        _put(sec, "items", items)
        if sec:
            out.append(sec)
    return out


def _measures(nodes):
    """Les cotes d'un produit : ses vues, et les traits mesurés sur chaque vue."""
    out = []
    for blocks in _aligned(nodes, "measureBlocks"):
        block = {}
        _put(block, "title", _tr(blocks, "title"))
        _put(block, "unit", blocks[0].get("unit"))
        images = []
        for imgs in _aligned(blocks, "images"):
            image = {}
            _put(image, "src", imgs[0].get("src"))
            _put(image, "view", imgs[0].get("viewKey"))
            _put(image, "title", _tr(imgs, "title"))
            annotations = []
            for anns in _aligned(imgs, "annotations"):
                a = anns[0]
                ann = {"k": a.get("type")}
                for axis in ("x1", "y1", "x2", "y2"):
                    # Deux décimales suffisent : le trait est posé en pourcentage
                    # de l'image, et la page pèse déjà lourd.
                    ann[axis] = round(a.get(axis), 2)
                _put(ann, "l", a.get("label"))
                annotations.append(ann)
            _put(image, "ann", annotations)
            images.append(image)
        _put(block, "images", images)
        if block:
            out.append(block)
    return out


def _diagrams(nodes):
    """Les schémas d'une fiche : une image seule ou une série."""
    out = []
    for diags in _aligned(nodes, "diagrams"):
        diagram = {}
        _put(diagram, "title", _tr(diags, "title"))
        images = diags[0].get("images") or []
        if not images and diags[0].get("image"):
            images = [diags[0]["image"]]
        _put(diagram, "images", images)
        if diagram:
            out.append(diagram)
    return out


def _element_blocks(nodes):
    """Les blocs « éléments » : un titre, une photo, une liste de libellés."""
    out = []
    for blocks in _aligned(nodes, "elementBlocks"):
        block = {}
        _put(block, "title", _tr(blocks, "title"))
        _put(block, "image", blocks[0].get("image"))
        _put(block, "items", _tr(blocks, "items"))
        if block:
            out.append(block)
    return out


def _related(nodes):
    """Les renvois d'une fiche : un lien externe, ou une autre fiche du guide."""
    out = []
    for links in _aligned(nodes, "relatedLinks"):
        link = {}
        _put(link, "label", _tr(links, "label"))
        _put(link, "url", links[0].get("url"))
        _put(link, "cat", links[0].get("targetCatId"))
        gi, pi = links[0].get("targetGi"), links[0].get("targetPi")
        if gi is not None:
            link["gi"] = gi
        if pi is not None:
            link["pi"] = pi
        if link:
            out.append(link)
    return out


def _item(nodes, tools):
    """Une fiche du guide."""
    item = {}
    _put(item, "t", _tr(nodes, "problem"))
    _put(item, "cover", nodes[0].get("coverImage"))
    _put(item, "video", nodes[0].get("link"))
    _put(item, "actor", nodes[0].get("actor"))
    # Le portail marque d'un « completed » les fiches déjà rédigées, à vrai ou à
    # faux selon qu'elles sont finies ; le hub retient seulement qu'elles existent.
    if "completed" in nodes[0]:
        item["done"] = bool(nodes[0]["completed"])
    _put(item, "why", _tr(nodes, "consequence"))
    solution = _tr(nodes, "solution")
    if solution:
        solution = {l: (v if isinstance(v, list) else [v]) for l, v in solution.items()}
    _put(item, "sol", solution)
    _put(item, "solImgs", _image_rows(nodes[0].get("stepImages")))
    _put(item, "mats", _materials(nodes, tools))
    chapters = []
    for chaps in _aligned(nodes, "chapters"):
        chapter = {}
        _put(chapter, "h", _tr(chaps, "heading"))
        _put(chapter, "steps", _steps(chaps))
        if chapter:
            chapters.append(chapter)
    _put(item, "chapters", chapters)
    _put(item, "diagrams", _diagrams(nodes))
    _put(item, "related", _related(nodes))
    _put(item, "eblocks", _element_blocks(nodes))
    _put(item, "measures", _measures(nodes))
    return item


def _memo_blocks(nodes):
    """Les blocs d'un mémo : du texte, une liste, ou un tableau de réglages."""
    out = []
    for blocks in _aligned(nodes, "blocks"):
        block = {"kind": blocks[0].get("kind")}
        _put(block, "h", _tr(blocks, "heading"))
        _put(block, "img", blocks[0].get("image"))
        _put(block, "thumb", blocks[0].get("thumb"))
        _put(block, "text", _tr(blocks, "text"))
        items = blocks[0].get("items") or []
        if items and isinstance(items[0], dict):
            rows = []
            for its in _aligned(blocks, "items"):
                row = {}
                _put(row, "color", its[0].get("color"))
                _put(row, "label", _tr(its, "label"))
                _put(row, "value", _tr(its, "value"))
                _put(row, "note", _tr(its, "note"))
                _put(row, "text", _tr(its, "text"))
                rows.append(row)
            _put(block, "items", rows)
        else:
            _put(block, "items", _tr(blocks, "items"))
        out.append(block)
    return out


def _tree(uis):
    """L'arbre des pannes : deux familles de symptômes, chacune vers sa fiche."""
    groups = [
        ("pannesGroupWater", ["symWaterNotFlowing", "symBadTaste", "symLeak",
                              "symNotCold", "symLowFlow"]),
        ("pannesGroupOther", ["symNoise", "symCo2Consumption", "symSystemHot",
                              "symRestartOften", "symSettingNeeded"]),
    ]
    out = []
    for heading, symptoms in groups:
        items = []
        for sym in symptoms:
            item = {"label": {l: ui[sym] for l, ui in zip(LANGS, uis) if ui.get(sym)}}
            _put(item, "cat", SYMPTOM_CATEGORIES.get(sym))
            items.append(item)
        out.append({"h": {l: ui.get(heading) for l, ui in zip(LANGS, uis)},
                    "items": items})
    return out


# Vers quelle catégorie du guide chaque symptôme de l'arbre des pannes renvoie.
SYMPTOM_CATEGORIES = {
    "symWaterNotFlowing": "no-water",
    "symBadTaste": "taste-temp",
    "symLeak": "leak",
    "symNotCold": "taste-temp",
    "symLowFlow": "low-flow",
    "symNoise": "noise",
    "symCo2Consumption": "no-sparkling",
    "symSystemHot": "system-hot",
    "symRestartOften": "restart",
    "symSettingNeeded": "reglage",
}


def build(snapshot):
    """L'instantané du portail, recomposé tel que le hub l'attend."""
    langs = _langs(snapshot)
    uis = [l.get("ui") or {} for l in langs]
    tools = {
        lang: {t["id"]: t for t in (l.get("tools") or [])}
        for lang, l in zip(LANGS, langs)
    }
    out = []
    for cats in _aligned(langs, "categories"):
        cat = {"id": cats[0].get("id"), "type": cats[0].get("type")}
        _put(cat, "t", _tr(cats, "title"))
        _put(cat, "sub", _tr(cats, "subtitle"))
        groups = []
        for grs in _aligned(cats, "groups"):
            group = {}
            _put(group, "h", _tr(grs, "heading"))
            items = []
            for its in _aligned(grs, "problems"):
                items.append(_item(its, tools))
            _put(group, "items", items)
            groups.append(group)
        _put(cat, "groups", groups)
        _put(cat, "mblocks", _memo_blocks(cats))
        if cats[0].get("treeOverrides"):
            _put(cat, "tree", _tree(uis))
        videos = []
        for vids in _aligned(cats, "videos"):
            video = {}
            _put(video, "label", _tr(vids, "label"))
            _put(video, "url", vids[0].get("url"))
            videos.append(video)
        _put(cat, "videos", videos)
        ref_groups = []
        for rgs in _aligned(cats, "refGroups"):
            group = {}
            _put(group, "h", _tr(rgs, "heading"))
            items = []
            for its in _aligned(rgs, "items"):
                item = {}
                _put(item, "ref", its[0].get("ref"))
                _put(item, "name", _tr(its, "name"))
                _put(item, "img", its[0].get("image"))
                items.append(item)
            _put(group, "items", items)
            ref_groups.append(group)
        _put(cat, "refGroups", ref_groups)
        out.append(cat)
    return out
