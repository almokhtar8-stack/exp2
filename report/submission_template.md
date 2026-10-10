# Kinetic characterisation of *Escherichia coli* β-galactosidase with ONPG and its inhibition by IPTG, determined by stopped-reaction spectrophotometry

**Experiment 2: Studying Enzyme Kinetics using Spectrophotometry**
Methods in Molecular and Cellular Biology, B241

Student: Almokhtar Aljarodi
Laboratory partner: Abdulrahman Khardali
Laboratory sessions: 7 September 2026 (Part II) and 11 September 2026 (Part III); report compiled {{DATE}}

## Summary

Enzyme kinetics condenses how an enzyme responds to substrate, inhibitors and its own abundance into two constants, K_m and V_max, the basis for understanding metabolism and enzyme-targeted drugs. *E. coli* β-galactosidase acting on *o*-nitrophenyl-β-D-galactopyranoside (ONPG) was characterised by following the yellow product *o*-nitrophenol (ONP) after stopping timed aliquots with Na₂CO₃. The primary kinetic analysis used a course-provided reference dataset; our own measurements were analysed separately. ONP absorbed maximally at {{lambda_max}} nm and obeyed the Beer–Lambert law to {{lin_max_mM|2}} mM (ε = {{eps|2}} mM⁻¹ cm⁻¹). Initial velocity rose approximately in proportion to enzyme concentration (R² = {{ed_r2|2}}). Over 0.069 to 2.20 mM ONPG the velocity approached saturation; the Lineweaver–Burk analysis gave K_m = {{lbU_Km|2}} mM and V_max = {{lbU_Vmax|2}} µmol min⁻¹ per assay. With 0.458 mM IPTG the apparent K_m rose {{Km_ratio_lb|1}}-fold to {{lbI_Km|2}} mM, inhibition grew as substrate fell, and a competitive model fitted both series better than a noncompetitive one, giving K_i = {{Ki_lb|2}} to {{Ki_max|2}} mM across rule-based initial-rate estimators. The behaviour is consistent with competitive inhibition by IPTG and with the K_i of 0.08 mM reported for the purified enzyme: a substrate analogue raises an enzyme's substrate requirement without destroying its catalytic capacity.

## Objectives

To determine whether the initial velocity of β-galactosidase is proportional to enzyme concentration, to measure K_m and V_max for ONPG hydrolysis, and to test whether IPTG inhibits the enzyme competitively by measuring its effect on the apparent K_m and V_max and deriving K_i.

## Introduction

Enzymes accelerate reactions by binding substrates at active sites, and the dependence of reaction velocity on substrate concentration reveals how tightly and how productively they do so. Michaelis and Menten described this dependence by postulating a reversible enzyme–substrate complex that breaks down to product, giving V₀ = V_max[S]/(K_m + [S]) (1, 2). V_max = k_cat[E]_T is the limiting velocity when every active site is occupied and is therefore proportional to the amount of enzyme; K_m is the substrate concentration at half-maximal velocity and reports how much substrate is needed to engage the enzyme. Lineweaver and Burk rearranged the equation to a straight line, 1/V₀ = (K_m/V_max)(1/[S]) + 1/V_max, whose intercepts give the two constants (3). The reciprocal transformation distorts the error structure of the data, so that estimates from it can be unreliable (4); it remains the standard teaching representation and is the method required here, and a direct fit of the untransformed data is used as a check.

β-Galactosidase (EC 3.2.1.23), the *lacZ* product of *Escherichia coli*, is a homotetramer of 1023-residue subunits that hydrolyses the β-1,4 glycosidic bond of lactose and of synthetic β-galactosides (5, 6). The chromogenic substrate ONPG is cleaved to galactose and *o*-nitrophenol. At alkaline pH *o*-nitrophenol exists as the yellow *o*-nitrophenolate anion, whose absorbance near 415 to 420 nm follows the Beer–Lambert law, A = εcl. Adding 1 M Na₂CO₃ to a timed aliquot therefore both stops the reaction, by raising the pH far above the enzyme's working range, and develops the colour, so one reading gives the product formed up to that moment (7). A series of stopped samples builds a progress curve whose initial slope is the initial velocity V₀, measured before substrate depletion, product accumulation or enzyme instability slow the reaction. Alternatives include continuous monitoring of ONP in a thermostatted cuvette, which resolves early curvature far better than 2-min sampling, or coupled assays that measure the released galactose; the stopped method was used here because it needs only a fixed-wavelength spectrophotometer.

