# Experiment 2: β-galactosidase kinetics by stopped-reaction spectrophotometry (KAUST B241)

Repository: https://github.com/almokhtar8-stack/exp2

Reproducible analysis and reports for **Experiment 2, Studying Enzyme Kinetics using Spectrophotometry** (Methods in Molecular and Cellular Biology, B241, KAUST; Almokhtar Aljarodi with lab partner Abdulrahman Khardali). *E. coli* β-galactosidase hydrolyses *o*-nitrophenyl-β-D-galactopyranoside (ONPG) to *o*-nitrophenol (ONP), quantified at 415 nm after timed aliquots are stopped with Na₂CO₃; the dependence of the initial velocity on enzyme amount and on substrate is measured, and IPTG is tested as an inhibitor.

Everything in `data/processed/`, `tables/`, `figures/` and `report/` is regenerated from the raw data by one command (see *Reproducing the analysis*). No number in any report is typed by hand: the reports are filled from `data/processed/report_values.csv` by `R/08_assemble_reports.R`.

## The two datasets

| Term | What it is | Where it is used |
|---|---|---|
| **Reference dataset** | Measurements provided by the course (Prof. Samah Gadhoum, e-mail of 13 September 2026) for use in the Results section: ONP spectrum and standard curve (Part I), enzyme dilution (Part II), ONPG series without and with IPTG (Part III) | Results: calibration, initial velocities, K_m, V_max, K_m,app, V_max,app, K_i; Figures 1–4, Tables 1–5 |
| **Experimental dataset** | Our group's own GENESYS 10S printouts (7 and 11 September 2026) | Discussion, troubleshooting, secondary analysis (Figures S1, S4; Tables S3, S7, S8), raw-data appendix |

The two terms describe origin and analytical role only: the reference dataset is a course teaching dataset, not validated or published data. Each condition was measured once in both datasets, so the ± values in the reports are standard errors of fits, not replicate variation. The original labels on the source material are kept in the raw files and in the crosswalk tables (`tables/table_dataset_crosswalk.md`, `tables/table_audit_*.md`); `data/raw/README.md` is the data dictionary.

## What is in the reports

| File | Content |
|---|---|
| `report/experiment_2_submission.md`, `.docx`, `.pdf` | **Course submission** in the B241 format (Times New Roman 12, 1.5 spacing, 1-inch margins): Summary ≤ 200 words on the cover, Objectives, Introduction ≤ 2 pages, Experimental Procedure, Results ≤ 4 pages, Discussion ≤ 1 page, a Data and Code Availability statement, numbered Biochemistry-style references with DOIs, the ten Section VII questions and the raw-data appendix with the 14 printout photographs (the course confirmed that no flow sheet is required with this submission). Question 1 is answered with a Michaelis–Menten diagram drawn from the equation. |
| `report/experiment_2_report_full.md`, `experiment_2_supplementary.pdf` | **Supplementary / technical record**: data audit, every analytical decision, the initial-velocity rule and its alternatives, calibration variants, the origin-offset test, the global competitive, noncompetitive and mixed fits, the secondary analysis of the experimental dataset, and reproducibility notes (the PDF is rendered from the Markdown by `report/build_supplementary_pdf.py`) |
| `report/cell_style/experiment_2_cell_style.pdf` | **Journal-style manuscript** (two-column research-article layout with highlights, graphical abstract, STAR-style methods and supplemental items), typeset from `cell_template.tex` with XeLaTeX. A course document, not a journal publication. |
| `report/experiment_2_figures.pdf` | All figures, one per page, with legends (vector) |
| `figures/` | Main figures 1–4 (drawn at their printed size, 6.5 × 1.85 in: Figure 1 spectrum and standard curve; Figure 2 enzyme dilution; Figure 3 progress curves without and with IPTG; Figure 4 Michaelis–Menten and Lineweaver–Burk plots) and the graphical abstract as 600-dpi PNG and vector PDF; `figures/supplementary/` holds Figures S1–S4 and the Question 1 diagram; `figures/README.md` lists every figure with its legend |
| `tables/` | Every table as CSV and Markdown (course tables 1–5, supplementary tables, audit and crosswalk tables, validation report) |

## Headline results (reference dataset)

