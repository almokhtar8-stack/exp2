# 07b_supplementary_figures.R
# Supplementary figures:
#   S1  experimental progress curves beside the reference curves, same axes
#   S2  increment diagnostics behind every V0 window decision
#   S3  sensitivity of Km, Km,app and Ki to the V0 estimator (reference dataset)
#   S4  Michaelis-Menten analysis of the experimental dataset and tube-by-tube comparison
#   Q1  Michaelis-Menten diagram for Question 1 (schematic, Km = Vmax = 1)
# and figures/README.md with captions for all figures, filled from the results.
source(here::here("R", "00_setup.R"))
theme_set(theme_nebula_science(base_size = 10))

tidy  <- read_csv(file.path(dir_proc, "absorbance_tidy.csv"), show_col_types = FALSE)
fits  <- read_csv(file.path(dir_proc, "progress_curve_fits.csv"), show_col_types = FALSE)
v0s   <- read_csv(file.path(dir_proc, "v0_scenarios.csv"), show_col_types = FALSE)
sens  <- read_csv(file.path(dir_proc, "sensitivity_analysis.csv"), show_col_types = FALSE)
expk  <- read_csv(file.path(dir_proc, "experimental_secondary_kinetics.csv"), show_col_types = FALSE)
cmp   <- read_csv(file.path(dir_proc, "experimental_vs_reference_v0.csv"), show_col_types = FALSE)
depl  <- read_csv(file.path(dir_proc, "depletion_estimates.csv"), show_col_types = FALSE)
vals  <- read_csv(file.path(dir_fig, "main_figure_values.csv"), show_col_types = FALSE)
calib <- read_csv(file.path(dir_proc, "onp_calibration.csv"), show_col_types = FALSE)
glob  <- read_csv(file.path(dir_proc, "global_fits.csv"), show_col_types = FALSE)
offs  <- read_csv(file.path(dir_proc, "origin_offset_scenario.csv"), show_col_types = FALSE)
V <- function(n) vals$value[vals$name == n]
eps <- V("eps"); I_mM <- V("I_mM"); PRIMARY <- "P: two-tier rule (primary)"
lab_A415 <- "Absorbance at 415 nm (stopped sample)"
lab_V0u  <- expression("Initial reaction rate, "*italic(V)[0]~"("*mu*mol~min^-1*")")

# S1: experimental versus reference progress curves ------------------------------------------------
obs <- tidy |> filter(measured) |>
  left_join(fits |> select(dataset, tube, origin_assumed, slope, intercept, t_last, V0_dA415_per_min), by = c("dataset", "tube")) |>
  mutate(used = if_else(origin_assumed, time_min == 2, time_min <= t_last),
         role_label = factor(ROLE_LABELS[data_role], levels = ROLE_LABELS),
         condition = factor(condition, levels = c("enzyme_dilution", "mm_no_inhibitor", "mm_plus_iptg"), labels = CONDITION_LABELS[1:3]))
segs <- fits |> filter(n_used > 0) |>
  mutate(x0 = if_else(origin_assumed, 0, t_first), x1 = if_else(origin_assumed, 2, t_last),
         y0 = if_else(origin_assumed, 0, intercept + slope * t_first), y1 = if_else(origin_assumed, V0_dA415_per_min * 2, intercept + slope * t_last),
         role_label = factor(ROLE_LABELS[data_role], levels = ROLE_LABELS),
         condition = factor(condition, levels = c("enzyme_dilution", "mm_no_inhibitor", "mm_plus_iptg"), labels = CONDITION_LABELS[1:3]))
notes <- tibble(role_label = factor(ROLE_LABELS[["experimental"]], levels = ROLE_LABELS),
                condition = factor(CONDITION_LABELS[c("mm_no_inhibitor", "mm_plus_iptg")], levels = levels(obs$condition)),
                label = c("Tube F not performed", "Tube B: faster than A at half the nominal [ONPG]\n(open: excluded 10-min point)\nTube E: discarded before measurement\nTube F not performed"))
