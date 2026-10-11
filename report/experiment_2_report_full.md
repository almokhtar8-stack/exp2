# Experiment 2, β-galactosidase kinetics: supplementary information and technical record

This document accompanies `experiment_2_submission.md` (the graded course report) and the journal-style version. It records the data audit, every analysis decision, the sensitivity analyses, the secondary analysis of the experimental dataset, and how to regenerate everything. All numbers are inserted from the processed outputs by `R/08_assemble_reports.R`; nothing is typed in by hand. Compiled 11 October 2026.

## 1. Datasets, provenance and terminology

Two datasets were analysed. The **reference dataset** is the set of course-provided measurements supplied by the laboratory instructor (Professor Samah Gadhoum; e-mail of 13 September 2026: "These are some results you can use for your results section. Please discuss your own results in the discussion part") and was used for the primary kinetic analysis. The **experimental dataset** is the set of measurements collected by our laboratory group (14 GENESYS 10S printouts from 7 and 11 September 2026) and was analysed separately for technical interpretation and troubleshooting. The labels describe origin and analytical role; neither dataset is externally validated or published, and the experimental dataset is not a replicate of the reference dataset (different sessions, different operators). Original labels are retained in the raw files and in the crosswalk below.

| Role | Dataset label in this project | Label on the source | File |
|---|---|---|---|
| reference | Reference Part I | Day1_PartI_ONP_and_enzyme_dilution.docx (tables 1-2) | data/raw/reference/part1_onp_spectrum.csv; part1_onp_standard_curve.csv |
| reference | Reference Part II | Day1_PartI_ONP_and_enzyme_dilution.docx (table 3) | data/raw/reference/part2_enzyme_dilution.csv |
| reference | Reference Part III (-IPTG) | Day2 pptx / instructor_day2_primary_results.csv: 'No IPTG' | data/raw/reference/part3_substrate_series.csv |
| reference | Reference Part III (+IPTG) | Day2 pptx / instructor_day2_primary_results.csv: '+ IPTG' | data/raw/reference/part3_substrate_series.csv |
| experimental | Experimental Part II | printouts labelled 'Day 1' (red ink), 7 Sep 2026 | data/raw/experimental/absorbance_raw.csv |
| experimental | Experimental Part III (-IPTG) | printouts labelled 'Day 2 Blue', 11 Sep 2026 | data/raw/experimental/absorbance_raw.csv |
| experimental | Experimental Part III (+IPTG) | printouts labelled 'Day 2 Black', 11 Sep 2026 | data/raw/experimental/absorbance_raw.csv |

**Table A0.** Dataset crosswalk: labels used in this project, labels on the source files, and file locations.

## 2. Data audit

### 2.1 Reference files against the transcribed CSVs

All 17 spectrum values and all 7 standard-curve values in the supplied `instructor_part1_values.csv` match the course .docx; all 60 Part III values in `instructor_day2_primary_results.csv` match the .pptx. The supplied Part I CSV omits the enzyme-dilution table that the .docx contains (tubes A to E, relative enzyme 1.00 to 0.15, five time points); it was transcribed from the .docx into `part2_enzyme_dilution.csv`. The pipeline re-verifies every transcription against the source files when they are present (`data/processed/validation_report.csv`).

### 2.2 Standard-curve tube assignment

The manual describes eight preparations (a blank and standards 1 to 7 with 0.25, 0.50, 0.75, 1.0, 1.3, 1.6 and 2.0 mL of 1 mM ONP in 3.0 mL). The course table lists seven readings labelled tubes 1 to 7 (0, 0.428, 0.856, 1.240, 1.723, 2.256, 3.236). Classmates queried the discrepancy and the instructor clarified that the first reading is the zero-concentration point, listed against the first reported tube rather than as a separately numbered blank. Two facts fix the assignment of the remaining six readings: a 0.25 mL standard (0.083 mM) could not read 0, and the spectrum tube (manual standard 4, 1.0 mL) read 1.723 at 415 nm, identical to the fifth reported reading. Under the adopted mapping (reported tube k = manual standard k − 1) the absorbance-to-concentration ratios of the first five standards are 4.96 to 5.21 per mM, as Beer–Lambert behaviour requires; under the alternative (reported tubes 2 to 7 = manual standards 2 to 7) the ratios would fall from 2.57 to 4.85 per mM and the spectrum tube would not match. The manual's standard 7 (0.667 mM) is therefore the preparation with no reported reading; whether it was not prepared or not reported cannot be determined from the files, and no absorbance was assumed for it. The zero-concentration preparation is chemically the blank (2.0 mL Z buffer + 1.0 mL Na₂CO₃ read against itself), which is why it reads 0; it is shown on the standard curve but not used in the fit.

| Reported tube (course table) | Manual preparation | ONP 1 mM (mL) | Z buffer (mL) | Na2CO3 1 M (mL) | [ONP] in cuvette (mM) | A415 (reported) | Basis of the mapping |
|---|---|---|---|---|---|---|---|
| 1 | Blank (0 mL ONP) | 0 | 2 | 1 | 0 | 0.000 | Reported as tube 1 with OD 0; the instructor confirmed it is the zero-concentration point (blank-like preparation, read against itself) |
| 2 | Standard 1 | 0.25 | 1.75 | 1 | 0.0833 | 0.428 | Next reported reading; mapping consistent with Beer-Lambert ratio A/[ONP] = 5.1 per mM |
| 3 | Standard 2 | 0.5 | 1.5 | 1 | 0.1667 | 0.856 | A/[ONP] = 5.1 per mM |
| 4 | Standard 3 | 0.75 | 1.25 | 1 | 0.25 | 1.240 | A/[ONP] = 5.0 per mM |
| 5 | Standard 4 | 1 | 1 | 1 | 0.3333 | 1.723 | Identical to the spectrum reading of manual tube 4 at 415 nm (1.723), which anchors the mapping |
| 6 | Standard 5 | 1.3 | 0.7 | 1 | 0.4333 | 2.256 | A/[ONP] = 5.2 per mM |
| 7 | Standard 6 | 1.6 | 0.4 | 1 | 0.5333 | 3.236 | A/[ONP] = 6.1 per mM; highest reported reading |
| not reported | Standard 7 | 2 | 0 | 1 | 0.6667 | none | Not in the reported table (0.667 mM); unknown whether this standard was not prepared or not reported |

**Table A1.** Mapping of the reported standard-curve readings to the manual's preparations.

### 2.3 Features of the reference progress curves

Enzyme-dilution tube A has an 8-min reading (0.965) far below its 2 to 6 min trend, with the 10-min reading back on the line; tube C is similar. Uninhibited tubes B to F decelerate from the first interval onward: the second increment is 50 to 73% of the first and the fourth is 6 to 50% of the first. Inhibited tube A has an irregular 4-min reading (0.480); inhibited tubes B to F are close to linear with small increments (0.005 to 0.07 A per 2 min), where the 0.001 A read-out resolution matters.

| dataset | condition_label | tube | observed_time_points | n_missing | increments | inc2_over_inc1 | last_over_prior | source_check | observation |
|---|---|---|---|---|---|---|---|---|---|
| Reference Part II | Enzyme dilution (Part II) | A | 2, 4, 6, 8, 10 | 0 | 0.270 / 0.274 / 0.089 / 0.442 | 1.01 | 2.09 | Transcribed from the course .docx (table absent from the supplied CSV) | 8-min reading (0.965) far below the 2-6 min trend; 10-min reading returns to it |
| Reference Part II | Enzyme dilution (Part II) | B | 2, 4, 6, 8, 10 | 0 | 0.242 / 0.183 / 0.220 / 0.194 | 0.756 | 0.902 | Transcribed from the course .docx (table absent from the supplied CSV) | Approximately linear; small increments (read-out resolution 0.001 A matters) |
| Reference Part II | Enzyme dilution (Part II) | C | 2, 4, 6, 8, 10 | 0 | 0.150 / 0.178 / 0.093 / 0.144 | 1.19 | 1.03 | Transcribed from the course .docx (table absent from the supplied CSV) | 8-min reading below trend |
| Reference Part II | Enzyme dilution (Part II) | D | 2, 4, 6, 8, 10 | 0 | 0.040 / 0.057 / 0.062 / 0.033 | 1.43 | 0.623 | Transcribed from the course .docx (table absent from the supplied CSV) | Tubes D (0.25) and E (0.15 relative enzyme) gave nearly equal rates |
| Reference Part II | Enzyme dilution (Part II) | E | 2, 4, 6, 8, 10 | 0 | 0.047 / 0.048 / 0.040 / 0.050 | 1.02 | 1.11 | Transcribed from the course .docx (table absent from the supplied CSV) | Tubes D (0.25) and E (0.15 relative enzyme) gave nearly equal rates |
| Reference Part III (+IPTG) | ONPG series + IPTG | A | 2, 4, 6, 8, 10 | 0 | 0.282 / 0.106 / 0.198 / 0.182 | 0.376 | 0.932 | Supplied CSV matches the course .pptx (all 30 values per condition) | Irregular 4-min reading (0.480); later increments below the first |
| Reference Part III (+IPTG) | ONPG series + IPTG | B | 2, 4, 6, 8, 10 | 0 | 0.062 / 0.069 / 0.043 / 0.055 | 1.11 | 0.948 | Supplied CSV matches the course .pptx (all 30 values per condition) | Slows after 6 min |
| Reference Part III (+IPTG) | ONPG series + IPTG | C | 2, 4, 6, 8, 10 | 0 | 0.041 / 0.042 / 0.026 / 0.033 | 1.02 | 0.908 | Supplied CSV matches the course .pptx (all 30 values per condition) | Slows after 6 min |
| Reference Part III (+IPTG) | ONPG series + IPTG | D | 2, 4, 6, 8, 10 | 0 | 0.022 / 0.017 / 0.017 / 0.014 | 0.773 | 0.75 | Supplied CSV matches the course .pptx (all 30 values per condition) | Approximately linear; small increments (read-out resolution 0.001 A matters) |
| Reference Part III (+IPTG) | ONPG series + IPTG | E | 2, 4, 6, 8, 10 | 0 | 0.015 / 0.012 / 0.013 / 0.009 | 0.8 | 0.675 | Supplied CSV matches the course .pptx (all 30 values per condition) | Approximately linear; small increments (read-out resolution 0.001 A matters) |
| Reference Part III (+IPTG) | ONPG series + IPTG | F | 2, 4, 6, 8, 10 | 0 | 0.008 / 0.006 / 0.006 / 0.005 | 0.75 | 0.75 | Supplied CSV matches the course .pptx (all 30 values per condition) | Approximately linear; small increments (read-out resolution 0.001 A matters) |
| Reference Part III (-IPTG) | ONPG series, no inhibitor | A | 2, 4, 6, 8, 10 | 0 | 0.264 / 0.269 / 0.279 / 0.234 | 1.02 | 0.865 | Supplied CSV matches the course .pptx (all 30 values per condition) | Linear to 10 min |
| Reference Part III (-IPTG) | ONPG series, no inhibitor | B | 2, 4, 6, 8, 10 | 0 | 0.181 / 0.133 / 0.112 / 0.095 | 0.735 | 0.669 | Supplied CSV matches the course .pptx (all 30 values per condition) | Rate falls from the first interval onward (increments decline monotonically) |
| Reference Part III (-IPTG) | ONPG series, no inhibitor | C | 2, 4, 6, 8, 10 | 0 | 0.122 / 0.079 / 0.068 / 0.043 | 0.648 | 0.48 | Supplied CSV matches the course .pptx (all 30 values per condition) | Rate falls from the first interval onward (increments decline monotonically) |
| Reference Part III (-IPTG) | ONPG series, no inhibitor | D | 2, 4, 6, 8, 10 | 0 | 0.062 / 0.039 / 0.029 / 0.061 | 0.629 | 1.41 | Supplied CSV matches the course .pptx (all 30 values per condition) | Rate falls from the first interval onward (increments decline monotonically) |
| Reference Part III (-IPTG) | ONPG series, no inhibitor | E | 2, 4, 6, 8, 10 | 0 | 0.032 / 0.018 / 0.005 / 0.009 | 0.563 | 0.491 | Supplied CSV matches the course .pptx (all 30 values per condition) | Rate falls from the first interval onward (increments decline monotonically) |
| Reference Part III (-IPTG) | ONPG series, no inhibitor | F | 2, 4, 6, 8, 10 | 0 | 0.020 / 0.010 / 0.007 / 0.006 | 0.5 | 0.486 | Supplied CSV matches the course .pptx (all 30 values per condition) | Rate falls from the first interval onward (increments decline monotonically) |

**Table A2.** Audit of the reference progress curves.

### 2.4 Experimental printouts