| Quantity | Value | Qualification |
|---|---|---|
| λ_max of ONP in the alkaline assay matrix | 415 nm | 410–420 nm within 2 % of the maximum |
| ε at 415 nm | 5.22 ± 0.10 A mM⁻¹ cm⁻¹ | five standards, 0.083–0.433 mM, R² = 0.9988; the 0.533 mM standard (A = 3.24, +17 %) excluded; zero-concentration point shown but not fitted |
| Velocity versus enzyme | V₀ = 0.481 × relative enzyme µmol min⁻¹ per assay, R² = 0.97 | rate per unit enzyme 0.71 (tube D) to 1.21 (tube C); tubes D and E nearly equal |
| K_m, V_max (Lineweaver–Burk, course method) | 0.31 mM, 0.477 µmol min⁻¹ per 12 mL assay | five of six uninhibited V₀ are origin-assumed 0–2 min average rates (no reading at t = 0) |
| K_m, V_max (nonlinear) | 0.36 ± 0.13 mM, 0.494 ± 0.059 µmol min⁻¹ | |
| With 0.458 mM IPTG (Lineweaver–Burk) | K_m,app = 1.76 mM (5.6-fold), V_max,app = 0.282 µmol min⁻¹ | no plateau within 0.069–2.2 mM; V_max,app rests on an extrapolated intercept (3.55 ± 2.33) and cannot show whether V_max changed |
| K_i (competitive relation) | 0.100 mM (Lineweaver–Burk); 0.107 ± 0.042 mM (global competitive fit) | 0.22 mM under the baseline-offset scenario; 0.50 mM if every curve is reduced to its 0–2 min average rate; alternative method-dependent estimates, not a confidence interval |
| Mechanism | **consistent with competitive inhibition** | a competitive model fitted both series with a 1.9-fold lower residual sum of squares than a pure noncompetitive model with the same number of parameters, and a mixed model reduced to the competitive one; the competitive model shares V_max by construction, so its fit does not show that V_max was unchanged, and the independently fitted inhibited V_max is poorly constrained (no plateau) |
| Literature (purified *E. coli* enzyme, ONPG, TES pH 7.0, 25 °C; Juers et al. 2009) | K_m 0.12 mM, K_i(IPTG) 0.08 mM | conditions differ from Z buffer |

Unit conversion: V₀ (µmol min⁻¹ per 12.0 mL assay) = ΔA₄₁₅ min⁻¹ ÷ ε × 1.5 (the 2:1 stop dilution) × 12.0 mL = 3.447 × ΔA₄₁₅ min⁻¹.

## Things a reader should know

- **Initial velocities.** One pre-specified rule (`R/00_setup.R`, `R/02_progress_curves.R`) chooses the initial linear window of every curve; where the later increments fall below the first, no linear window can be fitted and V₀ is the average rate over 0–2 min, A₄₁₅(2 min)/2 min, which assumes A₄₁₅ = 0 at t = 0 because no reading exists there. This origin-assumed estimate is an average over the first interval, not a measured instantaneous initial velocity, and may lie below or above the true V₀; it is flagged (†) everywhere. A baseline-offset sensitivity scenario sets the t = 0 absorbance to the median intercept of the linear curves (0.013 A; an assumption transferred between reactions, not a bound). Five estimators are compared (`tables/tableS6_sensitivity.md`, Figure S3); the rule was not chosen for the K_i it gives.
- **Standard curve numbering.** The course table reported seven readings for the manual's eight preparations. The first (0) is the zero-concentration point, as the instructor clarified; the other six were assigned to standards 1–6 in order, anchored by the spectrum tube (standard 4, 1.723 A at 415 nm). Standard 7 (2.0 mL, 0.667 mM) has no reading, and whether it was not prepared or not reported is unknown; nothing was assumed (`tables/table_standard_curve_mapping.md`).
- **Experimental dataset anomalies are kept.** +IPTG tube B ran 1.57-fold faster than tube A at half the substrate; its 10-min value (1.106) is retained as read and the tube is excluded from the secondary fits (results with and without it are tabulated). +IPTG tube E was discarded before measurement and is `NA`. Tube F was not performed in our sessions. No reading was changed, replaced or interpolated.
- **Enzyme dilution.** The reference series is approximately proportional to enzyme (free intercept not distinguishable from zero), but tubes D (0.25) and E (0.15 relative enzyme) gave nearly equal rates, so the rate per unit enzyme ranges from 0.71 to 1.21.
- **Low-substrate reference curves flattened** at about 38 % of the nominal product yield (tubes E, F), which substrate depletion alone does not explain; timing of the aliquots, reaction preparation, a lower-than-nominal effective ONPG concentration, and stopping or read-out effects are possible contributors, none demonstrated by the data.

## Reproducing the analysis

```bash
Rscript R/run_all.R            # from the project root
```

