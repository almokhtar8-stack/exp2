# 07_generate_figures.R
# Main figures 1-4 (reference dataset). Each is a two-panel figure sized for a
# 6.2 in text width after embedding (7.4 x 3.4 in at 600 dpi, plus vector PDF).
# Conventions in every progress-curve panel: filled symbol, observation used
# for V0; open symbol, observation retained but not used; solid line, fitted
# initial window; dashed segment from the origin, 0-2 min secant through the
# assumed origin (no reading exists at t = 0); dotted line, extrapolation of
# the fit. Lower-bound V0 estimates carry an upward tick in velocity plots.
# Fit equations are given in the captions, not drawn over the data.
#
# Inputs : data/processed/*.csv
# Outputs: figures/figure1_onp_calibration, figure2_enzyme_dilution,
#          figure3_substrate_saturation, figure4_iptg_inhibition (.png and .pdf)
#          figures/main_figure_values.csv (numbers used in the captions)
source(here::here("R", "00_setup.R"))
theme_set(theme_nebula_science(base_size = 11))
MAIN_FIG_H <- 2.8  # inches; main figures are 7.4 x 2.8 in (two panels side by side)

tidy  <- read_csv(file.path(dir_proc, "absorbance_tidy.csv"), show_col_types = FALSE)
fits  <- read_csv(file.path(dir_proc, "progress_curve_fits.csv"), show_col_types = FALSE)
spec  <- read_csv(file.path(dir_proc, "onp_spectrum.csv"), show_col_types = FALSE)
stdf  <- read_csv(file.path(dir_proc, "onp_standards_fit.csv"), show_col_types = FALSE,
                  col_types = cols(reported_tube = "c", manual_tube = "c", mapping_basis = "c", reported = "l", used_in_fit = "l", .default = "d"))
std0  <- read_csv(file.path(dir_proc, "onp_standards.csv"), show_col_types = FALSE,
                  col_types = cols(reported_tube = "c", manual_tube = "c", mapping_basis = "c", reported = "l", .default = "d"))
calib <- read_csv(file.path(dir_proc, "onp_calibration.csv"), show_col_types = FALSE)
ed    <- read_csv(file.path(dir_proc, "enzyme_dilution_results.csv"), show_col_types = FALSE) |> filter(data_role == "reference")
edfit <- read_csv(file.path(dir_proc, "enzyme_dilution_fit.csv"), show_col_types = FALSE) |> filter(data_role == "reference")
v0s   <- read_csv(file.path(dir_proc, "v0_scenarios.csv"), show_col_types = FALSE)
kin   <- read_csv(file.path(dir_proc, "kinetic_parameters.csv"), show_col_types = FALSE)
sens  <- read_csv(file.path(dir_proc, "sensitivity_analysis.csv"), show_col_types = FALSE)
glob  <- read_csv(file.path(dir_proc, "global_fits.csv"), show_col_types = FALSE)

cal <- function(q) calib$value[calib$quantity == q]
eps <- cal("epsilon_A_per_mM_per_cm"); eps_icpt <- cal("intercept_A"); eps_r2 <- cal("r2"); lmax <- cal("lambda_max_nm")
I_mM <- unique(na.omit(v0s$iptg_mM[v0s$condition == "mm_plus_iptg"]))
PRIMARY <- "P: two-tier rule (primary)"
to_umol <- function(x) convert_v0(x, eps)$V0_umol_per_min_assay

lab_A415 <- expression(italic(A)[415]~"of stopped sample")
lab_time <- "Time (min)"
lab_V0u  <- expression(italic(V)[0]~"("*mu*mol~min^-1*")")
lab_S    <- "ONPG concentration (mM)"
ANNOT_SIZE <- 3.0

