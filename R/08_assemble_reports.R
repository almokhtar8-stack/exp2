# 08_assemble_reports.R
# Fill the report templates from the processed results so that every number in
# the prose comes from the pipeline:
#   report/submission_template.md         -> report/experiment_2_submission.md     (B241 course report)
#   report/full_template.md               -> report/experiment_2_report_full.md    (technical record / supplementary)
#   report/cell_style/cell_template.tex   -> report/cell_style/experiment_2_cell_style.tex (journal-style version)
#   report/figures_template.tex           -> report/experiment_2_figures.tex       (all figures with captions)
# Placeholders: {{name}} or {{name|digits}} for a number; {{TABLE:file}} inserts
# tables/<file>.md; {{LATEXROWS:file}} inserts the rows of tables/<file>.csv as
# LaTeX table rows; {{CAPTIONS}} inserts figures/README.md; {{REPO}} inserts the
# repository statement.
source(here::here("R", "00_setup.R"))

rd <- function(f, ...) read_csv(file.path(dir_proc, f), show_col_types = FALSE, ...)
vals_fig <- read_csv(file.path(dir_fig, "main_figure_values.csv"), show_col_types = FALSE)
fits <- rd("progress_curve_fits.csv"); v0 <- rd("v0_scenarios.csv"); sens <- rd("sensitivity_analysis.csv")
expk <- rd("experimental_secondary_kinetics.csv"); cmp <- rd("experimental_vs_reference_v0.csv"); depl <- rd("depletion_estimates.csv")
ed <- rd("enzyme_dilution_results.csv"); edfit <- rd("enzyme_dilution_fit.csv"); glob <- rd("global_fits.csv"); calib <- rd("onp_calibration.csv")
offs <- rd("origin_offset_scenario.csv"); calv <- rd("calibration_variants.csv")
PRIMARY <- "P: two-tier rule (primary)"; OFFSET <- "O: two-tier rule, baseline-offset scenario for the 0-2 min estimates"