pS1 <- ggplot() +
  geom_segment(data = segs |> filter(!origin_assumed), aes(x = x0, xend = x1, y = y0, yend = y1, colour = tube), linewidth = 0.6, show.legend = FALSE) +
  geom_segment(data = segs |> filter(origin_assumed), aes(x = x0, xend = x1, y = y0, yend = y1, colour = tube), linewidth = 0.6, linetype = "22", show.legend = FALSE) +
  geom_line(data = obs, aes(time_min, absorbance_415nm, colour = tube, group = tube), linewidth = 0.3, alpha = 0.5) +
  geom_point(data = obs |> filter(!used), aes(time_min, absorbance_415nm, colour = tube, shape = tube), fill = "white", size = 1.8, stroke = 0.6) +
  geom_point(data = obs |> filter(used), aes(time_min, absorbance_415nm, colour = tube, shape = tube, fill = tube), size = 1.9, stroke = 0.4) +
  geom_text(data = notes, aes(x = 0.2, y = 1.42, label = label), hjust = 0, vjust = 1, size = 2.3, lineheight = 0.9, family = FIG_FONT, colour = nebula[["grey"]]) +
  facet_grid(condition ~ role_label, switch = "y") +
  scale_colour_manual(values = TUBE_COLOURS, name = "Tube", guide = guide_legend(override.aes = list(fill = TUBE_COLOURS, shape = TUBE_SHAPES))) +
  scale_shape_manual(values = TUBE_SHAPES, name = "Tube") + scale_fill_manual(values = TUBE_COLOURS, guide = "none") +
  scale_x_continuous(breaks = seq(0, 10, 2), limits = c(0, 10.5)) + scale_y_continuous(limits = c(0, 1.45), breaks = seq(0, 1.4, 0.35)) +
  labs(title = "Figure S1   Progress curves of the two datasets on common axes",
       subtitle = "Solid segments: regression windows used for V₀; dashed: origin-assumed 0–2 min average rate (no reading at t = 0); open: not used for V₀",
       x = "Time (min)", y = lab_A415) +
  theme(strip.placement = "outside", strip.text.y.left = element_text(angle = 90), legend.position = "right", panel.spacing = unit(8, "pt"))
save_figure(pS1, "figureS1_experimental_vs_reference_curves", 7.4, 8.0, dir = dir_supp)

# S2: increment diagnostics --------------------------------------------------------------------------
rho <- obs |> group_by(dataset, tube) |> arrange(time_min, .by_group = TRUE) |>
  mutate(rho = (absorbance_415nm - lag(absorbance_415nm)) / (V0_dA415_per_min * 2)) |> filter(!is.na(rho)) |> ungroup() |>
  mutate(panel = factor(dataset, levels = c("Reference Part II", "Reference Part III (-IPTG)", "Reference Part III (+IPTG)",
                                            "Experimental Part II", "Experimental Part III (-IPTG)", "Experimental Part III (+IPTG)"),
                        labels = c("Reference: enzyme dilution", "Reference: ONPG, no IPTG", "Reference: ONPG + IPTG",
                                   "Experimental: enzyme dilution", "Experimental: ONPG, no IPTG", "Experimental: ONPG + IPTG")))
pS2 <- ggplot(rho, aes(time_min, rho)) +
  annotate("rect", xmin = 3, xmax = 11, ymin = 1 - REL_TOL, ymax = 1 + REL_TOL, fill = nebula[["mist"]]) +
  geom_hline(yintercept = 1, colour = nebula[["grey"]], linewidth = 0.4) +
  geom_line(aes(group = tube, colour = tube), linewidth = 0.35, alpha = 0.6) +
  geom_point(data = rho |> filter(!used), aes(colour = tube, shape = tube), fill = "white", size = 1.9, stroke = 0.7) +
  geom_point(data = rho |> filter(used), aes(colour = tube, shape = tube, fill = tube), size = 1.9, stroke = 0.4) +
  facet_wrap(~ panel, nrow = 2) +
  scale_colour_manual(values = TUBE_COLOURS, name = "Tube", guide = guide_legend(override.aes = list(fill = TUBE_COLOURS, shape = TUBE_SHAPES))) +
  scale_shape_manual(values = TUBE_SHAPES, name = "Tube") + scale_fill_manual(values = TUBE_COLOURS, guide = "none") +
  scale_x_continuous(breaks = c(4, 6, 8, 10), limits = c(3, 11), labels = c("2–4", "4–6", "6–8", "8–10")) +
  scale_y_continuous(limits = c(0, 2.6), breaks = seq(0, 2.5, 0.5)) +
  labs(title = "Figure S2   Successive 2-min increments relative to the fitted initial velocity",
       subtitle = sprintf("Increment / (V₀ × 2 min); shaded: ±%.0f%% tolerance of the window rule (or ±%.3f A); open: intervals not used for V₀\nFor origin-assumed curves V₀ is the 0–2 min average rate, so every later interval falls below 1", 100 * REL_TOL, ABS_TOL),
       x = "Interval (min)", y = "Increment / (V₀ × 2 min)")
save_figure(pS2, "figureS2_increment_diagnostics", 7.4, 5.0, dir = dir_supp)

# S3: sensitivity to the V0 estimator (reference dataset) ----------------------------------------------
sl <- sens |> mutate(code = str_sub(estimator, 1, 1),
                     method_short = recode(method, `Lineweaver-Burk` = "Lineweaver-Burk", `Nonlinear MM` = "Nonlinear MM", `Global nonlinear competitive` = "Global competitive")) |>
  select(code, method_short, `Km (mM)` = Km, `Km,app (mM)` = Km_app, `Ki (mM)` = Ki_competitive) |>
  pivot_longer(-c(code, method_short), names_to = "parameter", values_to = "value") |>
  mutate(parameter = factor(parameter, levels = c("Km (mM)", "Km,app (mM)", "Ki (mM)")),
         code = factor(code, levels = c("A", "R", "S", "O", "P")), sign = if_else(value > 0, "positive", "non-physical (negative)"))