# Shared progress-curve panel. Secant curves: dashed segment from the assumed
# origin to the 2-min reading; the origin is marked with a small cross.
progress_panel <- function(ds, labels, title, subtitle = NULL, ylim, ybreaks = waiver(), legend_pos = c(0.02, 0.98)) {
  o <- tidy |> filter(dataset == ds, measured) |>
    left_join(fits |> select(dataset, tube, lower_bound, slope, intercept, t_last, V0_dA415_per_min), by = c("dataset", "tube")) |>
    mutate(used = if_else(lower_bound, time_min == 2, time_min <= t_last))
  f <- fits |> filter(dataset == ds, n_used > 0) |>
    mutate(x0 = if_else(lower_bound, 0, t_first), x1 = if_else(lower_bound, 2, t_last),
           y0 = if_else(lower_bound, 0, intercept + slope * t_first), y1 = if_else(lower_bound, V0_dA415_per_min * 2, intercept + slope * t_last),
           ye = if_else(lower_bound, V0_dA415_per_min * 10, intercept + slope * 10))
  ggplot() +
    geom_segment(data = f |> filter(x1 < 10), aes(x = x1, xend = 10, y = y1, yend = ye, colour = tube), linetype = "dotted", linewidth = 0.45, alpha = 0.7, show.legend = FALSE) +
    geom_segment(data = f |> filter(!lower_bound), aes(x = x0, xend = x1, y = y0, yend = y1, colour = tube), linewidth = 0.8, show.legend = FALSE) +
    geom_segment(data = f |> filter(lower_bound), aes(x = x0, xend = x1, y = y0, yend = y1, colour = tube), linetype = "22", linewidth = 0.8, show.legend = FALSE) +
    geom_point(data = f |> filter(lower_bound) |> distinct(x0, y0), aes(x0, y0), shape = 4, size = 2, colour = nebula[["grey"]]) +
    geom_point(data = o |> filter(!used), aes(time_min, absorbance_415nm, colour = tube, shape = tube), fill = "white", size = 2.3, stroke = 0.8, alpha = 0.9) +
    geom_point(data = o |> filter(used), aes(time_min, absorbance_415nm, colour = tube, shape = tube, fill = tube), size = 2.4, stroke = 0.6) +
    scale_colour_manual(values = TUBE_COLOURS, labels = labels, name = NULL, breaks = names(labels),
                        guide = guide_legend(override.aes = list(fill = TUBE_COLOURS[names(labels)], shape = TUBE_SHAPES[names(labels)], size = 2.4))) +
    scale_shape_manual(values = TUBE_SHAPES, labels = labels, name = NULL, breaks = names(labels)) +
    scale_fill_manual(values = TUBE_COLOURS, guide = "none") +
    scale_x_continuous(breaks = seq(0, 10, 2), limits = c(0, 10.4), expand = expansion(mult = c(0, 0.01))) +
    scale_y_continuous(limits = ylim, breaks = ybreaks, expand = expansion(mult = c(0, 0.02))) +
    labs(title = title, subtitle = subtitle, x = lab_time, y = lab_A415) +
    theme(legend.position = legend_pos, legend.justification = c(0, 1), legend.key.height = unit(10, "pt"),
          legend.text = element_text(size = 8.2), legend.spacing.y = unit(0, "pt"), legend.background = element_rect(fill = alpha("white", 0.75), colour = NA))
}

# Figure 1: spectrum and calibration ------------------------------------------------
band <- str_split(calib$text[calib$quantity == "band_within_2pct_nm"], "-")[[1]] |> as.numeric()
sp_smooth <- as_tibble(spline(spec$wavelength_nm, spec$absorbance, n = 200)) |> rename(wavelength_nm = x, absorbance = y)
p1a <- ggplot(spec, aes(wavelength_nm, absorbance)) +
  annotate("rect", xmin = band[1], xmax = band[2], ymin = -Inf, ymax = Inf, fill = nebula[["mist"]]) +
  geom_vline(xintercept = lmax, colour = nebula[["magenta"]], linewidth = 0.5, linetype = "longdash") +
  geom_line(data = sp_smooth, colour = nebula[["purple"]], linewidth = 0.9) +
  geom_point(colour = nebula[["violet"]], fill = "white", shape = 21, size = 2.2, stroke = 0.8) +
  geom_point(data = spec |> filter(wavelength_nm == lmax), colour = nebula[["magenta"]], fill = nebula[["magenta"]], shape = 21, size = 2.8) +
  annotate("text", x = lmax + 3, y = 0.78, hjust = 0, size = ANNOT_SIZE, family = FIG_FONT, colour = nebula[["ink"]],
           label = sprintf("λₘₐₓ = %d nm", lmax)) +
  scale_x_continuous(breaks = seq(385, 465, 20), expand = expansion(mult = 0.02)) +
  scale_y_continuous(limits = c(0.6, 1.85), breaks = seq(0.6, 1.8, 0.3), expand = expansion(mult = c(0, 0.02))) +
  labs(title = "A   ONP absorption spectrum", subtitle = "0.333 mM ONP in the alkaline assay matrix\nshaded: within 2% of the maximum",
       x = "Wavelength (nm)", y = "Absorbance")