Inhibitors reveal themselves by how they change K_m and V_max. A competitive inhibitor binds free enzyme at the active site and is displaced by substrate: it leaves V_max unchanged but raises the apparent Michaelis constant to K_m,app = K_m(1 + [I]/K_i), where K_i is the inhibitor's dissociation constant. A noncompetitive inhibitor inactivates a fraction of the enzyme whatever the substrate concentration, lowering V_max and leaving K_m unchanged (2). Isopropyl-β-D-thiogalactopyranoside (IPTG) is the thiogalactoside used as a gratuitous inducer of the *lac* operon because it induces the enzyme without being hydrolysed by it (8, 9). The same stability makes it a dead-end ligand of β-galactosidase: it occupies the galactose subsite of the active site but its thioglycosidic bond is not cleaved, so it is expected to behave as a competitive inhibitor with K_i of the order of 0.1 mM (6, 10). The kinetics matter biologically because the inducer of β-galactosidase also competes with its substrates, and because the same logic underlies competitive drugs such as statins and many antivirals.

In this experiment the ONP absorption spectrum and standard curve were established, the dependence of V₀ on enzyme concentration was measured at saturating ONPG, and V₀ was measured over a 32-fold range of ONPG concentrations with and without IPTG. Velocity scaled with enzyme, saturated with substrate, and was inhibited by IPTG in the pattern expected of competition for the active site.

## Experimental Procedure

All procedures followed the Experiment 2 laboratory manual (11) except for the modifications listed below. Z buffer (0.06 M Na₂HPO₄, 0.04 M NaH₂PO₄, 0.01 M KCl, 0.001 M MgSO₄, 0.05 M β-mercaptoethanol, pH 7.0), ONPG (1.0 mg mL⁻¹, 3.3 mM), IPTG (1.31 mg mL⁻¹, 5.5 mM), 1 mM ONP and 1 M Na₂CO₃ were provided, together with β-galactosidase standardised by the teaching staff to give A₄₁₅ = 1.20 to 1.30 after 10 min in the standard reaction. Reactions (12.0 mL, room temperature) were assembled as in the manual's tables with enzyme added last; 2.0 mL aliquots were stopped with 1.0 mL Na₂CO₃ at 2, 4, 6, 8 and 10 min and read at 415 nm against a Z-buffer blank in a GENESYS 10S UV-Vis spectrophotometer (1 cm path). Part I standards and the Part I blank contained Na₂CO₃ as specified in the manual.

**Datasets and modifications.** Two datasets were analysed: a course-provided reference dataset supplied by the laboratory instructor (Professor Samah Gadhoum; e-mail of 13 September 2026) and an experimental dataset collected by our laboratory group. The reference measurements (Part I spectrum, ONP standard curve and enzyme-dilution series; Part III substrate series with and without IPTG, tubes A to F) were used for the primary kinetic analysis in the Results, as instructed. Our experimental measurements (Part II tubes A to E on 7 September; Part III tubes A to E without IPTG and A to D with IPTG on 11 September; 14 instrument printouts) were analysed with the identical procedure and are examined in the Discussion for technical interpretation and troubleshooting; they are not combined with the reference measurements in any curve. The two labels describe origin and analytical role, not accuracy. Deviations from the manual in our own sessions: Part I was performed by the teaching staff; in Part III, tube F was not performed and the IPTG tube E was discarded before measurement. The reference standard-curve table lists seven readings (tubes 1 to 7, the first reading 0), whereas the manual describes a blank and seven standards; the instructor confirmed that the first reading is the zero-concentration point, and the mapping adopted for the remaining six readings is set out in the Results.