Requirements: R ≥ 4.3 with `tidyverse`, `broom`, `patchwork`, `scales`, `here` (checked by `R/00_setup.R`; `ragg` and `systemfonts` are optional). The build was last run with R 4.3.3 (`report/sessionInfo.txt`). Optional typesetting steps run automatically when the tools are present and are skipped with a message otherwise: XeLaTeX (journal-style manuscript and figure booklet; needs the Liberation Sans and DejaVu Sans fonts), Node.js with the `docx` package (`cd report && npm install`; builds the course `.docx`), LibreOffice (`soffice`, converts the `.docx` to PDF) and pandoc with Python Playwright/Chromium (renders the supplementary PDF).

Scripts, in the order `run_all.R` runs them:

| Script | Purpose |
|---|---|
| `R/00_setup.R` | packages, project paths, manual constants, dataset roles and crosswalk, the V₀ rule, model functions, figure theme |
| `R/01_import_clean.R` | import and validation of both datasets, concentrations, standard-curve mapping table, audit and crosswalk tables, raw-data tables |
| `R/02_progress_curves.R` | candidate windows, two-point secants, regressions, the two-tier rule, baseline-offset scenario, estimator comparison |
| `R/03_standard_curve.R` | spectrum, calibration and its variants (through origin, with zero point, with all six standards) |
| `R/04_enzyme_dilution.R` | velocity versus enzyme amount, proportional and free-intercept fits |
| `R/05_michaelis_menten.R` | Lineweaver–Burk and nonlinear fits under every estimator, depletion estimates |
| `R/06_inhibition.R` | apparent constants with IPTG, K_i, global competitive/noncompetitive/mixed fits, experimental-dataset secondary analysis |
| `R/07_generate_figures.R`, `R/07b_supplementary_figures.R`, `R/09_graphical_abstract.R` | figures (PNG + PDF) and `figures/README.md` |
| `R/08_assemble_reports.R` | fills the report templates (`report/*_template.md`, `report/cell_style/cell_template.tex`, `report/figures_template.tex`) and refuses to write a report with an unfilled placeholder |

`report/build_submission_docx.js` turns the assembled Markdown into the course `.docx`; `report/build_supplementary_pdf.py` renders the supplementary record. `verification/independent_check.py` recomputes the headline numbers of the reference dataset with NumPy/SciPy only, independently of the R code (its output is kept next to it).

## Repository structure

```text
├── README.md, .gitignore, .here, experiment-2-beta-galactosidase-kinetics.Rproj
├── data/
│   ├── raw/                     # manually entered inputs only (see data/raw/README.md)
│   │   ├── reference/           # reference dataset (transcribed from the course files)
│   │   ├── experimental/        # experimental dataset (transcribed from our printouts)
│   │   └── tube_compositions.csv
│   └── processed/               # regenerated
├── R/                           # analysis scripts (above)
├── verification/                # independent NumPy/SciPy recomputation of the headline numbers
├── figures/                     # regenerated figures and figures/README.md
├── tables/                      # regenerated tables (CSV + Markdown)
└── report/                      # templates, assembled reports, cell_style/, raw_data_printouts/
```

## Provenance, permissions and disclosure

- The course's original files (the Part I .docx, the Day 2 .pptx and CSVs) and the instructor's e-mail are kept locally in `data/raw/reference/source_files/` for the cross-check in `R/01_import_clean.R`, but that folder is excluded from version control because permission to redistribute course material has not been obtained. The transcribed values in `data/raw/reference/*.csv` are what the scripts use.
- The 14 printout photographs in `report/raw_data_printouts/` are our own instrument printouts; they contain no personal information.
- The headline numbers were recomputed independently of the R pipeline with a NumPy/SciPy script (`verification/independent_check.py`; its output is kept next to it).
- The transcribed reference values in `data/raw/reference/*.csv` are course-provided teaching data. Explicit permission to redistribute them publicly has not been recorded; they are included because the analysis cannot be reproduced without them. Until the course confirms, treat them as course material rather than open data.
- Public repository: https://github.com/almokhtar8-stack/exp2 (the project folder keeps its longer name). No licence has been chosen yet.

## Outstanding physical items for the course submission

- Question 1 asks for a hand-drawn Michaelis–Menten sketch; the report answers it with the diagram `figures/supplementary/figureQ1_michaelis_menten_sketch.png` (drawn from the equation at its printed size). If the course insists on a drawing by hand, draw it on that page before submission.
- The TA's signature on the original instrument printouts, which the course requires for raw data placed at the end of the report.
