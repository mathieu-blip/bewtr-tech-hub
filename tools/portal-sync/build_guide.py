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


def _img(value):
    """Un fichier du dépôt, ou rien : le hub n'affiche que ce qu'il possède."""
    return value if isinstance(value, str) and value.startswith("img/") else None


def _file(value):
    """Un document du dépôt — les fiches produit vivent sous `files/`."""
    return value if isinstance(value, str) and value.startswith("files/") else None


def _imgs(values):
    """La liste des fichiers que le dépôt possède, les autres écartés."""
    return [v for v in (values or []) if _img(v)]


def _image_rows(rows):
    """Les photos rang par rang ; le portail laisse un trou là où il n'y en a pas."""
    return [_imgs(row) for row in rows or []]


def _steps(nodes):
    """Les étapes d'un chapitre : le texte, ses photos, ses liens, ses flèches."""
    texts = [(n.get("steps") or []) for n in nodes]
    images = _image_rows(nodes[0].get("stepImages"))
    links = nodes[0].get("stepLinks") or []
    annots = nodes[0].get("stepAnnots") or []
    out = []
    for i in range(max(len(texts[0]), len(images))):
        step = {}
        d = {}
        for lang, t in zip(LANGS, texts):
            if i < len(t) and t[i]:
                d[lang] = t[i]
        _put(step, "d", d)
        _put(step, "imgs", images[i] if i < len(images) else None)
        _put(step, "links", [u for u in (links[i] if i < len(links) else []) or [] if u])
        _put(step, "ann", [a for a in (annots[i] if i < len(annots) else []) or [] if a])
        if step:
            out.append(step)
    return out


def _notes(nodes):
    """Les encarts d'un chapitre : un titre, une intro, des lignes, des photos.

    Chaque ligne porte son genre dans `kinds`, au même rang : `h` pour un
    intertitre, `t` pour un titre, `p` pour un paragraphe.
    """
    out = []
    for notes in _aligned(nodes, "notes"):
        note = {}
        _put(note, "h", _tr(notes, "h"))
        _put(note, "intro", _tr(notes, "intro"))
        kinds = notes[0].get("kinds") or []
        texts = [(n.get("lines") or []) for n in notes]
        lines = []
        for i in range(len(texts[0])):
            d = {}
            for lang, t in zip(LANGS, texts):
                if i < len(t) and t[i]:
                    d[lang] = t[i]
            if not d:
                continue
            line = {"k": kinds[i] if i < len(kinds) else "p"}
            line["d"] = d
            lines.append(line)
        _put(note, "lines", lines)
        _put(note, "imgs", _imgs(notes[0].get("imgs")))
        if note:
            out.append(note)
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
            _put(item, "img", _img(image))
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
        _put(block, "pays", blocks[0].get("pays"))
        _put(block, "frn", blocks[0].get("fournisseur"))
        _put(block, "lien", blocks[0].get("lien"))
        carac = []
        for cars in _aligned(blocks, "carac"):
            if cars[0].get("off"):
                continue
            entry = {}
            _put(entry, "id", cars[0].get("id"))
            _put(entry, "k", _tr(cars, "k"))
            # Une contenance, une pression, une référence de gaz n'ont pas de
            # langue. Le portail les saisit pourtant trois fois, et ses versions
            # anglaise et allemande ont pris du retard : on s'en tient au
            # français, que l'équipe tient à jour.
            _put(entry, "v", cars[0].get("v"))
            if entry:
                carac.append(entry)
        _put(block, "carac", carac)
        images = []
        for imgs in _aligned(blocks, "images"):
            image = {}
            _put(image, "src", _img(imgs[0].get("src")))
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
        images = _imgs(diags[0].get("images"))
        if not images and _img(diags[0].get("image")):
            images = [diags[0]["image"]]
        # Un schéma dont le dépôt n'a pas l'image ne laisse qu'un cadre vide
        # dans la page : mieux vaut ne rien montrer. Le compte rendu, lui, dit
        # que le portail en a un.
        if not images:
            continue
        _put(diagram, "images", images)
        out.append(diagram)
    return out