vals <- setNames(as.list(vals_fig$value), vals_fig$name)
vals$ed_relrates <- vals_fig$text[vals_fig$name == "ed_relrates"]
vals$eps_M <- 1000 * vals$eps; vals$eps_icpt_abs <- abs(vals$eps_icpt)
vals$eps_icpt_p <- calib$value[calib$quantity == "intercept_p"]
vals$eps_origin <- calib$value[calib$quantity == "epsilon_through_origin"]
vals$eps_zero <- calib$value[calib$quantity == "epsilon_with_zero_point"]
vals$eps_all6 <- calib$value[calib$quantity == "epsilon_all_six"]
vals$excl_T <- calib$value[calib$quantity == "excluded_transmittance_pct"]
vals$instr_limit <- calib$value[calib$quantity == "instrument_linear_limit_A"]
vals$Vmax_scale_all6 <- calv$Vmax_scale_factor[calv$variant == "all six nonzero standards, free intercept"]
vals$REL_TOL_pct <- 100 * REL_TOL; vals$ABS_TOL <- ABS_TOL
vals$lbU_xint <- -1 / vals$lbU_Km; vals$lbI_xint <- -1 / vals$lbI_Km
vals$n_std <- calib$value[calib$quantity == "n_standards_used"]
# per-tube V0 (reference) in both units
for (cnd in c("mm_no_inhibitor", "mm_plus_iptg", "enzyme_dilution")) {
  d <- v0 |> filter(data_role == "reference", condition == cnd, estimator == PRIMARY)
  if (cnd == "enzyme_dilution") d <- ed |> filter(data_role == "reference") |> transmute(tube, V0_dA = V0_dA415_per_min, V0_umol_per_min_assay)
  pre <- c(mm_no_inhibitor = "u", mm_plus_iptg = "i", enzyme_dilution = "e")[[cnd]]
  for (k in seq_len(nrow(d))) { vals[[paste0(pre, "_dA_", d$tube[k])]] <- d$V0_dA[k]; vals[[paste0(pre, "_umol_", d$tube[k])]] <- d$V0_umol_per_min_assay[k] }
}
ed_r <- ed |> filter(data_role == "reference"); ed_e <- ed |> filter(data_role == "experimental")
for (k in seq_len(nrow(ed_r))) { vals[[paste0("e_rel_", ed_r$tube[k])]] <- ed_r$rel_rate[k]; vals[[paste0("e_rpe_", ed_r$tube[k])]] <- ed_r$rate_per_enzyme[k] }
vals$ed_rpe_min <- min(ed_r$rate_per_enzyme); vals$ed_rpe_max <- max(ed_r$rate_per_enzyme)
vals$ed_exp_r2 <- edfit$r2_about_mean[edfit$data_role == "experimental" & edfit$model == "proportional (through origin)"]
vals$ed_exp_relrates <- paste(sprintf("%.2f", ed_e$rel_rate), collapse = ", ")
vals$ed_fold_enzyme <- max(ed_r$rel_enzyme) / min(ed_r$rel_enzyme)
vals$ed_fold_rate <- max(ed_r$V0_dA415_per_min) / min(ed_r$V0_dA415_per_min)
# inhibition summaries
p <- sens |> filter(estimator == PRIMARY, method == "Lineweaver-Burk")
vals$Km_ratio_lb <- p$Km_ratio; vals$Vmax_ratio_lb <- p$Vmax_ratio; vals$Ki_noncomp_lb <- p$Ki_from_Vmax_noncompetitive
vals$lb_slope_ratio <- vals$lbI_slope / vals$lbU_slope
gc <- glob |> filter(model == "global competitive"); gn <- glob |> filter(model == "global noncompetitive"); gm <- glob |> filter(model == "global mixed")
vals$g_aic <- gc$aic[1]; vals$g_rss <- gc$rss[1]
vals$gn_aic <- gn$aic[1]; vals$gn_rss <- gn$rss[1]; vals$gn_Ki <- gn$estimate[gn$parameter == "Ki"]; vals$gn_Km <- gn$estimate[gn$parameter == "Km"]; vals$gn_Vmax <- gn$estimate[gn$parameter == "Vmax"]
vals$gn_rss_ratio <- gn$rss[1] / gc$rss[1]; vals$gn_daic <- gn$aic[1] - gc$aic[1]
vals$g_mixed_aic <- gm$aic[1]; vals$g_Kip <- gm$estimate[gm$parameter == "Kip"]; vals$g_mixed_Ki <- gm$estimate[gm$parameter == "Ki"]
vals$inh_pct_A <- 100 * (1 - vals$i_umol_A / vals$u_umol_A); vals$inh_pct_F <- 100 * (1 - vals$i_umol_F / vals$u_umol_F)
vals$inh_pct_B <- 100 * (1 - vals$i_umol_B / vals$u_umol_B); vals$inh_pct_D <- 100 * (1 - vals$i_umol_D / vals$u_umol_D)
vals$u_fold_AF <- vals$u_umol_A / vals$u_umol_F; vals$i_fold_AF <- vals$i_umol_A / vals$i_umol_F
# depletion (reference, no inhibitor)
du <- depl |> filter(data_role == "reference", condition == "mm_no_inhibitor")
for (k in seq_len(nrow(du))) { vals[[paste0("conv2_", du$tube[k])]] <- du$percent_converted_2min[k]; vals[[paste0("conv10_", du$tube[k])]] <- du$percent_converted_10min[k] }
ds <- depl |> filter(data_role == "experimental", condition == "mm_no_inhibitor")
for (k in seq_len(nrow(ds))) vals[[paste0("sconv10_", ds$tube[k])]] <- ds$percent_converted_10min[k]
# estimator sensitivity
pick <- function(est, meth = "Lineweaver-Burk") sens |> filter(estimator == est, method == meth)
sA <- pick("A: all five points for every curve"); vals$A_Km <- sA$Km
sR <- pick("R: initial-window regression only"); vals$R_icpt_sign <- ifelse(sR$physical, "positive", "negative")
sS <- pick("S: origin-assumed 0-2 min average rate for every curve"); vals$S_Km <- sS$Km; vals$S_Kmapp <- sS$Km_app; vals$S_Ki <- sS$Ki_competitive
sO <- pick(OFFSET); vals$O_Km <- sO$Km; vals$O_Kmapp <- sO$Km_app; vals$O_Ki <- sO$Ki_competitive; vals$O_Km_ratio <- sO$Km_ratio; vals$O_Vmax <- sO$Vmax
sOn <- pick(OFFSET, "Nonlinear MM"); vals$O_nl_Km <- sOn$Km; vals$O_nl_Vmax <- sOn$Vmax
ki_set <- c(vals$Ki_lb, vals$g_Ki, vals$O_Ki); vals$Ki_min <- min(ki_set); vals$Ki_max <- max(ki_set)
km_set <- c(vals$lbU_Km, vals$nlU_Km, vals$O_Km, vals$O_nl_Km, vals$g_Km); vals$Km_min <- min(km_set); vals$Km_max <- max(km_set)
# origin offset test
ob <- offs |> filter(data_role == "both"); orf <- offs |> filter(data_role == "reference")
vals$off_median <- ob$median_intercept; vals$off_min <- ob$min_intercept; vals$off_max <- ob$max_intercept; vals$off_n <- ob$n_curves
vals$off_shift_median <- ob$median_scenario_shift_dA_per_min; vals$off_shift_max <- ob$max_scenario_shift_dA_per_min
vals$off_ref_median <- orf$median_intercept; vals$off_ref_max <- orf$max_intercept
# experimental dataset kinetics (tube B excluded / included)
su <- expk |> filter(tube_B == "excluded")
for (m in c("Lineweaver-Burk", "Nonlinear MM")) { r <- su |> filter(method == m); pre <- ifelse(m == "Lineweaver-Burk", "s_lb", "s_nl")
  vals[[paste0(pre, "_Km")]] <- r$Km; vals[[paste0(pre, "_Kmapp")]] <- r$Km_app; vals[[paste0(pre, "_Vmax")]] <- r$Vmax; vals[[paste0(pre, "_Vmaxapp")]] <- r$Vmax_app
  vals[[paste0(pre, "_Ki")]] <- r$Ki_competitive; vals[[paste0(pre, "_Vratio")]] <- r$Vmax_ratio; vals[[paste0(pre, "_Kratio")]] <- r$Km_ratio
  vals[[paste0(pre, "_Km_se")]] <- r$Km_se; vals[[paste0(pre, "_Kmapp_se")]] <- r$Km_app_se; vals[[paste0(pre, "_Vmax_se")]] <- r$Vmax_se; vals[[paste0(pre, "_n")]] <- r$n; vals[[paste0(pre, "_napp")]] <- r$n_app }