lit <- tibble(parameter = factor(c("Km (mM)", "Ki (mM)"), levels = levels(sl$parameter)), value = c(0.12, 0.08),
              label = c("purified enzyme: 0.12", "purified enzyme: 0.08"))
pS3 <- ggplot(sl |> filter(sign == "positive"), aes(value, code)) +
  geom_vline(data = lit, aes(xintercept = value), colour = nebula[["cyan"]], linewidth = 0.7) +
  geom_text(data = lit |> mutate(code = factor("P", levels = levels(sl$code))), aes(x = value, y = code, label = label), colour = nebula[["cyan"]], size = 2.5, hjust = -0.05, nudge_y = 0.55, family = FIG_FONT) +
  geom_point(aes(shape = method_short, colour = method_short), size = 2.8, stroke = 0.8, fill = "white") +
  geom_text(data = sl |> filter(sign != "positive") |> distinct(code, parameter, method_short), aes(x = 0.03, y = code, label = "LB: negative\n(non-physical)"), hjust = 0, size = 2.2, lineheight = 0.85, colour = nebula[["rose"]], family = FIG_FONT) +
  facet_wrap(~ parameter, scales = "free_x", nrow = 1) +
  scale_x_log10(labels = label_number(accuracy = 0.01), expand = expansion(mult = 0.15)) +
  scale_y_discrete(limits = levels(sl$code), labels = c(A = "A: all five points", R = "R: regression only", S = "S: 0–2 min average rate, all curves", O = "O: rule, baseline-offset scenario", P = "P: two-tier rule (used)")) +
  scale_shape_manual(values = c(`Lineweaver-Burk` = 21, `Nonlinear MM` = 24, `Global competitive` = 23), name = NULL) +
  scale_colour_manual(values = c(`Lineweaver-Burk` = nebula[["violet"]], `Nonlinear MM` = nebula[["vermilion"]], `Global competitive` = nebula[["blue"]]), name = NULL) +
  coord_cartesian(clip = "off") +
  labs(title = "Figure S3   Kinetic parameters of the reference dataset under five V₀ estimators",
       subtitle = "Log scale. Nonlinear fits of the inhibited series ran to the Kₘ bound (no plateau within 0.069–2.2 mM): no Kₘ,app or Kᵢ for that method\nCyan: values for purified E. coli β-galactosidase (TES buffer, pH 7.0, 25 °C)",
       x = "Value (mM)", y = NULL) + theme(legend.position = "right")
save_figure(pS3, "figureS3_estimator_sensitivity", 7.4, 3.2, dir = dir_supp)

# S4: experimental dataset kinetics and tube-by-tube ratios ------------------------------------------------
sp <- v0s |> filter(data_role == "experimental", estimator == PRIMARY) |>
  mutate(excluded = condition == "mm_plus_iptg" & tube %in% EXPERIMENTAL_EXCLUDE_FROM_FIT$tube, condition = factor(condition, levels = names(COND_LABELS)))
su <- expk |> filter(tube_B == "excluded")
lbU <- su |> filter(method == "Lineweaver-Burk"); nlU <- su |> filter(method == "Nonlinear MM")
Sg <- tibble(S = seq(0.001, 2.35, length.out = 300))
curS <- bind_rows(Sg |> mutate(condition = "mm_no_inhibitor", V = nlU$Vmax * S / (nlU$Km + S)),
                  Sg |> mutate(condition = "mm_plus_iptg",    V = nlU$Vmax_app * S / (nlU$Km_app + S))) |> mutate(condition = factor(condition, levels = names(COND_LABELS)))