**Data analysis.** Concentrations were calculated from the stated stock concentrations and the manual's volumes ([ONPG] = 3.3 mM × V/12.0 mL; [IPTG] = 5.5 mM × 1.0/12.0 = 0.458 mM; ONP standards 1 mM × V/3.0 mL). The manual asks for V₀ from the initial linear portion of each progress curve, with the points used identified. One rule was applied to all {{n_curves_total}} curves: the least-squares line A₄₁₅ = a + bt was fitted to the 2, 4 and 6 min points and extended one point at a time while the next increment lay within {{REL_TOL_pct|0}}% (or {{ABS_TOL|3}} A, whichever larger) of the increment predicted by the current line; V₀ = b. When the second and third increments both fell below the first by more than this tolerance, the curve had no initial linear portion and V₀ was taken from the earliest available interval, the 0 to 2 min secant through the origin, flagged (†) as a lower-bound estimate. No reading exists at t = 0, so the secant assumes a zero absorbance offset; this assumption was tested against the intercepts of the curves that were linear and carried through a sensitivity analysis together with four alternative estimators (regression only, secant only, all five points, offset-corrected secant). The extinction coefficient was the slope of A₄₁₅ against [ONP] over the linear region chosen by the same increment rule. V₀ in ΔA₄₁₅ min⁻¹ was converted to µmol ONP min⁻¹ per assay as V₀/ε × 1.5 (the 2 mL aliquot was diluted with 1 mL stop reagent) × 12.0 mL (reaction volume); the manual's instruction to divide the slope by ε gives the cuvette rate in mM min⁻¹, and the two further factors convert it to an amount per minute. K_m and V_max were obtained from the Lineweaver–Burk regression as required (V_max = 1/intercept, K_m = slope × V_max) and checked by unweighted nonlinear least squares on the velocity scale; K_i was calculated from K_m,app = K_m(1 + [I]/K_i). Competitive, pure noncompetitive and mixed models were also fitted to both series simultaneously. All calculations were performed in R 4.3.3 with tidyverse (12); the scripts, raw data and outputs are in the {{REPO}}. Each condition was measured once, so the uncertainties quoted are regression standard errors, not replicate variability.

## Results

All values in this section are from the reference dataset: Part I to III measurements provided by the course (Prof. Samah Gadhoum, e-mail of 13 September 2026) for use in the Results. Our own measurements (experimental dataset, Table R1) are analysed in the Discussion.

**1. Absorbance spectrum of o-nitrophenol.** The spectrum of 0.333 mM ONP (manual tube 4: [ONP] = 1 mM × 1.0 mL/3.0 mL) peaked at {{lambda_max}} nm (A = {{A_lmax|3}}; Table 1, Figure 1A); 410 to 420 nm lay within 2% of the maximum, so 415 nm was used for all kinetic measurements.

**Table 1. Absorbance spectrum of 0.333 mM ONP in Z buffer/1 M Na₂CO₃ (2:1), read against the Z buffer/Na₂CO₃ blank (reference Part I).**

{{TABLE:table_r1_spectrum}}

**2. Standard curve of o-nitrophenol.** The reference table reported seven readings (Table 2): the first (0) is the zero-concentration preparation (2.0 mL Z buffer + 1.0 mL Na₂CO₃), as the instructor confirmed, and the other six are manual standards 1 to 6 in order, anchored by the spectrum tube (standard 4, {{A_lmax|3}} at 415 nm, identical to the fifth reading). Standard 7 (0.667 mM) has no reported reading; whether it was unprepared or unreported is unknown, and no value was assumed. Absorbance was linear for the five standards from 0.083 to 0.433 mM, A₄₁₅ = {{eps|3}}[ONP] − {{eps_icpt_abs|3}} (R² = {{eps_r2|4}}; Figure 1B), giving ε = {{eps|2}} ± {{eps_se|2}} A mM⁻¹ cm⁻¹ ({{eps_origin|2}} through the origin). The 0.533 mM standard (A = {{excl_A|2}}) lay {{excl_pct|0}}% above the line and was excluded; including it would give ε = {{eps_all6|2}} and lower every V_max by 13%, leaving K_m and K_i unchanged.

![Figure 1](../figures/figure1_onp_calibration.png)

**Figure 1. ONP absorbs maximally at 415 nm and obeys the Beer–Lambert law to 0.43 mM.** (A) Spectrum of 0.333 mM ONP; dashed line, maximum; shaded, within 2% of it. (B) Standard curve; filled points and line, calibration over the shaded range (equation in the text); ×, zero-concentration point (not fitted); open point, excluded 0.533 mM standard. Reference Part I data.

**Table 2. ONP standard curve at 415 nm (reference Part I): reported readings, their assignment to the manual's preparations, [ONP] in the 3.0 mL cuvette (1 mM × V/3.0 mL) and use in the fit.**

{{TABLE:table2_onp_calibration}}