zero_pt <- std0 |> filter(reported, onp_ml == 0)
p1b <- ggplot(stdf, aes(onp_mM_cuvette, abs_415nm)) +
  annotate("rect", xmin = 0, xmax = cal("linear_range_mM_max"), ymin = -Inf, ymax = Inf, fill = nebula[["mist"]]) +
  geom_abline(intercept = eps_icpt, slope = eps, colour = nebula[["blue"]], linewidth = 0.8) +
  geom_point(data = zero_pt, aes(onp_mM_cuvette, abs_415nm), shape = 4, size = 2.6, stroke = 0.9, colour = nebula[["grey"]]) +
  geom_point(data = stdf |> filter(!used_in_fit), colour = nebula[["rose"]], fill = "white", shape = 21, size = 2.8, stroke = 1) +
  geom_point(data = stdf |> filter(used_in_fit), colour = nebula[["violet"]], fill = nebula[["violet"]], shape = 21, size = 2.6, stroke = 0.5) +
  annotate("text", x = cal("excluded_standard_mM") - 0.025, y = cal("excluded_standard_A") - 0.42, hjust = 1, size = ANNOT_SIZE, family = FIG_FONT, colour = nebula[["rose"]],
           label = "excluded standard\n(+17% above the line)") +
  annotate("text", x = 0.02, y = 3.3, hjust = 0, vjust = 1, size = ANNOT_SIZE, family = FIG_FONT, colour = nebula[["ink"]],
           label = sprintf("ε = %.2f ± %.2f mM⁻¹ cm⁻¹\nR² = %.4f (5 standards)", eps, cal("epsilon_se"), eps_r2)) +
  scale_x_continuous(limits = c(0, 0.57), breaks = seq(0, 0.5, 0.1), expand = expansion(mult = c(0, 0.01))) +
  scale_y_continuous(limits = c(0, 3.4), breaks = seq(0, 3, 0.5), expand = expansion(mult = c(0, 0.01))) +
  labs(title = "B   ONP standard curve at 415 nm", subtitle = "Filled: fitted; open: excluded; ×: zero-concentration point\nshaded: calibration range",
       x = "ONP concentration (mM)", y = lab_A415)
save_figure(p1a + p1b, "figure1_onp_calibration", 7.4, MAIN_FIG_H)

# Figure 2: enzyme dilution ------------------------------------------------------------
f2 <- fits |> filter(dataset == "Reference Part II") |> arrange(tube)
lab2 <- setNames(sprintf("%s   E = %.2f   V₀ = %.3f", f2$tube, f2$rel_enzyme, f2$V0_dA415_per_min), f2$tube)
p2a <- progress_panel("Reference Part II", lab2, ylim = c(0, 1.55), ybreaks = seq(0, 1.5, 0.25),
                      title = "A   Progress curves at five enzyme levels",
                      subtitle = "2.20 mM ONPG; E = relative enzyme; V₀ in ΔA₄₁₅ min⁻¹\nfilled: used for V₀; open: not used; dotted: extrapolation")