pS4a <- ggplot() +
  geom_line(data = curS, aes(S, V, colour = condition), linewidth = 0.85) +
  geom_point(data = sp |> filter(excluded), aes(onpg_mM, V0_umol_per_min_assay, colour = condition, shape = condition), fill = "white", size = 2.7, stroke = 0.9, show.legend = FALSE) +
  geom_point(data = sp |> filter(!excluded), aes(onpg_mM, V0_umol_per_min_assay, colour = condition, shape = condition, fill = condition), size = 2.7, stroke = 0.55) +
  geom_text(data = sp, aes(onpg_mM, V0_umol_per_min_assay, label = paste0(tube, ifelse(origin_assumed, "†", ""))), nudge_y = ifelse(sp$condition == "mm_no_inhibitor", 0.03, -0.03), nudge_x = 0.05, size = 2.6, family = FIG_FONT) +
  scale_colour_manual(values = COND_COLOURS, labels = COND_LABELS, name = NULL, guide = guide_legend(override.aes = list(fill = COND_COLOURS, shape = COND_SHAPES))) +
  scale_shape_manual(values = COND_SHAPES, guide = "none") + scale_fill_manual(values = COND_COLOURS, guide = "none") +
  scale_x_continuous(limits = c(0, 2.35), breaks = c(0, 0.55, 1.1, 1.65, 2.2), expand = expansion(mult = c(0, 0.01))) +
  scale_y_continuous(limits = c(0, 0.62), breaks = seq(0, 0.6, 0.1), expand = expansion(mult = c(0, 0.01))) +
  labs(title = "A   Experimental dataset, Michaelis–Menten", subtitle = "Nonlinear fits; open symbol: +IPTG tube B, excluded\nfrom the fits; † origin-assumed 0–2 min estimate",
       x = "ONPG concentration (mM)", y = lab_V0u) + theme(legend.position = c(0.98, 0.02), legend.justification = c(1, 0))
cmp2 <- cmp |> filter(!is.na(ratio_experimental_over_reference)) |>
  mutate(condition = factor(condition, levels = c("enzyme_dilution", "mm_no_inhibitor", "mm_plus_iptg"), labels = c("Enzyme dilution", "ONPG, no IPTG", "ONPG + IPTG")),
         flag = case_when(condition == "ONPG + IPTG" & tube == "B" ~ "anomalous", TRUE ~ "ok"))
pS4b <- ggplot(cmp2, aes(tube, ratio_experimental_over_reference, fill = condition)) +
  geom_hline(yintercept = 1, colour = nebula[["grey"]], linewidth = 0.4) +
  geom_col(aes(alpha = flag), colour = NA, width = 0.7, position = position_dodge(width = 0.8)) +
  geom_text(aes(label = sprintf("%.2f", ratio_experimental_over_reference), y = ratio_experimental_over_reference + 0.08), position = position_dodge(width = 0.8), size = 2.4, family = FIG_FONT, vjust = 0) +
  scale_fill_manual(values = c(`Enzyme dilution` = nebula[["violet"]], `ONPG, no IPTG` = nebula[["blue"]], `ONPG + IPTG` = nebula[["vermilion"]]), name = NULL) +
  scale_alpha_manual(values = c(ok = 1, anomalous = 0.35), guide = "none") +
  scale_y_continuous(limits = c(0, 4.1), breaks = seq(0, 4, 1), expand = expansion(mult = c(0, 0.02))) +
  labs(title = "B   Experimental / reference V₀ by tube", subtitle = "1 = identical rate; faded: anomalous +IPTG tube B\nF and +IPTG E have no experimental value",
       x = "Tube", y = "V₀ experimental / V₀ reference") + theme(legend.position = c(0.98, 0.98), legend.justification = c(1, 1))
save_figure(pS4a + pS4b + plot_layout(widths = c(1.15, 1)), "figureS4_experimental_kinetics", 7.4, 3.4, dir = dir_supp)

