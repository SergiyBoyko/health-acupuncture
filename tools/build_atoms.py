#!/usr/bin/env python3
"""Збирає папку atoms/ з document_source.pdf та ручної транскрипції в tools/data/.

Запуск:  python tools/build_atoms.py            (потрібен пакет pymupdf)
Текстовий шар у PDF непридатний (скан), тому тексти — у tools/data/*.txt,
а PDF використовується лише для вирізання малюнків.
"""
import json
import re
import shutil
import sys
from collections import OrderedDict, defaultdict
from pathlib import Path

import fitz  # pymupdf

ROOT = Path(__file__).resolve().parent.parent
DATA = ROOT / "tools" / "data"
PDF = ROOT / "document_source.pdf"
OUT = ROOT / "atoms"
APP = ROOT / "app"
APP_ASSETS = APP / "assets"
ZOOM = 3.0  # масштаб рендера при вирізанні малюнків
MAX_SIDE = 1200  # найбільша сторона малюнка, px

SEGMENTS = OrderedDict([
    ("vstup", dict(dir="00-vstup", title="Вступ", ru="Введение (фрагмент)", pages="3")),
    ("golova", dict(dir="01-golova", title="Голова", ru="Точки надавливания на голове", pages="4–8")),
    ("shyya", dict(dir="02-shyya", title="Шия", ru="Точки надавливания на шее", pages="9–10")),
    ("tulub", dict(dir="03-tulub", title="Тулуб", ru="Точки надавливания на туловище", pages="10–14")),
    ("spyna", dict(dir="04-spyna", title="Спина", ru="Точки надавливания на спине", pages="15–16")),
    ("ruky-nohy", dict(dir="05-ruky-nohy", title="Руки і ноги", ru="Точки надавливания на руках и ногах", pages="17–20")),
])
SOMATIC_LIST = ["25", "78", "21", "X", "19", "63", "13B", "5M", "10M", "1B", "2B", "15M", "62", "49", "64"]
HAND_LISTS = {  # червоні рукописні переліки точок угорі сторінок
    "golova": [(5, "2M, 35, 5M, 1M, 1B, 9M, 2B"), (6, "3M, 18, 10B, 14M, 6, 92, 13(M), 16(M), 34, 10M, 17"),
               (7, "E, 4, 9B, 12M, 11B, 3B, 16B, 11M, 63, 52, 53"), (8, "JB8, 14B, JB9, 51, JB10, 19, 80")],
    "shyya": [(9, "48, 5B, 15B"), (10, "12B, 13B, 15M")],
    "tulub": [(11, "36, 7, 8, 37, 38, 39, 56, 95, 96"), (12, "66, 25, 30, 32, 64, 67, 31, 33, S1, S2, S3"),
              (13, "23, 54, 65, 24, 88, 93, 49, 1, 2, 3, 4, 60"), (14, "26, 78, 28, 61, 62, 29, 27")],
    "spyna": [(15, "50, 47, 46, 21, 81"), (16, "22, 59, 86, 45, 94, 84, 76, 77, 70, 68")],
    "ruky-nohy": [(18, "97, 79, 82, 20, 71, 74, 72, 55, 73, 43, 69"), (19, "98, 44, 91, 87, 90, 89, 41, 42, 40, 75"),
                  (20, "57, 83, 58, 85")],
}
INTRO = """…жение указательным или средним пальцем. Это массажное движение.

Для непредвиденного случая каждая семья должна иметь какие-то лечебные сведения, чтобы оказать доврачебную помощь.

Не забывайте, что все люди индивидуальны. Приведенные схемы показывают размещение контактных точек, но так как вы можете быть более худым или более толстым, или иметь другое строение, ваша контактная точка может быть слегка смещена. Это не является проблемой. Даже если вы не знаете название точки или с каким органом она связана, лечите эту болезненную точку; болезненность указывает на то, что энергия утекает, а это необходимо исправить.

Болезни или расстройства, которые вы желаете вылечить, перечислены в указателе в алфавитном порядке с номерами соответствующих контактных точек.

## Как часто надо обрабатывать точки надавливания

Всегда применяйте только такое надавливание, которое вы можете вытерпеть. Нажим на точки должен быть сильным, но не до такой степени, чтобы вызывать острую боль. Помните, что чрезмерно нажимать нельзя. Чем дольше и чаще, тем лучше. Во всех серьезных, острых или хронических случаях обрабатывайте точку в первую неделю ежедневно, затем 2-3 раза в неделю, наконец, один раз в неделю. Это определяется вашими собственными потребностями. Иногда требуется много времени, в другой же раз ваше состояние будет реагировать до невероятности быстро.
"""


