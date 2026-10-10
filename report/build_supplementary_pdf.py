#!/usr/bin/env python3
"""Typeset report/experiment_2_report_full.md as report/experiment_2_supplementary.pdf.

Optional step (run from the project root): python3 report/build_supplementary_pdf.py
Needs pandoc and the Python Playwright package with a Chromium browser. The
Markdown record is complete without this PDF; the script only renders it.
"""
import pathlib
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
REPORT = ROOT / "report"
MD = REPORT / "experiment_2_report_full.md"
HTML = REPORT / "experiment_2_supplementary.html"
PDF = REPORT / "experiment_2_supplementary.pdf"

CSS = """
@page { size: Letter; margin: 0.7in 0.6in; }
body { font-family: "Liberation Sans", "DejaVu Sans", Arial, sans-serif; font-size: 9.5pt; line-height: 1.35; color: #111; }
h1 { font-size: 16pt; margin: 0 0 6pt 0; }
h2 { font-size: 12.5pt; margin: 16pt 0 4pt 0; border-bottom: 1px solid #999; padding-bottom: 2pt; page-break-after: avoid; }
h3 { font-size: 10.5pt; margin: 12pt 0 3pt 0; page-break-after: avoid; }
p { margin: 0 0 6pt 0; text-align: justify; }
code { font-family: "DejaVu Sans Mono", monospace; font-size: 8.5pt; }
pre { font-size: 8.5pt; background: #f4f4f4; padding: 4pt; }
table { border-collapse: collapse; font-size: 7pt; margin: 4pt 0 6pt 0; width: 100%; }
th, td { border: 0.5pt solid #bbb; padding: 1.5pt 3pt; vertical-align: top; text-align: left; }
th { background: #eee; font-weight: bold; }
tr { page-break-inside: avoid; }
img { max-width: 100%; height: auto; display: block; margin: 6pt auto; page-break-inside: avoid; }
a { color: #1a4fb3; text-decoration: none; }
"""


def main() -> int:
    if not MD.exists():
        print(f"missing {MD}; run Rscript R/run_all.R first", file=sys.stderr)
        return 1
    css = REPORT / "supplementary.css"
    css.write_text(CSS, encoding="utf-8")
    subprocess.run(["pandoc", str(MD), "-s", "-o", str(HTML), "--css", css.name,
                    "--metadata", "pagetitle=Experiment 2 supplementary information", "--columns=400"], check=True)
    # image paths in the Markdown are relative to figures/; the HTML lives in report/
    html = HTML.read_text(encoding="utf-8").replace('src="figure', 'src="../figures/figure').replace('src="supplementary/', 'src="../figures/supplementary/')
    HTML.write_text(html, encoding="utf-8")
    try:
        from playwright.sync_api import sync_playwright
    except ImportError:
        print("Python Playwright is not installed; the HTML version was written instead:", HTML, file=sys.stderr)
        return 0
    with sync_playwright() as p:
        browser = p.chromium.launch()
        page = browser.new_page()
        page.goto(HTML.as_uri())
        page.wait_for_load_state("networkidle")
        page.pdf(path=str(PDF), format="Letter", print_background=True, prefer_css_page_size=True,
                 display_header_footer=True, header_template="<div></div>",
                 footer_template='<div style="font-size:7pt;width:100%;text-align:center;color:#666;">'
                                 'Experiment 2 supplementary information and technical record, page '
                                 '<span class="pageNumber"></span> of <span class="totalPages"></span></div>')
        browser.close()
    print("wrote", PDF)
    return 0


if __name__ == "__main__":
    sys.exit(main())