pr <- edfit |> filter(model == "proportional (through origin)"); fr <- edfit |> filter(model == "free intercept")
k_umol <- to_umol(1)
p2b <- ggplot(ed, aes(rel_enzyme, V0_umol_per_min_assay)) +
  geom_abline(intercept = 0, slope = pr$slope_umol_per_min_per_unit_enzyme, colour = nebula[["violet"]], linewidth = 0.8) +
  geom_abline(intercept = to_umol(fr$intercept), slope = fr$slope_umol_per_min_per_unit_enzyme, colour = nebula[["grey"]], linetype = "dotted", linewidth = 0.5) +
  geom_point(aes(colour = tube, shape = tube, fill = tube), size = 3, stroke = 0.6, show.legend = FALSE) +
  geom_text(aes(label = tube), nudge_x = 0.05, nudge_y = -0.02, size = ANNOT_SIZE, family = FIG_FONT, colour = nebula[["ink"]]) +
  annotate("text", x = 0.03, y = 0.525, hjust = 0, vjust = 1, size = ANNOT_SIZE, family = FIG_FONT, colour = nebula[["ink"]],
           label = sprintf("Solid: V₀ = %.3f E, R² = %.2f\nDotted: free intercept %.4f (p = %.2f)",
                           pr$slope_umol_per_min_per_unit_enzyme, pr$r2_about_mean, to_umol(fr$intercept), fr$intercept_p)) +
  scale_colour_manual(values = TUBE_COLOURS) + scale_fill_manual(values = TUBE_COLOURS) + scale_shape_manual(values = TUBE_SHAPES) +
  scale_x_continuous(limits = c(0, 1.08), breaks = c(0, 0.25, 0.5, 0.75, 1), expand = expansion(mult = c(0, 0.01))) +
  scale_y_continuous(limits = c(0, 0.54), breaks = seq(0, 0.5, 0.1), expand = expansion(mult = c(0, 0.01)),
                     sec.axis = sec_axis(~ . / k_umol, name = expression(italic(V)[0]~"("*Delta*italic(A)[415]~min^-1*")"), breaks = seq(0, 0.14, 0.02))) +
  labs(title = "B   Initial rate against enzyme amount", subtitle = sprintf("V₀ converted with ε = %.2f mM⁻¹ cm⁻¹, × 1.5, × 12.0 mL\nn = 1 curve per tube", eps),
       x = "Relative enzyme concentration (tube A = 1)", y = lab_V0u)
save_figure(p2a + p2b, "figure2_enzyme_dilution", 7.4, MAIN_FIG_H)

# Figure 3: substrate saturation, no inhibitor ------------------------------------------
f3 <- fits |> filter(dataset == "Reference Part III (-IPTG)") |> arrange(tube)
lab3 <- setNames(sprintf("%s   %.4g mM   V₀ = %.3f%s", f3$tube, f3$onpg_mM, f3$V0_dA415_per_min, ifelse(f3$lower_bound, "†", "")), f3$tube)
p3a <- progress_panel("Reference Part III (-IPTG)", lab3, ylim = c(0, 1.45), ybreaks = seq(0, 1.4, 0.2),
                      title = "A   Progress curves, no inhibitor",
                      subtitle = "† no initial linear portion: V₀ = 0–2 min secant (dashed)\nthrough the assumed origin (×); open: not used")
u   <- v0s |> filter(data_role == "reference", condition == "mm_no_inhibitor", estimator == PRIMARY)
lbU <- kin |> filter(condition == "mm_no_inhibitor", method == "Lineweaver-Burk"); nlU <- kin |> filter(condition == "mm_no_inhibitor", method == "Nonlinear MM")
Sg  <- tibble(S = seq(0.001, 2.35, length.out = 300))
cur3 <- bind_rows(Sg |> mutate(method = "Nonlinear MM", V = nlU$Vmax * S / (nlU$Km + S)),
                  Sg |> mutate(method = "Lineweaver-Burk", V = lbU$Vmax * S / (lbU$Km + S)))