vals$s_nl_Ki_se <- (su |> filter(method == "Nonlinear MM"))$Ki_se
sg <- su |> filter(method == "Global nonlinear competitive")
if (nrow(sg) == 1) { vals$s_g_Ki <- sg$Ki_competitive; vals$s_g_Ki_se <- sg$Ki_se; vals$s_g_Km <- sg$Km; vals$s_g_Km_se <- sg$Km_se; vals$s_g_Vmax <- sg$Vmax; vals$s_g_Vmax_se <- sg$Vmax_se }
sgB <- expk |> filter(tube_B == "included", method == "Global nonlinear competitive")
if (nrow(sgB) == 1) { vals$s_g_Ki_withB <- sgB$Ki_competitive; vals$s_g_Ki_withB_se <- sgB$Ki_se }
tbr <- rd("experimental_tubeB_control_ratio.csv"); vals$s_B_over_control <- tbr$value[1]; vals$s_B_over_control_pct <- 100 * (tbr$value[1] - 1)
sB <- expk |> filter(tube_B == "included", method == "Lineweaver-Burk"); vals$s_lb_Kmapp_withB <- sB$Km_app
sBn <- expk |> filter(tube_B == "included", method == "Nonlinear MM"); vals$s_nl_Ki_withB <- sBn$Ki_competitive; vals$s_nl_Kmapp_withB <- sBn$Km_app
for (k in seq_len(nrow(cmp))) if (!is.na(cmp$ratio_experimental_over_reference[k]))
  vals[[paste0("r_", c(enzyme_dilution = "e", mm_no_inhibitor = "u", mm_plus_iptg = "i")[[cmp$condition[k]]], "_", cmp$tube[k])]] <- cmp$ratio_experimental_over_reference[k]
sf <- fits |> filter(data_role == "experimental")
vals$s_blackB_V0 <- sf$V0_dA415_per_min[sf$dataset == "Experimental Part III (+IPTG)" & sf$tube == "B"]
vals$s_blackA_V0 <- sf$V0_dA415_per_min[sf$dataset == "Experimental Part III (+IPTG)" & sf$tube == "A"]
vals$s_blackB_over_A <- vals$s_blackB_V0 / vals$s_blackA_V0
vals$s_day1A_10 <- sf$a415_10min[sf$dataset == "Experimental Part II" & sf$tube == "A"]
vals$s_blueA_10 <- sf$a415_10min[sf$dataset == "Experimental Part III (-IPTG)" & sf$tube == "A"]
vals$s_blackA_10 <- sf$a415_10min[sf$dataset == "Experimental Part III (+IPTG)" & sf$tube == "A"]
vals$r_edA_10 <- fits$a415_10min[fits$dataset == "Reference Part II" & fits$tube == "A"]
vals$r_uA_10 <- fits$a415_10min[fits$dataset == "Reference Part III (-IPTG)" & fits$tube == "A"]
vals$n_secant_reference <- sum(fits$origin_assumed[fits$data_role == "reference"], na.rm = TRUE)
vals$n_curves_reference <- sum(fits$data_role == "reference")
vals$n_curves_total <- sum(fits$n_used > 0)
vals$plateau_frac_E <- vals$conv10_E; vals$plateau_frac_F <- vals$conv10_F
# repository statement
vals$REPO <- if (is.na(REPOSITORY_URL)) "repository `experiment-2-beta-galactosidase-kinetics` (public publication pending; the complete project accompanies this report)" else sprintf("public repository %s", REPOSITORY_URL)
vals$REPO_TEX <- if (is.na(REPOSITORY_URL)) "repository \\texttt{experiment-2-beta-galactosidase-kinetics} (public publication pending at the time of writing; the complete project accompanies this report)" else sprintf("public repository \\url{%s}", REPOSITORY_URL)
vals$DATE <- format(Sys.Date(), "%d %B %Y")