# Q1 diagram: the Michaelis-Menten curve asked for in Question 1, drawn at its printed size ---------------------
# (4.6 x 2.9 in; type 7.5-9 pt). Everything the question asks for is marked: V = Vmax[S]/(Km + [S])
# to [S] = 4 Km, the asymptote V = Vmax, the point ([S] = Km, V = Vmax/2), the tangent at the
# origin with slope Vmax/Km meeting V = Vmax at [S] = Km, and V(4 Km) = 0.8 Vmax.
Km_s <- 1; Vmax_s <- 1
q <- tibble(S = seq(0, 4 * Km_s, length.out = 400), V = Vmax_s * S / (Km_s + S))
marks <- tibble(S = c(Km_s, 4 * Km_s, Km_s), V = c(Vmax_s / 2, 0.8 * Vmax_s, Vmax_s))
qs <- function(pt) pt / .pt
figQ1 <- ggplot(q, aes(S, V)) +
  geom_hline(yintercept = Vmax_s, colour = nebula[["grey"]], linetype = "dashed", linewidth = 0.4) +
  geom_hline(yintercept = Vmax_s / 2, colour = nebula[["grey"]], linetype = "dotted", linewidth = 0.35) +
  geom_hline(yintercept = 0.8 * Vmax_s, colour = nebula[["grey"]], linetype = "dotted", linewidth = 0.35) +
  geom_vline(xintercept = Km_s, colour = nebula[["grey"]], linetype = "dotted", linewidth = 0.35) +
  annotate("segment", x = 0, xend = Km_s, y = 0, yend = Vmax_s, colour = nebula[["vermilion"]], linetype = "longdash", linewidth = 0.6) +
  geom_line(colour = nebula[["violet"]], linewidth = 0.8) +
  geom_point(data = marks, aes(S, V), shape = 21, size = 2.2, stroke = 0.7, fill = "white", colour = nebula[["ink"]]) +
  annotate("text", x = 2.05, y = 0.40, label = "V = Vmax [S] / (Km + [S])", colour = nebula[["violet"]], hjust = 0, vjust = 1, size = qs(8.5), family = FIG_FONT, fontface = "bold") +
  annotate("text", x = 3.95, y = 1.03, label = "asymptote V = Vmax", hjust = 1, vjust = 0, size = qs(7.5), family = FIG_FONT) +
  annotate("text", x = 1.08, y = 0.43, label = "([S] = Km, V = Vmax/2)", hjust = 0, size = qs(7.5), family = FIG_FONT) +
  annotate("text", x = 3.95, y = 0.75, label = "V(4 Km) = 0.8 Vmax", hjust = 1, vjust = 1, size = qs(7.5), family = FIG_FONT) +
  annotate("text", x = 1.08, y = 0.95, label = "tangent meets V = Vmax at [S] = Km", hjust = 0, vjust = 1, size = qs(7.5), family = FIG_FONT, colour = nebula[["vermilion"]]) +
  annotate("text", x = 0.08, y = 1.14, label = "tangent at the origin, slope Vmax/Km", colour = nebula[["vermilion"]], hjust = 0, size = qs(7.5), family = FIG_FONT) +
  scale_x_continuous(breaks = 0:4, labels = c("0", "Km", "2 Km", "3 Km", "4 Km"), expand = expansion(mult = c(0, 0.02))) +
  scale_y_continuous(breaks = c(0, 0.5, 0.8, 1), labels = c("0", "Vmax/2", "0.8 Vmax", "Vmax"), limits = c(0, 1.2), expand = expansion(mult = c(0, 0.02))) +
  labs(x = "Substrate concentration [S]", y = "Initial velocity V") +
  theme_nebula_science(base_size = 8.5) + theme(axis.text = element_text(size = 7.5), axis.title = element_text(size = 8.5), plot.margin = margin(4, 6, 2, 3))
save_figure(figQ1, "figureQ1_michaelis_menten_sketch", 4.6, 2.9, dir = dir_supp)

