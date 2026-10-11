# 07_generate_figures.R
# Main figures 1-4 (reference dataset). Each is a two-panel figure drawn at its
# final printed size, 6.5 x 1.85 in (the full text width of the course report),
# so that every type size below is the size on the page: panel titles 9 pt,
# axis titles 8.5 pt, tick labels and legends 7.5 pt (600 dpi PNG plus vector PDF).
# Conventions in every progress-curve panel: filled symbol, observation used
# for V0; open symbol, observation retained but not used; solid line, fitted
# initial window; dashed segment from a grey cross at the origin, origin-assumed
# 0-2 min average rate (no reading exists at t = 0); dotted line, extrapolation
# of the fit. Origin-assumed estimates carry a dagger in the velocity plot
# (Figure 4A), as in the tables.
# Fit equations, parameter values and explanations are given in the captions
# and tables, not drawn over the data.
#
# Inputs : data/processed/*.csv
# Outputs: figures/figure1_onp_calibration, figure2_enzyme_dilution,
#          figure3_substrate_saturation (progress curves without and with IPTG),
#          figure4_iptg_inhibition (Michaelis-Menten and Lineweaver-Burk plots) (.png and .pdf)
#          figures/main_figure_values.csv (numbers used in the captions)
source(here::here("R", "00_setup.R"))
suppressPackageStartupMessages(library(patchwork))

FIG_W <- 6.5; FIG_H <- 1.85         # inches, final printed size
fs <- function(pt) pt / .pt         # ggplot2 text size (mm) from points

theme_fig <- function() {
  theme_nebula_science(base_size = 8.5) +
    theme(axis.text         = element_text(size = 7.5),
          axis.title        = element_text(size = 8.5),
          axis.title.x      = element_text(margin = margin(t = 3)),
          axis.title.y      = element_text(margin = margin(r = 3)),
          axis.ticks.length = unit(2, "pt"),
          plot.title        = element_text(size = 9, margin = margin(b = 3)),
          legend.text       = element_text(size = 7.5),
          legend.title      = element_text(size = 7.5, face = "bold"),
          legend.key.size   = unit(8, "pt"),
          legend.key.width  = unit(14, "pt"),
          legend.margin     = margin(0, 0, 0, 0),
          legend.box.margin = margin(0, 0, 0, 0),
          legend.box.spacing = unit(3, "pt"),
          legend.spacing.x  = unit(3, "pt"),
          plot.margin       = margin(3, 6, 2, 3))
}
theme_set(theme_fig())
legend_top    <- theme(legend.position = "top", legend.justification = "left", legend.direction = "horizontal", legend.margin = margin(0, 0, 0, 4))
legend_inside <- function(x, y, jx, jy) theme(legend.position = c(x, y), legend.justification = c(jx, jy),
                                              legend.background = element_rect(fill = alpha("white", 0.85), colour = NA))

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

lab_A415 <- expression(italic(A)[415])
lab_time <- "Time (min)"
lab_V0u  <- expression(italic(V)[0]~"("*mu*mol~min^-1*")")
lab_S    <- "[ONPG] (mM)"
PT_SIZE  <- 1.9; PT_STROKE <- 0.45     # marker diameter about 5 pt on the page
LW_FIT   <- 0.6; LW_GUIDE <- 0.35