def fname(code):
    return code.replace("½", "-half")


def rows(path):
    for line in (DATA / path).read_text(encoding="utf-8").splitlines():
        if line.strip() and not line.startswith("#"):
            yield line


# ---------- точки ----------
def load_points():
    pts = OrderedDict()
    cur = None
    for line in (DATA / "points.txt").read_text(encoding="utf-8").splitlines():
        if line.startswith("## "):
            code, seg, page, title = [x.strip() for x in line[3:].split("|", 3)]
            cur = dict(code=code, segment=seg, page=int(page), title=title, body=[], notes=[], fixes=[],
                       figures=[], terms=[])
            pts[code] = cur
        elif cur is None or line.startswith("# ") or not line.strip():
            continue
        elif line.startswith("@note "):
            cur["notes"].append(line[6:].strip())
        elif line.startswith("@fix "):
            cur["fixes"].append(line[5:].strip())
        else:
            cur["body"].append(line.rstrip())
    return pts


def load_figures():
    figs = []
    for line in rows("figures.txt"):
        fid, page, box, seg, kind, codes, cap = [x.strip() for x in line.split("|", 6)]
        figs.append(dict(id=fid, page=int(page), box=[float(v) for v in box.split(",")], segment=seg, kind=kind,
                         codes=[] if codes == "-" else [c.strip() for c in codes.split(",")], caption=cap))
    return figs


def fig_file(f):
    slug = "-".join(fname(c) for c in f["codes"][:6]) or "schema"
    if len(f["codes"]) > 6:
        slug += "-etc"
    return f"{f['id']}_p{f['page'] + 2:02d}_{slug}.jpg"  # сторінка книги = сторінка PDF + 2


# ---------- покажчик ----------
TOKEN = re.compile(
    r"^(?P<code>JB1O|JB\d+|B8|S\d|[XХ]|[EЕ]|\d+½?)(?P<suf>MB|мВ|[MBМВмв])?\s*(?P<q>\(3и4\))?\s*"
    r"(?P<side>левая и правая|левая|правая)?(?P<rest>\s*\(.*\))?$")
SIDES = {"левая": "left", "правая": "right", "левая и правая": "both"}
OVERRIDE = {
    "S1правая,2,3,S1левая,2,3и56": "S1правая,S2правая,S3правая,S1левая,S2левая,S3левая,56",
    "Xлевая,правая,2B,32,61": "Xлевая,Xправая,2B,32,61",
    "10м,S1правая,2,3,30": "10м,S1правая,S2правая,S3правая,30",
}


def parse_codes(raw, points):
    """-> список елементів: dict(ids=[...], text='як показати', side=..)"""
    s = raw.strip().rstrip(".").strip()
    s = OVERRIDE.get(s, s)
    s = s.replace(",1/2", "½").replace(" 1/2", "½")
    out = []
    for chunk in [c.strip() for c in s.split(",") if c.strip()]:
        alts = [a.strip() for a in chunk.split(" или ")]
        for ai, alt in enumerate(alts):
            parts = [p.strip() for p in alt.split("+")]
            items = []
            for part in parts:
                m = TOKEN.match(part)
                ids, label = [], part
                if m:
                    code = {"JB1O": "JB10", "B8": "JB8", "Х": "X", "Е": "E"}.get(m["code"], m["code"])
                    suf = (m["suf"] or "").replace("М", "M").replace("В", "B").replace("м", "M").replace("в", "B")
                    cands = [code + suf[0], code + suf[1]] if len(suf) == 2 else [code + suf]
                    if all(c in points for c in cands):
                        ids = cands
                        tail = "".join(" " + x.strip() for x in (m["q"], m["side"], m["rest"]) if x)
                        if m["q"]:
                            tail = tail.replace("(3и4)", "(3 и 4)")
                        items.append(dict(ids=ids, tail=tail, pair=len(suf) == 2, kind="point",
                                          side=SIDES.get(m["side"]), q=m["q"], rest=(m["rest"] or "").strip() or None))
                        continue
                kind = "unknown" if re.search(r"\d|[A-Z]", label) else "text"
                items.append(dict(ids=[], tail=label, pair=False, kind=kind, side=None, q=None, rest=None))
            out.append(dict(items=items, alt=ai > 0))
    return out