**3. Enzyme dilution.** At 2.20 mM ONPG, product formation was linear over an initial window in every tube (Figure 2A; Table 3). V₀ fell from {{e_dA_A|3}} ΔA₄₁₅ min⁻¹ with undiluted enzyme to {{e_dA_E|4}} at 0.15 of that amount ({{ed_fold_rate|1}}-fold for a {{ed_fold_enzyme|1}}-fold dilution). Sample calculation, tube A: {{e_dA_A|3}}/{{eps|2}} = 0.0260 mM min⁻¹ in the cuvette, × 1.5 = 0.0391 mM min⁻¹ in the reaction, × 12.0 mL = {{e_umol_A|3}} µmol min⁻¹; relative rate of tube B = {{e_dA_B|4}}/{{e_dA_A|3}} = {{e_rel_B|2}}. The relative rates (Table 3) were approximately proportional to enzyme (V₀ = {{ed_slope_umol|3}} × E µmol min⁻¹ through the origin, R² = {{ed_r2|3}}; free intercept {{ed_free_icpt_umol|4}}, p = {{ed_free_p|2}}; Figure 2B), although the rate per unit enzyme ranged from {{ed_rpe_min|2}} (tube D) to {{ed_rpe_max|2}} (tube C), and tubes D and E gave nearly equal rates despite 1.7-fold more enzyme in D.

![Figure 2](../figures/figure2_enzyme_dilution.png)

**Figure 2. Initial velocity rose approximately in proportion to the amount of β-galactosidase.** (A) Progress curves, 2.20 mM ONPG, 1.00 to 0.15 relative enzyme (tubes A to E); lines, fits to the initial linear window (filled used, open excluded, dotted extrapolation). (B) V₀ against relative enzyme; solid, line through the origin (slope {{ed_slope_umol|3}} µmol min⁻¹, R² = {{ed_r2|2}}); dotted, free-intercept fit. n = 1 per tube; reference Part II data.

**Table 3. Enzyme dilution (reference Part II): A₄₁₅ of the stopped samples, points used, V₀ (ΔA₄₁₅ min⁻¹; µmol ONP min⁻¹ per assay, × {{k_umol|3}}), rate relative to tube A and rate per unit enzyme.**

{{TABLE:table_results_enzyme_dilution}}

**4. Michaelis–Menten kinetics without inhibitor.** Only the 2.20 mM tube remained linear to 10 min (V₀ = {{u_dA_A|3}} ΔA₄₁₅ min⁻¹); in tubes B to F the rate fell from the first interval onward, so V₀ is the 0 to 2 min secant, a lower bound (†; Figure 3A, Table 4). V₀ rose {{u_fold_AF|1}}-fold over the 32-fold substrate range and flattened above 1 mM (Figure 3B). Sample calculation, tube B: [S] = 3.3 mM × 4.0/12.0 = 1.10 mM; V₀ = {{u_dA_B|3}}/{{eps|2}} × 1.5 × 12.0 = {{u_umol_B|3}} µmol min⁻¹; 1/[S] = 0.909 mM⁻¹, 1/V₀ = 2.87 min µmol⁻¹. Lineweaver–Burk regression (Figure 4B): 1/V₀ = {{lbU_slope|3}}(1/[S]) + {{lbU_icpt|3}} (R² = {{lbU_r2|3}}), so V_max = 1/{{lbU_icpt|3}} = {{lbU_Vmax|3}} µmol min⁻¹ and K_m = {{lbU_slope|3}} × {{lbU_Vmax|3}} = {{lbU_Km|2}} mM; the nonlinear fit gave K_m = {{nlU_Km|2}} ± {{nlU_Km_se|2}} mM and V_max = {{nlU_Vmax|3}} ± {{nlU_Vmax_se|3}} µmol min⁻¹ (Table 5).

![Figure 3](../figures/figure3_substrate_saturation.png)

**Figure 3. β-Galactosidase approached saturation with ONPG.** (A) Progress curves, 2.20 to 0.069 mM ONPG (tubes A to F, no inhibitor); A, regression; B to F (†), 0 to 2 min secant (dashed) through the assumed origin (×), a lower bound; open points not used. (B) V₀ against [ONPG]; solid, nonlinear fit; dashed, Lineweaver–Burk hyperbola; ↑ lower bound. Reference Part III data.