# Shared progress-curve panel ---------------------------------------------------------
progress_panel <- function(ds, tubes, title, ylim, ybreaks) {
  o <- tidy |> filter(dataset == ds, measured) |>
    left_join(fits |> select(dataset, tube, origin_assumed, slope, intercept, t_last, V0_dA415_per_min), by = c("dataset", "tube")) |>
    mutate(used = if_else(origin_assumed, time_min == 2, time_min <= t_last))
  f <- fits |> filter(dataset == ds, n_used > 0) |>
    mutate(x0 = if_else(origin_assumed, 0, t_first), x1 = if_else(origin_assumed, 2, t_last),
           y0 = if_else(origin_assumed, 0, intercept + slope * t_first), y1 = if_else(origin_assumed, V0_dA415_per_min * 2, intercept + slope * t_last),
           ye = if_else(origin_assumed, V0_dA415_per_min * 10, intercept + slope * 10))
  ggplot() +
    geom_segment(data = f |> filter(x1 < 10), aes(x = x1, xend = 10, y = y1, yend = ye, colour = tube),
                 linetype = "dotted", linewidth = LW_GUIDE, alpha = 0.7, show.legend = FALSE) +
    geom_segment(data = f |> filter(!origin_assumed), aes(x = x0, xend = x1, y = y0, yend = y1, colour = tube),
                 linewidth = LW_FIT, show.legend = FALSE) +
    geom_segment(data = f |> filter(origin_assumed), aes(x = x0, xend = x1, y = y0, yend = y1, colour = tube),
                 linetype = "22", linewidth = LW_FIT, show.legend = FALSE) +
    geom_point(data = f |> filter(origin_assumed) |> distinct(x0, y0), aes(x0, y0), shape = 4, size = 1.8, stroke = 0.6, colour = nebula[["grey"]]) +
    geom_point(data = o |> filter(!used), aes(time_min, absorbance_415nm, colour = tube, shape = tube), fill = "white", size = PT_SIZE, stroke = PT_STROKE) +
    geom_point(data = o |> filter(used), aes(time_min, absorbance_415nm, colour = tube, shape = tube, fill = tube), size = PT_SIZE, stroke = PT_STROKE) +
    scale_colour_manual(values = TUBE_COLOURS, breaks = tubes, name = "Tube",
                        guide = guide_legend(nrow = 1, override.aes = list(fill = TUBE_COLOURS[tubes], shape = TUBE_SHAPES[tubes], size = PT_SIZE))) +
    scale_shape_manual(values = TUBE_SHAPES, breaks = tubes, name = "Tube") +
    scale_fill_manual(values = TUBE_COLOURS, guide = "none") +
    scale_x_continuous(breaks = seq(0, 10, 2), limits = c(0, 10.4), expand = expansion(mult = c(0, 0.01))) +
    scale_y_continuous(limits = ylim, breaks = ybreaks, expand = expansion(mult = c(0, 0.02))) +
    coord_cartesian(clip = "off") +
    labs(title = title, x = lab_time, y = lab_A415) +
    legend_top + theme(legend.key.width = unit(8, "pt"))
}

# Figure 1: spectrum and calibration ------------------------------------------------
band <- str_split(calib$text[calib$quantity == "band_within_2pct_nm"], "-")[[1]] |> as.numeric()
sp_smooth <- as_tibble(spline(spec$wavelength_nm, spec$absorbance, n = 200)) |> rename(wavelength_nm = x, absorbance = y)
p1a <- ggplot(spec, aes(wavelength_nm, absorbance)) +
  annotate("rect", xmin = band[1], xmax = band[2], ymin = -Inf, ymax = Inf, fill = nebula[["mist"]]) +
  geom_vline(xintercept = lmax, colour = nebula[["magenta"]], linewidth = 0.4, linetype = "longdash") +
  geom_line(data = sp_smooth, colour = nebula[["purple"]], linewidth = LW_FIT) +
  geom_point(colour = nebula[["violet"]], fill = "white", shape = 21, size = 1.6, stroke = 0.55) +
  geom_point(data = spec |> filter(wavelength_nm == lmax), colour = nebula[["magenta"]], fill = nebula[["magenta"]], shape = 21, size = PT_SIZE) +
  annotate("text", x = 386, y = 1.82, hjust = 0, vjust = 1, size = fs(7.5), family = FIG_FONT, colour = nebula[["ink"]],
           label = sprintf("lambda[max]~'='~'%d nm'", lmax), parse = TRUE) +
  scale_x_continuous(breaks = seq(385, 465, 20), expand = expansion(mult = 0.02)) +
  scale_y_continuous(limits = c(0.6, 1.85), breaks = seq(0.6, 1.8, 0.3), expand = expansion(mult = c(0, 0.02))) +
  labs(title = "A   ONP absorption spectrum", x = "Wavelength (nm)", y = "Absorbance")