def load_index(points):
    entries, group = [], None
    for line in rows("index.txt"):
        if line.startswith("@group "):
            group = line[7:].strip()
            entries.append(dict(kind="group", term=group))
            continue
        if line.startswith("@endgroup"):
            group = None
            continue
        hand = line.startswith("@hand ")
        sub = line.startswith("> ")
        body = line[6:] if hand else line[2:] if sub else line
        term, _, raw = body.rpartition("-")
        e = dict(kind="hand" if hand else "sub" if sub else "entry", term=term.strip(), raw=raw.strip(),
                 group=group if sub else None, codes=parse_codes(raw, points))
        entries.append(e)
    return entries


def render_codes(e, points, prefix):
    chunks, unresolved = [], []
    for c in e["codes"]:
        segs = []
        for it in c["items"]:
            if it["ids"]:
                links = "/".join(f"[{i}]({prefix}{SEGMENTS[points[i]['segment']]['dir']}/{fname(i)}.md)" for i in it["ids"])
                segs.append(links + (" (MB)" if it["pair"] else "") + it["tail"])
            else:
                segs.append(it["tail"])
                if re.search(r"\d|[A-Z]", it["tail"]):
                    unresolved.append(it["tail"])
        chunks.append(("или " if c["alt"] else "") + " + ".join(segs))
    return ", ".join(chunks).replace(", или ", " или "), unresolved


# ---------- експорт для застосунку ----------
TRANSLIT = dict(zip("абвгдеёжзийклмнопрстуфхцчшщъыьэюяіїєґ",
                    ["a", "b", "v", "g", "d", "e", "e", "zh", "z", "i", "y", "k", "l", "m", "n", "o", "p", "r", "s", "t", "u",
                     "f", "h", "ts", "ch", "sh", "sch", "", "y", "", "e", "yu", "ya", "i", "yi", "ye", "g"]))
QUOTED = re.compile(r'"([0-9A-Z½]+(?: (?:правая|левая))?)"')


def slug(text):
    out = "".join(TRANSLIT.get(ch, ch) for ch in text.lower())
    return re.sub(r"[^a-z0-9]+", "-", out).strip("-")


def app_sections(p, points):
    """Тіло точки -> секції {headings[], paragraphs[]} з розміткою [[КОД]] / [[КОД|підпис]]."""
    related = []

    def link(m):
        label = m.group(1)
        base = label.split(" ")[0]
        if base in points and base != p["code"]:
            if base not in related:
                related.append(base)
            return f'"[[{base}]]"' if label == base else f'"[[{base}|{label}]]"'
        return m.group(0)

    sections = [dict(headings=[], paragraphs=[])]
    for line in p["body"]:
        if line.startswith("### "):
            if sections[-1]["paragraphs"]:
                sections.append(dict(headings=[], paragraphs=[]))
            sections[-1]["headings"].append(line[4:].strip())
        else:
            sections[-1]["paragraphs"].append(QUOTED.sub(link, line))
    return sections, related


