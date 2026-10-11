# data/raw: data dictionary

The only manually entered inputs of the project. All results are produced from these files by `Rscript R/run_all.R`. Original readings are never altered by the scripts: missing values stay `NA`, anomalous values stay as read, and every analytical decision (window choice, exclusion from a fit) is recorded in the processed tables rather than applied to the raw files.

## Two datasets, two roles

| Term used throughout the project | Origin | Role |
|---|---|---|
| **Reference dataset** | Measurements provided by the course (Prof. Samah Gadhoum; Parts I/II on 10 September 2026, Part III on 13 September 2026) for use in the Results section: Part I (ONP spectrum, ONP standard curve), Part II (enzyme dilution) and Part III (ONPG series without and with IPTG) | Results section of the report |
| **Experimental dataset** | Our laboratory group's own GENESYS 10S printouts (Almokhtar Aljarodi and Abdulrahman Khardali; 7 and 11 September 2026) | Discussion section and raw-data appendix |

The terms describe origin and analytical role only. The reference dataset is a course teaching dataset: it is not validated or published data, and nothing in the project implies otherwise. Each condition was measured once in both datasets (no replicates).

### Crosswalk to the labels on the source material (`R/00_setup.R`, `DATASET_CROSSWALK`)

| Project label | Label on the source | Source |
|---|---|---|
| Reference Part I | "Part I" (ONP spectrum; standard curve tubes 1–7) | course .docx `Day1_PartI_ONP_and_enzyme_dilution.docx` |
| Reference Part II | "Part I" table 3 / enzyme dilution tubes A–E | same .docx (table absent from the course CSV) |
| Reference Part III (−IPTG) | "Day 2, no IPTG", tubes A–F | course .pptx / CSV `Day2_primary_results_noIPTG_and_IPTG.pptx` |
| Reference Part III (+IPTG) | "Day 2, IPTG", tubes A–F | same |
| Experimental Part II | printouts labelled "Day 1", tubes A–E | our printouts, 7 Sep 2026 |
| Experimental Part III (−IPTG) | printouts labelled "Day 2 Blue", tubes A–E | our printouts, 11 Sep 2026 |
| Experimental Part III (+IPTG) | printouts labelled "Day 2 Black", tubes A–E (E discarded before measurement) | our printouts, 11 Sep 2026 |


## reference/ (Reference dataset)

| File | Columns | Notes |
|---|---|---|
| `part1_onp_spectrum.csv` | `wavelength_nm`, `absorbance` | 385–465 nm in 5 nm steps; manual tube 4 (0.333 mM ONP in Z buffer/1 M Na₂CO₃ 2:1) read against the Z buffer/Na₂CO₃ blank |
| `part1_onp_standard_curve.csv` | `reported_tube`, `abs_415nm`, `manual_tube`, `onp_ml`, `z_buffer_ml`, `na2co3_ml`, `mapping_basis` | Seven readings were reported for eight preparations in the manual. `reported_tube` is the number in the course table; `manual_tube` is the preparation it was assigned to (Blank = 2.0 mL Z buffer + 1.0 mL Na₂CO₃; standards 1–6 = 0.25, 0.5, 0.75, 1.0, 1.3, 1.6 mL of 1 mM ONP). The first reported reading (0) is the zero-concentration point, as the instructor clarified. Manual standard 7 (2.0 mL, 0.667 mM) has no reported reading: the row is kept with `abs_415nm = NA` and `mapping_basis` records that it is unknown whether it was not prepared or not reported. No value was assumed. |
| `part2_enzyme_dilution.csv` | `tube`, `relative_enzyme`, `time_min`, `absorbance_415nm` | Tubes A–E (0.2, 0.15, 0.1, 0.05, 0.03 mL enzyme; 2.20 mM ONPG), stopped samples at 2, 4, 6, 8, 10 min |
| `part3_substrate_series.csv` | `condition` (No IPTG / + IPTG), `tube`, `time_min`, `absorbance_415nm` | Tubes A–F (8.0 to 0.25 mL of 3.3 mM ONPG in 12.0 mL) without and with 1.0 mL of 5.5 mM IPTG; stopped samples at 2, 4, 6, 8, 10 min |
| `source_files/` | (none) | The course's original .docx, .pptx and CSV files and the instructor's e-mail, kept locally for the cross-check in `01_import_clean.R` and for provenance. **Not redistributed**: the folder is excluded from version control (`.gitignore`) because permission to republish course material has not been obtained. The scripts run without it. |

## experimental/ (Experimental dataset)

| File | Columns | Notes |
|---|---|---|
| `absorbance_raw.csv` | `source_label`, `tube`, `time_min`, `absorbance_415nm`, `note` | Transcribed from 14 GENESYS 10S printouts (photographs in `report/raw_data_printouts/`) and verified value by value. `source_label` keeps the label written on the printout (Day 1, Day 2 Blue, Day 2 Black). Day 2 Black E is `NA` at every time (sample discarded before measurement). Day 2 Black B 10 min = 1.106 is retained as read. Tube F was not performed in our sessions. The photograph `Day1_B.jpeg` was taken upside down and is stored rotated by 180° for legibility; no other photograph was edited. |
| `printout_metadata.csv` | `source_label`, `tube`, `label_ink`, `instrument`, `firmware`, `serial`, `instrument_clock`, `wavelength_nm`, `samples_on_printout`, `photo_file`, `verification` | Header lines of each printout (instrument, firmware, serial, clock stamp), the ink colour that identifies the series, the photograph file and the outcome of the transcription check |

## tube_compositions.csv

Columns `part`, `condition`, `tube`, `z_buffer_ml`, `onpg_ml`, `iptg_ml`, `enzyme_ml`, `onp_ml`, `na2co3_ml`: volumes (mL) of every tube in Parts I–III from the Experiment 2 manual (Part II/III tubes total 12.0 mL). Concentrations in the reaction are computed from these volumes and the stock concentrations in `R/00_setup.R` (3.3 mM ONPG, 5.5 mM IPTG); no concentration was changed on the basis of the results.

## Instrument note

Thermo Scientific GENESYS 10S UV-Vis (our printouts); the course did not state the instrument used for the reference dataset. The manufacturer specifies a photometric range to 3.5 A; the scripts flag any absorbance above that limit and the 0.533 mM standard (A = 3.236, 0.06% transmittance) is discussed in the reports.