All 14 photographs were compared with the transcription; every legible value matches (one last digit, Part III +IPTG tube A at 6 min, is under glare in the photograph and reads 0.47x; the value 0.476 was read from the original printout and sits on that tube's straight line). Part III +IPTG tube E has no data (sample discarded before measurement) and is `NA` throughout. Part III +IPTG tube B (nominally 1.10 mM ONPG) is anomalous as a whole curve: increments 0.237, 0.242, 0.247 over the first 8 min exceed those of tube A (0.157, 0.156, 0.152) at twice the substrate, and its 10-min increment (0.111) is 46% of the preceding mean. The mapping of the blue- and black-labelled printouts to the uninhibited and inhibited series was established from tube count, the manual's enzyme-standardisation specification and the rate structure (blue A reached 1.061 at 10 min and black A only 0.780; black rates fell 4.3-fold from A to D against 1.3-fold for blue); the reference dataset shows the same pattern (inhibited A 0.966, uninhibited A 1.328 at 10 min).

| dataset | source_label | condition_label | tube | observed_time_points | n_missing | increments | inc2_over_inc1 | last_over_prior | verification | instrument_clock | observation |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Experimental Part II | Day 1 | Enzyme dilution (Part II) | A | 2, 4, 6, 8, 10 | 0 | 0.268 / 0.273 / 0.320 / 0.191 | 1.02 | 0.666 | all five values match CSV | 9:45pm 7Sep26 | Linear to 8 or 10 min |
| Experimental Part II | Day 1 | Enzyme dilution (Part II) | B | 2, 4, 6, 8, 10 | 0 | 0.174 / 0.179 / 0.161 / 0.166 | 1.03 | 0.969 | all five values match CSV (photo was taken upside down; the file is stored rotated 180° for legibility) | 9:54pm 7Sep26 | Linear to 8 or 10 min |
| Experimental Part II | Day 1 | Enzyme dilution (Part II) | C | 2, 4, 6, 8, 10 | 0 | 0.122 / 0.120 / 0.124 / 0.084 | 0.984 | 0.689 | all five values match CSV | 9:58pm 7Sep26 | Linear to 8 or 10 min |
| Experimental Part II | Day 1 | Enzyme dilution (Part II) | D | 2, 4, 6, 8, 10 | 0 | 0.056 / 0.055 / 0.059 / 0.048 | 0.982 | 0.847 | all five values match CSV | 10:04pm 7Sep26 | Linear to 8 or 10 min |
| Experimental Part II | Day 1 | Enzyme dilution (Part II) | E | 2, 4, 6, 8, 10 | 0 | 0.043 / 0.037 / 0.042 / 0.036 | 0.86 | 0.885 | all five values match CSV | 10:07pm 7Sep26 | Linear to 8 or 10 min |
| Experimental Part III (+IPTG) | Day 2 Black | ONPG series + IPTG | A | 2, 4, 6, 8, 10 | 0 | 0.157 / 0.156 / 0.152 / 0.152 | 0.994 | 0.981 | all five values match CSV; ID 3 last digit under glare in the photograph (legible as 0.47x), read as 0.476 from the original printout | 4:29am 11Sep26 | Linear to 10 min; ID 3 last digit under photo glare, 0.476 read from the original printout |
| Experimental Part III (+IPTG) | Day 2 Black | ONPG series + IPTG | B | 2, 4, 6, 8, 10 | 0 | 0.237 / 0.242 / 0.247 / 0.111 | 1.02 | 0.459 | all five values match CSV | 4:25am 11Sep26 | Whole curve faster than tube A at half the nominal ONPG; 10-min value 1.106 retained (46% of predicted increment) |
| Experimental Part III (+IPTG) | Day 2 Black | ONPG series + IPTG | C | 2, 4, 6, 8, 10 | 0 | 0.078 / 0.086 / 0.060 / 0.058 | 1.1 | 0.777 | all five values match CSV | 4:33am 11Sep26 | Linear to 8 or 10 min |
| Experimental Part III (+IPTG) | Day 2 Black | ONPG series + IPTG | D | 2, 4, 6, 8, 10 | 0 | 0.041 / 0.034 / 0.035 / 0.037 | 0.829 | 1.01 | all five values match CSV | 4:20am 11Sep26 | Linear to 8 or 10 min |
| Experimental Part III (+IPTG) | Day 2 Black | ONPG series + IPTG | E | none | 5 | NA | NA | NA | no printout: sample discarded before measurement | NA | All five observations missing: sample discarded before measurement (kept NA) |
| Experimental Part III (-IPTG) | Day 2 Blue | ONPG series, no inhibitor | A | 2, 4, 6, 8, 10 | 0 | 0.221 / 0.216 / 0.242 / 0.123 | 0.977 | 0.543 | all five values match CSV | 3:32am 11Sep26 | Linear to 8 or 10 min |
| Experimental Part III (-IPTG) | Day 2 Blue | ONPG series, no inhibitor | B | 2, 4, 6, 8, 10 | 0 | 0.212 / 0.219 / 0.209 / 0.201 | 1.03 | 0.942 | all five values match CSV | 3:36am 11Sep26 | Linear to 8 or 10 min |
| Experimental Part III (-IPTG) | Day 2 Blue | ONPG series, no inhibitor | C | 2, 4, 6, 8, 10 | 0 | 0.188 / 0.161 / 0.193 / 0.138 | 0.856 | 0.764 | all five values match CSV | 3:39am 11Sep26 | Linear to 8 or 10 min |
| Experimental Part III (-IPTG) | Day 2 Blue | ONPG series, no inhibitor | D | 2, 4, 6, 8, 10 | 0 | 0.184 / 0.165 / 0.123 / 0.090 | 0.897 | 0.572 | all five values match CSV | 3:46am 11Sep26 | Decelerates after 6 min |
| Experimental Part III (-IPTG) | Day 2 Blue | ONPG series, no inhibitor | E | 2, 4, 6, 8, 10 | 0 | 0.090 / 0.048 / 0.052 / 0.045 | 0.533 | 0.711 | all five values match CSV | 3:51am 11Sep26 | Non-linear from the outset (2nd increment 53% of 1st) |

**Table A3.** Audit of the experimental progress curves.

## 3. Methods of analysis

### 3.1 Concentrations and volumes

[ONPG] = 3.3 mM × V_ONPG/12.0 mL (2.20, 1.10, 0.55, 0.275, 0.1375, 0.06875 mM for tubes A to F); [IPTG] = 5.5 mM × 1.0/12.0 = 0.4583 mM in every inhibited tube; ONP standards 1 mM × V/3.0 mL. Every reaction tube in the manual sums to 12.0 mL and every Part I preparation to 3.0 mL (checked programmatically; `validation_report.csv`).

| Part | Condition | Tube | Z buffer (mL) | ONPG 3.3 mM (mL) | IPTG 5.5 mM (mL) | Enzyme (mL) | [ONPG] in reaction (mM) | [IPTG] in reaction (mM) | Relative enzyme |
|---|---|---|---|---|---|---|---|---|---|
| Part II | Enzyme dilution (Part II) | A | 3.8 | 8 | 0 | 0.2 | 2.2 | 0 | 1 |
| Part II | Enzyme dilution (Part II) | B | 3.85 | 8 | 0 | 0.15 | 2.2 | 0 | 0.75 |
| Part II | Enzyme dilution (Part II) | C | 3.9 | 8 | 0 | 0.1 | 2.2 | 0 | 0.5 |
| Part II | Enzyme dilution (Part II) | D | 3.95 | 8 | 0 | 0.05 | 2.2 | 0 | 0.25 |
| Part II | Enzyme dilution (Part II) | E | 3.97 | 8 | 0 | 0.03 | 2.2 | 0 | 0.15 |
| Part III | ONPG series, no inhibitor | A | 3.8 | 8 | 0 | 0.2 | 2.2 | 0 | NA |
| Part III | ONPG series, no inhibitor | B | 7.8 | 4 | 0 | 0.2 | 1.1 | 0 | NA |
| Part III | ONPG series, no inhibitor | C | 9.8 | 2 | 0 | 0.2 | 0.55 | 0 | NA |
| Part III | ONPG series, no inhibitor | D | 10.8 | 1 | 0 | 0.2 | 0.275 | 0 | NA |
| Part III | ONPG series, no inhibitor | E | 11.3 | 0.5 | 0 | 0.2 | 0.1375 | 0 | NA |
| Part III | ONPG series, no inhibitor | F | 11.55 | 0.25 | 0 | 0.2 | 0.0687 | 0 | NA |
| Part III | ONPG series + IPTG | A | 2.8 | 8 | 1 | 0.2 | 2.2 | 0.4583 | NA |
| Part III | ONPG series + IPTG | B | 6.8 | 4 | 1 | 0.2 | 1.1 | 0.4583 | NA |
| Part III | ONPG series + IPTG | C | 8.8 | 2 | 1 | 0.2 | 0.55 | 0.4583 | NA |
| Part III | ONPG series + IPTG | D | 9.8 | 1 | 1 | 0.2 | 0.275 | 0.4583 | NA |
| Part III | ONPG series + IPTG | E | 10.3 | 0.5 | 1 | 0.2 | 0.1375 | 0.4583 | NA |
| Part III | ONPG series + IPTG | F | 10.55 | 0.25 | 1 | 0.2 | 0.0687 | 0.4583 | NA |

**Table A4.** Tube compositions from the manual with derived concentrations.

### 3.2 Rule for the initial velocity

The manual asks for V₀ from the initial linear portion of each progress curve, with the points used identified. The rule applies that instruction identically to every curve. Tier 1: fit A₄₁₅ = a + bt to the 2, 4 and 6 min points and extend one point at a time while the added increment lies within 20% (or 0.010 A, whichever larger; the absolute floor protects low-signal curves from read-out noise) of the increment predicted by the current line; V₀ = b. Tier 2: when the second and third increments both fall below the first by more than the tolerance, there is no initial linear portion within the sampled interval and a regression on 2 to 6 min would average over a falling rate; V₀ is then the average rate over the first interval, A₄₁₅(2 min)/2 min, which assumes A₄₁₅ = 0 at t = 0 because no reading exists there. This origin-assumed estimate is an average over 0 to 2 min, not a measured instantaneous initial velocity; it may lie below the true V₀ (if the rate was already falling within the interval) or above it (if the true t = 0 absorbance was positive), and it is flagged (†) wherever it is used. The inhibited reference tube A shows why no direction can be assumed: its 0 to 2 min estimate (0.099 ΔA₄₁₅ min⁻¹) is lower than the measured 2 to 4 min average rate (0.141), so the early rate did not fall monotonically there. Tier 2 applied to 6 of the 17 reference curves (uninhibited B to F and inhibited A) and to one experimental curve (uninhibited E). The rule depends only on the shape of each curve, not on the kinetic parameters that result from it.

**Baseline-offset scenario.** No reading exists at t = 0, so the Tier-2 estimate assumes zero absorbance there. For the 24 curves that were linear, the regression intercept estimates that curve's own t = 0 absorbance (reaction before the timer, the matrix difference between the stopped sample and the Z-buffer blank, read-out offset): median 0.013 A, range -0.020 to 0.059 A (reference curves alone: median 0.014 A, maximum 0.059 A). The scenario transfers the median intercept to the Tier-2 curves as an assumed t = 0 absorbance and recomputes their 0 to 2 min estimates as (A₄₁₅(2 min) − 0.013)/2 min, a shift of 0.006 ΔA₄₁₅ min⁻¹ (with the largest intercept instead, 0.030); estimator O below carries this scenario through every kinetic parameter. Intercepts measured on other reactions do not bound the unknown baseline of a Tier-2 curve, so the scenario shows the sensitivity of the parameters to the assumption; it is not a correction, an uncertainty interval or evidence that the primary estimates are biased in one direction.

| Dataset | Linear curves (n) | Median intercept (A415) | Min | Max | Scenario shift of a 0-2 min estimate, median intercept (dA415/min) | Scenario shift, largest intercept (dA415/min) |
|---|---|---|---|---|---|---|
| Experimental dataset (our laboratory group) | 13 | 0.011 | -0.0205 | 0.0307 | 0.0055 | 0.0153 |
| Reference dataset (course-provided) | 11 | 0.0142 | -0.0017 | 0.0593 | 0.0071 | 0.0297 |
| both datasets | 24 | 0.0126 | -0.0205 | 0.0593 | 0.0063 | 0.0297 |

**Table A5.** Intercepts of the linear curves and the shift that the baseline-offset scenario applies to a 0 to 2 min estimate.

| Dataset | Tube | Concentration variable | Increments (A415 per 2 min) | V0 estimator | Points used (min) | V0 (dA415/min) | Regression R2 | Intercept (A415) | Notes |
|---|---|---|---|---|---|---|---|---|---|
| Reference Part II | A | relative enzyme 1.00 | 0.270 / 0.274 / 0.089 / 0.442 | regression 2-6 min | 2, 4, 6 | 0.136 | 1 | 0.0593 | Point(s) at 8, 10 min departed from the initial trend and were excluded from the regression; raw values retained |
| Reference Part II | B | relative enzyme 0.75 | 0.242 / 0.183 / 0.220 / 0.194 | regression 2-10 min | 2, 4, 6, 8, 10 | 0.1041 | 0.9983 | 0.0509 | All five points within the initial linear window |
| Reference Part II | C | relative enzyme 0.50 | 0.150 / 0.178 / 0.093 / 0.144 | regression 2-6 min | 2, 4, 6 | 0.082 | 0.9976 | 0.0023 | Point(s) at 8, 10 min departed from the initial trend and were excluded from the regression; raw values retained |
| Reference Part II | D | relative enzyme 0.25 | 0.040 / 0.057 / 0.062 / 0.033 | regression 2-6 min | 2, 4, 6 | 0.0243 | 0.9899 | 0.0187 | Point(s) at 8, 10 min departed from the initial trend and were excluded from the regression; raw values retained |
| Reference Part II | E | relative enzyme 0.15 | 0.047 / 0.048 / 0.040 / 0.050 | regression 2-10 min | 2, 4, 6, 8, 10 | 0.0229 | 0.9991 | 0.018 | All five points within the initial linear window |
| Reference Part III (+IPTG) | A | [ONPG] 2.2000 mM + [IPTG] 0.458 mM | 0.282 / 0.106 / 0.198 / 0.182 | 0-2 min average rate, origin assumed (no initial linear portion) | 0 (origin), 2 | 0.099 | NA | NA | Second and third increments both below the first by more than the tolerance: no initial linear portion; V0 = A415(2 min)/2 min with A415(0) assumed 0 (origin-assumed average rate over the first interval, not a measured instantaneous rate) |
| Reference Part III (+IPTG) | B | [ONPG] 1.1000 mM + [IPTG] 0.458 mM | 0.062 / 0.069 / 0.043 / 0.055 | regression 2-6 min | 2, 4, 6 | 0.0328 | 0.999 | -0.0017 | Point(s) at 8, 10 min departed from the initial trend and were excluded from the regression; raw values retained |
| Reference Part III (+IPTG) | C | [ONPG] 0.5500 mM + [IPTG] 0.458 mM | 0.041 / 0.042 / 0.026 / 0.033 | regression 2-6 min | 2, 4, 6 | 0.0208 | 1 | 0.0033 | Point(s) at 8, 10 min departed from the initial trend and were excluded from the regression; raw values retained |
| Reference Part III (+IPTG) | D | [ONPG] 0.2750 mM + [IPTG] 0.458 mM | 0.022 / 0.017 / 0.017 / 0.014 | regression 2-10 min | 2, 4, 6, 8, 10 | 0.0087 | 0.9936 | 0.0142 | All five points within the initial linear window |
| Reference Part III (+IPTG) | E | [ONPG] 0.1375 mM + [IPTG] 0.458 mM | 0.015 / 0.012 / 0.013 / 0.009 | regression 2-10 min | 2, 4, 6, 8, 10 | 0.0062 | 0.9935 | 0.0093 | All five points within the initial linear window |
| Reference Part III (+IPTG) | F | [ONPG] 0.0687 mM + [IPTG] 0.458 mM | 0.008 / 0.006 / 0.006 / 0.005 | regression 2-10 min | 2, 4, 6, 8, 10 | 0.0031 | 0.9928 | 0.0058 | All five points within the initial linear window |
| Reference Part III (-IPTG) | A | [ONPG] 2.2000 mM | 0.264 / 0.269 / 0.279 / 0.234 | regression 2-10 min | 2, 4, 6, 8, 10 | 0.132 | 0.9993 | 0.021 | All five points within the initial linear window |
| Reference Part III (-IPTG) | B | [ONPG] 1.1000 mM | 0.181 / 0.133 / 0.112 / 0.095 | 0-2 min average rate, origin assumed (no initial linear portion) | 0 (origin), 2 | 0.101 | NA | NA | Second and third increments both below the first by more than the tolerance: no initial linear portion; V0 = A415(2 min)/2 min with A415(0) assumed 0 (origin-assumed average rate over the first interval, not a measured instantaneous rate) |
| Reference Part III (-IPTG) | C | [ONPG] 0.5500 mM | 0.122 / 0.079 / 0.068 / 0.043 | 0-2 min average rate, origin assumed (no initial linear portion) | 0 (origin), 2 | 0.078 | NA | NA | Second and third increments both below the first by more than the tolerance: no initial linear portion; V0 = A415(2 min)/2 min with A415(0) assumed 0 (origin-assumed average rate over the first interval, not a measured instantaneous rate) |
| Reference Part III (-IPTG) | D | [ONPG] 0.2750 mM | 0.062 / 0.039 / 0.029 / 0.061 | 0-2 min average rate, origin assumed (no initial linear portion) | 0 (origin), 2 | 0.055 | NA | NA | Second and third increments both below the first by more than the tolerance: no initial linear portion; V0 = A415(2 min)/2 min with A415(0) assumed 0 (origin-assumed average rate over the first interval, not a measured instantaneous rate) |
| Reference Part III (-IPTG) | E | [ONPG] 0.1375 mM | 0.032 / 0.018 / 0.005 / 0.009 | 0-2 min average rate, origin assumed (no initial linear portion) | 0 (origin), 2 | 0.058 | NA | NA | Second and third increments both below the first by more than the tolerance: no initial linear portion; V0 = A415(2 min)/2 min with A415(0) assumed 0 (origin-assumed average rate over the first interval, not a measured instantaneous rate) |
| Reference Part III (-IPTG) | F | [ONPG] 0.0687 mM | 0.020 / 0.010 / 0.007 / 0.006 | 0-2 min average rate, origin assumed (no initial linear portion) | 0 (origin), 2 | 0.0235 | NA | NA | Second and third increments both below the first by more than the tolerance: no initial linear portion; V0 = A415(2 min)/2 min with A415(0) assumed 0 (origin-assumed average rate over the first interval, not a measured instantaneous rate) |

**Table A6.** Initial velocities of the reference curves (primary data).

| Dataset | Tube | Concentration variable | Increments (A415 per 2 min) | V0 estimator | Points used (min) | V0 (dA415/min) | Regression R2 | Intercept (A415) | Notes |
|---|---|---|---|---|---|---|---|---|---|
| Experimental Part II | A | relative enzyme 1.00 | 0.268 / 0.273 / 0.320 / 0.191 | regression 2-8 min | 2, 4, 6, 8 | 0.1428 | 0.9981 | -0.0205 | Point(s) at 10 min departed from the initial trend and were excluded from the regression; raw values retained |
| Experimental Part II | B | relative enzyme 0.75 | 0.174 / 0.179 / 0.161 / 0.166 | regression 2-10 min | 2, 4, 6, 8, 10 | 0.085 | 0.9996 | 0.0142 | All five points within the initial linear window |
| Experimental Part II | C | relative enzyme 0.50 | 0.122 / 0.120 / 0.124 / 0.084 | regression 2-8 min | 2, 4, 6, 8 | 0.0609 | 1 | 0.011 | Point(s) at 10 min departed from the initial trend and were excluded from the regression; raw values retained |
| Experimental Part II | D | relative enzyme 0.25 | 0.056 / 0.055 / 0.059 / 0.048 | regression 2-10 min | 2, 4, 6, 8, 10 | 0.0275 | 0.9991 | 0.011 | All five points within the initial linear window |
| Experimental Part II | E | relative enzyme 0.15 | 0.043 / 0.037 / 0.042 / 0.036 | regression 2-10 min | 2, 4, 6, 8, 10 | 0.0197 | 0.9992 | 0.0091 | All five points within the initial linear window |
| Experimental Part III (+IPTG) | A | [ONPG] 2.2000 mM + [IPTG] 0.458 mM | 0.157 / 0.156 / 0.152 / 0.152 | regression 2-10 min | 2, 4, 6, 8, 10 | 0.0771 | 0.9999 | 0.0108 | All five points within the initial linear window |
| Experimental Part III (+IPTG) | B | [ONPG] 1.1000 mM + [IPTG] 0.458 mM | 0.237 / 0.242 / 0.247 / 0.111 | regression 2-8 min | 2, 4, 6, 8 | 0.121 | 0.9999 | 0.0245 | 10-min point excluded (46% of predicted increment); whole curve faster than tube A, see audit |
| Experimental Part III (+IPTG) | C | [ONPG] 0.5500 mM + [IPTG] 0.458 mM | 0.078 / 0.086 / 0.060 / 0.058 | regression 2-6 min | 2, 4, 6 | 0.041 | 0.9992 | -0.0033 | Point(s) at 8, 10 min departed from the initial trend and were excluded from the regression; raw values retained |
| Experimental Part III (+IPTG) | D | [ONPG] 0.2750 mM + [IPTG] 0.458 mM | 0.041 / 0.034 / 0.035 / 0.037 | regression 2-10 min | 2, 4, 6, 8, 10 | 0.0181 | 0.9991 | 0.0067 | All five points within the initial linear window |
| Experimental Part III (+IPTG) | E | [ONPG] 0.1375 mM + [IPTG] 0.458 mM | NA | none | none | NA | NA | NA | No V0: sample discarded before measurement (all observations NA) |
| Experimental Part III (-IPTG) | A | [ONPG] 2.2000 mM | 0.221 / 0.216 / 0.242 / 0.123 | regression 2-8 min | 2, 4, 6, 8 | 0.1126 | 0.9994 | 0.03 | Point(s) at 10 min departed from the initial trend and were excluded from the regression; raw values retained |
| Experimental Part III (-IPTG) | B | [ONPG] 1.1000 mM | 0.212 / 0.219 / 0.209 / 0.201 | regression 2-10 min | 2, 4, 6, 8, 10 | 0.1055 | 0.9998 | 0.0158 | All five points within the initial linear window |
| Experimental Part III (-IPTG) | C | [ONPG] 0.5500 mM | 0.188 / 0.161 / 0.193 / 0.138 | regression 2-8 min | 2, 4, 6, 8 | 0.0894 | 0.9989 | 0.023 | Point(s) at 10 min departed from the initial trend and were excluded from the regression; raw values retained |
| Experimental Part III (-IPTG) | D | [ONPG] 0.2750 mM | 0.184 / 0.165 / 0.123 / 0.090 | regression 2-6 min | 2, 4, 6 | 0.0872 | 0.999 | 0.0307 | Point(s) at 8, 10 min departed from the initial trend and were excluded from the regression; raw values retained |
| Experimental Part III (-IPTG) | E | [ONPG] 0.1375 mM | 0.090 / 0.048 / 0.052 / 0.045 | 0-2 min average rate, origin assumed (no initial linear portion) | 0 (origin), 2 | 0.0555 | NA | NA | Second and third increments both below the first by more than the tolerance: no initial linear portion; V0 = A415(2 min)/2 min with A415(0) assumed 0 (origin-assumed average rate over the first interval, not a measured instantaneous rate) |

**Table A6b.** Initial velocities of the experimental curves.

| Role | Dataset | Tube | Window | n | Slope (dA415/min) | Intercept | R2 | RMSE | Selected |
|---|---|---|---|---|---|---|---|---|---|
| Experimental dataset (our laboratory group) | Experimental Part II | A | 2-6 min | 3 | 0.1353 | 0.0047 | 1 | 0.002 |  |
| Experimental dataset (our laboratory group) | Experimental Part II | A | 2-8 min | 4 | 0.1428 | -0.0205 | 0.9981 | 0.0195 | yes |
| Experimental dataset (our laboratory group) | Experimental Part II | A | 2-10 min | 5 | 0.1348 | 0.0113 | 0.9955 | 0.0331 |  |
| Experimental dataset (our laboratory group) | Experimental Part II | B | 2-6 min | 3 | 0.0883 | 0.0027 | 0.9999 | 0.002 |  |
| Experimental dataset (our laboratory group) | Experimental Part II | B | 2-8 min | 4 | 0.086 | 0.01 | 0.9995 | 0.0059 |  |
| Experimental dataset (our laboratory group) | Experimental Part II | B | 2-10 min | 5 | 0.085 | 0.0142 | 0.9996 | 0.0061 | yes |
| Experimental dataset (our laboratory group) | Experimental Part II | C | 2-6 min | 3 | 0.0605 | 0.0123 | 1 | 0.0008 |  |
| Experimental dataset (our laboratory group) | Experimental Part II | C | 2-8 min | 4 | 0.0609 | 0.011 | 1 | 0.0012 | yes |
| Experimental dataset (our laboratory group) | Experimental Part II | C | 2-10 min | 5 | 0.0572 | 0.0258 | 0.9958 | 0.0135 |  |
| Experimental dataset (our laboratory group) | Experimental Part II | D | 2-6 min | 3 | 0.0277 | 0.0097 | 1 | 0.0004 |  |
| Experimental dataset (our laboratory group) | Experimental Part II | D | 2-8 min | 4 | 0.0282 | 0.008 | 0.9998 | 0.0013 |  |
| Experimental dataset (our laboratory group) | Experimental Part II | D | 2-10 min | 5 | 0.0275 | 0.011 | 0.9991 | 0.0029 | yes |
| Experimental dataset (our laboratory group) | Experimental Part II | E | 2-6 min | 3 | 0.02 | 0.008 | 0.9981 | 0.0024 |  |
| Experimental dataset (our laboratory group) | Experimental Part II | E | 2-8 min | 4 | 0.0202 | 0.0075 | 0.9992 | 0.0018 |  |
| Experimental dataset (our laboratory group) | Experimental Part II | E | 2-10 min | 5 | 0.0197 | 0.0091 | 0.9992 | 0.0021 | yes |
| Experimental dataset (our laboratory group) | Experimental Part III (+IPTG) | A | 2-6 min | 3 | 0.0782 | 0.0067 | 1 | 0.0004 |  |
| Experimental dataset (our laboratory group) | Experimental Part III (+IPTG) | A | 2-8 min | 4 | 0.0775 | 0.009 | 0.9999 | 0.0018 |  |
| Experimental dataset (our laboratory group) | Experimental Part III (+IPTG) | A | 2-10 min | 5 | 0.0771 | 0.0108 | 0.9999 | 0.0022 | yes |
| Experimental dataset (our laboratory group) | Experimental Part III (+IPTG) | B | 2-6 min | 3 | 0.1198 | 0.0287 | 1 | 0.002 |  |
| Experimental dataset (our laboratory group) | Experimental Part III (+IPTG) | B | 2-8 min | 4 | 0.121 | 0.0245 | 0.9999 | 0.0035 | yes |
| Experimental dataset (our laboratory group) | Experimental Part III (+IPTG) | B | 2-10 min | 5 | 0.1082 | 0.0759 | 0.986 | 0.047 |  |
| Experimental dataset (our laboratory group) | Experimental Part III (+IPTG) | C | 2-6 min | 3 | 0.041 | -0.0033 | 0.9992 | 0.0033 | yes |
| Experimental dataset (our laboratory group) | Experimental Part III (+IPTG) | C | 2-8 min | 4 | 0.0379 | 0.007 | 0.9952 | 0.0083 |  |
| Experimental dataset (our laboratory group) | Experimental Part III (+IPTG) | C | 2-10 min | 5 | 0.0355 | 0.0166 | 0.9927 | 0.0111 |  |
| Experimental dataset (our laboratory group) | Experimental Part III (+IPTG) | D | 2-6 min | 3 | 0.0187 | 0.0047 | 0.9971 | 0.0029 |  |
| Experimental dataset (our laboratory group) | Experimental Part III (+IPTG) | D | 2-8 min | 4 | 0.0182 | 0.0065 | 0.9982 | 0.0025 |  |
| Experimental dataset (our laboratory group) | Experimental Part III (+IPTG) | D | 2-10 min | 5 | 0.0181 | 0.0067 | 0.9991 | 0.002 | yes |
| Experimental dataset (our laboratory group) | Experimental Part III (-IPTG) | A | 2-6 min | 3 | 0.1092 | 0.0413 | 1 | 0.002 |  |
| Experimental dataset (our laboratory group) | Experimental Part III (-IPTG) | A | 2-8 min | 4 | 0.1126 | 0.03 | 0.9994 | 0.0089 | yes |
| Experimental dataset (our laboratory group) | Experimental Part III (-IPTG) | A | 2-10 min | 5 | 0.1031 | 0.0682 | 0.9911 | 0.0356 |  |
| Experimental dataset (our laboratory group) | Experimental Part III (-IPTG) | B | 2-6 min | 3 | 0.1077 | 0.0073 | 0.9999 | 0.0029 |  |
| Experimental dataset (our laboratory group) | Experimental Part III (-IPTG) | B | 2-8 min | 4 | 0.1069 | 0.01 | 0.9999 | 0.0029 |  |
| Experimental dataset (our laboratory group) | Experimental Part III (-IPTG) | B | 2-10 min | 5 | 0.1055 | 0.0158 | 0.9998 | 0.0058 | yes |
| Experimental dataset (our laboratory group) | Experimental Part III (-IPTG) | C | 2-6 min | 3 | 0.0873 | 0.03 | 0.998 | 0.011 |  |
| Experimental dataset (our laboratory group) | Experimental Part III (-IPTG) | C | 2-8 min | 4 | 0.0894 | 0.023 | 0.9989 | 0.0095 | yes |
| Experimental dataset (our laboratory group) | Experimental Part III (-IPTG) | C | 2-10 min | 5 | 0.0857 | 0.0376 | 0.9976 | 0.0154 |  |
| Experimental dataset (our laboratory group) | Experimental Part III (-IPTG) | D | 2-6 min | 3 | 0.0872 | 0.0307 | 0.999 | 0.0078 | yes |
| Experimental dataset (our laboratory group) | Experimental Part III (-IPTG) | D | 2-8 min | 4 | 0.0791 | 0.058 | 0.9924 | 0.0219 |  |
| Experimental dataset (our laboratory group) | Experimental Part III (-IPTG) | D | 2-10 min | 5 | 0.0706 | 0.0918 | 0.9812 | 0.0357 |  |
| Experimental dataset (our laboratory group) | Experimental Part III (-IPTG) | E | 2-6 min | 3 | 0.0345 | 0.049 | 0.97 | 0.0171 | origin-assumed 0-2 min estimate used instead |
| Experimental dataset (our laboratory group) | Experimental Part III (-IPTG) | E | 2-8 min | 4 | 0.0309 | 0.061 | 0.9761 | 0.0153 | origin-assumed 0-2 min estimate used instead |
| Experimental dataset (our laboratory group) | Experimental Part III (-IPTG) | E | 2-10 min | 5 | 0.0285 | 0.0706 | 0.979 | 0.0152 | origin-assumed 0-2 min estimate used instead |
| Reference dataset (course-provided) | Reference Part II | A | 2-6 min | 3 | 0.136 | 0.0593 | 1 | 0.0016 | yes |
| Reference dataset (course-provided) | Reference Part II | A | 2-8 min | 4 | 0.1086 | 0.1505 | 0.9595 | 0.0706 |  |
| Reference dataset (course-provided) | Reference Part II | A | 2-10 min | 5 | 0.1256 | 0.0825 | 0.967 | 0.0847 |  |
| Reference dataset (course-provided) | Reference Part II | B | 2-6 min | 3 | 0.1063 | 0.0423 | 0.9936 | 0.0241 |  |
| Reference dataset (course-provided) | Reference Part II | B | 2-8 min | 4 | 0.1059 | 0.0435 | 0.9974 | 0.0171 |  |
| Reference dataset (course-provided) | Reference Part II | B | 2-10 min | 5 | 0.1041 | 0.0509 | 0.9983 | 0.0155 | yes |
| Reference dataset (course-provided) | Reference Part II | C | 2-6 min | 3 | 0.082 | 0.0023 | 0.9976 | 0.0114 | yes |
| Reference dataset (course-provided) | Reference Part II | C | 2-8 min | 4 | 0.072 | 0.0355 | 0.9862 | 0.0269 |  |
| Reference dataset (course-provided) | Reference Part II | C | 2-10 min | 5 | 0.07 | 0.0435 | 0.9919 | 0.0232 |  |
| Reference dataset (course-provided) | Reference Part II | D | 2-6 min | 3 | 0.0243 | 0.0187 | 0.9899 | 0.0069 | yes |
| Reference dataset (course-provided) | Reference Part II | D | 2-8 min | 4 | 0.0267 | 0.0105 | 0.9911 | 0.008 |  |
| Reference dataset (course-provided) | Reference Part II | D | 2-10 min | 5 | 0.0252 | 0.0167 | 0.9912 | 0.0086 |  |
| Reference dataset (course-provided) | Reference Part II | E | 2-6 min | 3 | 0.0238 | 0.0153 | 1 | 0.0004 |  |
| Reference dataset (course-provided) | Reference Part II | E | 2-8 min | 4 | 0.0226 | 0.019 | 0.9984 | 0.0029 |  |
| Reference dataset (course-provided) | Reference Part II | E | 2-10 min | 5 | 0.0229 | 0.018 | 0.9991 | 0.0025 | yes |
| Reference dataset (course-provided) | Reference Part III (+IPTG) | A | 2-6 min | 3 | 0.097 | 0.0333 | 0.9358 | 0.0719 | origin-assumed 0-2 min estimate used instead |
| Reference dataset (course-provided) | Reference Part III (+IPTG) | A | 2-8 min | 4 | 0.0932 | 0.046 | 0.9701 | 0.0517 | origin-assumed 0-2 min estimate used instead |
| Reference dataset (course-provided) | Reference Part III (+IPTG) | A | 2-10 min | 5 | 0.092 | 0.0508 | 0.9843 | 0.0425 | origin-assumed 0-2 min estimate used instead |
| Reference dataset (course-provided) | Reference Part III (+IPTG) | B | 2-6 min | 3 | 0.0328 | -0.0017 | 0.999 | 0.0029 | yes |
| Reference dataset (course-provided) | Reference Part III (+IPTG) | B | 2-8 min | 4 | 0.0295 | 0.009 | 0.9918 | 0.0085 |  |
| Reference dataset (course-provided) | Reference Part III (+IPTG) | B | 2-10 min | 5 | 0.0285 | 0.0132 | 0.9942 | 0.0079 |  |
| Reference dataset (course-provided) | Reference Part III (+IPTG) | C | 2-6 min | 3 | 0.0208 | 0.0033 | 1 | 0.0004 | yes |
| Reference dataset (course-provided) | Reference Part III (+IPTG) | C | 2-8 min | 4 | 0.0185 | 0.011 | 0.9897 | 0.0059 |  |
| Reference dataset (course-provided) | Reference Part III (+IPTG) | C | 2-10 min | 5 | 0.0176 | 0.0144 | 0.992 | 0.0058 |  |
| Reference dataset (course-provided) | Reference Part III (+IPTG) | D | 2-6 min | 3 | 0.0097 | 0.0103 | 0.9946 | 0.002 |  |
| Reference dataset (course-provided) | Reference Part III (+IPTG) | D | 2-8 min | 4 | 0.0092 | 0.012 | 0.9956 | 0.0019 |  |
| Reference dataset (course-provided) | Reference Part III (+IPTG) | D | 2-10 min | 5 | 0.0087 | 0.0142 | 0.9936 | 0.0026 | yes |
| Reference dataset (course-provided) | Reference Part III (+IPTG) | E | 2-6 min | 3 | 0.0068 | 0.007 | 0.9959 | 0.0012 |  |
| Reference dataset (course-provided) | Reference Part III (+IPTG) | E | 2-8 min | 4 | 0.0066 | 0.0075 | 0.9979 | 0.0009 |  |
| Reference dataset (course-provided) | Reference Part III (+IPTG) | E | 2-10 min | 5 | 0.0062 | 0.0093 | 0.9935 | 0.0018 | yes |
| Reference dataset (course-provided) | Reference Part III (+IPTG) | F | 2-6 min | 3 | 0.0035 | 0.0043 | 0.9932 | 0.0008 |  |
| Reference dataset (course-provided) | Reference Part III (+IPTG) | F | 2-8 min | 4 | 0.0033 | 0.005 | 0.9945 | 0.0008 |  |
| Reference dataset (course-provided) | Reference Part III (+IPTG) | F | 2-10 min | 5 | 0.0031 | 0.0058 | 0.9928 | 0.001 | yes |
| Reference dataset (course-provided) | Reference Part III (-IPTG) | A | 2-6 min | 3 | 0.1332 | 0.0147 | 1 | 0.002 |  |
| Reference dataset (course-provided) | Reference Part III (-IPTG) | A | 2-8 min | 4 | 0.1352 | 0.008 | 0.9998 | 0.0054 |  |
| Reference dataset (course-provided) | Reference Part III (-IPTG) | A | 2-10 min | 5 | 0.132 | 0.021 | 0.9993 | 0.0126 | yes |
| Reference dataset (course-provided) | Reference Part III (-IPTG) | B | 2-6 min | 3 | 0.0785 | 0.053 | 0.9923 | 0.0196 | origin-assumed 0-2 min estimate used instead |
| Reference dataset (course-provided) | Reference Part III (-IPTG) | B | 2-8 min | 4 | 0.0706 | 0.0795 | 0.9878 | 0.0248 | origin-assumed 0-2 min estimate used instead |
| Reference dataset (course-provided) | Reference Part III (-IPTG) | B | 2-10 min | 5 | 0.0643 | 0.1043 | 0.9836 | 0.0304 | origin-assumed 0-2 min estimate used instead |
| Reference dataset (course-provided) | Reference Part III (-IPTG) | C | 2-6 min | 3 | 0.0502 | 0.0627 | 0.985 | 0.0176 | origin-assumed 0-2 min estimate used instead |
| Reference dataset (course-provided) | Reference Part III (-IPTG) | C | 2-8 min | 4 | 0.0443 | 0.0825 | 0.9805 | 0.0198 | origin-assumed 0-2 min estimate used instead |
| Reference dataset (course-provided) | Reference Part III (-IPTG) | C | 2-10 min | 5 | 0.0386 | 0.1055 | 0.9658 | 0.0265 | origin-assumed 0-2 min estimate used instead |
| Reference dataset (course-provided) | Reference Part III (-IPTG) | D | 2-6 min | 3 | 0.0253 | 0.0633 | 0.983 | 0.0094 | origin-assumed 0-2 min estimate used instead |
| Reference dataset (course-provided) | Reference Part III (-IPTG) | D | 2-8 min | 4 | 0.0214 | 0.076 | 0.9704 | 0.0118 | origin-assumed 0-2 min estimate used instead |
| Reference dataset (course-provided) | Reference Part III (-IPTG) | D | 2-10 min | 5 | 0.0225 | 0.0718 | 0.9842 | 0.0104 | origin-assumed 0-2 min estimate used instead |
| Reference dataset (course-provided) | Reference Part III (-IPTG) | E | 2-6 min | 3 | 0.0125 | 0.0933 | 0.9745 | 0.0057 | origin-assumed 0-2 min estimate used instead |
| Reference dataset (course-provided) | Reference Part III (-IPTG) | E | 2-8 min | 4 | 0.0092 | 0.1045 | 0.9018 | 0.0095 | origin-assumed 0-2 min estimate used instead |
| Reference dataset (course-provided) | Reference Part III (-IPTG) | E | 2-10 min | 5 | 0.0076 | 0.1109 | 0.889 | 0.0097 | origin-assumed 0-2 min estimate used instead |
| Reference dataset (course-provided) | Reference Part III (-IPTG) | F | 2-6 min | 3 | 0.0075 | 0.0337 | 0.9643 | 0.0041 | origin-assumed 0-2 min estimate used instead |
| Reference dataset (course-provided) | Reference Part III (-IPTG) | F | 2-8 min | 4 | 0.006 | 0.0385 | 0.9425 | 0.0047 | origin-assumed 0-2 min estimate used instead |
| Reference dataset (course-provided) | Reference Part III (-IPTG) | F | 2-10 min | 5 | 0.0051 | 0.0421 | 0.9322 | 0.0051 | origin-assumed 0-2 min estimate used instead |

**Table A7.** Regression over every candidate initial window (2 to 6, 2 to 8, 2 to 10 min) for every curve; "Selected" marks the window used, or notes that the origin-assumed 0 to 2 min estimate replaced it.

| Role | Dataset | Tube | increments | secant 0-2 (origin) | secant 2-4 | secant 2-6 | regression 2-6 | regression initial window | initial window | regression all 5 points | rule (V0 used) | rule estimator | 0-2 min estimate, offset scenario |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| experimental | Experimental Part II | A | 0.268 / 0.273 / 0.320 / 0.191 | 0.138 | 0.134 | 0.1352 | 0.1353 | 0.1428 | 2-8 min | 0.1348 | 0.1428 | regression 2-8 min | 0.1317 |
| experimental | Experimental Part II | B | 0.174 / 0.179 / 0.161 / 0.166 | 0.09 | 0.087 | 0.0883 | 0.0883 | 0.085 | 2-10 min | 0.085 | 0.085 | regression 2-10 min | 0.0837 |
| experimental | Experimental Part II | C | 0.122 / 0.120 / 0.124 / 0.084 | 0.0665 | 0.061 | 0.0605 | 0.0605 | 0.0609 | 2-8 min | 0.0572 | 0.0609 | regression 2-8 min | 0.0602 |
| experimental | Experimental Part II | D | 0.056 / 0.055 / 0.059 / 0.048 | 0.0325 | 0.028 | 0.0277 | 0.0277 | 0.0275 | 2-10 min | 0.0275 | 0.0275 | regression 2-10 min | 0.0262 |
| experimental | Experimental Part II | E | 0.043 / 0.037 / 0.042 / 0.036 | 0.0235 | 0.0215 | 0.02 | 0.02 | 0.0197 | 2-10 min | 0.0197 | 0.0197 | regression 2-10 min | 0.0172 |
| experimental | Experimental Part III (+IPTG) | A | 0.157 / 0.156 / 0.152 / 0.152 | 0.0815 | 0.0785 | 0.0782 | 0.0782 | 0.0771 | 2-10 min | 0.0771 | 0.0771 | regression 2-10 min | 0.0752 |
| experimental | Experimental Part III (+IPTG) | B | 0.237 / 0.242 / 0.247 / 0.111 | 0.1345 | 0.1185 | 0.1197 | 0.1198 | 0.121 | 2-8 min | 0.1082 | 0.121 | regression 2-8 min | 0.1282 |
| experimental | Experimental Part III (+IPTG) | C | 0.078 / 0.086 / 0.060 / 0.058 | 0.04 | 0.039 | 0.041 | 0.041 | 0.041 | 2-6 min | 0.0355 | 0.041 | regression 2-6 min | 0.0337 |
| experimental | Experimental Part III (+IPTG) | D | 0.041 / 0.034 / 0.035 / 0.037 | 0.0205 | 0.0205 | 0.0188 | 0.0187 | 0.0181 | 2-10 min | 0.0181 | 0.0181 | regression 2-10 min | 0.0142 |
| experimental | Experimental Part III (-IPTG) | A | 0.221 / 0.216 / 0.242 / 0.123 | 0.1295 | 0.1105 | 0.1092 | 0.1092 | 0.1126 | 2-8 min | 0.1031 | 0.1126 | regression 2-8 min | 0.1232 |
| experimental | Experimental Part III (-IPTG) | B | 0.212 / 0.219 / 0.209 / 0.201 | 0.112 | 0.106 | 0.1078 | 0.1077 | 0.1055 | 2-10 min | 0.1055 | 0.1055 | regression 2-10 min | 0.1057 |
| experimental | Experimental Part III (-IPTG) | C | 0.188 / 0.161 / 0.193 / 0.138 | 0.1 | 0.094 | 0.0873 | 0.0873 | 0.0894 | 2-8 min | 0.0857 | 0.0894 | regression 2-8 min | 0.0937 |
| experimental | Experimental Part III (-IPTG) | D | 0.184 / 0.165 / 0.123 / 0.090 | 0.101 | 0.092 | 0.0873 | 0.0872 | 0.0872 | 2-6 min | 0.0706 | 0.0872 | regression 2-6 min | 0.0947 |
| experimental | Experimental Part III (-IPTG) | E | 0.090 / 0.048 / 0.052 / 0.045 | 0.0555 | 0.045 | 0.0345 | 0.0345 | 0.0345 | 2-6 min | 0.0285 | 0.0555 | 0-2 min average rate, origin assumed (no initial linear portion) | 0.0492 |
| reference | Reference Part II | A | 0.270 / 0.274 / 0.089 / 0.442 | 0.166 | 0.135 | 0.136 | 0.136 | 0.136 | 2-6 min | 0.1256 | 0.136 | regression 2-6 min | 0.1597 |
| reference | Reference Part II | B | 0.242 / 0.183 / 0.220 / 0.194 | 0.1225 | 0.121 | 0.1063 | 0.1063 | 0.1041 | 2-10 min | 0.1041 | 0.1041 | regression 2-10 min | 0.1162 |
| reference | Reference Part II | C | 0.150 / 0.178 / 0.093 / 0.144 | 0.0855 | 0.075 | 0.082 | 0.082 | 0.082 | 2-6 min | 0.07 | 0.082 | regression 2-6 min | 0.0792 |
| reference | Reference Part II | D | 0.040 / 0.057 / 0.062 / 0.033 | 0.035 | 0.02 | 0.0243 | 0.0243 | 0.0243 | 2-6 min | 0.0252 | 0.0243 | regression 2-6 min | 0.0287 |
| reference | Reference Part II | E | 0.047 / 0.048 / 0.040 / 0.050 | 0.0315 | 0.0235 | 0.0238 | 0.0238 | 0.0229 | 2-10 min | 0.0229 | 0.0229 | regression 2-10 min | 0.0252 |
| reference | Reference Part III (+IPTG) | A | 0.282 / 0.106 / 0.198 / 0.182 | 0.099 | 0.141 | 0.097 | 0.097 | 0.092 | 2-10 min | 0.092 | 0.099 | 0-2 min average rate, origin assumed (no initial linear portion) | 0.0927 |
| reference | Reference Part III (+IPTG) | B | 0.062 / 0.069 / 0.043 / 0.055 | 0.0325 | 0.031 | 0.0328 | 0.0328 | 0.0328 | 2-6 min | 0.0285 | 0.0328 | regression 2-6 min | 0.0262 |
| reference | Reference Part III (+IPTG) | C | 0.041 / 0.042 / 0.026 / 0.033 | 0.0225 | 0.0205 | 0.0208 | 0.0208 | 0.0208 | 2-6 min | 0.0176 | 0.0208 | regression 2-6 min | 0.0162 |
| reference | Reference Part III (+IPTG) | D | 0.022 / 0.017 / 0.017 / 0.014 | 0.0145 | 0.011 | 0.0098 | 0.0097 | 0.0087 | 2-10 min | 0.0087 | 0.0087 | regression 2-10 min | 0.0082 |
| reference | Reference Part III (+IPTG) | E | 0.015 / 0.012 / 0.013 / 0.009 | 0.01 | 0.0075 | 0.0068 | 0.0068 | 0.0062 | 2-10 min | 0.0062 | 0.0062 | regression 2-10 min | 0.0037 |
| reference | Reference Part III (+IPTG) | F | 0.008 / 0.006 / 0.006 / 0.005 | 0.0055 | 0.004 | 0.0035 | 0.0035 | 0.0031 | 2-10 min | 0.0031 | 0.0031 | regression 2-10 min | -0.0008 |
| reference | Reference Part III (-IPTG) | A | 0.264 / 0.269 / 0.279 / 0.234 | 0.141 | 0.132 | 0.1332 | 0.1332 | 0.132 | 2-10 min | 0.132 | 0.132 | regression 2-10 min | 0.1347 |
| reference | Reference Part III (-IPTG) | B | 0.181 / 0.133 / 0.112 / 0.095 | 0.101 | 0.0905 | 0.0785 | 0.0785 | 0.0785 | 2-6 min | 0.0643 | 0.101 | 0-2 min average rate, origin assumed (no initial linear portion) | 0.0947 |
| reference | Reference Part III (-IPTG) | C | 0.122 / 0.079 / 0.068 / 0.043 | 0.078 | 0.061 | 0.0502 | 0.0502 | 0.0502 | 2-6 min | 0.0386 | 0.078 | 0-2 min average rate, origin assumed (no initial linear portion) | 0.0717 |
| reference | Reference Part III (-IPTG) | D | 0.062 / 0.039 / 0.029 / 0.061 | 0.055 | 0.031 | 0.0252 | 0.0253 | 0.0253 | 2-6 min | 0.0225 | 0.055 | 0-2 min average rate, origin assumed (no initial linear portion) | 0.0487 |
| reference | Reference Part III (-IPTG) | E | 0.032 / 0.018 / 0.005 / 0.009 | 0.058 | 0.016 | 0.0125 | 0.0125 | 0.0125 | 2-6 min | 0.0076 | 0.058 | 0-2 min average rate, origin assumed (no initial linear portion) | 0.0517 |
| reference | Reference Part III (-IPTG) | F | 0.020 / 0.010 / 0.007 / 0.006 | 0.0235 | 0.01 | 0.0075 | 0.0075 | 0.0051 | 2-10 min | 0.0051 | 0.0235 | 0-2 min average rate, origin assumed (no initial linear portion) | 0.0172 |

**Table A7b.** Two-point secants, window regressions and the rule's V₀ for every curve (ΔA₄₁₅ min⁻¹). For linear curves the 2 to 6 min secant and the 2 to 6 min regression agree within rounding, as they must for three equally spaced points; the 0 to 2 min secant through the origin exceeds them wherever the intercept is positive.

### 3.3 Units

V₀ (mM min⁻¹ in the cuvette) = slope/ε. The stopped sample is 2 mL reaction + 1 mL Na₂CO₃, so the reaction-mixture rate is 1.5 × the cuvette rate; multiplying by 12.0 mL gives µmol ONP min⁻¹ per assay. With ε = 5.22 A mM⁻¹ cm⁻¹, 1 ΔA₄₁₅ min⁻¹ = 3.447 µmol min⁻¹ per assay (1/5.2224 × 1.5 × 12.0 = 3.4467; dimensionally A min⁻¹ ÷ (A mM⁻¹) × mL = µmol min⁻¹). The manual's abbreviated instruction, "divide the slope by ε", yields the cuvette rate in mM min⁻¹; the two volume factors are needed to express an amount per minute. K_m and K_i do not depend on the factor (it cancels in slope/intercept ratios); V_max scales with it, and per mL of enzyme the per-assay value is multiplied by 5 (0.2 mL enzyme per assay).

### 3.4 Calibration

ε is the slope of the least-squares line through the five standards from 0.083 to 0.433 mM (free intercept -0.0224 A, p = 0.50, so not distinguishable from zero). Alternatives are tabulated below. The 0.533 mM standard read 3.236 A, 17% above the line; its transmittance is 0.06% of the incident light. The instrument's specified photometric linear range extends to 3.5 A (at 260 nm), so the reading is within the nominal range but close to its limit, where small stray-light or detector-linearity errors are amplified; stray light would depress a reading, whereas this one is high, so a pipetting difference in the 1.6 mL standard is as plausible as an instrumental cause. The data cannot decide, which is why the point is excluded on the operational criterion (increment rule) and its effect quantified rather than explained. Matrix: the Part I standards and blank contain Na₂CO₃ as the stopped samples do, but the stopped samples contain ONPG (± IPTG) and enzyme while the Part II/III blank is Z buffer alone; ONPG does not absorb appreciably at 415 nm, and the small positive intercepts of the linear progress curves (Table A5) are the empirical measure of any residual mismatch.

| Calibration | Points | Highest [ONP] (mM) | Highest A415 | Epsilon (A per mM per cm) | SE | Intercept (A) | R2 | Vmax relative to primary |
|---|---|---|---|---|---|---|---|---|
| five standards, free intercept (used) | 5 | 0.433 | 2.256 | 5.222 | 0.104 | -0.0224 | 0.9988 | 1 |
| five standards, through the origin | 5 | 0.433 | 2.256 | 5.151 | 0.043 | 0 | 0.9986 | 1.014 |
| zero-concentration point + five standards, free intercept | 6 | 0.433 | 2.256 | 5.186 | 0.072 | -0.0109 | 0.9992 | 1.007 |
| all six nonzero standards, free intercept | 6 | 0.533 | 3.236 | 6.008 | 0.426 | -0.1792 | 0.9802 | 0.869 |
| zero point + all six standards, free intercept | 7 | 0.533 | 3.236 | 5.796 | 0.332 | -0.0992 | 0.9839 | 0.901 |

**Table A8.** Calibration variants and their effect on V_max (K_m and K_i unchanged).

### 3.5 Kinetic models

Lineweaver–Burk by ordinary least squares (course method); unweighted nonlinear least squares of V₀ = V_max[S]/(K_m + [S]) on the velocity scale with the bounded "port" algorithm from a grid of starting values (a fit that runs to the K_m bound of 100 mM is reported as "no plateau within the tested range" rather than as a number); K_i = [I]/(K_m,app/K_m − 1) as in the manual; and three global models fitted to both series simultaneously: competitive, V = V_max[S]/(K_m(1 + [I]/K_i) + [S]); pure noncompetitive, V = V_max[S]/((K_m + [S])(1 + [I]/K_i)); mixed, V = V_max[S]/(K_m(1 + [I]/K_i) + [S](1 + [I]/K_i')). Competitive and noncompetitive have three parameters each, so their residual sums of squares compare directly; the mixed model nests both. No variance weights were used.

## 4. Primary results (reference dataset)

Main figures (`figures/`) are drawn from the reference dataset (course-provided measurements, used for the Results section at the instructor's direction); supplementary figures (`figures/supplementary/`) hold the experimental dataset (our own printouts), diagnostics and sensitivity analyses. All figures: 600 dpi PNG plus vector PDF, generated by `R/07_generate_figures.R` and `R/07b_supplementary_figures.R`. Conventions: filled symbol, observation used for V₀; open symbol, observation retained but not used; solid line, fitted initial window; dashed segment from the origin, origin-assumed 0–2 min average rate (A₄₁₅(2 min)/2 min with A₄₁₅ = 0 assumed at t = 0, where no reading exists); dotted line, extrapolation; † marks such an origin-assumed estimate, which is an average rate over the first interval rather than a measured instantaneous initial velocity. Each condition was measured once, so no error bars are shown.

## Figure 1. o-Nitrophenol absorbs maximally at 415 nm and obeys the Beer–Lambert law to 0.43 mM
![Figure 1](figure1_onp_calibration.png)

**(A)** Absorbance spectrum of 0.333 mM ONP (manual tube 4: 1.0 mL of 1 mM ONP + 1.0 mL Z buffer + 1.0 mL 1 M Na₂CO₃) read from 465 to 385 nm in 5 nm steps against the Z buffer/Na₂CO₃ blank (reference Part I). Points are the readings, the line a spline through them, the dashed line the maximum at 415 nm (A = 1.723); the shaded band (410–420 nm) lies within 2% of the maximum, so 415 nm was used for all kinetic measurements. **(B)** Standard curve at 415 nm for 1 mM ONP diluted to 0.083–0.533 mM in the same 3.0 mL matrix ([ONP] = 1 mM × V/3.0 mL; mapping of the reported readings to the manual's preparations in Table S1). Filled points and the line are the least-squares calibration over the linear region (shaded, 0.083–0.433 mM, chosen by the same increment rule used for progress curves): A₄₁₅ = 5.222[ONP] − 0.022, R² = 0.9988, n = 5, giving ε = 5.22 ± 0.10 A mM⁻¹ cm⁻¹ (5222 M⁻¹ cm⁻¹). The zero-concentration point (×, reported as 0) is shown but not fitted. The 0.533 mM standard (open, A = 3.24) lay +17% above the line and was excluded; the cause of the deviation cannot be identified from a single reading (see text). The calibration converts every velocity in this report from ΔA₄₁₅ min⁻¹ to product formed.

## Figure 2. Initial velocity rose approximately in proportion to the amount of β-galactosidase
![Figure 2](figure2_enzyme_dilution.png)

**(A)** Progress curves (A₄₁₅ of 2.0 mL aliquots stopped with 1.0 mL 1 M Na₂CO₃) for 2.20 mM ONPG hydrolysed by 1.00, 0.75, 0.50, 0.25 and 0.15 relative amounts of the standardised enzyme (tubes A–E; reference Part II). Lines are least-squares fits to the initial linear window chosen by the operational rule (Methods); the 8-min readings of tubes A and C fell far below their initial trend and were excluded (open), while tubes B and E were linear to 10 min. V₀ ranged from 0.136 (A) to 0.023 (E), a 5.9-fold span for a 6.7-fold change in enzyme. **(B)** V₀, converted with ε = 5.22 mM⁻¹ cm⁻¹ to μmol ONP min⁻¹ per 12.0 mL assay, against relative enzyme concentration. Line: proportional model through the origin, V₀ = 0.481 × E (R² about the mean 0.972); a free-intercept fit (intercept -0.0006 μmol min⁻¹, not distinguishable from zero, p = 0.98) coincides with it and is not drawn; letters identify the tubes. Relative rates were 1.00, 0.77, 0.60, 0.18, 0.17 for relative enzyme 1.00, 0.75, 0.50, 0.25, 0.15: velocity rose approximately in proportion to enzyme, but the rate per unit enzyme ranged from 0.71 (D) to 1.21 (C) and tubes D and E gave nearly equal rates despite a 1.7-fold difference in enzyme.

## Figure 3. Product formation slowed as substrate fell and when IPTG was present
![Figure 3](figure3_substrate_saturation.png)

**(A)** Progress curves for 0.2 mL enzyme acting on 2.20, 1.10, 0.55, 0.275, 0.1375 and 0.069 mM ONPG in 12.0 mL Z buffer at room temperature (tubes A–F; reference Part III, no inhibitor). Only tube A stayed linear to 10 min (V₀ = 0.132 ΔA₄₁₅ min⁻¹, regression); in tubes B–F the later increments fell below the first, so no linear window could be fitted and their V₀ is the origin-assumed 0–2 min average rate, A₄₁₅(2 min)/2 min (†; dashed, × marks the assumed origin; dotted extrapolation). No reading exists at t = 0, so this is an average rate over the first interval, not a measured instantaneous initial velocity, and whether it under- or overestimates the true V₀ depends on the unmeasured early course of each curve. As a sensitivity scenario, assuming instead a t = 0 absorbance equal to the median intercept of the curves that were linear (0.013 A; range -0.020 to 0.059 A) lowers each 0–2 min estimate by about 0.006 ΔA₄₁₅ min⁻¹ (estimator O, Figure S3); intercepts of other reactions do not bound the baseline of these curves. Later points (open) were not used. **(B)** The same six tubes with 0.458 mM IPTG (1.0 mL of 5.5 mM IPTG per 12.0 mL; reference Part III), on a smaller absorbance scale. Tube A is origin-assumed (its 4–10 min increments fell below the first); tubes B–F were fitted by regression over the filled points. The uninhibited velocities rose 5.6-fold from 0.069 to 2.20 mM ONPG and approached a plateau (Figure 4A): Lineweaver–Burk Kₘ = 0.31 mM, Vₘₐₓ = 0.477 μmol min⁻¹ (R² = 0.928); direct nonlinear fit Kₘ = 0.36 ± 0.13 mM, Vₘₐₓ = 0.494 ± 0.059 μmol min⁻¹ (R² = 0.919). Five of six uninhibited V₀ values are origin-assumed 0–2 min estimates, so Kₘ depends on how the initial rate is estimated (Figure S3).

## Figure 4. β-Galactosidase approached saturation with ONPG, and IPTG raised the apparent Kₘ
![Figure 4](figure4_iptg_inhibition.png)

**(A)** V₀ against [ONPG] without inhibitor (circles) and with 0.458 mM IPTG (triangles), from the progress curves in Figure 3 (1.0 mL of 5.5 mM IPTG per 12.0 mL tube; reference Part III, tubes A–F). Dashed curves are the hyperbolae implied by the two Lineweaver–Burk lines in B; solid curves are a single competitive-inhibition model fitted to both series at once (shared Vₘₐₓ = 0.53 ± 0.07 μmol min⁻¹, Kₘ = 0.44 ± 0.17 mM, Kᵢ = 0.107 ± 0.042 mM; the shared Vₘₐₓ is an assumption of this model, not a result). With IPTG, V₀ fell to 75% of the uninhibited value at 2.20 mM ONPG and to 13% at 0.069 mM: inhibition grew as substrate fell. **(B)** Double-reciprocal plot of the same velocities. No inhibitor: 1/V₀ = 0.66(1/[S]) + 2.10, R² = 0.928, giving Vₘₐₓ = 0.477 μmol min⁻¹ and Kₘ = 0.31 mM. + IPTG: 1/V₀ = 6.24(1/[S]) + 3.55, R² = 0.988, giving apparent Vₘₐₓ = 0.282 μmol min⁻¹ and apparent Kₘ = 1.76 mM (5.6-fold increase). Kᵢ = [I]/(Kₘ,app/Kₘ − 1) = 0.458/(1.76/0.31 − 1) = 0.100 mM. The inhibited series shows no plateau within the tested range, so its apparent Vₘₐₓ rests on an extrapolated intercept (3.55 ± 2.33) and is poorly determined; the shift of the x-intercept (−1/Kₘ) from -3.19 to -0.57 mM⁻¹ is the better-determined feature. A pure noncompetitive model fitted to the same twelve points (shared Kₘ, Vₘₐₓ reduced) left a residual sum of squares 1.9 times larger than the competitive model (0.0371 against 0.0194); the pattern is therefore consistent with competitive inhibition, with Kᵢ of the order of 0.1 mM by this method. † marks origin-assumed 0–2 min estimates.

## Supplementary figures (`figures/supplementary/`)

### Figure S1. Progress curves of the experimental dataset beside the reference dataset
![Figure S1](supplementary/figureS1_experimental_vs_reference_curves.png)

Progress curves from our 14 GENESYS 10S printouts (right column; 7 and 11 September 2026) plotted on the same axes as the reference dataset (left column) for the three experiments. Solid segments are the regression windows and dashed segments the origin-assumed 0–2 min average rates used for V₀ under the identical rule. The standard tube (A: 0.2 mL enzyme, 2.20 mM ONPG) agreed between the two datasets within 5% (enzyme dilution) and 15% (substrate series). Our low-substrate tubes without inhibitor stayed linear longer than the reference tubes (only tube E was non-linear from the outset), and our inhibited tubes C and D ran about twice as fast as the reference tubes. Our inhibited tube B (open) ran faster than tube A at half the nominal substrate and is excluded from kinetic fits; our inhibited tube E has no data (sample discarded); tube F was not performed on either day.

### Figure S2. Increment diagnostics behind every V₀ decision
![Figure S2](supplementary/figureS2_increment_diagnostics.png)

For each of the 31 measured curves, every successive 2-min increment divided by the increment predicted by the fitted V₀ (V₀ × 2 min). A value of 1 means the interval ran at the fitted initial rate; the shaded band is the acceptance window of the rule (±20% or ±0.010 A, whichever is larger). Open symbols are intervals not used for V₀. For curves with no initial linear portion (reference no-IPTG B–F, reference +IPTG A, experimental no-IPTG E) the reference V₀ is the origin-assumed 0–2 min average rate, so all later intervals fall below 1, showing how the measured increments declined: to 35–60% of the first-interval rate by the second interval in the reference uninhibited tubes B–F.

### Figure S3. Sensitivity of the kinetic parameters to the V₀ estimator
![Figure S3](supplementary/figureS3_estimator_sensitivity.png)

Kₘ (no inhibitor), apparent Kₘ (+IPTG) and Kᵢ from the reference dataset under five ways of estimating V₀: A, regression on all five points of every curve; R, the initial-window regression for every curve; S, the origin-assumed 0–2 min average rate for every curve; O, the two-tier rule under the baseline-offset scenario, in which each 0–2 min estimate is recomputed with a t = 0 absorbance equal to the median intercept of the linear curves (0.013 A; an assumption transferred between reactions, not a measured baseline); P, the two-tier rule used in the Results. Circles, Lineweaver–Burk; triangles, nonlinear Michaelis–Menten; diamond, global competitive fit. With regression-only V₀ the uninhibited Lineweaver–Burk line has a negative intercept (non-physical Kₘ and Vₘₐₓ, noted in red), and with all five points Kₘ exceeds 3 mM, because both estimators average over the falling phase of the curved low-substrate tubes. The offset scenario moves Kₘ from 0.31 to 0.55 mM and Kᵢ from 0.10 to 0.22 mM; applying the 0–2 min average rate to every curve (S) gives Kᵢ = 0.50 mM, because for the inhibited tubes, which were linear over 2–10 min, that estimate replaces a five-point regression with a single interval. These are alternative method-dependent estimates, not a confidence interval for Kᵢ. Cyan lines: Kₘ = 0.12 mM and Kᵢ = 0.08 mM reported for purified E. coli β-galactosidase with ONPG in TES buffer, pH 7.0, 25 °C.

### Figure S4. Kinetic analysis of the experimental dataset
![Figure S4](supplementary/figureS4_experimental_kinetics.png)

**(A)** Michaelis–Menten representation of our Part III data with the same V₀ rule and units as the Results, with the anomalous +IPTG tube B (open) excluded and +IPTG tube E absent; † marks an origin-assumed 0–2 min estimate. Nonlinear fits: Kₘ = 0.14 mM, Vₘₐₓ = 0.41 μmol min⁻¹ without inhibitor; apparent Kₘ = 1.21 mM, apparent Vₘₐₓ = 0.41 with IPTG (ratio 1.01); Kᵢ = 0.059 mM. **(B)** Ratio of our V₀ to the reference V₀ for every tube measured in both datasets. The standard tube agreed within 5–15%; our uninhibited tube D and inhibited tubes C and D ran 1.6- to 2.1-fold faster; our inhibited tube B (faded) ran 3.7-fold faster than the reference tube B.

### 4.1 Calibration

| Reported tube | Manual preparation | ONP 1 mM (mL) | [ONP] in cuvette (mM) | A415 | A415 / [ONP] (per mM) | Fitted |
|---|---|---|---|---|---|---|
| 1 | Blank | 0 | 0 | 0 | NA | no (zero point) |
| 2 | Standard 1 | 0.25 | 0.0833 | 0.428 | 5.14 | yes |
| 3 | Standard 2 | 0.5 | 0.1667 | 0.856 | 5.14 | yes |
| 4 | Standard 3 | 0.75 | 0.25 | 1.24 | 4.96 | yes |
| 5 | Standard 4 | 1 | 0.3333 | 1.723 | 5.17 | yes |
| 6 | Standard 5 | 1.3 | 0.4333 | 2.256 | 5.21 | yes |
| 7 | Standard 6 | 1.6 | 0.5333 | 3.236 | 6.07 | no (+17%) |

**Table A9.** ONP standard curve. λ_max = 415 nm (A = 1.723; 410 to 420 nm within 2% of the maximum). Calibration over 5 standards: A₄₁₅ = 5.222[ONP] − 0.022, R² = 0.9988, ε = 5.22 ± 0.10 A mM⁻¹ cm⁻¹ (5222 M⁻¹ cm⁻¹). For comparison, ε ≈ 4.5 mM⁻¹ cm⁻¹ at 420 nm is the value used in Miller's classical assay in the same alkaline stop; at pH 7.0, where ONP is largely protonated, Juers et al. used 2.65 mM⁻¹ cm⁻¹ at 420 nm, which is not comparable with the alkaline value measured here.

### 4.2 Enzyme dilution

| Tube | Relative enzyme | V0 (dA415/min) | V0 (umol/min) | Relative rate | Rate / enzyme | Points used | V0 experimental (dA415/min) | Relative rate, experimental |
|---|---|---|---|---|---|---|---|---|
| A | 1 | 0.136 | 0.469 | 1 | 1 | 2-6 min | 0.1428 | 1 |
| B | 0.75 | 0.1041 | 0.359 | 0.77 | 1.02 | 2-10 min | 0.085 | 0.6 |
| C | 0.5 | 0.082 | 0.283 | 0.6 | 1.21 | 2-6 min | 0.0609 | 0.43 |
| D | 0.25 | 0.0243 | 0.084 | 0.18 | 0.71 | 2-6 min | 0.0275 | 0.19 |
| E | 0.15 | 0.0229 | 0.079 | 0.17 | 1.12 | 2-10 min | 0.0197 | 0.14 |

**Table A10.** Enzyme dilution, reference (primary) with the experimental values alongside. Reference: proportional slope 0.481 µmol min⁻¹ per unit relative enzyme, R² 0.972; free intercept -0.0006 µmol min⁻¹, p = 0.98; rate per unit enzyme 0.71 (D) to 1.21 (C). Experimental: R² 0.963, relative rates 1.00, 0.60, 0.43, 0.19, 0.14. In both datasets the rate per unit enzyme is lowest for tube D (0.25); in the reference dataset tubes D and E gave nearly the same rate (relative rates 0.18 and 0.17 for enzyme 0.25 and 0.15). The trend is approximately, not exactly, proportional.

### 4.3 Substrate series and inhibition

| Series | Tube | [S] (mM) | 2 min | 4 min | 6 min | 8 min | 10 min | V0 (dA/min) | V0 (umol/min) | 1/[S] | 1/V0 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| no inhibitor | A | 2.2 | 0.282 | 0.546 | 0.815 | 1.094 | 1.328 | 0.132 | 0.455 | 0.45 | 2.2 |
| no inhibitor | B | 1.1 | 0.202 | 0.383 | 0.516 | 0.628 | 0.723 | 0.101† | 0.348† | 0.91 | 2.87 |
| no inhibitor | C | 0.55 | 0.156 | 0.278 | 0.357 | 0.425 | 0.468 | 0.078† | 0.269† | 1.82 | 3.72 |
| no inhibitor | D | 0.275 | 0.11 | 0.172 | 0.211 | 0.24 | 0.301 | 0.055† | 0.190† | 3.64 | 5.28 |
| no inhibitor | E | 0.1375 | 0.116 | 0.148 | 0.166 | 0.171 | 0.18 | 0.058† | 0.200† | 7.27 | 5 |
| no inhibitor | F | 0.06875 | 0.047 | 0.067 | 0.077 | 0.084 | 0.09 | 0.0235† | 0.081† | 14.55 | 12.35 |
| + 0.458 mM IPTG | A | 2.2 | 0.198 | 0.48 | 0.586 | 0.784 | 0.966 | 0.099† | 0.341† | 0.45 | 2.93 |
| + 0.458 mM IPTG | B | 1.1 | 0.065 | 0.127 | 0.196 | 0.239 | 0.294 | 0.03275 | 0.113 | 0.91 | 8.86 |
| + 0.458 mM IPTG | C | 0.55 | 0.045 | 0.086 | 0.128 | 0.154 | 0.187 | 0.02075 | 0.072 | 1.82 | 13.98 |
| + 0.458 mM IPTG | D | 0.275 | 0.029 | 0.051 | 0.068 | 0.085 | 0.099 | 0.0087 | 0.030 | 3.64 | 33.35 |
| + 0.458 mM IPTG | E | 0.1375 | 0.02 | 0.035 | 0.047 | 0.06 | 0.069 | 0.00615 | 0.021 | 7.27 | 47.18 |
| + 0.458 mM IPTG | F | 0.06875 | 0.011 | 0.019 | 0.025 | 0.031 | 0.036 | 0.0031 | 0.011 | 14.55 | 93.59 |

**Table A11.** Data-sheet view of the primary substrate series: absorbances, V₀ and reciprocals.

| Condition | Method | Km | Vmax | Ki | Fit |
|---|---|---|---|---|---|
| No inhibitor | Lineweaver-Burk | 0.314 | 0.477 | NA | R2 0.928 |
| No inhibitor | Nonlinear MM | 0.363 ± 0.128 | 0.494 ± 0.059 | NA | R2 0.919 |
| + 0.458 mM IPTG | Lineweaver-Burk | 1.757 (app.) | 0.282 (app.) | 0.100 | R2 0.988 |
| + 0.458 mM IPTG | Nonlinear MM | n.d. | n.d. | NA | R2 0.962 |
| Both series | Global, competitive | 0.435 ± 0.166 | 0.529 ± 0.072 | 0.107 ± 0.042 | RSS 0.0194 |
| Both series | Global, noncompetitive | 0.744 ± 0.382 | 0.626 ± 0.139 | 0.433 ± 0.181 | RSS 0.0371 |

| Method | Km (mM) | Km,app (mM) | Km,app/Km | Vmax (umol/min) | Vmax,app (umol/min) | Vmax,app/Vmax | [IPTG] (mM) | Ki, competitive (mM) | Ki if noncompetitive (mM) |
|---|---|---|---|---|---|---|---|---|---|
| Lineweaver-Burk | 0.314 | 1.757 | 5.6 | 0.477 | 0.282 | 0.59 | 0.458 | 0.1 | 0.662 |
| Nonlinear MM | 0.363 | NA | NA | 0.494 | NA | NA | 0.458 | NA | NA |
| Global nonlinear competitive | 0.435 | 2.297 | 5.28 | 0.529 | 0.529 | 1 | 0.458 | 0.107 | NA |

**Table A12.** Primary kinetic parameters and inhibition analysis. The +IPTG Lineweaver–Burk intercept (3.55 ± 2.33) is poorly determined because the inhibited velocities halve with each halving of substrate from tube B downward (first-order behaviour) and only tube A hints at a plateau; the apparent V_max (0.282 µmol min⁻¹) therefore rests on extrapolation, and the nonlinear fit of the inhibited series alone runs to the K_m bound. A test of the intercept against zero says nothing about whether the two series share a V_max; the question is addressed by the model comparison in Table A13. The K_i that a noncompetitive interpretation would assign to the apparent V_max change (0.66 mM) is listed for completeness.

| Model | Parameter | Estimate | SE | RSS | AIC | n | Converged | Note |
|---|---|---|---|---|---|---|---|---|
| global competitive | Vmax | 0.5285 | 0.072 | 0.01941 | -35.07 | 12 | TRUE |  |
| global competitive | Km | 0.4351 | 0.1662 | 0.01941 | -35.07 | 12 | TRUE |  |
| global competitive | Ki | 0.1071 | 0.0418 | 0.01941 | -35.07 | 12 | TRUE |  |
| global noncompetitive | Vmax | 0.6262 | 0.1388 | 0.03713 | -27.28 | 12 | TRUE |  |
| global noncompetitive | Km | 0.7438 | 0.3824 | 0.03713 | -27.28 | 12 | TRUE |  |
| global noncompetitive | Ki | 0.4333 | 0.1806 | 0.03713 | -27.28 | 12 | TRUE |  |
| global mixed | Vmax | 0.5286 | 0.0778 | 0.01942 | -33.06 | 12 | TRUE |  |
| global mixed | Km | 0.4352 | 0.1788 | 0.01942 | -33.06 | 12 | TRUE |  |
| global mixed | Ki | 0.1072 | 0.0792 | 0.01942 | -33.06 | 12 | TRUE |  |
| global mixed | Kip | 500 | 422500 | 0.01942 | -33.06 | 12 | TRUE | at upper bound (model reduces to competitive) |

**Table A13.** Global fits to both series (12 points). Competitive: V_max = 0.529 ± 0.072 µmol min⁻¹, K_m = 0.435 ± 0.166 mM, K_i = 0.107 ± 0.042 mM, RSS 0.0194, AIC -35.1. Pure noncompetitive (same number of parameters): K_i = 0.433 mM, RSS 0.0371 (1.9 times larger), AIC -27.3 (ΔAIC = 7.8). Mixed: the ES-binding constant K_i' ran to its upper bound (500 mM), K_i = 0.107 mM, AIC -33.1, i.e. the mixed model reduces to the competitive one. The comparison favours the competitive mechanism, but with twelve single measurements and no inhibited plateau it cannot exclude a modest uncompetitive component, and the equal V_max of the competitive and mixed fits is a property of those models, not an independent observation.

| Dataset | Tube | [ONPG]0 (mM) | A415 2 min | Converted at 2 min (%) | A415 10 min | Converted at 10 min (%) |
|---|---|---|---|---|---|---|
| Reference Part III (+IPTG) | A | 2.2 | 0.198 | 2.6 | 0.966 | 12.6 |
| Reference Part III (+IPTG) | B | 1.1 | 0.065 | 1.7 | 0.294 | 7.7 |
| Reference Part III (+IPTG) | C | 0.55 | 0.045 | 2.4 | 0.187 | 9.8 |
| Reference Part III (+IPTG) | D | 0.275 | 0.029 | 3 | 0.099 | 10.3 |
| Reference Part III (+IPTG) | E | 0.138 | 0.02 | 4.2 | 0.069 | 14.4 |
| Reference Part III (+IPTG) | F | 0.0687 | 0.011 | 4.6 | 0.036 | 15 |
| Reference Part III (-IPTG) | A | 2.2 | 0.282 | 3.7 | 1.33 | 17.3 |
| Reference Part III (-IPTG) | B | 1.1 | 0.202 | 5.3 | 0.723 | 18.9 |
| Reference Part III (-IPTG) | C | 0.55 | 0.156 | 8.1 | 0.468 | 24.4 |
| Reference Part III (-IPTG) | D | 0.275 | 0.11 | 11.5 | 0.301 | 31.4 |
| Reference Part III (-IPTG) | E | 0.138 | 0.116 | 24.2 | 0.18 | 37.6 |
| Reference Part III (-IPTG) | F | 0.0687 | 0.047 | 19.6 | 0.09 | 37.6 |
| Experimental Part III (+IPTG) | A | 2.2 | 0.163 | 2.1 | 0.78 | 10.2 |
| Experimental Part III (+IPTG) | B | 1.1 | 0.269 | 7 | 1.11 | 28.9 |
| Experimental Part III (+IPTG) | C | 0.55 | 0.08 | 4.2 | 0.362 | 18.9 |
| Experimental Part III (+IPTG) | D | 0.275 | 0.041 | 4.3 | 0.188 | 19.6 |
| Experimental Part III (-IPTG) | A | 2.2 | 0.259 | 3.4 | 1.06 | 13.9 |
| Experimental Part III (-IPTG) | B | 1.1 | 0.224 | 5.8 | 1.06 | 27.8 |
| Experimental Part III (-IPTG) | C | 0.55 | 0.2 | 10.4 | 0.88 | 46 |
| Experimental Part III (-IPTG) | D | 0.275 | 0.202 | 21.1 | 0.764 | 79.8 |
| Experimental Part III (-IPTG) | E | 0.138 | 0.111 | 23.2 | 0.346 | 72.3 |

**Table A14.** Substrate converted by 2 and 10 min, from A₄₁₅/(ε × 2/3) relative to nominal [ONPG]. Reference uninhibited tubes D to F reached only 31 to 38% conversion by 10 min yet their rates fell to a few percent of the initial rate. Candidate explanations and the test each implies: substrate depletion (predicts a plateau at 100% conversion; observed about 38% in E and F); enzyme inactivation (made less likely, but not excluded, by tube A, same enzyme and session, linear to 10 min); timing of the aliquots (a late first stop raises the first reading relative to the others, and uneven later stops distort the apparent plateau; the magnitude cannot be reconstructed from the printouts); reaction preparation and a lower-than-nominal effective ONPG concentration in the low tubes (would place the plateau at the true concentration; testable by reading the ONPG stock's own absorbance or by complete hydrolysis of an aliquot); stopping and read-out effects (incomplete mixing with Na₂CO₃, instrument drift at low absorbance); a background absorbance unrelated to product (would appear as a non-zero intercept; the linear curves show intercepts of 0.00 to 0.06 A, smaller than the plateaus of 0.09 to 0.30 A). None of these is demonstrated by the data. The experimental uninhibited D and E tubes, by contrast, reached 80% and 72% conversion.

## 5. Secondary analysis: the experimental dataset

| +IPTG tube B | Method | Km (mM) | Km,app (mM) | Vmax (umol/min) | Vmax,app (umol/min) | Vmax,app/Vmax | Ki (mM) | R2 (-I) | R2 (+I) | Tubes (-I / +I) |
|---|---|---|---|---|---|---|---|---|---|---|
| excluded | Lineweaver-Burk | 0.156 | 3.087 | 0.421 | 0.792 | 1.88 | 0.024 | 0.95 | 0.969 | ABCDE / ACD |
| excluded | Nonlinear MM | 0.137 | 1.206 | 0.409 | 0.414 | 1.01 | 0.059 | 0.942 | 0.984 | ABCDE / ACD |
| included | Lineweaver-Burk | 0.156 | 38.16 | 0.421 | 9.042 | 21.5 | 0.002 | 0.95 | 0.945 | ABCDE / ABCD |
| included | Nonlinear MM | 0.137 | 0.783 | 0.409 | 0.458 | 1.12 | 0.097 | 0.942 | 0.541 | ABCDE / ABCD |

**Table A15.** Kinetics from our Part III printouts with the same rule and units (uninhibited E is a Tier-2 origin-assumed estimate). With +IPTG tube B excluded, the nonlinear fits give K_m = 0.137 mM, V_max = 0.409 µmol min⁻¹, K_m,app = 1.206 mM, V_max,app = 0.414 (ratio 1.01), K_i = 0.059 mM: the textbook competitive pattern, with K_m near the literature 0.12 mM. The Lineweaver–Burk analysis of the same points is distorted by the three-point inhibited series (K_m,app 3.09 mM, V_max,app 1.88 × V_max) and, if tube B is included, becomes meaningless (K_m,app = 38 mM).

| Condition | Tube | V0 reference (dA415/min) | V0 experimental (dA415/min) | Experimental / reference | Estimator, reference | Estimator, experimental | A415 at 10 min, reference | A415 at 10 min, experimental |
|---|---|---|---|---|---|---|---|---|
| Enzyme dilution (Part II) | A | 0.136 | 0.1428 | 1.05 | regression 2-6 min | regression 2-8 min | 1.407 | 1.328 |
| Enzyme dilution (Part II) | B | 0.1041 | 0.085 | 0.82 | regression 2-10 min | regression 2-10 min | 1.084 | 0.86 |
| Enzyme dilution (Part II) | C | 0.082 | 0.0609 | 0.74 | regression 2-6 min | regression 2-8 min | 0.736 | 0.583 |
| Enzyme dilution (Part II) | D | 0.0243 | 0.0275 | 1.13 | regression 2-6 min | regression 2-10 min | 0.262 | 0.283 |
| Enzyme dilution (Part II) | E | 0.0229 | 0.0197 | 0.86 | regression 2-10 min | regression 2-10 min | 0.248 | 0.205 |
| ONPG series, no inhibitor | A | 0.132 | 0.1126 | 0.85 | regression 2-10 min | regression 2-8 min | 1.328 | 1.061 |
| ONPG series, no inhibitor | B | 0.101 | 0.1055 | 1.04 | 0-2 min average rate, origin assumed (no initial linear portion) | regression 2-10 min | 0.723 | 1.065 |
| ONPG series, no inhibitor | C | 0.078 | 0.0894 | 1.15 | 0-2 min average rate, origin assumed (no initial linear portion) | regression 2-8 min | 0.468 | 0.88 |
| ONPG series, no inhibitor | D | 0.055 | 0.0872 | 1.59 | 0-2 min average rate, origin assumed (no initial linear portion) | regression 2-6 min | 0.301 | 0.764 |
| ONPG series, no inhibitor | E | 0.058 | 0.0555 | 0.96 | 0-2 min average rate, origin assumed (no initial linear portion) | 0-2 min average rate, origin assumed (no initial linear portion) | 0.18 | 0.346 |
| ONPG series, no inhibitor | F | 0.0235 | NA | NA | 0-2 min average rate, origin assumed (no initial linear portion) | NA | 0.09 | NA |
| ONPG series + IPTG | A | 0.099 | 0.0771 | 0.78 | 0-2 min average rate, origin assumed (no initial linear portion) | regression 2-10 min | 0.966 | 0.78 |
| ONPG series + IPTG | B | 0.0328 | 0.121 | 3.69 | regression 2-6 min | regression 2-8 min | 0.294 | 1.106 |
| ONPG series + IPTG | C | 0.0208 | 0.041 | 1.98 | regression 2-6 min | regression 2-6 min | 0.187 | 0.362 |
| ONPG series + IPTG | D | 0.0087 | 0.0181 | 2.09 | regression 2-10 min | regression 2-10 min | 0.099 | 0.188 |
| ONPG series + IPTG | E | 0.0062 | NA | NA | regression 2-10 min | NA | 0.069 | NA |
| ONPG series + IPTG | F | 0.0031 | NA | NA | regression 2-10 min | NA | 0.036 | NA |

**Table A16.** Tube-by-tube comparison. The standard tube agreed within 5% (enzyme dilution, 1.05) and 15% (substrate series, 0.85). Our uninhibited low-substrate tubes ran faster than the reference tubes (D: 1.59) because they stayed linear longer, and our inhibited tubes C and D ran 2.0- and 2.1-fold faster; +IPTG tube B ran 3.7-fold faster than the reference tube B and 1.57-fold faster than our own tube A.

**+IPTG tube B.** The observation is that velocity increased when substrate halved at fixed enzyme and inhibitor, which no kinetic mechanism allows; the tube's nominal composition is therefore unverifiable. Its first four points are as linear as any in the dataset (R² 0.9999), so instrument error is unlikely. Hypotheses, in order of simplicity: IPTG omitted (the curve matches an uninhibited tube at high substrate), or a larger volume of ONPG or enzyme than intended. The 10-min value (1.106) is 46% of the increment the first four points predict and is consistent with the stop reagent added early or the aliquot mixed late; it is retained in the raw data and excluded from that tube's regression by the ordinary rule. The instrument clock stamps show the black set was read as a batch (04:20 to 04:33, order D, B, A, C), so read order carries no information about reaction order.

**+IPTG tube E.** Discarded before measurement; no value was estimated. The inhibited experimental series therefore rests on tubes A, C and D.

## 6. Sensitivity analysis

| Estimator | Method | Km (mM) | Km,app (mM) | Vmax (umol/min) | Vmax,app (umol/min) | Km,app/Km | Vmax,app/Vmax | Ki (mM) | R2 (-I) | R2 (+I) | Physical (-I / +I) | Primary |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| A | Lineweaver-Burk | 3.405 | 1.317 | 0.849 | 0.214 | 0.39 | 0.25 | -0.747 | 0.965 | 0.988 | TRUE / TRUE |  |
| A | Nonlinear MM | 20.9 | NA | 4.744 | NA | NA | NA | NA | 0.995 | 0.951 | TRUE / FALSE |  |
| O | Lineweaver-Burk | 0.551 | 1.726 | 0.577 | 0.277 | 3.13 | 0.48 | 0.215 | 0.917 | 0.988 | TRUE / TRUE |  |
| O | Nonlinear MM | 0.524 | NA | 0.527 | NA | NA | NA | NA | 0.924 | 0.971 | TRUE / FALSE |  |
| P | Lineweaver-Burk | 0.314 | 1.757 | 0.477 | 0.282 | 5.6 | 0.59 | 0.1 | 0.928 | 0.988 | TRUE / TRUE | yes |
| P | Nonlinear MM | 0.363 | NA | 0.494 | NA | NA | NA | NA | 0.919 | 0.962 | TRUE / FALSE |  |
| R | Lineweaver-Burk | -3.48 | 1.722 | -0.912 | 0.276 | -0.49 | -0.3 | -0.307 | 0.99 | 0.989 | FALSE / TRUE |  |
| R | Nonlinear MM | 3.379 | NA | 1.147 | NA | NA | NA | NA | 0.998 | 0.972 | TRUE / FALSE |  |
| S | Lineweaver-Burk | 0.322 | 0.62 | 0.487 | 0.188 | 1.93 | 0.39 | 0.495 | 0.928 | 0.984 | TRUE / TRUE |  |
| S | Nonlinear MM | 0.436 | NA | 0.537 | NA | NA | NA | NA | 0.908 | 0.954 | TRUE / FALSE |  |
| P | Global nonlinear competitive | 0.435 | 2.297 | 0.529 | 0.529 | 5.28 | 1 | 0.107 | 0.919 | NA | TRUE / NA |  |

**Table A17.** Kinetic parameters from the reference dataset under five V₀ estimators. Regression on every curve (R) gives a negative uninhibited Lineweaver–Burk intercept, so K_m and V_max are undefined; all five points (A) give K_m = 3.4 mM; the origin-assumed 0 to 2 min average rate for every curve (S) gives K_m = 0.32 mM but collapses K_m,app to 0.62 mM and raises K_i to 0.50 mM, because for the inhibited tubes, which were linear over 2 to 10 min with intercepts of 0.006 to 0.014 A, a single origin-anchored interval replaces a five-point regression; the baseline-offset scenario (O) moves K_m to 0.55 mM (K_m,app 1.73 mM, ratio 3.1) and K_i to 0.22 mM. The two-tier rule (P) is the estimator that follows the manual's instruction (initial linear portion where one exists, earliest interval where none exists) and gives physically admissible parameters for both series; it was not chosen for the values it produces. Conclusions that survive every estimator: velocity saturates with substrate, and IPTG slows the enzyme progressively more as substrate falls. Conclusions that depend on the estimator: the numerical K_m (0.31 to 0.55 mM among the rule-based estimators and the global fit) and, through it, K_i (0.10 to 0.22 mM among those estimators; 0.50 mM under the uniform 0 to 2 min estimate). These are alternative method-dependent estimates, not a confidence interval.

## 7. Limitations

Single measurements per condition (no replicate variance; quoted uncertainties are regression standard errors); manual 2-min sampling that cannot resolve the initial rate when it falls within the first interval, which affects five of six uninhibited reference tubes; a substrate range whose highest concentration (2.20 mM) is near the uninhibited K_m estimate and below the apparent K_m with IPTG, so the inhibited plateau was never reached and V_max,app is extrapolated; the assumed zero absorbance at t = 0 behind the origin-assumed estimates, examined in a sensitivity scenario but not verifiable from these data; read-out resolution of 0.001 A relative to increments of 0.005 A in the most dilute inhibited tubes; nominal ONPG concentrations that the plateaus of the low-substrate reference tubes suggest may have been lower than stated; room temperature uncontrolled; the experimental inhibited series reduced to three tubes by the loss of E and the anomaly in B; literature values measured for the purified enzyme in TES buffer with 145 mM NaCl at pH 7.0 and 25 °C by a continuous assay at 420 nm, so exact agreement is not expected.

## 8. Reproducibility

```bash
Rscript R/run_all.R
```

regenerates `data/processed/`, `tables/`, `figures/` and the three report sources from the raw files (R 4.3.3; tidyverse, broom, patchwork, scales, here; ragg optional; XeLaTeX for the PDF versions). Analysis settings live in `R/00_setup.R` (tolerances of the V₀ rule, the excluded experimental tube, the K_m bound). Session information of the last run is in `report/sessionInfo.txt`. Code and data: public repository https://github.com/almokhtar8-stack/exp2. The course's original files and the instructor's e-mail are kept locally for the cross-check in `01_import_clean.R` but are not redistributed (permission not obtained); the scripts run without them.

## 9. References

See the reference list in `experiment_2_submission.md`. Literature comparison values: Juers et al. (2009) Protein Sci. 18, 1281-1292 (Table II, native enzyme: k_cat 620 s⁻¹, K_m 0.12 mM for oNPG; Table IV: K_i 0.08 mM for IPTG at 0.01 mM Mg²⁺ and ~150 mM NaCl; TES buffer, pH 7.0, 25 °C; ε(oNP) 2.65 mM⁻¹ cm⁻¹ at 420 nm, pH 7.0). The classical alkaline-stop assay and its extinction coefficient: Miller (1972) Experiments in Molecular Genetics, pp 352-355. Instrument specification: Thermo Fisher Scientific, GENESYS 10S Series UV-Visible Spectrophotometers brochure (photometric linear range up to 3.5 A at 260 nm; accuracy ± 0.005 A at 1.0 A).