def export_app(points, figs, index, gl):
    errors = []
    seg_order = [k for k in SEGMENTS if k != "vstup"]

    def asset(f):
        return f"assets/images/{SEGMENTS[f['segment']]['dir']}/{f['file']}"

    # симптоми: об'єднання однакових термінів
    symptoms, by_key, groups = [], {}, []
    for e in index:
        if e["kind"] == "group":
            groups.append(dict(id=slug(e["term"]), title=e["term"]))
            continue
        group = slug(e["group"]) if e.get("group") else None
        key = (group, e["term"].lower(), e["kind"] == "hand")
        sym = by_key.get(key)
        if sym is None:
            sid = "--".join(x for x in (group, slug(e["term"])) if x) + ("--hand" if e["kind"] == "hand" else "")
            if any(s["id"] == sid for s in symptoms):
                errors.append(f"duplicate symptom id {sid}")
            sym = dict(id=sid, term=e["term"], group=group, handwritten=e["kind"] == "hand", refs=[], sourceLines=[])
            by_key[key] = sym
            symptoms.append(sym)
        line = e["raw"].rstrip(".")
        if line not in sym["sourceLines"]:
            sym["sourceLines"].append(line)
        for c in e["codes"]:
            parts = []
            for it in c["items"]:
                qual = " ".join(x for x in ((it["q"] or "").replace("(3и4)", "(3 и 4)"), it["rest"]) if x) or None
                parts.append(dict(kind=it["kind"], codes=it["ids"], pair=it["pair"], side=it["side"], qualifier=qual,
                                  label=None if it["kind"] == "point" else it["tail"].strip()))
            ref = dict(parts=parts, alternative=c["alt"])
            if ref not in sym["refs"]:
                sym["refs"].append(ref)

    symptom_ids = defaultdict(list)
    unresolved = []
    for s in symptoms:
        for r in s["refs"]:
            for part in r["parts"]:
                if part["kind"] == "unknown":
                    unresolved.append(dict(symptomId=s["id"], label=part["label"]))
                for c in part["codes"]:
                    if c not in points:
                        errors.append(f"symptom {s['id']}: unknown point {c}")
                    elif s["id"] not in symptom_ids[c]:
                        symptom_ids[c].append(s["id"])

    out_points = []
    for order, (code, p) in enumerate(points.items()):
        sections, related = app_sections(p, points)
        ordered = sorted(p["figures"], key=lambda f: (f["kind"] == "overview", f["id"]))
        out_points.append(dict(
            code=code, segmentId=p["segment"], title=p["title"],
            somatic=code in SOMATIC_LIST or "СОМАТИЧЕСК" in p["title"].upper(),
            sourcePage=p["page"], order=order, sections=sections, notes=p["notes"], transcriptionNotes=p["fixes"],
            figureIds=[f["id"] for f in ordered], relatedCodes=related, symptomIds=symptom_ids.get(code, [])))
        for c in related:
            if c not in points:
                errors.append(f"point {code}: unknown related {c}")

    fig_ids = {f["id"] for f in figs}
    for p in out_points:
        errors += [f"point {p['code']}: unknown figure {i}" for i in p["figureIds"] if i not in fig_ids]
    for f in figs:
        if not (APP / asset(f)).exists():
            errors.append(f"figure {f['id']}: missing asset {asset(f)}")
        if max(f["width"], f["height"]) > MAX_SIDE:
            errors.append(f"figure {f['id']}: larger than {MAX_SIDE}px")

    intro = [dict(headings=[], paragraphs=[])]
    for block in INTRO.strip().split("\n\n"):
        if block.startswith("## "):
            intro.append(dict(headings=[block[3:].strip()], paragraphs=[]))
        else:
            intro[-1]["paragraphs"].append(block.strip())

    content = dict(
        version=1,
        segments=[dict(id=k, title=SEGMENTS[k]["title"], sourceTitle=SEGMENTS[k]["ru"], sourcePages=SEGMENTS[k]["pages"],
                       overviewFigureIds=[f["id"] for f in figs if f["segment"] == k and f["kind"] == "overview"],
                       pointCodes=[c for c, p in points.items() if p["segment"] == k]) for k in seg_order],
        points=out_points,
        figures=[dict(id=f["id"], asset=asset(f), kind=f["kind"], caption=f["caption"], sourcePage=f["page"] + 2,
                      segmentId=f["segment"], pointCodes=f["codes"], width=f["width"], height=f["height"]) for f in figs],
        symptomGroups=groups,
        symptoms=symptoms,
        glossary=[dict(term=t.strip(), definition=d.strip()) for t, d in gl],
        meta=dict(
            legend=[dict(code="JB", meaning="челюстная кость"), dict(code="S", meaning="грудные контактные места"),
                    dict(code="E", meaning="обработка уха"), dict(code="X", meaning="кровь"),
                    dict(code="MB", meaning="парные точки")],
            somaticCodes=SOMATIC_LIST, unresolvedCodes=unresolved,
            intro=dict(sections=intro, figureIds=[f["id"] for f in figs if f["segment"] == "vstup"]),
            source="«Интерес», периодическое издание Белоцерковского кооператива «Журналист», январь 1992 г."))

    if errors:
        sys.exit("content integrity errors:\n  " + "\n  ".join(errors))
    APP_ASSETS.mkdir(parents=True, exist_ok=True)
    (APP_ASSETS / "content.json").write_text(json.dumps(content, ensure_ascii=False, separators=(",", ":")),
                                             encoding="utf-8")
    size = sum(f.stat().st_size for f in APP_ASSETS.rglob("*") if f.is_file())
    if size > 15 * 1024 * 1024:
        sys.exit(f"app assets too large: {size / 1e6:.1f} MB")
    print(f"app: content.json {((APP_ASSETS / 'content.json').stat().st_size) / 1024:.0f} KB, "
          f"symptoms={len(symptoms)} (з {sum(e['kind'] != 'group' for e in index)} рядків), "
          f"assets {size / 1e6:.1f} MB")