zero_pt <- std0 |> filter(reported, onp_ml == 0)
p1b <- ggplot(stdf, aes(onp_mM_cuvette, abs_415nm)) +
  annotate("rect", xmin = 0, xmax = cal("linear_range_mM_max"), ymin = -Inf, ymax = Inf, fill = nebula[["mist"]]) +
  geom_abline(intercept = eps_icpt, slope = eps, colour = nebula[["blue"]], linewidth = LW_FIT) +
  geom_point(data = zero_pt, aes(onp_mM_cuvette, abs_415nm), shape = 4, size = 2.6, stroke = 0.8, colour = nebula[["ink"]]) +
  geom_point(data = stdf |> filter(!used_in_fit), colour = nebula[["rose"]], fill = "white", shape = 21, size = PT_SIZE + 0.2, stroke = 0.7) +
  geom_point(data = stdf |> filter(used_in_fit), colour = nebula[["violet"]], fill = nebula[["violet"]], shape = 21, size = PT_SIZE, stroke = PT_STROKE) +
  annotate("text", x = cal("excluded_standard_mM") - 0.03, y = cal("excluded_standard_A"), hjust = 1, vjust = 0.5, size = fs(7.5), family = FIG_FONT,
           colour = nebula[["ink"]], label = sprintf("excluded, +%.0f%%", cal("excluded_deviation_pct"))) +
  scale_x_continuous(limits = c(0, 0.57), breaks = seq(0, 0.5, 0.1), expand = expansion(mult = c(0, 0.01))) +
  scale_y_continuous(limits = c(0, 3.4), breaks = seq(0, 3, 1), expand = expansion(mult = c(0, 0.01))) +
  coord_cartesian(clip = "off") +
  labs(title = "B   ONP standard curve, 415 nm", x = "[ONP] (mM)", y = lab_A415)
save_figure(p1a + p1b, "figure1_onp_calibration", FIG_W, FIG_H)

# Figure 2: enzyme dilution ------------------------------------------------------------
p2a <- progress_panel("Reference Part II", LETTERS[1:5], "A   Progress curves, five enzyme levels", ylim = c(0, 1.55), ybreaks = seq(0, 1.5, 0.5))
pr <- edfit |> filter(model == "proportional (through origin)"); fr <- edfit |> filter(model == "free intercept")
k_umol <- to_umol(1)
lab_pos2 <- tibble(tube = c("A", "B", "C", "D", "E"), dx = c(0.035, 0.035, 0.035, 0.035, -0.035), dy = c(-0.035, -0.035, -0.035, -0.035, 0.035), hjust = c(0, 0, 0, 0, 1))
ed_lab <- ed |> inner_join(lab_pos2, by = "tube")
p2b <- ggplot(ed, aes(rel_enzyme, V0_umol_per_min_assay)) +
  geom_abline(intercept = 0, slope = pr$slope_umol_per_min_per_unit_enzyme, colour = nebula[["violet"]], linewidth = LW_FIT) +
  geom_point(aes(colour = tube, shape = tube, fill = tube), size = PT_SIZE + 0.2, stroke = PT_STROKE, show.legend = FALSE) +
  geom_text(data = ed_lab, aes(rel_enzyme + dx, V0_umol_per_min_assay + dy, label = tube, hjust = hjust), size = fs(7.5), family = FIG_FONT, colour = nebula[["ink"]]) +
  scale_colour_manual(values = TUBE_COLOURS) + scale_fill_manual(values = TUBE_COLOURS) + scale_shape_manual(values = TUBE_SHAPES) +
  scale_x_continuous(limits = c(0, 1.08), breaks = c(0, 0.25, 0.5, 0.75, 1), expand = expansion(mult = c(0, 0.01))) +
  scale_y_continuous(limits = c(0, 0.54), breaks = seq(0, 0.5, 0.1), expand = expansion(mult = c(0, 0.01))) +
  labs(title = "B   Initial rate against enzyme amount", x = "Relative enzyme (tube A = 1)", y = lab_V0u)
save_figure(p2a + p2b, "figure2_enzyme_dilution", FIG_W, FIG_H)

