# assemble_photometry_report.py
#
# SV 10/1/26: report helpers for PMA_photometry_complete_SVv1.m, run by
# MATLAB as a command (runReportPython) with whichever installed Python has
# PyMuPDF - not through MATLAB's own Python interface, because the Python
# a given MATLAB release supports (3.10 for R2024b) may not have it.
#
#   python assemble_photometry_report.py assemble <manifest.json> <out.pdf>
#       merges the section PDFs drawn by writeBehaviorReportsAcrossDays
#       into ONE report PDF with a clickable contents page, a navigation bar
#       at the top of every page, and a bookmark outline.
#   python assemble_photometry_report.py fit <file.pdf>
#       places every page that is not already 8.5 x 11 in onto a Letter
#       portrait page, uniformly scaled (vector) to fit inside 0.5 in
#       margins (fitPDFToLetter).
#
#   manifest.json - written by assemblePhotometryReport:
#       {"title": str, "info": [str, ...],
#        "sections": [{"file", "behavior", "behavior_label", "comparison",
#                      "comparison_label", "kind" ("plots" | "qc"),
#                      "page_kinds": ["plots" | "stats" | "qc", ...],
#                      "page_days":  [day key or "", ...]}, ...]}
#   out_path      - the report PDF to write.
# Needs PyMuPDF (pip install pymupdf).
#
# Report order: contents page; every "plots" page (behavior -> comparison ->
# day, as the sections arrive); every "stats" page (same order); every QC
# page (behavior -> channel -> day).
#
# Navigation bar (top 0.4 in of each page, which every report page leaves
# empty): row 1 = behaviors, row 2 = comparisons (or QC channels) and days.
# A link goes to the SAME day (and comparison/channel) in the target
# behavior where that exists, otherwise to the nearest sensible page. The
# page's own position is shown in bold black; links are blue.

import json
import os
import sys

import pymupdf

LINK_BLUE = (0.05, 0.25, 0.75)
BLACK = (0, 0, 0)
GREY = (0.55, 0.55, 0.55)
NAV_SIZE = 6.5
MARGIN = 36.0


def as_list(x):
    if x is None:
        return []
    if isinstance(x, list):
        return x
    return [x]


def text_width(text, bold, size):
    return pymupdf.get_text_length(text, fontname="hebo" if bold else "helv", fontsize=size)


def add_link(page, rect, target):
    page.insert_link({"kind": pymupdf.LINK_GOTO, "page": target, "from": rect,
                      "to": pymupdf.Point(0, 0)})


def draw_items(page, x, y, label, items, size):
    """Draw 'label  a · b · c' at baseline y from x. items: (text, target
    page or None, is_current). Returns the x after the last item."""
    if label:
        page.insert_text((x, y), label, fontname="hebo", fontsize=size, color=GREY)
        x += text_width(label, True, size) + 4
    for k, (text, target, current) in enumerate(items):
        if k > 0:
            sep = "  ·  "
            page.insert_text((x, y), sep, fontname="helv", fontsize=size, color=GREY)
            x += text_width(sep, False, size)
        bold = bool(current)
        color = BLACK if current else (LINK_BLUE if target is not None else GREY)
        page.insert_text((x, y), text, fontname="hebo" if bold else "helv", fontsize=size, color=color)
        w = text_width(text, bold, size)
        if target is not None and not current:
            add_link(page, pymupdf.Rect(x - 1, y - size, x + w + 1, y + 2), target)
        x += w
    return x


def row_width(label, items, size):
    w = (text_width(label, True, size) + 4) if label else 0
    for k, (text, _, current) in enumerate(items):
        if k > 0:
            w += text_width("  ·  ", False, size)
        w += text_width(text, bool(current), size)
    return w


def fit_size(width_needed_at_nav, available):
    if width_needed_at_nav <= available:
        return NAV_SIZE
    return max(4.0, NAV_SIZE * available / width_needed_at_nav)