p3b <- ggplot() +
  geom_hline(yintercept = nlU$Vmax, colour = nebula[["grey"]], linetype = "dashed", linewidth = 0.4) +
  annotate("segment", x = nlU$Km, xend = nlU$Km, y = 0, yend = nlU$Vmax / 2, colour = nebula[["grey"]], linetype = "dotted", linewidth = 0.4) +
  annotate("segment", x = 0, xend = nlU$Km, y = nlU$Vmax / 2, yend = nlU$Vmax / 2, colour = nebula[["grey"]], linetype = "dotted", linewidth = 0.4) +
  geom_line(data = cur3 |> filter(method == "Lineweaver-Burk"), aes(S, V), colour = COND_COLOURS[["mm_no_inhibitor"]], linetype = "22", linewidth = 0.6) +
  geom_line(data = cur3 |> filter(method == "Nonlinear MM"), aes(S, V), colour = COND_COLOURS[["mm_no_inhibitor"]], linewidth = 0.9) +
  geom_segment(data = u |> filter(lower_bound), aes(x = onpg_mM, xend = onpg_mM, y = V0_umol_per_min_assay + 0.014, yend = V0_umol_per_min_assay + 0.06),
               colour = nebula[["grey"]], linewidth = 0.45, arrow = arrow(length = unit(3.5, "pt"), type = "closed")) +
  geom_point(data = u, aes(onpg_mM, V0_umol_per_min_assay, shape = tube, fill = tube, colour = tube), size = 2.9, stroke = 0.6, show.legend = FALSE) +
  geom_text(data = u, aes(onpg_mM, V0_umol_per_min_assay, label = tube), nudge_y = -0.032, nudge_x = 0.05, size = ANNOT_SIZE, family = FIG_FONT, colour = nebula[["ink"]]) +
  annotate("text", x = nlU$Km + 0.04, y = 0.025, hjust = 0, size = 2.8, family = FIG_FONT, colour = nebula[["grey"]], label = sprintf("Kₘ = %.2f mM", nlU$Km)) +
  annotate("text", x = 2.3, y = nlU$Vmax + 0.022, hjust = 1, vjust = 0, size = 2.8, family = FIG_FONT, colour = nebula[["grey"]], label = sprintf("Vₘₐₓ = %.2f μmol min⁻¹", nlU$Vmax)) +
  scale_colour_manual(values = TUBE_COLOURS) + scale_fill_manual(values = TUBE_COLOURS) + scale_shape_manual(values = TUBE_SHAPES) +
  scale_x_continuous(limits = c(0, 2.35), breaks = c(0, 0.55, 1.1, 1.65, 2.2), expand = expansion(mult = c(0, 0.01))) +
  scale_y_continuous(limits = c(0, 0.62), breaks = seq(0, 0.6, 0.1), expand = expansion(mult = c(0, 0.01))) +
  labs(title = "B   Michaelis–Menten representation", subtitle = "Solid: nonlinear fit; dashed: hyperbola from the\nLineweaver–Burk line; ↑ lower-bound V₀",
       x = lab_S, y = lab_V0u)
save_figure(p3a + p3b, "figure3_substrate_saturation", 7.4, MAIN_FIG_H)

# Figure 4: IPTG inhibition -----------------------------------------------------------------
pts <- v0s |> filter(data_role == "reference", estimator == PRIMARY) |> mutate(condition = factor(condition, levels = names(COND_LABELS)))
lbI <- kin |> filter(condition == "mm_plus_iptg", method == "Lineweaver-Burk")
gc  <- glob |> filter(model == "global competitive", converged)
Ki_lb <- sens |> filter(estimator == PRIMARY, method == "Lineweaver-Burk") |> pull(Ki_competitive)
have_g <- nrow(gc) == 3
gV <- if (have_g) gc$estimate[gc$parameter == "Vmax"] else NA; gK <- if (have_g) gc$estimate[gc$parameter == "Km"] else NA; gKi <- if (have_g) gc$estimate[gc$parameter == "Ki"] else NA
gKi_se <- if (have_g) gc$se[gc$parameter == "Ki"] else NA
cur4 <- bind_rows(
  Sg |> mutate(condition = "mm_no_inhibitor", kind = "Lineweaver-Burk", V = lbU$Vmax * S / (lbU$Km + S)),
  Sg |> mutate(condition = "mm_plus_iptg",    kind = "Lineweaver-Burk", V = lbI$Vmax * S / (lbI$Km + S)),
  if (have_g) Sg |> mutate(condition = "mm_no_inhibitor", kind = "Global competitive", V = gV * S / (gK + S)),
  if (have_g) Sg |> mutate(condition = "mm_plus_iptg",    kind = "Global competitive", V = gV * S / (gK * (1 + I_mM / gKi) + S))) |>
  mutate(condition = factor(condition, levels = names(COND_LABELS)))