# Captions -------------------------------------------------------------------------------------------------------
d_i <- depl |> filter(data_role == "reference", condition == "mm_no_inhibitor")
gc  <- glob |> filter(model == "global competitive"); gn <- glob |> filter(model == "global noncompetitive")
gk  <- function(p, tb = gc, col = "estimate") tb[[col]][tb$parameter == p]
off_both <- offs |> filter(data_role == "both")
cap <- c(
"# Figures",
"",
"Main figures (`figures/`) are drawn from the reference dataset (course-provided measurements, used for the Results section at the instructor's direction); supplementary figures (`figures/supplementary/`) hold the experimental dataset (our own printouts), diagnostics and sensitivity analyses. All figures: 600 dpi PNG plus vector PDF, generated by `R/07_generate_figures.R` and `R/07b_supplementary_figures.R`. Conventions: filled symbol, observation used for V₀; open symbol, observation retained but not used; solid line, fitted initial window; dashed segment from the origin, origin-assumed 0–2 min average rate (A₄₁₅(2 min)/2 min with A₄₁₅ = 0 assumed at t = 0, where no reading exists); dotted line, extrapolation; † marks such an origin-assumed estimate, which is an average rate over the first interval rather than a measured instantaneous initial velocity. Each condition was measured once, so no error bars are shown.",
"",
"## Figure 1. o-Nitrophenol absorbs maximally at 415 nm and obeys the Beer–Lambert law to 0.43 mM",
"![Figure 1](figure1_onp_calibration.png)",
"",
sprintf("**(A)** Absorbance spectrum of 0.333 mM ONP (manual tube 4: 1.0 mL of 1 mM ONP + 1.0 mL Z buffer + 1.0 mL 1 M Na₂CO₃) read from 465 to 385 nm in 5 nm steps against the Z buffer/Na₂CO₃ blank (reference Part I). Points are the readings, the line a spline through them, the dashed line the maximum at %d nm (A = %.3f); the shaded band (410–420 nm) lies within 2%% of the maximum, so 415 nm was used for all kinetic measurements. **(B)** Standard curve at 415 nm for 1 mM ONP diluted to 0.083–0.533 mM in the same 3.0 mL matrix ([ONP] = 1 mM × V/3.0 mL; mapping of the reported readings to the manual's preparations in Table S1). Filled points and the line are the least-squares calibration over the linear region (shaded, 0.083–0.433 mM, chosen by the same increment rule used for progress curves): A₄₁₅ = %.3f[ONP] %s %.3f, R² = %.4f, n = %d, giving ε = %.2f ± %.2f A mM⁻¹ cm⁻¹ (%.0f M⁻¹ cm⁻¹). The zero-concentration point (×, reported as 0) is shown but not fitted. The 0.533 mM standard (open, A = %.2f) lay %+.0f%% above the line and was excluded; the cause of the deviation cannot be identified from a single reading (see text). The calibration converts every velocity in this report from ΔA₄₁₅ min⁻¹ to product formed.",
        V("lambda_max"), V("A_lmax"), eps, ifelse(V("eps_icpt") < 0, "−", "+"), abs(V("eps_icpt")), V("eps_r2"), calib$value[calib$quantity == "n_standards_used"], eps, V("eps_se"), 1000 * eps, V("excl_A"), V("excl_pct")),
"",
"## Figure 2. Initial velocity rose approximately in proportion to the amount of β-galactosidase",
"![Figure 2](figure2_enzyme_dilution.png)",
"",
sprintf("**(A)** Progress curves (A₄₁₅ of 2.0 mL aliquots stopped with 1.0 mL 1 M Na₂CO₃) for 2.20 mM ONPG hydrolysed by 1.00, 0.75, 0.50, 0.25 and 0.15 relative amounts of the standardised enzyme (tubes A–E; reference Part II). Lines are least-squares fits to the initial linear window chosen by the operational rule (Methods); the 8-min readings of tubes A and C fell far below their initial trend and were excluded (open), while tubes B and E were linear to 10 min. V₀ ranged from %.3f (A) to %.3f (E), a %.1f-fold span for a 6.7-fold change in enzyme. **(B)** V₀, converted with ε = %.2f mM⁻¹ cm⁻¹ to μmol ONP min⁻¹ per 12.0 mL assay, against relative enzyme concentration. Line: proportional model through the origin, V₀ = %.3f × E (R² about the mean %.3f); a free-intercept fit (intercept %.4f μmol min⁻¹, not distinguishable from zero, p = %.2f) coincides with it and is not drawn; letters identify the tubes. Relative rates were %s for relative enzyme 1.00, 0.75, 0.50, 0.25, 0.15: velocity rose approximately in proportion to enzyme, but the rate per unit enzyme ranged from 0.71 (D) to 1.21 (C) and tubes D and E gave nearly equal rates despite a 1.7-fold difference in enzyme.",
        V("ed_V0A_dA"), V("ed_V0E_dA"), V("ed_V0A_dA") / V("ed_V0E_dA"), eps, V("ed_slope_umol"), V("ed_r2"), V("ed_free_icpt_umol"), V("ed_free_p"), vals$text[vals$name == "ed_relrates"]),
"",
"## Figure 3. Product formation slowed as substrate fell and when IPTG was present",
"![Figure 3](figure3_substrate_saturation.png)",
"",
sprintf("**(A)** Progress curves for 0.2 mL enzyme acting on 2.20, 1.10, 0.55, 0.275, 0.1375 and 0.069 mM ONPG in 12.0 mL Z buffer at room temperature (tubes A–F; reference Part III, no inhibitor). Only tube A stayed linear to 10 min (V₀ = %.3f ΔA₄₁₅ min⁻¹, regression); in tubes B–F the later increments fell below the first, so no linear window could be fitted and their V₀ is the origin-assumed 0–2 min average rate, A₄₁₅(2 min)/2 min (†; dashed, × marks the assumed origin; dotted extrapolation). No reading exists at t = 0, so this is an average rate over the first interval, not a measured instantaneous initial velocity, and whether it under- or overestimates the true V₀ depends on the unmeasured early course of each curve. As a sensitivity scenario, assuming instead a t = 0 absorbance equal to the median intercept of the curves that were linear (%.3f A; range %.3f to %.3f A) lowers each 0–2 min estimate by about %.3f ΔA₄₁₅ min⁻¹ (estimator O, Figure S3); intercepts of other reactions do not bound the baseline of these curves. Later points (open) were not used. **(B)** The same six tubes with %.3f mM IPTG (1.0 mL of 5.5 mM IPTG per 12.0 mL; reference Part III), on a smaller absorbance scale. Tube A is origin-assumed (its 4–10 min increments fell below the first); tubes B–F were fitted by regression over the filled points. The uninhibited velocities rose %.1f-fold from 0.069 to 2.20 mM ONPG and approached a plateau (Figure 4A): Lineweaver–Burk Kₘ = %.2f mM, Vₘₐₓ = %.3f μmol min⁻¹ (R² = %.3f); direct nonlinear fit Kₘ = %.2f ± %.2f mM, Vₘₐₓ = %.3f ± %.3f μmol min⁻¹ (R² = %.3f). Five of six uninhibited V₀ values are origin-assumed 0–2 min estimates, so Kₘ depends on how the initial rate is estimated (Figure S3).",
        fits$V0_dA415_per_min[fits$dataset == "Reference Part III (-IPTG)" & fits$tube == "A"], off_both$median_intercept, off_both$min_intercept, off_both$max_intercept, off_both$median_scenario_shift_dA_per_min,
        I_mM, V("u_V0A_umol") / V("u_V0F_umol"), V("lbU_Km"), V("lbU_Vmax"), V("lbU_r2"), V("nlU_Km"), V("nlU_Km_se"), V("nlU_Vmax"), V("nlU_Vmax_se"), V("nlU_r2")),
"",
"## Figure 4. β-Galactosidase approached saturation with ONPG, and IPTG raised the apparent Kₘ",
"![Figure 4](figure4_iptg_inhibition.png)",
"",
sprintf("**(A)** V₀ against [ONPG] without inhibitor (circles) and with %.3f mM IPTG (triangles), from the progress curves in Figure 3 (1.0 mL of 5.5 mM IPTG per 12.0 mL tube; reference Part III, tubes A–F). Dashed curves are the hyperbolae implied by the two Lineweaver–Burk lines in B; solid curves are a single competitive-inhibition model fitted to both series at once (shared Vₘₐₓ = %.2f ± %.2f μmol min⁻¹, Kₘ = %.2f ± %.2f mM, Kᵢ = %.3f ± %.3f mM; the shared Vₘₐₓ is an assumption of this model, not a result). With IPTG, V₀ fell to %.0f%% of the uninhibited value at 2.20 mM ONPG and to %.0f%% at 0.069 mM: inhibition grew as substrate fell. **(B)** Double-reciprocal plot of the same velocities. No inhibitor: 1/V₀ = %.2f(1/[S]) + %.2f, R² = %.3f, giving Vₘₐₓ = %.3f μmol min⁻¹ and Kₘ = %.2f mM. + IPTG: 1/V₀ = %.2f(1/[S]) + %.2f, R² = %.3f, giving apparent Vₘₐₓ = %.3f μmol min⁻¹ and apparent Kₘ = %.2f mM (%.1f-fold increase). Kᵢ = [I]/(Kₘ,app/Kₘ − 1) = %.3f/(%.2f/%.2f − 1) = %.3f mM. The inhibited series shows no plateau within the tested range, so its apparent Vₘₐₓ rests on an extrapolated intercept (%.2f ± %.2f) and is poorly determined; the shift of the x-intercept (−1/Kₘ) from %.2f to %.2f mM⁻¹ is the better-determined feature. A pure noncompetitive model fitted to the same twelve points (shared Kₘ, Vₘₐₓ reduced) left a residual sum of squares %.1f times larger than the competitive model (%.4f against %.4f); the pattern is therefore consistent with competitive inhibition, with Kᵢ of the order of 0.1 mM by this method. † marks origin-assumed 0–2 min estimates.",
        I_mM, gk("Vmax"), gk("Vmax", col = "se"), gk("Km"), gk("Km", col = "se"), gk("Ki"), gk("Ki", col = "se"),
        100 * V("i_V0A_umol") / V("u_V0A_umol"), 100 * V("i_V0F_umol") / V("u_V0F_umol"),
        V("lbU_slope"), V("lbU_icpt"), V("lbU_r2"), V("lbU_Vmax"), V("lbU_Km"), V("lbI_slope"), V("lbI_icpt"), V("lbI_r2"), V("lbI_Vmax"), V("lbI_Km"), V("lbI_Km") / V("lbU_Km"),
        I_mM, V("lbI_Km"), V("lbU_Km"), V("Ki_lb"), V("lbI_icpt"), V("lbI_icpt_se"), -1 / V("lbU_Km"), -1 / V("lbI_Km"),
        gn$rss[1] / gc$rss[1], gn$rss[1], gc$rss[1]),
"",
"## Supplementary figures (`figures/supplementary/`)",
"",
"### Figure S1. Progress curves of the experimental dataset beside the reference dataset",
"![Figure S1](supplementary/figureS1_experimental_vs_reference_curves.png)",
"",
"Progress curves from our 14 GENESYS 10S printouts (right column; 7 and 11 September 2026) plotted on the same axes as the reference dataset (left column) for the three experiments. Solid segments are the regression windows and dashed segments the origin-assumed 0–2 min average rates used for V₀ under the identical rule. The standard tube (A: 0.2 mL enzyme, 2.20 mM ONPG) agreed between the two datasets within 5% (enzyme dilution) and 15% (substrate series). Our low-substrate tubes without inhibitor stayed linear longer than the reference tubes (only tube E was non-linear from the outset), and our inhibited tubes C and D ran about twice as fast as the reference tubes. Our inhibited tube B (open) ran faster than tube A at half the nominal substrate and is excluded from kinetic fits; our inhibited tube E has no data (sample discarded); tube F was not performed on either day.",
"",
"### Figure S2. Increment diagnostics behind every V₀ decision",
"![Figure S2](supplementary/figureS2_increment_diagnostics.png)",
"",
sprintf("For each of the 31 measured curves, every successive 2-min increment divided by the increment predicted by the fitted V₀ (V₀ × 2 min). A value of 1 means the interval ran at the fitted initial rate; the shaded band is the acceptance window of the rule (±%.0f%% or ±%.3f A, whichever is larger). Open symbols are intervals not used for V₀. For curves with no initial linear portion (reference no-IPTG B–F, reference +IPTG A, experimental no-IPTG E) the reference V₀ is the origin-assumed 0–2 min average rate, so all later intervals fall below 1, showing how the measured increments declined: to 35–60%% of the first-interval rate by the second interval in the reference uninhibited tubes B–F.", 100 * REL_TOL, ABS_TOL),
"",
"### Figure S3. Sensitivity of the kinetic parameters to the V₀ estimator",
"![Figure S3](supplementary/figureS3_estimator_sensitivity.png)",
"",
sprintf("Kₘ (no inhibitor), apparent Kₘ (+IPTG) and Kᵢ from the reference dataset under five ways of estimating V₀: A, regression on all five points of every curve; R, the initial-window regression for every curve; S, the origin-assumed 0–2 min average rate for every curve; O, the two-tier rule under the baseline-offset scenario, in which each 0–2 min estimate is recomputed with a t = 0 absorbance equal to the median intercept of the linear curves (%.3f A; an assumption transferred between reactions, not a measured baseline); P, the two-tier rule used in the Results. Circles, Lineweaver–Burk; triangles, nonlinear Michaelis–Menten; diamond, global competitive fit. With regression-only V₀ the uninhibited Lineweaver–Burk line has a negative intercept (non-physical Kₘ and Vₘₐₓ, noted in red), and with all five points Kₘ exceeds 3 mM, because both estimators average over the falling phase of the curved low-substrate tubes. The offset scenario moves Kₘ from %.2f to %.2f mM and Kᵢ from %.2f to %.2f mM; applying the 0–2 min average rate to every curve (S) gives Kᵢ = %.2f mM, because for the inhibited tubes, which were linear over 2–10 min, that estimate replaces a five-point regression with a single interval. These are alternative method-dependent estimates, not a confidence interval for Kᵢ. Cyan lines: Kₘ = 0.12 mM and Kᵢ = 0.08 mM reported for purified E. coli β-galactosidase with ONPG in TES buffer, pH 7.0, 25 °C.",
        off_both$median_intercept, V("lbU_Km"), sens$Km[sens$estimator == "O: two-tier rule, baseline-offset scenario for the 0-2 min estimates" & sens$method == "Lineweaver-Burk"],
        V("Ki_lb"), sens$Ki_competitive[sens$estimator == "O: two-tier rule, baseline-offset scenario for the 0-2 min estimates" & sens$method == "Lineweaver-Burk"],
        sens$Ki_competitive[sens$estimator == "S: origin-assumed 0-2 min average rate for every curve" & sens$method == "Lineweaver-Burk"]),
"",
"### Figure S4. Kinetic analysis of the experimental dataset",
"![Figure S4](supplementary/figureS4_experimental_kinetics.png)",
"",
sprintf("**(A)** Michaelis–Menten representation of our Part III data with the same V₀ rule and units as the Results, with the anomalous +IPTG tube B (open) excluded and +IPTG tube E absent; † marks an origin-assumed 0–2 min estimate. Nonlinear fits: Kₘ = %.2f mM, Vₘₐₓ = %.2f μmol min⁻¹ without inhibitor; apparent Kₘ = %.2f mM, apparent Vₘₐₓ = %.2f with IPTG (ratio %.2f); Kᵢ = %.3f mM. **(B)** Ratio of our V₀ to the reference V₀ for every tube measured in both datasets. The standard tube agreed within 5–15%%; our uninhibited tube D and inhibited tubes C and D ran 1.6- to 2.1-fold faster; our inhibited tube B (faded) ran 3.7-fold faster than the reference tube B.",
        nlU$Km, nlU$Vmax, nlU$Km_app, nlU$Vmax_app, nlU$Vmax_ratio, nlU$Ki_competitive)
)
writeLines(cap, file.path(dir_fig, "README.md"))

for (f in c("figureS1_experimental_vs_reference_curves", "figureS2_increment_diagnostics", "figureS3_estimator_sensitivity", "figureS4_experimental_kinetics", "figureQ1_michaelis_menten_sketch"))
  check_that(all(file.exists(file.path(dir_supp, paste0(f, c(".png", ".pdf"))))), paste("figure not written:", f))
message("07b_supplementary_figures.R: S1-S4 and Q1 written to ", dir_supp, "; captions in figures/README.md")