**Table 4. Substrate series without and with 0.458 mM IPTG (reference Part III): A₄₁₅ of stopped samples, V₀ (ΔA₄₁₅ min⁻¹; µmol min⁻¹ per assay) and Lineweaver–Burk reciprocals (1/[S], mM⁻¹; 1/V₀, min µmol⁻¹). †, 0 to 2 min secant through the origin (lower bound); others, regression.**

{{TABLE:table_results_substrate}}

**5. Michaelis–Menten kinetics with IPTG.** With 0.458 mM IPTG every tube was slower, by {{inh_pct_A|0}}% at 2.20 mM ONPG and {{inh_pct_F|0}}% at 0.069 mM, so inhibition grew as substrate fell (Figure 4A). The Lineweaver–Burk line steepened {{lb_slope_ratio|1}}-fold, 1/V₀ = {{lbI_slope|2}}(1/[S]) + {{lbI_icpt|2}} (R² = {{lbI_r2|3}}; Figure 4B), giving K_m,app = {{lbI_Km|2}} mM ({{Km_ratio_lb|1}}-fold increase) and V_max,app = {{lbI_Vmax|3}} µmol min⁻¹ from an extrapolated intercept ({{lbI_icpt|2}} ± {{lbI_icpt_se|2}}). K_i = [I]/(K_m,app/K_m − 1) = 0.458/({{lbI_Km|2}}/{{lbU_Km|2}} − 1) = {{Ki_lb|3}} mM. A competitive model fitted to both series (shared V_max = {{g_Vmax|2}} ± {{g_Vmax_se|2}} µmol min⁻¹, K_m = {{g_Km|2}} ± {{g_Km_se|2}} mM, K_i = {{g_Ki|3}} ± {{g_Ki_se|3}} mM) left a residual sum of squares {{gn_rss_ratio|1}} times smaller than a noncompetitive model with the same number of parameters, and a mixed model reduced to it (Table 5).

![Figure 4](../figures/figure4_iptg_inhibition.png)

**Figure 4. IPTG raised the apparent K_m of β-galactosidase for ONPG.** (A) V₀ against [ONPG] without (circles) and with 0.458 mM IPTG (triangles); dashed, Lineweaver–Burk hyperbolae; solid, competitive model fitted to both series (shared V_max assumed); ↑ lower bound. (B) Lineweaver–Burk plot; x-intercepts −1/K_m = {{lbU_xint|2}}, −1/K_m,app = {{lbI_xint|2}} mM⁻¹. Reference Part III data.

**Table 5. Kinetic parameters (reference Part III; K_m, K_i in mM; V_max in µmol min⁻¹ per assay; ± SE of the fit) by Lineweaver–Burk (course method) and nonlinear fits; app., apparent (with IPTG); n.d., no plateau, not determinable; global fits share V_max (competitive) or K_m (noncompetitive) between the series; RSS, residual sum of squares.**

{{TABLE:table5_kinetic_parameters}}

## Discussion

The reference data show Michaelis–Menten behaviour: V₀ rose approximately in proportion to enzyme at saturating substrate (R² = {{ed_r2|2}}; rate per unit enzyme {{ed_rpe_min|2}} to {{ed_rpe_max|2}}), velocity saturated with substrate (K_m = {{lbU_Km|2}} to {{nlU_Km|2}} mM, V_max ≈ {{lbU_Vmax|2}} µmol min⁻¹), and IPTG raised the apparent K_m {{Km_ratio_lb|1}}-fold while inhibiting most at low substrate. A competitive model fitted both series {{gn_rss_ratio|1}}-fold better (residual sum of squares) than a noncompetitive one, so the behaviour is consistent with competitive inhibition but does not prove it: the inhibited series never approached saturation, so V_max,app ({{lbI_Vmax|2}} µmol min⁻¹) rests on an extrapolated intercept and cannot show whether V_max changed, and the shared V_max of the global fit is a model assumption. K_i is model- and estimator-dependent ({{Ki_lb|2}} mM by Lineweaver–Burk, {{g_Ki|2}} mM by the global fit, {{O_Ki|2}} mM with secants corrected for the median t = 0 offset of {{off_median|3}} A, and {{S_Ki|2}} mM if every curve is reduced to its 0 to 2 min secant, an estimator biased upward for the inhibited tubes), so it is known only to within a factor of two to five; the 0.08 mM for purified enzyme (TES buffer, 145 mM NaCl, pH 7.0, 25 °C) (10) is of the same order under different conditions. K_m ({{lbU_Km|2}} to {{O_Km|2}} mM) exceeds the literature 0.12 mM (10) because five of six uninhibited V₀ are lower bounds from tubes that decelerated within the first 2 min, which inflates 1/V₀ at low [S]; 2-min sampling, not the enzyme, limits this estimate. Those curves flattened at about {{plateau_frac_E|0}}% of the nominal yield (tubes E, F) although depletion predicts 100%, the same enzyme stayed linear in tube A and timing errors cannot create plateaus; a lower-than-nominal effective ONPG concentration in those tubes is the untested explanation.