def _element_blocks(nodes):
    """Les blocs « éléments » : un titre, une photo, une liste de libellés."""
    out = []
    for blocks in _aligned(nodes, "elementBlocks"):
        block = {}
        _put(block, "title", _tr(blocks, "title"))
        _put(block, "image", _img(blocks[0].get("image")))
        _put(block, "items", _tr(blocks, "items"))
        _put(block, "pts", [p for p in (blocks[0].get("pts") or []) if p])
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
    _put(item, "intro", _tr(nodes, "intro"))
    _put(item, "cover", _img(nodes[0].get("coverImage")))
    _put(item, "video", nodes[0].get("link"))
    _put(item, "actor", nodes[0].get("actor"))
    # Le portail marque d'un « completed » les fiches déjà rédigées, à vrai ou à
    # faux selon qu'elles sont finies ; le hub retient seulement qu'elles existent.
    if "completed" in nodes[0]:
        item["done"] = bool(nodes[0]["completed"])
    _put(item, "why", _tr(nodes, "consequence"))
    _put(item, "warn", _tr(nodes, "warn"))
    _put(item, "tip", _tr(nodes, "tip"))
    _put(item, "pnote", _keyed_notes(nodes))
    _put(item, "ask", _ask(nodes))
    _put(item, "endBtns", _end_btns(nodes))
    # Sur quelle réponse à la question `pre` du groupe cette fiche compte :
    # sans elle, elle vaut pour tout le monde.
    _put(item, "need", nodes[0].get("need"))
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
        _put(chapter, "notes", _notes(chaps))
        _put(chapter, "steps", _steps(chaps))
        if chapter:
            chapters.append(chapter)
    _put(item, "chapters", chapters)
    _put(item, "diagrams", _diagrams(nodes))
    _put(item, "related", _related(nodes))
    _put(item, "eblocks", _element_blocks(nodes))
    _put(item, "measures", _measures(nodes))
    return item


def _keyed_notes(nodes):
    """Les notes qui ne valent que pour un filtre donné : « avec un BE CONNECT… »."""
    keys = [k for k in (nodes[0].get("preNote") or {})]
    out = []
    for key in keys:
        d = {}
        for lang, node in zip(LANGS, nodes):
            text = (node.get("preNote") or {}).get(key)
            if text:
                d[lang] = text
        if d:
            out.append({"k": key, "d": d})
    return out


def _options(nodes, holder):
    """Les réponses possibles d'une question, avec leur photo.

    `go` dit où la réponse mène : `next` passe à la fiche suivante de la
    liste, `fix` arrête là et montre la solution de la fiche courante.
    """
    out = []
    lists = [(n.get(holder) or {}).get("opts") or [] for n in nodes]
    for i in range(len(lists[0])):
        opts = [(l[i] if i < len(l) else {}) for l in lists]
        opt = {}
        _put(opt, "id", opts[0].get("id"))
        _put(opt, "e", opts[0].get("e"))
        _put(opt, "l", _tr(opts, "l"))
        # La légende d'une réponse — « Fonctionnement normal » sous « Blanc » —
        # pas encore affichée par le portail lui-même, mais déjà écrite.
        _put(opt, "sub", _tr(opts, "sub"))
        _put(opt, "img", _img(opts[0].get("img")))
        _put(opt, "go", opts[0].get("go"))
        if opt:
            out.append(opt)
    return out


def _end_btns(nodes):
    """Les boutons de fin de fiche, quand il n'y a pas de vraie question posée :
    une confirmation à faire, plutôt qu'un choix entre deux photos."""
    out = []
    lists = [n.get("endBtns") or [] for n in nodes]
    for i in range(len(lists[0])):
        opts = [(l[i] if i < len(l) else {}) for l in lists]
        opt = {}
        _put(opt, "e", opts[0].get("e"))
        _put(opt, "l", _tr(opts, "l"))
        _put(opt, "go", opts[0].get("go"))
        if opt:
            out.append(opt)
    return out


def _question(nodes, holder):
    """Une question posée au technicien : l'énoncé, l'aide, les réponses."""
    asks = [n.get(holder) or {} for n in nodes]
    if not asks[0]:
        return None
    out = {}
    _put(out, "q", _tr(asks, "q"))
    _put(out, "hint", _tr(asks, "hint"))
    _put(out, "himg", _img(asks[0].get("himg")))
    _put(out, "howL", _tr(asks, "howL"))
    _put(out, "how", _tr(asks, "how"))
    _put(out, "howImg", _img(asks[0].get("howImg")))
    _put(out, "opts", _options(nodes, holder))
    # Sans elle, le portail ajoute d'office un bouton « Je n'en ai pas dans
    # mon installation » ; certaines questions n'ont pas ce cas et l'éteignent.
    _put(out, "noneOff", asks[0].get("noneOff"))
    return out or None


def _ask(nodes):
    return _question(nodes, "ask")


def _sheets(cats):
    """Les fiches produit d'une catégorie : un PDF, sa vignette, son format."""
    out = []
    for sheet in cats[0].get("sheets") or []:
        entry = {}
        _put(entry, "id", sheet.get("id"))
        _put(entry, "t", {l: sheet[l] for l in LANGS if sheet.get(l)})
        _put(entry, "fmt", sheet.get("fmt"))
        _put(entry, "thumb", _file(sheet.get("thumb")))
        _put(entry, "pdf", _file(sheet.get("pdf")))
        if entry.get("pdf"):
            out.append(entry)
    return out