p4a <- ggplot() +
  geom_line(data = cur4 |> filter(kind == "Lineweaver-Burk"), aes(S, V, colour = condition), linetype = "22", linewidth = 0.6, alpha = 0.9) +
  geom_line(data = cur4 |> filter(kind == "Global competitive"), aes(S, V, colour = condition), linewidth = 0.9) +
  geom_segment(data = pts |> filter(lower_bound), aes(x = onpg_mM, xend = onpg_mM, y = V0_umol_per_min_assay + 0.014, yend = V0_umol_per_min_assay + 0.055),
               colour = nebula[["grey"]], linewidth = 0.45, arrow = arrow(length = unit(3.5, "pt"), type = "closed")) +
  geom_point(data = pts, aes(onpg_mM, V0_umol_per_min_assay, colour = condition, shape = condition, fill = condition), size = 2.8, stroke = 0.6) +
  geom_text(data = pts, aes(onpg_mM, V0_umol_per_min_assay, label = tube), nudge_y = ifelse(pts$condition == "mm_no_inhibitor", 0.033, -0.033),
            nudge_x = 0.04, size = 2.7, family = FIG_FONT, colour = nebula[["ink"]]) +
  scale_colour_manual(values = COND_COLOURS, labels = COND_LABELS, name = NULL, guide = guide_legend(override.aes = list(fill = COND_COLOURS, shape = COND_SHAPES, linetype = "solid"))) +
  scale_shape_manual(values = COND_SHAPES, labels = COND_LABELS, name = NULL) + scale_fill_manual(values = COND_COLOURS, guide = "none") +
  scale_x_continuous(limits = c(0, 2.35), breaks = c(0, 0.55, 1.1, 1.65, 2.2), expand = expansion(mult = c(0, 0.01))) +
  scale_y_continuous(limits = c(0, 0.62), breaks = seq(0, 0.6, 0.1), expand = expansion(mult = c(0, 0.01))) +
  labs(title = "A   Michaelis–Menten representation",
       subtitle = "Solid: one competitive model fitted to both series\ndashed: Lineweaver–Burk hyperbolae; ↑ lower bound",
       x = lab_S, y = lab_V0u) +
  theme(legend.position = c(0.02, 0.98), legend.justification = c(0, 1), legend.background = element_rect(fill = alpha("white", 0.75), colour = NA))

pts4 <- pts |> mutate(inv_S = 1 / onpg_mM, inv_V = 1 / V0_umol_per_min_assay)
xr4 <- c(-3.6, 15.5)
lines4 <- bind_rows(tibble(condition = "mm_no_inhibitor", x = xr4, y = lbU$lb_intercept + lbU$lb_slope * xr4),
                    tibble(condition = "mm_plus_iptg",    x = xr4, y = lbI$lb_intercept + lbI$lb_slope * xr4)) |>
  mutate(condition = factor(condition, levels = names(COND_LABELS)))
p4b <- ggplot() +
  geom_hline(yintercept = 0, colour = nebula[["grey"]], linewidth = 0.35) + geom_vline(xintercept = 0, colour = nebula[["grey"]], linewidth = 0.35) +
  geom_line(data = lines4, aes(x, y, colour = condition, linetype = condition), linewidth = 0.8) +
  geom_point(data = pts4, aes(inv_S, inv_V, colour = condition, shape = condition, fill = condition), size = 2.7, stroke = 0.6, show.legend = FALSE) +
  geom_text(data = pts4, aes(inv_S, inv_V, label = tube), nudge_x = 0.5, nudge_y = ifelse(pts4$condition == "mm_no_inhibitor", -4.5, 4.5), size = 2.7, family = FIG_FONT, colour = nebula[["ink"]]) +
  annotate("text", x = 15.2, y = 48, hjust = 1, vjust = 1, size = 2.8, family = FIG_FONT, colour = nebula[["ink"]],
           label = sprintf("x-intercepts (−1/Kₘ):\n%.2f (no inhibitor)\n%.2f mM⁻¹ (+ IPTG)", -1 / lbU$Km, -1 / lbI$Km)) +
  scale_colour_manual(values = COND_COLOURS, labels = COND_LABELS, name = NULL) + scale_linetype_manual(values = COND_LINES, labels = COND_LABELS, name = NULL) +
  scale_shape_manual(values = COND_SHAPES) + scale_fill_manual(values = COND_COLOURS) +
  scale_x_continuous(breaks = seq(-3, 15, 3)) + scale_y_continuous(breaks = seq(0, 90, 15)) +
  coord_cartesian(xlim = xr4, ylim = c(-13, 100), expand = FALSE) +
  labs(title = "B   Lineweaver–Burk representation", subtitle = "Lines: least-squares fits that give the course-required\nKₘ, Vₘₐₓ, Kₘ,app and Vₘₐₓ,app",
       x = expression(1/"["*ONPG*"]"~(mM^-1)), y = expression(1/italic(V)[0]~"(min "*mu*mol^-1*")")) +
  theme(legend.position = c(0.02, 0.98), legend.justification = c(0, 1), legend.background = element_rect(fill = alpha("white", 0.75), colour = NA))