Our own measurements, analysed identically, reproduced the pattern (standard tube A within 5 to 15% of the reference; K_m = {{s_nl_Km|2}} mM, raised {{s_nl_Kratio|1}}-fold by IPTG with V_max unchanged, ratio {{s_nl_Vratio|2}}; K_i = {{s_nl_Ki|3}} mM). Two tubes deviated. IPTG tube B (nominally 1.10 mM ONPG) ran {{s_blackB_over_A|2}}-fold faster than tube A at half the substrate, impossible at fixed enzyme; its profile matches an uninhibited high-substrate tube (IPTG omitted, or ONPG or enzyme over-pipetted, as hypotheses) and its 10-min value suggests a mistimed stop; it is retained as recorded but excluded from the fits (included, K_m,app = {{s_lb_Kmapp_withB|0}} mM). IPTG tube E was discarded before measurement. Improvements: 30-s sampling in the first 2 min, ONPG from 0.03 to above 2 mM, duplicate tubes, and spectrophotometric verification of the ONPG stock. Biologically, the *lac* inducer competes with substrates at the active site of the enzyme it induces, as competitive drugs do. The objectives were met: velocity was approximately proportional to enzyme, K_m and V_max were determined, and IPTG behaved consistently with competitive inhibition, K_i ≈ 0.1 to 0.2 mM by the rule-based estimators.

## References

1. Michaelis, L., and Menten, M. L. (1913) Die Kinetik der Invertinwirkung, Biochem. Z. 49, 333-369.
2. Johnson, K. A., and Goody, R. S. (2011) The original Michaelis constant: translation of the 1913 Michaelis-Menten paper, Biochemistry 50, 8264-8269.
3. Lineweaver, H., and Burk, D. (1934) The determination of enzyme dissociation constants, J. Am. Chem. Soc. 56, 658-666.
4. Dowd, J. E., and Riggs, D. S. (1965) A comparison of estimates of Michaelis-Menten kinetic constants from various linear transformations, J. Biol. Chem. 240, 863-869.
5. Jacobson, R. H., Zhang, X.-J., DuBose, R. F., and Matthews, B. W. (1994) Three-dimensional structure of β-galactosidase from E. coli, Nature 369, 761-766.
6. Juers, D. H., Heightman, T. D., Vasella, A., McCarter, J. D., Mackenzie, L., Withers, S. G., and Matthews, B. W. (2001) A structural view of the action of Escherichia coli (lacZ) β-galactosidase, Biochemistry 40, 14781-14794.
7. Miller, J. H. (1972) Experiments in Molecular Genetics, pp 352-355, Cold Spring Harbor Laboratory, Cold Spring Harbor, NY.
8. Jacob, F., and Monod, J. (1961) Genetic regulatory mechanisms in the synthesis of proteins, J. Mol. Biol. 3, 318-356.
9. Herzenberg, L. A. (1959) Studies on the induction of β-galactosidase in a cryptic strain of Escherichia coli, Biochim. Biophys. Acta 31, 525-538.
10. Juers, D. H., Rob, B., Dugdale, M. L., Rahimzadeh, N., Giang, C., Lee, M., Matthews, B. W., and Huber, R. E. (2009) Direct and indirect roles of His-418 in metal binding and in the activity of β-galactosidase (E. coli), Protein Sci. 18, 1281-1292.
11. Biological and Environmental Science and Engineering Division, KAUST. (2026) Methods in Molecular and Cellular Biology B241 Laboratory Manual, Experiment 2: Studying Enzyme Kinetics using Spectrophotometry, pp 1-19.
12. Wickham, H., Averick, M., Bryan, J., Chang, W., McGowan, L. D., François, R., Grolemund, G., Hayes, A., Henry, L., Hester, J., Kuhn, M., Pedersen, T. L., Miller, E., Bache, S. M., Müller, K., Ooms, J., Robinson, D., Seidel, D. P., Spinu, V., Takahashi, K., Vaughan, D., Wilke, C., Woo, K., and Yutani, H. (2019) Welcome to the tidyverse, J. Open Source Softw. 4, 1686.

