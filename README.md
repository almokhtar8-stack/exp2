# Experiment 2: Enzyme Kinetics of β-Galactosidase

B241 Methods in Molecular and Cellular Biology, KAUST

Almokhtar Aljarodi (lab partner: Abdulrahman Khardali)

## Report

- `report/experiment_2_submission.pdf` (also `.docx`)

## Supplementary figures

`supplementary_figures/` contains Figures S1–S4 (additional analysis of our own data, not part of the report).

## Data

- `data/raw/reference/`: course-provided dataset (Prof. Samah Gadhoum), used in the Results.
- `data/raw/experimental/`: our own spectrophotometer readings (7 and 11 September 2026), used in the Discussion. Photographs of the printouts are in `report/raw_data_printouts/`.

## Analysis

The R scripts in `R/` produce every number, table and figure in the report. To rerun everything:

```bash
Rscript R/run_all.R
```

Requires R 4.3 or later with `tidyverse`, `broom`, `patchwork`, `scales` and `here`. Rebuilding the Word/PDF report also needs Node.js (`npm install` in `report/`) and LibreOffice.