save_figure(p4a + p4b, "figure4_iptg_inhibition", 7.4, MAIN_FIG_H)

# Numbers used in captions and reports
vals <- tibble(
  name = c("lambda_max", "A_lmax", "eps", "eps_se", "eps_icpt", "eps_r2", "lin_max_mM", "excl_mM", "excl_A", "excl_pct",
           "ed_slope_umol", "ed_r2", "ed_free_icpt_umol", "ed_free_p", "ed_relrates", "ed_V0A_dA", "ed_V0E_dA", "ed_V0A_umol", "ed_V0E_umol",
           "lbU_Km", "lbU_Vmax", "lbU_r2", "lbU_slope", "lbU_icpt", "nlU_Km", "nlU_Km_se", "nlU_Vmax", "nlU_Vmax_se", "nlU_r2",
           "lbI_Km", "lbI_Vmax", "lbI_r2", "lbI_slope", "lbI_icpt", "lbI_icpt_se", "lbI_icpt_p", "Ki_lb", "I_mM",
           "g_Vmax", "g_Vmax_se", "g_Km", "g_Km_se", "g_Ki", "g_Ki_se", "u_V0A_umol", "u_V0F_umol", "i_V0A_umol", "i_V0F_umol", "k_umol"),
  value = c(lmax, cal("A_at_lambda_max"), eps, cal("epsilon_se"), eps_icpt, eps_r2, cal("linear_range_mM_max"), cal("excluded_standard_mM"), cal("excluded_standard_A"), cal("excluded_deviation_pct"),
            pr$slope_umol_per_min_per_unit_enzyme, pr$r2_about_mean, to_umol(fr$intercept), fr$intercept_p, NA, ed$V0_dA415_per_min[ed$tube == "A"], ed$V0_dA415_per_min[ed$tube == "E"],
            ed$V0_umol_per_min_assay[ed$tube == "A"], ed$V0_umol_per_min_assay[ed$tube == "E"],
            lbU$Km, lbU$Vmax, lbU$r2, lbU$lb_slope, lbU$lb_intercept, nlU$Km, nlU$Km_se, nlU$Vmax, nlU$Vmax_se, nlU$r2,
            lbI$Km, lbI$Vmax, lbI$r2, lbI$lb_slope, lbI$lb_intercept, lbI$lb_intercept_se, lbI$intercept_p, Ki_lb, I_mM,
            gV, if (have_g) gc$se[gc$parameter == "Vmax"] else NA, gK, if (have_g) gc$se[gc$parameter == "Km"] else NA, gKi, gKi_se,
            u$V0_umol_per_min_assay[u$tube == "A"], u$V0_umol_per_min_assay[u$tube == "F"],
            pts$V0_umol_per_min_assay[pts$condition == "mm_plus_iptg" & pts$tube == "A"], pts$V0_umol_per_min_assay[pts$condition == "mm_plus_iptg" & pts$tube == "F"], k_umol),
  text = c(rep(NA, 14), paste(sprintf("%.2f", ed$rel_rate), collapse = ", "), rep(NA, 34)))
write_csv(vals, file.path(dir_fig, "main_figure_values.csv"), na = "NA")

for (f in c("figure1_onp_calibration", "figure2_enzyme_dilution", "figure3_substrate_saturation", "figure4_iptg_inhibition"))
  check_that(all(file.exists(file.path(dir_fig, paste0(f, c(".png", ".pdf"))))), paste("figure not written:", f))
message("07_generate_figures.R: figures 1-4 written to ", dir_fig)