# ---------- запис ----------
def linkify(text, points, here_seg):
    def rep(m):
        code = m.group(1).replace("1/2", "½")
        base = code.split(" ")[0]
        if base in points and base != rep.self:
            p = points[base]
            pre = "" if p["segment"] == here_seg else f"../{SEGMENTS[p['segment']]['dir']}/"
            return f'["{m.group(1)}"]({pre}{fname(base)}.md)'
        return m.group(0)
    rep.self = None
    return rep, re.compile(r'"([0-9A-Z½]+(?: (?:правая|левая))?)"')


def main():
    points = load_points()
    figs = load_figures()
    index = load_index(points)

    if OUT.exists():
        shutil.rmtree(OUT)
    for s in SEGMENTS.values():
        (OUT / s["dir"] / "images").mkdir(parents=True)
    (OUT / "slovnyk").mkdir()
    (OUT / "kody").mkdir()

    # малюнки
    if APP.exists() and (APP_ASSETS / "images").exists():
        shutil.rmtree(APP_ASSETS / "images")
    doc = fitz.open(PDF)
    for f in figs:
        page = doc[f["page"] - 1]
        k = page.rect.height / 1500.0
        x0, y0, x1, y1 = f["box"]
        clip = fitz.Rect(x0 * k, y0 * k, x1 * k, y1 * k) & page.rect
        f["file"] = fig_file(f)
        f["rel"] = f"images/{f['file']}"
        zoom = min(ZOOM, MAX_SIDE / max(clip.width, clip.height))
        pix = page.get_pixmap(matrix=fitz.Matrix(zoom, zoom), clip=clip)
        f["width"], f["height"] = pix.width, pix.height
        pix.save(OUT / SEGMENTS[f["segment"]]["dir"] / "images" / f["file"], jpg_quality=88)
        if APP.exists():
            dst = APP_ASSETS / "images" / SEGMENTS[f["segment"]]["dir"]
            dst.mkdir(parents=True, exist_ok=True)
            pix.save(dst / f["file"], jpg_quality=88)
        for c in f["codes"]:
            if c not in points:
                sys.exit(f"figure {f['id']}: unknown point {c}")
            points[c]["figures"].append(f)

    # зворотний покажчик
    unresolved_all = []
    for e in index:
        if e["kind"] == "group":
            continue
        term = f"{e['group']}: {e['term']}" if e.get("group") else e["term"]
        if e["kind"] == "hand":
            term += " (рукописне)"
        _, unresolved = render_codes(e, points, "../")
        unresolved_all += [(term, u) for u in unresolved]
        for c in e["codes"]:
            for it in c["items"]:
                for i in it["ids"]:
                    t = term + (f" —{it['tail']}" if it["tail"].strip() else "")
                    if t not in points[i]["terms"]:
                        points[i]["terms"].append(t)

    # файли точок
    for code, p in points.items():
        seg = SEGMENTS[p["segment"]]
        rep, rx = linkify("", points, p["segment"])
        rep.self = code
        somatic = code in SOMATIC_LIST or "СОМАТИЧЕСК" in p["title"].upper()
        fm = ["---", f'code: "{code}"', "type: point", f"segment: {seg['dir']}",
              f'segment_title: "{seg["ru"]}"', "title: " + json.dumps(p["title"], ensure_ascii=False),
              f"somatic: {'true' if somatic else 'false'}", f"source_page: {p['page']}",
              f"pdf_page: {p['page'] - 2}",
              "images: [" + ", ".join(f'"{f["rel"]}"' if f["segment"] == p["segment"] else
                                      f'"../{SEGMENTS[f["segment"]]["dir"]}/{f["rel"]}"' for f in p["figures"]) + "]",
              "index_terms: " + json.dumps(p["terms"], ensure_ascii=False), "---", ""]
        md = fm + [f"# {code} — {p['title']}", "",
                   f"**Сегмент:** [{seg['title']} — {seg['ru']}](_segment.md) · **Джерело:** стор. {p['page']} "
                   f"(PDF стор. {p['page'] - 2})" + (" · **Соматична точка**" if somatic else ""), "", "## Опис", ""]
        for line in p["body"]:
            md += [rx.sub(rep, line) if not line.startswith("###") else line, ""]
        if p["notes"]:
            md += ["## Рукописні нотатки власника", ""] + [f"- {n}" for n in p["notes"]] + [""]
        if p["fixes"]:
            md += ["## Примітки транскрипції", ""] + [f"- {n}" for n in p["fixes"]] + [""]
        md += ["## Зображення", ""]
        if not p["figures"]:
            md += ["_Окремого малюнка для цієї точки в документі немає._", ""]
        for f in sorted(p["figures"], key=lambda f: (f["kind"] == "overview", f["id"])):
            rel = f["rel"] if f["segment"] == p["segment"] else f"../{SEGMENTS[f['segment']]['dir']}/{f['rel']}"
            kind = "зведена схема" if f["kind"] == "overview" else "малюнок біля опису"
            md += [f"![{f['caption']}]({rel})", "", f"*{f['caption']}* — {kind}, стор. {f['page'] + 2}", ""]
        md += ["## У покажчику («Указатель»)", ""]
        md += [f"- {t}" for t in p["terms"]] or ["_Не згадується._"]
        md += ["", "→ [Повний покажчик](../kody/ukazatel.md)", ""]
        (OUT / seg["dir"] / f"{fname(code)}.md").write_text("\n".join(md), encoding="utf-8")

    # файли сегментів
    for key, seg in SEGMENTS.items():
        sp = [p for p in points.values() if p["segment"] == key]
        sf = [f for f in figs if f["segment"] == key]
        md = ["---", "type: segment", f"segment: {seg['dir']}", f'title: "{seg["ru"]}"',
              f'source_pages: "{seg["pages"]}"', f"points: [{', '.join(json.dumps(p['code'], ensure_ascii=False) for p in sp)}]",
              "---", "", f"# {seg['title']} — {seg['ru']}", "", f"Сторінки джерела: {seg['pages']}.", ""]
        if key == "vstup":
            md += ["> Сторінки 1–2 книги у скані відсутні, тому вступ починається з середини речення.", "", INTRO]
        else:
            md += ["## Точки", "", "| Код | Заголовок | Стор. | Малюнків |", "|---|---|---|---|"]
            md += [f"| [{p['code']}]({fname(p['code'])}.md) | {p['title']} | {p['page']} | {len(p['figures'])} |" for p in sp]
            md += [""]
            if key in HAND_LISTS:
                md += ["## Рукописні переліки точок угорі сторінок (червоним)", ""]
                md += [f"- стор. {pg}: {t}" for pg, t in HAND_LISTS[key]] + [""]
        for kind, head in (("overview", "## Зведені схеми"), ("detail", "## Малюнки біля описів")):
            ff = [f for f in sf if f["kind"] == kind]
            if not ff:
                continue
            md += [head, ""]
            for f in ff:
                links = ", ".join(f"[{c}]({'' if points[c]['segment'] == key else '../' + SEGMENTS[points[c]['segment']]['dir'] + '/'}{fname(c)}.md)"
                                  for c in f["codes"])
                md += [f"![{f['caption']}]({f['rel']})", "",
                       f"*{f['caption']}* (стор. {f['page'] + 2})" + (f" — точки: {links}" if links else ""), ""]
        (OUT / seg["dir"] / "_segment.md").write_text("\n".join(md), encoding="utf-8")

    # словник
    md = ["---", "type: glossary", 'title: "Словарь"', 'source_pages: "20–21"', "---", "", "# Словник («Словарь»)", "",
          "Порядок термінів — як у книзі (переклад зберіг алфавітний порядок англомовного оригіналу).", ""]
    gl = [l.split("|", 1) for l in rows("glossary.txt")]
    for t, d in gl:
        md += [f"**{t.strip()}** — {d.strip()}", ""]
    (OUT / "slovnyk" / "slovnyk.md").write_text("\n".join(md), encoding="utf-8")

    # покажчик
    md = ["---", "type: index", 'title: "Указатель"', 'source_pages: "22 і дві наступні ненумеровані сторінки"', "---", "",
          "# Коди («Указатель»)", "", "## Обозначения", "",
          "| Код | Значення |", "|---|---|", "| JB | челюстная кость |", "| S | грудные контактные места |",
          "| E | обработка уха |", "| X | кровь |", "| MB | парные точки |", "",
          "У покажчику також трапляються: суфікси **M** / **B** у кодах (2M, 2B…), `левая` / `правая` — сторона тіла, "
          "`A+B` — точки, які натискають разом, `49(3и4)` — підточки 3 і 4 навколо пупка, `49,1/2` — точка 49½, "
          "«положительные / отрицательные ионы» — надруковано як є, без пояснення в книзі.", "",
          "## Соматические контактные точки", "",
          "Надруковано таблицею 4×4: `25 78 21 LT-X / 19 63 13B 5M / 10M 1B 2B 15M / 62 49 64 RT-X` "
          "(LT-X — ліва X, RT-X — права X).", ""]
    md += [", ".join(f"[{c}](../{SEGMENTS[points[c]['segment']]['dir']}/{fname(c)}.md)" for c in SOMATIC_LIST), "",
           "У тексті описів соматичними названі ще: " + ", ".join(
               f"[{c}](../{SEGMENTS[p['segment']]['dir']}/{fname(c)}.md)" for c, p in points.items()
               if "СОМАТИЧЕСК" in p["title"].upper() and c not in SOMATIC_LIST) + ".", "",
           "## Покажчик хвороб і органів", "",
           "Порядок рядків — як у книзі (алфавіт англомовного оригіналу). Після посилань у `дужках-коді` — рядок, "
           "як він надрукований.", ""]
    for e in index:
        if e["kind"] == "group":
            md += [f"- **{e['term']}:**"]
            continue
        txt, _ = render_codes(e, points, "../")
        pre = "  - " if e["kind"] == "sub" else "- "
        mark = " ✍️ _(дописано від руки)_" if e["kind"] == "hand" else ""
        md += [f"{pre}**{e['term']}** — {txt}{mark} · `{e['raw'].rstrip('.')}`"]
    md += ["", "## Коди з покажчика, яких немає серед описаних точок", ""]
    md += [f"- `{u}` у рядку «{t}»" for t, u in unresolved_all] + [""]
    (OUT / "kody" / "ukazatel.md").write_text("\n".join(md), encoding="utf-8")

    # машинний індекс
    js = dict(points=[dict(code=c, segment=SEGMENTS[p["segment"]]["dir"], title=p["title"], source_page=p["page"],
                           file=f"{SEGMENTS[p['segment']]['dir']}/{fname(c)}.md",
                           images=[f"{SEGMENTS[f['segment']]['dir']}/{f['rel']}" for f in p["figures"]],
                           index_terms=p["terms"]) for c, p in points.items()],
              figures=[dict(id=f["id"], file=f"{SEGMENTS[f['segment']]['dir']}/{f['rel']}", kind=f["kind"],
                            source_page=f["page"] + 2, points=f["codes"], caption=f["caption"]) for f in figs],
              glossary=[dict(term=t.strip(), definition=d.strip()) for t, d in gl])
    shutil.copy(DATA / "README.atoms.md", OUT / "README.md")
    (OUT / "atoms.json").write_text(json.dumps(js, ensure_ascii=False, indent=1), encoding="utf-8")

    if APP.exists():
        export_app(points, figs, index, gl)

    print(f"points={len(points)} figures={len(figs)} index_entries={sum(e['kind'] != 'group' for e in index)} "
          f"glossary={len(gl)}")
    for seg in SEGMENTS:
        print(f"  {seg}: {sum(p['segment'] == seg for p in points.values())} points, "
              f"{sum(f['segment'] == seg for f in figs)} figures")
    print("points without figures:", [c for c, p in points.items() if not p["figures"]])
    print("points not in index:", [c for c, p in points.items() if not p["terms"]])
    print("unresolved index codes:", unresolved_all)


if __name__ == "__main__":
    main()