fmt_val <- function(v, d) { if (is.character(v)) return(v); if (is.na(d)) return(format(v)); if (abs(v) >= 1e4) return(format(round(v), big.mark = "")); formatC(v, digits = d, format = "f") }
latex_escape <- function(x) { x <- as.character(x); x[is.na(x) | x == "NA"] <- "–"
  x <- gsub("\\\\", "\\\\textbackslash{}", x); x <- gsub("([%&_#$])", "\\\\\\1", x); x <- gsub("\\^", "\\\\textasciicircum{}", x); x }
fill_template <- function(tmpl) {
  m <- gregexpr("\\{\\{([A-Za-z0-9_]+)(\\|(-?\\d+))?\\}\\}", tmpl)
  for (i in seq_along(tmpl)) {
    for (h in unique(regmatches(tmpl[i], m[i])[[1]])) {
      key <- sub("\\{\\{([A-Za-z0-9_]+).*", "\\1", h); dig <- suppressWarnings(as.integer(sub(".*\\|(-?\\d+)\\}\\}", "\\1", h)))
      if (!grepl("\\|", h)) dig <- NA
      if (key %in% c("TABLE", "CAPTIONS", "LATEXROWS")) next
      if (is.null(vals[[key]])) stop("Unknown placeholder: ", key)
      tmpl[i] <- gsub(h, fmt_val(vals[[key]], dig), tmpl[i], fixed = TRUE)
    }
  }
  for (i in seq_along(tmpl)) {
    if (grepl("^\\{\\{LATEXROWS:[A-Za-z0-9_]+\\}\\}$", tmpl[i])) {
      f <- sub("^\\{\\{LATEXROWS:([A-Za-z0-9_]+)\\}\\}$", "\\1", tmpl[i])
      d <- read_csv(file.path(dir_tab, paste0(f, ".csv")), show_col_types = FALSE, col_types = cols(.default = "c"))
      tmpl[i] <- paste0(paste(apply(d, 1, function(r) paste(latex_escape(r), collapse = " & ")), collapse = " \\\\\n"), " \\\\")
    }
    if (grepl("^\\{\\{TABLE:[A-Za-z0-9_]+\\}\\}$", tmpl[i])) {
      f <- sub("^\\{\\{TABLE:([A-Za-z0-9_]+)\\}\\}$", "\\1", tmpl[i]); tmpl[i] <- paste(readLines(file.path(dir_tab, paste0(f, ".md")), encoding = "UTF-8"), collapse = "\n")
    }
    if (tmpl[i] == "{{CAPTIONS}}") tmpl[i] <- paste(readLines(file.path(dir_fig, "README.md"), encoding = "UTF-8")[-(1:2)], collapse = "\n")
  }
  left <- grep("\\{\\{[A-Za-z0-9_:]+(\\|-?\\d+)?\\}\\}", tmpl, value = TRUE)
  if (length(left)) stop("Unfilled placeholder(s): ", paste(head(left, 3), collapse = " | "))
  tmpl
}
for (pair in list(c("submission_template.md", "experiment_2_submission.md"), c("full_template.md", "experiment_2_report_full.md"),
                  c("cell_style/cell_template.tex", "cell_style/experiment_2_cell_style.tex"), c("figures_template.tex", "experiment_2_figures.tex"))) {
  if (!file.exists(file.path(dir_rep, pair[1]))) { message("template missing: ", pair[1]); next }
  out <- fill_template(readLines(file.path(dir_rep, pair[1]), encoding = "UTF-8"))
  writeLines(out, file.path(dir_rep, pair[2]), useBytes = FALSE)
  message("08_assemble_reports.R: wrote ", pair[2], " (", length(out), " lines)")
}
write_csv(tibble(name = names(vals), value = sapply(vals, function(x) as.character(x))), file.path(dir_proc, "report_values.csv"))