# Figure 3: progress curves without and with IPTG -----------------------------------------
# Panel B has its own absorbance scale (0-1.0) because the inhibited reactions are 2- to 8-fold slower.
p3a <- progress_panel("Reference Part III (-IPTG)", LETTERS[1:6], "A   Progress curves, no inhibitor", ylim = c(0, 1.45), ybreaks = seq(0, 1.4, 0.2))
p3b <- progress_panel("Reference Part III (+IPTG)", LETTERS[1:6], sprintf("B   Progress curves, + %.3f mM IPTG", unique(na.omit(v0s$iptg_mM[v0s$condition == "mm_plus_iptg"]))),
                      ylim = c(0, 1.02), ybreaks = seq(0, 1, 0.2))   # own scale: the inhibited curves are 2- to 8-fold lower
fig3 <- (p3a + p3b) + plot_layout(guides = "collect") & legend_top
save_figure(fig3, "figure3_substrate_saturation", FIG_W, FIG_H)

# Quantities of the uninhibited series used by Figure 4 and the caption values
u   <- v0s |> filter(data_role == "reference", condition == "mm_no_inhibitor", estimator == PRIMARY)
lbU <- kin |> filter(condition == "mm_no_inhibitor", method == "Lineweaver-Burk"); nlU <- kin |> filter(condition == "mm_no_inhibitor", method == "Nonlinear MM")
Sg  <- tibble(S = seq(0.001, 2.35, length.out = 300))

# Figure 4: IPTG inhibition -----------------------------------------------------------------
pts <- v0s |> filter(data_role == "reference", estimator == PRIMARY) |> mutate(condition = factor(condition, levels = names(COND_LABELS)))
lbI <- kin |> filter(condition == "mm_plus_iptg", method == "Lineweaver-Burk")
gc  <- glob |> filter(model == "global competitive", converged)
Ki_lb <- sens |> filter(estimator == PRIMARY, method == "Lineweaver-Burk") |> pull(Ki_competitive)
have_g <- nrow(gc) == 3
gV <- if (have_g) gc$estimate[gc$parameter == "Vmax"] else NA; gK <- if (have_g) gc$estimate[gc$parameter == "Km"] else NA; gKi <- if (have_g) gc$estimate[gc$parameter == "Ki"] else NA
gKi_se <- if (have_g) gc$se[gc$parameter == "Ki"] else NA
FIT_LINES  <- c("Global competitive" = "solid", "Lineweaver-Burk" = "22")
FIT_LABELS <- c("Global competitive" = "Competitive model, global fit", "Lineweaver-Burk" = "Lineweaver–Burk hyperbola")
cur4 <- bind_rows(
  Sg |> mutate(condition = "mm_no_inhibitor", kind = "Lineweaver-Burk", V = lbU$Vmax * S / (lbU$Km + S)),
  Sg |> mutate(condition = "mm_plus_iptg",    kind = "Lineweaver-Burk", V = lbI$Vmax * S / (lbI$Km + S)),
  if (have_g) Sg |> mutate(condition = "mm_no_inhibitor", kind = "Global competitive", V = gV * S / (gK + S)),
  if (have_g) Sg |> mutate(condition = "mm_plus_iptg",    kind = "Global competitive", V = gV * S / (gK * (1 + I_mM / gKi) + S))) |>
  mutate(condition = factor(condition, levels = names(COND_LABELS)), kind = factor(kind, levels = names(FIT_LINES)))
# Dagger positions chosen by hand so that none sits on a curve or another marker
dag_pos4 <- tibble(condition = c(rep("mm_no_inhibitor", 5), "mm_plus_iptg"), tube = c("B", "C", "D", "E", "F", "A"),
                   dx = c(-0.05, 0.05, 0.05, 0.045, 0.045, 0.05), dy = c(-0.045, -0.045, -0.04, 0.035, 0, 0), hjust = c(1, 0, 0, 0, 0, 0))