def assemble(manifest_path, out_path):
    with open(manifest_path, encoding="utf-8") as fh:
        manifest = json.load(fh)
    sections = as_list(manifest.get("sections"))
    title = manifest.get("title", "Photometry Report")
    info = as_list(manifest.get("info"))

    # ---- collect pages in report order --------------------------------
    plots, stats, qcs = [], [], []
    for s in sections:
        kinds = as_list(s.get("page_kinds"))
        days = as_list(s.get("page_days"))
        for j, kind in enumerate(kinds):
            day = days[j] if j < len(days) else ""
            entry = {"file": s["file"], "page": j, "behavior": s["behavior"],
                     "behavior_label": s["behavior_label"], "comparison": s["comparison"],
                     "comparison_label": s["comparison_label"], "kind": kind, "day": day or ""}
            if s.get("kind") == "qc":
                entry["kind"] = "qc"
                qcs.append(entry)
            elif kind == "stats":
                stats.append(entry)
            else:
                plots.append(entry)
    ordered = plots + stats + qcs

    out = pymupdf.open()
    contents = out.new_page(width=612, height=792)
    sources = {}
    for e in ordered:
        if e["file"] not in sources:
            sources[e["file"]] = pymupdf.open(e["file"])
        out.insert_pdf(sources[e["file"]], from_page=e["page"], to_page=e["page"])
        e["out"] = out.page_count - 1
    # insert_pdf invalidates Page objects fetched before it ("'NoneType' object
    # has no attribute 'is_pdf'" on the next draw) - fetch the contents page anew.
    contents = out[0]

    # ---- indexes -------------------------------------------------------
    behaviors, beh_label = [], {}
    comps, days_of = {}, {}
    plots_at, plots_first, stats_first = {}, {}, {}
    qc_at, qc_first, qc_chans, qc_days = {}, {}, {}, {}
    for e in ordered:
        b = e["behavior"]
        if b not in beh_label:
            behaviors.append(b)
            beh_label[b] = e["behavior_label"]
        if e["kind"] == "plots":
            comps.setdefault(b, [])
            if e["comparison"] not in comps[b]:
                comps[b].append(e["comparison"])
            days_of.setdefault(b, [])
            if e["day"] and e["day"] not in days_of[b]:
                days_of[b].append(e["day"])
            plots_at.setdefault((b, e["comparison"], e["day"]), e["out"])
            plots_first.setdefault((b, e["comparison"]), e["out"])
        elif e["kind"] == "stats":
            stats_first.setdefault((b, e["comparison"]), e["out"])
        else:
            qc_chans.setdefault(b, [])
            if e["comparison"] not in qc_chans[b]:
                qc_chans[b].append(e["comparison"])
            qc_days.setdefault((b, e["comparison"]), [])
            if e["day"] and e["day"] not in qc_days[(b, e["comparison"])]:
                qc_days[(b, e["comparison"])].append(e["day"])
            qc_at.setdefault((b, e["comparison"], e["day"]), e["out"])
            qc_first.setdefault((b, e["comparison"]), e["out"])
    stats_start = stats[0]["out"] if stats else None
    qc_start = qcs[0]["out"] if qcs else None

    def first_plots_of(b):
        return next((plots_first[(b, c)] for c in comps.get(b, []) if (b, c) in plots_first), None)

    def first_qc_of(b):
        return next((qc_first[(b, c)] for c in qc_chans.get(b, []) if (b, c) in qc_first), None)

    def channel_of(comparison):
        return "RFP" if comparison.upper().startswith("RFP") else "GFP"

    # ---- navigation bar on every report page ----------------------------
    for e in ordered:
        page = out[e["out"]]
        b, comp, day = e["behavior"], e["comparison"], e["day"]
        width = page.rect.width
        avail = width - 2 * MARGIN

        if e["kind"] == "plots":
            row1 = [(beh_label[x], plots_at.get((x, comp, day), plots_first.get((x, comp), first_plots_of(x))), x == b)
                    for x in behaviors]
            row2a = ("Comparison:", [(c, plots_at.get((b, c, day), plots_first.get((b, c))), c == comp)
                                     for c in comps.get(b, [])])
            row2b = ("Day:", [(d, plots_at.get((b, comp, d)), d == day) for d in days_of.get(b, [])])
            qc_target = qc_at.get((b, channel_of(comp), day), first_qc_of(b))
            right = [("Contents", 0, False), ("Stats", stats_first.get((b, comp), stats_start), False),
                     ("QC", qc_target, False)]
        elif e["kind"] == "stats":
            row1 = [(beh_label[x], stats_first.get((x, comp), next(
                (stats_first[(x, c)] for c in comps.get(x, []) if (x, c) in stats_first), None)), x == b)
                    for x in behaviors]
            row2a = ("Stats for:", [(c, stats_first.get((b, c)), c == comp) for c in comps.get(b, [])])
            row2b = ("", [("Back to plots", plots_first.get((b, comp)), False)])
            right = [("Contents", 0, False), ("Stats", stats_start, True), ("QC", first_qc_of(b), False)]
        else:
            row1 = [(beh_label[x], qc_at.get((x, comp, day), qc_first.get((x, comp), first_qc_of(x))), x == b)
                    for x in behaviors]
            row2a = ("QC channel:", [(c, qc_at.get((b, c, day), qc_first.get((b, c))), c == comp)
                                     for c in qc_chans.get(b, [])])
            row2b = ("Day:", [(d, qc_at.get((b, comp, d)), d == day) for d in qc_days.get((b, comp), [])])
            right = [("Contents", 0, False), ("Stats", stats_start, False),
                     ("Plots", plots_at.get((b, comps.get(b, [""])[0], day), first_plots_of(b)), False)]

        w_right = row_width("", right, NAV_SIZE)
        size1 = fit_size(row_width("Behavior:", row1, NAV_SIZE), avail - w_right - 20)
        draw_items(page, MARGIN, 13, "Behavior:", row1, size1)
        x_r = width - MARGIN - w_right
        draw_items(page, x_r, 13, "", right, NAV_SIZE)

        gap = 14
        w2 = row_width(row2a[0], row2a[1], NAV_SIZE) + gap + row_width(row2b[0], row2b[1], NAV_SIZE)
        size2 = fit_size(w2, avail)
        x = draw_items(page, MARGIN, 23, row2a[0], row2a[1], size2)
        draw_items(page, x + gap * size2 / NAV_SIZE, 23, row2b[0], row2b[1], size2)

    # ---- contents page ----------------------------------------------------
    y = 64
    contents.insert_text((MARGIN, y), title, fontname="hebo", fontsize=15, color=BLACK)
    y += 18
    for line in info:
        contents.insert_text((MARGIN, y), line, fontname="helv", fontsize=8, color=GREY)
        y += 11
    y += 4
    contents.insert_textbox(pymupdf.Rect(MARGIN, y - 7, 612 - MARGIN, y + 20),
                            "Every name below is a link. Every page also has a navigation bar at the top "
                            "(jump to the same day in another behavior or comparison, or to another day), "
                            "and the bookmarks panel lists every section.",
                            fontname="helv", fontsize=7.5, color=GREY)
    y += 30

    def heading(text):
        nonlocal y
        contents.insert_text((MARGIN, y), text, fontname="hebo", fontsize=12, color=BLACK)
        y += 16

    def link_line(label, label_target, items, indent):
        nonlocal y
        x = MARGIN + indent
        x = draw_items(contents, x, y, "", [(label, label_target, False)], 9)
        if items:
            draw_items(contents, x + 12, y, "", items, 8)
        y += 13

    heading("Plots")
    for b in behaviors:
        contents.insert_text((MARGIN + 6, y), beh_label[b], fontname="hebo", fontsize=10, color=BLACK)
        y += 13
        for c in comps.get(b, []):
            link_line(c, plots_first.get((b, c)),
                      [(d, plots_at.get((b, c, d)), False) for d in days_of.get(b, [])], 16)
        y += 4
    if stats:
        y += 6
        heading("Statistics")
        for b in behaviors:
            items = [(c, stats_first.get((b, c)), False) for c in comps.get(b, []) if (b, c) in stats_first]
            if items:
                link_line(beh_label[b], items[0][1], items, 6)
    if qcs:
        y += 10
        heading("QC - raw whole-session traces per animal")
        for b in behaviors:
            for c in qc_chans.get(b, []):
                link_line("%s, %s" % (beh_label[b], c), qc_first.get((b, c)),
                          [(d, qc_at.get((b, c, d)), False) for d in qc_days.get((b, c), [])], 6)

    # ---- bookmarks ------------------------------------------------------------
    toc = [[1, "Contents", 1]]
    if plots:
        toc.append([1, "Plots", plots[0]["out"] + 1])
        for b in behaviors:
            if first_plots_of(b) is None:
                continue
            toc.append([2, beh_label[b], first_plots_of(b) + 1])
            for c in comps.get(b, []):
                toc.append([3, c, plots_first[(b, c)] + 1])
                for d in days_of.get(b, []):
                    if (b, c, d) in plots_at:
                        toc.append([4, d, plots_at[(b, c, d)] + 1])
    if stats:
        toc.append([1, "Statistics", stats_start + 1])
        for b in behaviors:
            keys = [c for c in comps.get(b, []) if (b, c) in stats_first]
            if keys:
                toc.append([2, beh_label[b], stats_first[(b, keys[0])] + 1])
                for c in keys:
                    toc.append([3, c, stats_first[(b, c)] + 1])
    if qcs:
        toc.append([1, "QC", qc_start + 1])
        for b in behaviors:
            if first_qc_of(b) is None:
                continue
            toc.append([2, beh_label[b], first_qc_of(b) + 1])
            for c in qc_chans.get(b, []):
                toc.append([3, c, qc_first[(b, c)] + 1])
                for d in qc_days.get((b, c), []):
                    toc.append([4, d, qc_at[(b, c, d)] + 1])
    out.set_toc(toc)

    tmp = out_path + ".tmp"
    out.save(tmp, garbage=3, deflate=True)
    out.close()
    for src in sources.values():
        src.close()
    os.replace(tmp, out_path)



def fit_to_letter(pdf_path):
    W, H, M = 612.0, 792.0, 36.0
    src = pymupdf.open(pdf_path)
    out = pymupdf.open()
    for i in range(src.page_count):
        r = src[i].rect
        page = out.new_page(width=W, height=H)
        if abs(r.width - W) < 2 and abs(r.height - H) < 2:
            page.show_pdf_page(page.rect, src, i)
            continue
        s = min((W - 2 * M) / r.width, (H - 2 * M) / r.height)
        w, h = r.width * s, r.height * s
        x0 = (W - w) / 2
        page.show_pdf_page(pymupdf.Rect(x0, M, x0 + w, M + h), src, i)
    tmp = pdf_path + ".letter_tmp"
    out.save(tmp, garbage=3, deflate=True)
    out.close()
    src.close()
    os.replace(tmp, pdf_path)


if __name__ == "__main__":
    if len(sys.argv) >= 4 and sys.argv[1] == "assemble":
        assemble(sys.argv[2], sys.argv[3])
    elif len(sys.argv) >= 3 and sys.argv[1] == "fit":
        fit_to_letter(sys.argv[2])
    else:
        sys.exit("usage: assemble_photometry_report.py assemble <manifest.json> <out.pdf> | fit <file.pdf>")
