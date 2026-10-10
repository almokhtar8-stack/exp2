# Experiment 2, β-galactosidase kinetics: supplementary information and technical record

This document accompanies `experiment_2_submission.md` (the graded course report) and the journal-style version. It records the data audit, every analysis decision, the sensitivity analyses, the secondary analysis of the experimental dataset, and how to regenerate everything. All numbers are inserted from the processed outputs by `R/08_assemble_reports.R`; nothing is typed in by hand. Compiled {{DATE}}.

## 1. Datasets, provenance and terminology

Two datasets were analysed. The **reference dataset** is the set of course-provided measurements supplied by the laboratory instructor (Professor Samah Gadhoum; e-mail of 13 September 2026: "These are some results you can use for your results section. Please discuss your own results in the discussion part") and was used for the primary kinetic analysis. The **experimental dataset** is the set of measurements collected by our laboratory group (14 GENESYS 10S printouts from 7 and 11 September 2026) and was analysed separately for technical interpretation and troubleshooting. The labels describe origin and analytical role; neither dataset is externally validated or published, and the experimental dataset is not a replicate of the reference dataset (different sessions, different operators). Original labels are retained in the raw files and in the crosswalk below.

{{TABLE:table_dataset_crosswalk}}

**Table A0.** Dataset crosswalk: labels used in this project, labels on the source files, and file locations.

## 2. Data audit

### 2.1 Reference files against the transcribed CSVs

All 17 spectrum values and all 7 standard-curve values in the supplied `instructor_part1_values.csv` match the course .docx; all 60 Part III values in `instructor_day2_primary_results.csv` match the .pptx. The supplied Part I CSV omits the enzyme-dilution table that the .docx contains (tubes A to E, relative enzyme 1.00 to 0.15, five time points); it was transcribed from the .docx into `part2_enzyme_dilution.csv`. The pipeline re-verifies every transcription against the source files when they are present (`data/processed/validation_report.csv`).

### 2.2 Standard-curve tube assignment

The manual describes eight preparations (a blank and standards 1 to 7 with 0.25, 0.50, 0.75, 1.0, 1.3, 1.6 and 2.0 mL of 1 mM ONP in 3.0 mL). The course table lists seven readings labelled tubes 1 to 7 (0, 0.428, 0.856, 1.240, 1.723, 2.256, 3.236). Classmates queried the discrepancy and the instructor clarified that the first reading is the zero-concentration point, listed against the first reported tube rather than as a separately numbered blank. Two facts fix the assignment of the remaining six readings: a 0.25 mL standard (0.083 mM) could not read 0, and the spectrum tube (manual standard 4, 1.0 mL) read 1.723 at 415 nm, identical to the fifth reported reading. Under the adopted mapping (reported tube k = manual standard k − 1) the absorbance-to-concentration ratios of the first five standards are 4.96 to 5.21 per mM, as Beer–Lambert behaviour requires; under the alternative (reported tubes 2 to 7 = manual standards 2 to 7) the ratios would fall from 2.57 to 4.85 per mM and the spectrum tube would not match. The manual's standard 7 (0.667 mM) is therefore the preparation with no reported reading; whether it was not prepared or not reported cannot be determined from the files, and no absorbance was assumed for it. The zero-concentration preparation is chemically the blank (2.0 mL Z buffer + 1.0 mL Na₂CO₃ read against itself), which is why it reads 0; it is shown on the standard curve but not used in the fit.

{{TABLE:table_standard_curve_mapping}}

**Table A1.** Mapping of the reported standard-curve readings to the manual's preparations.

### 2.3 Features of the reference progress curves

Enzyme-dilution tube A has an 8-min reading (0.965) far below its 2 to 6 min trend, with the 10-min reading back on the line; tube C is similar. Uninhibited tubes B to F decelerate from the first interval onward: the second increment is 50 to 73% of the first and the fourth is 6 to 50% of the first. Inhibited tube A has an irregular 4-min reading (0.480); inhibited tubes B to F are close to linear with small increments (0.005 to 0.07 A per 2 min), where the 0.001 A read-out resolution matters.