## VII. Questions – Answer on this form and submit with your lab report

*Michaelis-Menten Kinetics*

**1. Sketch by hand a typical enzyme kinetic curve of [S] versus V. The maximum [S] should be about 4 times the Km. Draw lines at [S]=Km and V=Vmax. Make sure you get the slope at the origin ([S]=0) correct. Draw the asymptote (tangent line) at [S]=0.**

[HAND-DRAWN SKETCH TO BE INSERTED HERE. The computer-drawn diagram below (Figure Q1) is a reference for the drawing, not the submitted sketch.]

![Figure Q1](../figures/supplementary/figureQ1_michaelis_menten_sketch.png)

Reference for the sketch: the curve is the hyperbola V = Vmax[S]/(Km + [S]). It leaves the origin with slope Vmax/Km (the first-order region, V ≈ (Vmax/Km)[S]), passes V = Vmax/2 at [S] = Km, and bends towards the asymptote V = Vmax, reaching 0.8 Vmax at [S] = 4 Km; the tangent at the origin meets the line V = Vmax at [S] = Km.

**2. What effect does altering Km have on Vmax?**

None. Vmax = kcat[E]T depends on the turnover number and the amount of enzyme; Km only moves the curve along the [S] axis (a mutation may change both constants, but that is two changes, not a consequence of one).

**3. What effect does altering [E] have on Km? Vmax?**

Km is unchanged, because it is a ratio of rate constants for the enzyme–substrate pair; Vmax changes in proportion to [E], as Figure 2 shows at 2.20 mM ONPG ({{ed_fold_rate|1}}-fold for a 6.7-fold dilution, approximately proportional).

**4. At what concentration of [S] is the initial velocity proportional to [E]?**

At every [S], provided [E] is much smaller than [S] so that the steady state holds: V₀ = kcat[E][S]/(Km + [S]) is linear in [E] for any fixed [S]. The proportionality constant depends on [S], so enzyme is assayed at saturating substrate ([S] much greater than Km), where V₀ ≈ Vmax = kcat[E] and small errors in [S] do not matter; that is why Part II used 2.20 mM ONPG.

*Competitive Inhibition*

**5. What effect does increasing [I] have on the apparent Vmax and Km?**

Apparent Vmax is unchanged, because sufficient substrate displaces the inhibitor; apparent Km increases linearly with [I], Km,app = Km(1 + [I]/Ki). Here 0.458 mM IPTG raised the apparent Km {{Km_ratio_lb|1}}-fold.

**6. What is the effect on the Km (apparent) when [I] = Ki; when [I] = 2Ki?**

Km,app = 2 Km when [I] = Ki and 3 Km when [I] = 2 Ki. (The observed {{Km_ratio_lb|1}}-fold increase corresponds to [I]/Ki = {{Km_ratio_lb|1}} − 1 = 4.6, i.e. Ki = 0.458/4.6 = {{Ki_lb|3}} mM.)

*Non-competitive Inhibition*

**7. What effect does increasing [I] have on the apparent Vmax and Km?**

Apparent Vmax falls as Vmax/(1 + [I]/Ki), because the inhibitor removes active enzyme regardless of [S]; apparent Km is unchanged, because the inhibitor binds E and ES equally and does not alter substrate affinity.

**8. What is the effect on Vmax when [I] = Ki; [I] = 9 Ki?**

Vmax,app = Vmax/2 when [I] = Ki and Vmax/10 when [I] = 9 Ki.

**9. Can you distinguish noncompetitive from competitive inhibition using just the activity at low substrate concentrations? (i.e. the slope of V versus [S] at the origin?) Why or why not? How much does the slope change?**

No. At low [S] the slope is Vmax,app/Km,app. For competitive inhibition it is Vmax/[Km(1 + [I]/Ki)]; for noncompetitive inhibition it is [Vmax/(1 + [I]/Ki)]/Km. Both equal (Vmax/Km)/(1 + [I]/Ki), so the slope falls by the same factor 1/(1 + [I]/Ki) in both cases (halved at [I] = Ki; to about one sixth at the [I]/Ki ≈ 4.6 of this experiment). The two mechanisms differ only near saturation, where the competitive curve recovers Vmax and the noncompetitive one does not.