def _memo_blocks(nodes):
    """Les blocs d'un mémo : du texte, une liste, ou un tableau de réglages."""
    out = []
    for blocks in _aligned(nodes, "blocks"):
        block = {"kind": blocks[0].get("kind")}
        _put(block, "h", _tr(blocks, "heading"))
        _put(block, "img", _img(blocks[0].get("image")))
        _put(block, "thumb", _img(blocks[0].get("thumb")))
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
    """L'arbre des pannes : deux familles de symptômes, chacune vers sa fiche.

    Le portail les affiche en question — « L'eau ne coule pas ? ». `ui[sym]`
    ne porte que l'énoncé : on ajoute le point d'interrogation à la reprise,
    plutôt que de lire `treeOverrides`, qui porte la même forme en français
    mais des traductions anglaise et allemande fautives (« Escape from
    water? » pour la fuite d'eau, le bruit resté en français).
    """
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
            label = {}
            for lang, ui in zip(LANGS, uis):
                v = ui.get(sym)
                if v:
                    label[lang] = v.rstrip() + (" ?" if lang == "fr" else "?")
            item = {"label": label}
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
        # La teinte et l'icône de la rubrique — celles que le portail met sur
        # ses propres tuiles ; le français fait foi, ce n'est pas du texte.
        _put(cat, "tone", cats[0].get("tone"))
        _put(cat, "icon", cats[0].get("icon"))
        groups = []
        for grs in _aligned(cats, "groups"):
            group = {}
            _put(group, "h", _tr(grs, "heading"))
            _put(group, "pre", _question(grs, "pre"))
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
            # l'image que le portail met sur la catégorie, pas seulement sur ses articles
            _put(group, "img", rgs[0].get("image"))
            items = []
            for its in _aligned(rgs, "items"):
                item = {}
                _put(item, "ref", its[0].get("ref"))
                _put(item, "name", _tr(its, "name"))
                _put(item, "img", _img(its[0].get("image")))
                items.append(item)
            _put(group, "items", items)
            ref_groups.append(group)
        _put(cat, "refGroups", ref_groups)
        _put(cat, "sheets", _sheets(cats))
        out.append(cat)
    return out


# Tout ce que le portail écrit et que ce fichier sait lire, plus ce qu'il
# laisse sciemment de côté. Ce qui n'est dans aucune des deux listes est du
# contenu que le portail a inventé depuis : le hub ne le montrera pas, et
# l'agent doit le dire plutôt que de le laisser tomber en silence.
CONSUMED = {
    "id", "type", "title", "subtitle", "groups", "heading", "problems",
    "blocks", "treeOverrides", "videos", "refGroups", "tools", "ui",
    "categories", "problem", "coverImage", "link", "actor", "completed",
    "consequence", "solution", "stepImages", "materialSections", "chapters",
    "diagrams", "relatedLinks", "elementBlocks", "measureBlocks", "steps",
    "items", "ref", "name", "image", "images", "label", "url", "kind", "text",
    "thumb", "value", "note", "color", "unit", "viewKey", "annotations",
    "x1", "y1", "x2", "y2", "src", "targetCatId", "targetGi", "targetPi",
    "notes", "lines", "kinds", "intro", "h", "imgs", "stepLinks", "stepAnnots",
    "carac", "off", "pays", "fournisseur", "lien", "pts", "tip", "preNote",
    "ask", "pre", "q", "opts", "hint", "himg", "how", "howL", "howImg",
    "sheets", "fmt", "pdf", "fr", "en", "de", "e", "go", "i", "x", "y",
    "img", "k", "l", "need", "endBtns", "tone", "icon", "sub", "warn",
    "noneOff",
}
IGNORED = {
    "parent", "section", "home", "desc", "links", "dims",
    "width", "height", "depth", "diameter", "targetType", "glossary",
    "hideMaterialsTitle", "hideProcedureTitle", "linkToCheck",
    # Le portail numérote ses versions pour son propre usage d'édition ;
    # le hub montre le contenu, pas ce compteur-là.
    "solV", "endV", "actorV", "preV", "v", "soon", "arrows", "diagram",
    "seed2V", "v2fix", "vidV", "tasteV", "badgeV", "tasteCo2V", "coldV",
    "coldImgV", "coldV2", "coldV3", "coldV4", "coldV5", "coldV6", "leakV",
    # Confirmé dans le contenu du 17/09/2026 : une fiche sans question n'en a
    # jamais eu besoin, `askOff` ne fait que le confirmer une deuxième fois.
    "askOff",
    # Identique à `id` dans les trois langues (même valeur non traduite) :
    # une clé technique du portail, pas un texte à afficher.
    "badge",
}
# Ces deux-là ont des clés qui sont des données, pas des noms de champs : la
# référence d'un filtre, le nom d'un symptôme. Inutile d'y descendre.
OPAQUE = {"preNote", "treeOverrides"}
KNOWN = CONSUMED | IGNORED


def unknown_fields(categories):
    """Les champs du portail dont le hub n'a jamais entendu parler.

    Rend, pour chaque nom de champ, le chemin où il apparaît et combien de fois.
    """
    found = {}
    def walk(value, path):
        if isinstance(value, dict):
            for key, sub in value.items():
                if key in OPAQUE:
                    continue
                if key not in KNOWN:
                    seen = found.setdefault(key, [path, 0])
                    seen[1] += 1
                else:
                    walk(sub, path + "/" + key)
        elif isinstance(value, list):
            for item in value:
                walk(item, path + "[]")
    walk(categories, "")
    return found