{{TABLE:table_audit_reference}}

**Table A2.** Audit of the reference progress curves.

### 2.4 Experimental printouts

All 14 photographs were compared with the transcription; every legible value matches (one last digit, Part III +IPTG tube A at 6 min, is under glare in the photograph and reads 0.47x; the recorded 0.478 sits on that tube's straight line). Part III +IPTG tube E has no data (sample discarded before measurement) and is `NA` throughout. Part III +IPTG tube B (nominally 1.10 mM ONPG) is anomalous as a whole curve: increments 0.237, 0.242, 0.247 over the first 8 min exceed those of tube A (0.157, 0.158, 0.150) at twice the substrate, and its 10-min increment (0.111) is 46% of the preceding mean. The mapping of the blue- and black-labelled printouts to the uninhibited and inhibited series was established from tube count, the manual's enzyme-standardisation specification and the rate structure (blue A reached 1.061 at 10 min and black A only 0.780; black rates fell 4.3-fold from A to D against 1.3-fold for blue); the reference dataset shows the same pattern (inhibited A 0.966, uninhibited A 1.328 at 10 min).

{{TABLE:table_audit_experimental}}

**Table A3.** Audit of the experimental progress curves.

## 3. Methods of analysis

### 3.1 Concentrations and volumes

[ONPG] = 3.3 mM × V_ONPG/12.0 mL (2.20, 1.10, 0.55, 0.275, 0.1375, 0.06875 mM for tubes A to F); [IPTG] = 5.5 mM × 1.0/12.0 = {{I_mM|4}} mM in every inhibited tube; ONP standards 1 mM × V/3.0 mL. Every reaction tube in the manual sums to 12.0 mL and every Part I preparation to 3.0 mL (checked programmatically; `validation_report.csv`).

{{TABLE:table_tube_compositions}}

**Table A4.** Tube compositions from the manual with derived concentrations.

### 3.2 Rule for the initial velocity

The manual asks for V₀ from the initial linear portion of each progress curve, with the points used identified. The rule applies that instruction identically to every curve. Tier 1: fit A₄₁₅ = a + bt to the 2, 4 and 6 min points and extend one point at a time while the added increment lies within {{REL_TOL_pct|0}}% (or {{ABS_TOL|3}} A, whichever larger; the absolute floor protects low-signal curves from read-out noise) of the increment predicted by the current line; V₀ = b. Tier 2: when the second and third increments both fall below the first by more than the tolerance, there is no initial linear portion within the sampled interval and a regression on 2 to 6 min would average over a falling rate; V₀ is taken from the earliest interval available, the 0 to 2 min secant through the origin, and flagged. Tier 2 applied to {{n_secant_reference}} of the {{n_curves_reference}} reference curves (uninhibited B to F and inhibited A) and to one experimental curve (uninhibited E). The rule depends only on the shape of each curve, not on the kinetic parameters that result from it.

**Origin assumption.** No reading exists at t = 0, so the Tier-2 secant assumes zero absorbance at t = 0. The regression intercepts of the {{off_n}} curves that were linear estimate the actual offset (reaction before the timer, the matrix difference between the stopped sample and the Z-buffer blank, read-out offset): median {{off_median|3}} A, range {{off_min|3}} to {{off_max|3}} A (reference curves alone: median {{off_ref_median|3}} A, maximum {{off_ref_max|3}} A). A positive offset makes the secant overstate the initial rate by offset/2 min, i.e. typically {{off_bias_median|3}} and at most {{off_bias_max|3}} ΔA₄₁₅ min⁻¹. The "lower bound" label on secant estimates therefore holds only if the offset is zero; estimator O below carries the median correction through every kinetic parameter.

{{TABLE:table_origin_offset}}

**Table A5.** Intercepts of the linear curves and the implied bias of the 0 to 2 min secant.

{{TABLE:table_v0_reference}}

**Table A6.** Initial velocities of the reference curves (primary data).

{{TABLE:tableS3_v0_experimental}}

**Table A6b.** Initial velocities of the experimental curves.

{{TABLE:tableS4_candidate_windows}}

**Table A7.** Regression over every candidate initial window (2 to 6, 2 to 8, 2 to 10 min) for every curve; "Selected" marks the window used, or notes that the secant replaced it.

{{TABLE:tableS4b_estimator_comparison}}

**Table A7b.** Two-point secants, window regressions and the rule's V₀ for every curve (ΔA₄₁₅ min⁻¹). For linear curves the 2 to 6 min secant and the 2 to 6 min regression agree within rounding, as they must for three equally spaced points; the 0 to 2 min secant exceeds them wherever the intercept is positive.

### 3.3 Units

V₀ (mM min⁻¹ in the cuvette) = slope/ε. The stopped sample is 2 mL reaction + 1 mL Na₂CO₃, so the reaction-mixture rate is 1.5 × the cuvette rate; multiplying by 12.0 mL gives µmol ONP min⁻¹ per assay. With ε = {{eps|2}} A mM⁻¹ cm⁻¹, 1 ΔA₄₁₅ min⁻¹ = {{k_umol|3}} µmol min⁻¹ per assay (1/{{eps|4}} × 1.5 × 12.0 = {{k_umol|4}}; dimensionally A min⁻¹ ÷ (A mM⁻¹) × mL = µmol min⁻¹). The manual's abbreviated instruction, "divide the slope by ε", yields the cuvette rate in mM min⁻¹; the two volume factors are needed to express an amount per minute. K_m and K_i do not depend on the factor (it cancels in slope/intercept ratios); V_max scales with it, and per mL of enzyme the per-assay value is multiplied by 5 (0.2 mL enzyme per assay).

### 3.4 Calibration

ε is the slope of the least-squares line through the five standards from 0.083 to 0.433 mM (free intercept {{eps_icpt|4}} A, p = {{eps_icpt_p|2}}, so not distinguishable from zero). Alternatives are tabulated below. The 0.533 mM standard read {{excl_A|3}} A, {{excl_pct|0}}% above the line; its transmittance is {{excl_T|2}}% of the incident light. The instrument's specified photometric linear range extends to {{instr_limit|1}} A (at 260 nm), so the reading is within the nominal range but close to its limit, where small stray-light or detector-linearity errors are amplified; stray light would depress a reading, whereas this one is high, so a pipetting difference in the 1.6 mL standard is as plausible as an instrumental cause. The data cannot decide, which is why the point is excluded on the operational criterion (increment rule) and its effect quantified rather than explained. Matrix: the Part I standards and blank contain Na₂CO₃ as the stopped samples do, but the stopped samples contain ONPG (± IPTG) and enzyme while the Part II/III blank is Z buffer alone; ONPG does not absorb appreciably at 415 nm, and the small positive intercepts of the linear progress curves (Table A5) are the empirical measure of any residual mismatch.

{{TABLE:tableS_calibration_variants}}

**Table A8.** Calibration variants and their effect on V_max (K_m and K_i unchanged).

### 3.5 Kinetic models

Lineweaver–Burk by ordinary least squares (course method); unweighted nonlinear least squares of V₀ = V_max[S]/(K_m + [S]) on the velocity scale with the bounded "port" algorithm from a grid of starting values (a fit that runs to the K_m bound of 100 mM is reported as "no plateau within the tested range" rather than as a number); K_i = [I]/(K_m,app/K_m − 1) as in the manual; and three global models fitted to both series simultaneously: competitive, V = V_max[S]/(K_m(1 + [I]/K_i) + [S]); pure noncompetitive, V = V_max[S]/((K_m + [S])(1 + [I]/K_i)); mixed, V = V_max[S]/(K_m(1 + [I]/K_i) + [S](1 + [I]/K_i')). Competitive and noncompetitive have three parameters each, so their residual sums of squares compare directly; the mixed model nests both. No variance weights were used.

## 4. Primary results (reference dataset)

{{CAPTIONS}}

### 4.1 Calibration

{{TABLE:table2_onp_calibration}}

**Table A9.** ONP standard curve. λ_max = {{lambda_max}} nm (A = {{A_lmax|3}}; 410 to 420 nm within 2% of the maximum). Calibration over 5 standards: A₄₁₅ = {{eps|3}}[ONP] − {{eps_icpt_abs|3}}, R² = {{eps_r2|4}}, ε = {{eps|2}} ± {{eps_se|2}} A mM⁻¹ cm⁻¹ ({{eps_M|0}} M⁻¹ cm⁻¹). For comparison, ε ≈ 4.5 mM⁻¹ cm⁻¹ at 420 nm is the value used in Miller's classical assay in the same alkaline stop; at pH 7.0, where ONP is largely protonated, Juers et al. used 2.65 mM⁻¹ cm⁻¹ at 420 nm, which is not comparable with the alkaline value measured here.

### 4.2 Enzyme dilution

{{TABLE:table4_enzyme_dilution}}

**Table A10.** Enzyme dilution, reference (primary) with the experimental values alongside. Reference: proportional slope {{ed_slope_umol|3}} µmol min⁻¹ per unit relative enzyme, R² {{ed_r2|3}}; free intercept {{ed_free_icpt_umol|4}} µmol min⁻¹, p = {{ed_free_p|2}}; rate per unit enzyme {{ed_rpe_min|2}} (D) to {{ed_rpe_max|2}} (C). Experimental: R² {{ed_exp_r2|3}}, relative rates {{ed_exp_relrates}}. In both datasets the rate per unit enzyme is lowest for tube D (0.25); in the reference dataset tubes D and E gave nearly the same rate (relative rates {{e_rel_D|2}} and {{e_rel_E|2}} for enzyme 0.25 and 0.15). The trend is approximately, not exactly, proportional.

### 4.3 Substrate series and inhibition

{{TABLE:table_results_substrate}}

**Table A11.** Data-sheet view of the primary substrate series: absorbances, V₀ and reciprocals.

{{TABLE:table5_kinetic_parameters}}

{{TABLE:table5b_inhibition}}

**Table A12.** Primary kinetic parameters and inhibition analysis. The +IPTG Lineweaver–Burk intercept ({{lbI_icpt|2}} ± {{lbI_icpt_se|2}}) is poorly determined because the inhibited velocities halve with each halving of substrate from tube B downward (first-order behaviour) and only tube A hints at a plateau; the apparent V_max ({{lbI_Vmax|3}} µmol min⁻¹) therefore rests on extrapolation, and the nonlinear fit of the inhibited series alone runs to the K_m bound. A test of the intercept against zero says nothing about whether the two series share a V_max; the question is addressed by the model comparison in Table A13. The K_i that a noncompetitive interpretation would assign to the apparent V_max change ({{Ki_noncomp_lb|2}} mM) is listed for completeness.

{{TABLE:tableS9_global_fits}}

**Table A13.** Global fits to both series (12 points). Competitive: V_max = {{g_Vmax|3}} ± {{g_Vmax_se|3}} µmol min⁻¹, K_m = {{g_Km|3}} ± {{g_Km_se|3}} mM, K_i = {{g_Ki|3}} ± {{g_Ki_se|3}} mM, RSS {{g_rss|4}}, AIC {{g_aic|1}}. Pure noncompetitive (same number of parameters): K_i = {{gn_Ki|3}} mM, RSS {{gn_rss|4}} ({{gn_rss_ratio|1}} times larger), AIC {{gn_aic|1}} (ΔAIC = {{gn_daic|1}}). Mixed: the ES-binding constant K_i' ran to its upper bound ({{g_Kip|0}} mM), K_i = {{g_mixed_Ki|3}} mM, AIC {{g_mixed_aic|1}}, i.e. the mixed model reduces to the competitive one. The comparison favours the competitive mechanism, but with twelve single measurements and no inhibited plateau it cannot exclude a modest uncompetitive component, and the equal V_max of the competitive and mixed fits is a property of those models, not an independent observation.

{{TABLE:tableS5_substrate_depletion}}

**Table A14.** Substrate converted by 2 and 10 min, from A₄₁₅/(ε × 2/3) relative to nominal [ONPG]. Reference uninhibited tubes D to F reached only {{conv10_D|0}} to {{conv10_F|0}}% conversion by 10 min yet their rates fell to a few percent of the initial rate. Candidate explanations and the test each implies: substrate depletion (predicts a plateau at 100% conversion; observed about {{plateau_frac_E|0}}% in E and F); enzyme inactivation (excluded by tube A, same enzyme and session, linear to 10 min); late stopping of the first aliquot (lowers V₀ but cannot create a plateau); a lower-than-nominal effective ONPG concentration in the low tubes (would place the plateau at the true concentration; testable by reading the ONPG stock's own absorbance or by complete hydrolysis of an aliquot); a background absorbance unrelated to product (would appear as a non-zero intercept; the linear curves show intercepts of 0.00 to 0.06 A, too small to explain plateaus of 0.09 to 0.30 A). The experimental uninhibited D and E tubes, by contrast, reached {{sconv10_D|0}}% and {{sconv10_E|0}}% conversion and curved for the expected reason.

## 5. Secondary analysis: the experimental dataset

{{TABLE:tableS7_experimental_secondary}}

**Table A15.** Kinetics from our Part III printouts with the same rule and units (uninhibited E is a Tier-2 secant). With +IPTG tube B excluded, the nonlinear fits give K_m = {{s_nl_Km|3}} mM, V_max = {{s_nl_Vmax|3}} µmol min⁻¹, K_m,app = {{s_nl_Kmapp|3}} mM, V_max,app = {{s_nl_Vmaxapp|3}} (ratio {{s_nl_Vratio|2}}), K_i = {{s_nl_Ki|3}} mM: the textbook competitive pattern, with K_m near the literature 0.12 mM. The Lineweaver–Burk analysis of the same points is distorted by the three-point inhibited series (K_m,app {{s_lb_Kmapp|2}} mM, V_max,app {{s_lb_Vratio|2}} × V_max) and, if tube B is included, becomes meaningless (K_m,app = {{s_lb_Kmapp_withB|0}} mM).

{{TABLE:tableS8_experimental_vs_reference}}

**Table A16.** Tube-by-tube comparison. The standard tube agreed within 5% (enzyme dilution, {{r_e_A|2}}) and 15% (substrate series, {{r_u_A|2}}). Our uninhibited low-substrate tubes ran faster than the reference tubes (D: {{r_u_D|2}}) because they stayed linear longer, and our inhibited tubes C and D ran {{r_i_C|1}}- and {{r_i_D|1}}-fold faster; +IPTG tube B ran {{r_i_B|1}}-fold faster than the reference tube B and {{s_blackB_over_A|2}}-fold faster than our own tube A.

**+IPTG tube B.** The observation is that velocity increased when substrate halved at fixed enzyme and inhibitor, which no kinetic mechanism allows; the tube's nominal composition is therefore unverifiable. Its first four points are as linear as any in the dataset (R² 0.9999), so instrument error is unlikely. Hypotheses, in order of simplicity: IPTG omitted (the curve matches an uninhibited tube at high substrate), or a larger volume of ONPG or enzyme than intended. The 10-min value (1.106) is 46% of the increment the first four points predict and is consistent with the stop reagent added early or the aliquot mixed late; it is retained in the raw data and excluded from that tube's regression by the ordinary rule. The instrument clock stamps show the black set was read as a batch (04:20 to 04:33, order D, B, A, C), so read order carries no information about reaction order.

**+IPTG tube E.** Discarded before measurement; no value was estimated. The inhibited experimental series therefore rests on tubes A, C and D.

## 6. Sensitivity analysis

{{TABLE:tableS6_sensitivity}}

**Table A17.** Kinetic parameters from the reference dataset under five V₀ estimators. Regression on every curve (R) gives a {{R_icpt_sign}} uninhibited Lineweaver–Burk intercept, so K_m and V_max are undefined; all five points (A) give K_m = {{A_Km|1}} mM; the 0 to 2 min secant for every curve (S) gives K_m = {{S_Km|2}} mM but collapses K_m,app to {{S_Kmapp|2}} mM and raises K_i to {{S_Ki|2}} mM, because the secant inflates the low-signal inhibited tubes (positive intercepts of 0.006 to 0.014 A make the 2-min reading a poor origin-anchored estimate); the offset-corrected rule (O) raises K_m to {{O_Km|2}} mM (K_m,app {{O_Kmapp|2}} mM, ratio {{O_Km_ratio|1}}) and K_i to {{O_Ki|2}} mM. The two-tier rule (P) is the estimator that follows the manual's instruction (initial linear portion where one exists, earliest interval where none exists) and gives physically admissible parameters for both series; it was not chosen for the values it produces. Conclusions that survive every estimator: velocity saturates with substrate, and IPTG slows the enzyme progressively more as substrate falls. Conclusions that depend on the estimator: the numerical K_m ({{Km_min|2}} to {{Km_max|2}} mM among the rule-based estimators and the global fit) and, through it, K_i ({{Ki_min|2}} to {{Ki_max|2}} mM among those estimators; {{S_Ki|2}} mM under the uniform 0 to 2 min secant, which is biased upward for the inhibited tubes).

## 7. Limitations

Single measurements per condition (no replicate variance; quoted uncertainties are regression standard errors); manual 2-min sampling that cannot resolve the initial rate when it falls within the first interval, which affects five of six uninhibited reference tubes; a substrate range whose highest concentration (2.20 mM) is near the uninhibited K_m estimate and below the apparent K_m with IPTG, so the inhibited plateau was never reached and V_max,app is extrapolated; the origin assumption of the secant estimates, bounded but not removed by the offset test; read-out resolution of 0.001 A relative to increments of 0.005 A in the most dilute inhibited tubes; nominal ONPG concentrations that the plateaus of the low-substrate reference tubes suggest may have been lower than stated; room temperature uncontrolled; the experimental inhibited series reduced to three tubes by the loss of E and the anomaly in B; literature values measured for the purified enzyme in TES buffer with 145 mM NaCl at pH 7.0 and 25 °C by a continuous assay at 420 nm, so exact agreement is not expected.

## 8. Reproducibility

```bash
Rscript R/run_all.R
```

regenerates `data/processed/`, `tables/`, `figures/` and the three report sources from the raw files (R 4.3.3; tidyverse, broom, patchwork, scales, here; ragg optional; XeLaTeX for the PDF versions). Analysis settings live in `R/00_setup.R` (tolerances of the V₀ rule, the excluded experimental tube, the K_m bound). Session information of the last run is in `report/sessionInfo.txt`. Code and data: {{REPO}}. The course's original files and the instructor's e-mail are kept locally for the cross-check in `01_import_clean.R` but are not redistributed (permission not obtained); the scripts run without them.

## 9. References

See the reference list in `experiment_2_submission.md`. Literature comparison values: Juers et al. (2009) Protein Sci. 18, 1281-1292 (Table II, native enzyme: k_cat 620 s⁻¹, K_m 0.12 mM for oNPG; Table IV: K_i 0.08 mM for IPTG at 0.01 mM Mg²⁺ and ~150 mM NaCl; TES buffer, pH 7.0, 25 °C; ε(oNP) 2.65 mM⁻¹ cm⁻¹ at 420 nm, pH 7.0). The classical alkaline-stop assay and its extinction coefficient: Miller (1972) Experiments in Molecular Genetics, pp 352-355. Instrument specification: Thermo Fisher Scientific, GENESYS 10S Series UV-Visible Spectrophotometers brochure (photometric linear range up to 3.5 A at 260 nm; accuracy ± 0.005 A at 1.0 A).