**10. Given a series of enzyme preparations with differing activities, how can you distinguish between the presence of an inhibitor and varying amounts of the active enzyme? Explain, considering both competitive and non-competitive inhibitors.**

Measure full V₀ versus [S] curves rather than single activities. Different amounts of active enzyme change Vmax in proportion and leave Km identical (Lineweaver–Burk lines share the x-intercept). A competitive inhibitor leaves Vmax and raises Km (lines share the y-intercept), which cannot be mimicked by enzyme amount. A noncompetitive inhibitor lowers Vmax at constant Km and so mimics less enzyme kinetically; to separate the two, dilute the preparation and re-assay (a reversible inhibitor's effect weakens as [I] falls, so specific activity rises, whereas a true enzyme difference gives constant specific activity), mix preparations (activities of inhibitor-free preparations add; an inhibitor makes the mixture sub-additive), remove small molecules by dialysis or gel filtration, or measure enzyme independently (protein assay, immunoblot or active-site titration with a tight-binding ligand such as PETG).

## Flow Sheet

[Attach the flow sheet prepared before the laboratory session and signed by the TA at the start of the lab period, 2 pages maximum. Required content: reagent preparation (Z buffer, 3.3 mM ONPG, 5.5 mM IPTG, 1 mM ONP, 1 M Na₂CO₃); assembly of 12.0 mL reactions in the manual's volumes with enzyme added last; timer start; 2.0 mL aliquots into tubes labelled 2, 4, 6, 8, 10; stop with 1.0 mL Na₂CO₃ at the labelled minute; read A₄₁₅ against Z buffer. If the signed original is unavailable, the loss of marks stated in the course manual applies; no signature is reproduced here.]

## Raw Data

Our own instrument printouts (GENESYS 10S UV-Vis; 14 photographs, transcribed and verified value by value; Table R1) are appended below. The TA's signature must be added to the originals. The course-provided reference measurements used in the Results are reproduced as received in Tables 1 to 4 and in the accompanying repository (`data/raw/reference/`, transcribed from the course's .docx and .pptx files and cross-checked against them); our printout data are in `data/raw/experimental/` and the photographs in `report/raw_data_printouts/`. `Rscript R/run_all.R` regenerates every table, figure and number in this report. Data and code availability: {{REPO}}.

**Table R1. Transcribed absorbance values from our printouts (experimental dataset; A₄₁₅ of stopped samples; NA = sample discarded before measurement; Part III + IPTG tube B 10 min = 1.106 retained as read). Printout labels: Day 1 = Part II (7 Sep 2026); Day 2 Blue = Part III without IPTG; Day 2 Black = Part III with IPTG (11 Sep 2026).**

{{TABLE:tableS2_experimental_raw_absorbance}}

Day 1 (7 Sep 2026, Part II, tubes A to E):

![Day 1 A](raw_data_printouts/Day1_A.jpeg) ![Day 1 B](raw_data_printouts/Day1_B.jpeg) ![Day 1 C](raw_data_printouts/Day1_C.jpeg) ![Day 1 D](raw_data_printouts/Day1_D.jpeg) ![Day 1 E](raw_data_printouts/Day1_E.jpeg)

Day 2 (11 Sep 2026, Part III without IPTG, blue labels, tubes A to E):

![Blue A](raw_data_printouts/Day2_Blue_A.jpeg) ![Blue B](raw_data_printouts/Day2_Blue_B.jpeg) ![Blue C](raw_data_printouts/Day2_Blue_C.jpeg) ![Blue D](raw_data_printouts/Day2_Blue_D.jpeg) ![Blue E](raw_data_printouts/Day2_Blue_E.jpeg)

Day 2 (11 Sep 2026, Part III with IPTG, black labels, tubes A to D; tube E discarded before measurement):

![Black A](raw_data_printouts/Day2_Black_A.jpeg) ![Black B](raw_data_printouts/Day2_Black_B.jpeg) ![Black C](raw_data_printouts/Day2_Black_C.jpeg) ![Black D](raw_data_printouts/Day2_Black_D.jpeg)