dag4 <- pts |> filter(origin_assumed) |> mutate(condition = as.character(condition)) |> inner_join(dag_pos4, by = c("condition", "tube"))
check_that(nrow(dag4) == sum(pts$origin_assumed), "every origin-assumed point in Figure 4A has a dagger position")
p4a <- ggplot() +
  geom_line(data = cur4, aes(S, V, colour = condition, linetype = kind), linewidth = LW_FIT, show.legend = c(colour = FALSE, linetype = TRUE)) +
  geom_point(data = pts, aes(onpg_mM, V0_umol_per_min_assay, colour = condition, shape = condition, fill = condition), size = PT_SIZE, stroke = PT_STROKE) +
  geom_text(data = dag4, aes(onpg_mM + dx, V0_umol_per_min_assay + dy, label = "†", hjust = hjust), size = fs(8), family = FIG_FONT, colour = nebula[["ink"]]) +
  scale_colour_manual(values = COND_COLOURS, labels = COND_LABELS, name = NULL,
                      guide = guide_legend(order = 1, override.aes = list(fill = COND_COLOURS, shape = COND_SHAPES, linetype = "blank", size = PT_SIZE))) +
  scale_shape_manual(values = COND_SHAPES, guide = "none") + scale_fill_manual(values = COND_COLOURS, guide = "none") +
  scale_linetype_manual(values = FIT_LINES, labels = FIT_LABELS, name = NULL,
                        guide = guide_legend(order = 2, override.aes = list(colour = nebula[["ink"]], linewidth = LW_FIT))) +
  scale_x_continuous(limits = c(0, 2.35), breaks = c(0, 0.5, 1, 1.5, 2), expand = expansion(mult = c(0, 0.01))) +
  scale_y_continuous(limits = c(0, 0.62), breaks = seq(0, 0.6, 0.2), expand = expansion(mult = c(0, 0.01))) +
  labs(title = "A   Michaelis–Menten plot", x = lab_S, y = lab_V0u)

pts4 <- pts |> mutate(inv_S = 1 / onpg_mM, inv_V = 1 / V0_umol_per_min_assay)
xr4 <- c(-3.6, 15.5)
lines4 <- bind_rows(tibble(condition = "mm_no_inhibitor", x = xr4, y = lbU$lb_intercept + lbU$lb_slope * xr4),
                    tibble(condition = "mm_plus_iptg",    x = xr4, y = lbI$lb_intercept + lbI$lb_slope * xr4)) |>
  mutate(condition = factor(condition, levels = names(COND_LABELS)))
line_lab4 <- tibble(x = c(15.2, 11.3), y = c(lbU$lb_intercept + lbU$lb_slope * 15.2 + 7, 93), hjust = 1, vjust = c(0, 1),
                    label = c("No inhibitor", sprintf("+ %.3f mM IPTG", I_mM)))
p4b <- ggplot() +
  geom_hline(yintercept = 0, colour = nebula[["grey"]], linewidth = 0.3) + geom_vline(xintercept = 0, colour = nebula[["grey"]], linewidth = 0.3) +
  geom_line(data = lines4, aes(x, y, colour = condition, linetype = condition), linewidth = LW_FIT, show.legend = FALSE) +
  geom_point(data = pts4, aes(inv_S, inv_V, colour = condition, shape = condition, fill = condition), size = PT_SIZE, stroke = PT_STROKE, show.legend = FALSE) +
  geom_text(data = line_lab4, aes(x, y, label = label, hjust = hjust, vjust = vjust), size = fs(7.5), family = FIG_FONT, colour = nebula[["ink"]]) +
  scale_colour_manual(values = COND_COLOURS, guide = "none") + scale_linetype_manual(values = COND_LINES, guide = "none") +
  scale_shape_manual(values = COND_SHAPES, guide = "none") + scale_fill_manual(values = COND_COLOURS, guide = "none") +
  scale_x_continuous(breaks = seq(-3, 15, 3)) + scale_y_continuous(breaks = seq(0, 90, 30)) +
  coord_cartesian(xlim = xr4, ylim = c(-13, 100), expand = FALSE) +
  labs(title = "B   Lineweaver–Burk plot", x = expression(1/"["*ONPG*"]"~(mM^-1)), y = expression(1/italic(V)[0]~"(min "*mu*mol^-1*")"))
fig4 <- (p4a + p4b) + plot_layout(guides = "collect") & legend_top
save_figure(fig4, "figure4_iptg_inhibition", FIG_W, FIG_H)

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
