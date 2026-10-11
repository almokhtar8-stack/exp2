# 06_inhibition.R
# Part III with IPTG (reference dataset, tubes A-F): apparent Km and Vmax by
# Lineweaver-Burk (course method) and by nonlinear fitting of the inhibited
# series on its own, Ki by the manual's competitive relation, global fits of
# the competitive, pure noncompetitive and mixed models to both series at once,
# the sensitivity of every parameter to the V0 estimator, and the same analysis
# of the experimental dataset for the Discussion.
#
# Manual: Km_app = Km (1 + [I]/Ki) -> Ki = [I]/(Km_app/Km - 1); [I] = 5.5 x 1.0/12.0 = 0.458 mM.
#
# Inputs : data/processed/v0_scenarios.csv, progress_curve_fits.csv
# Outputs: data/processed/kinetic_parameters.csv, inhibition_parameters.csv, sensitivity_analysis.csv,
#          global_fits.csv, global_fit_residuals.csv, experimental_secondary_kinetics.csv,
#          experimental_tubeB_control_ratio.csv,
#          experimental_vs_reference_v0.csv
#          tables/table5_kinetic_parameters, table5b_inhibition, table_results_substrate,
#          tableS6_sensitivity, tableS7_experimental_secondary, tableS8_experimental_vs_reference,
#          tableS9_global_fits
source(here::here("R", "00_setup.R"))

v0   <- read_csv(file.path(dir_proc, "v0_scenarios.csv"), show_col_types = FALSE)
fits <- read_csv(file.path(dir_proc, "progress_curve_fits.csv"), show_col_types = FALSE)
I_mM <- unique(na.omit(v0$iptg_mM[v0$condition == "mm_plus_iptg"])); check_that(length(I_mM) == 1, "more than one IPTG concentration")
PRIMARY <- "P: two-tier rule (primary)"

# Paired analysis (uninhibited and inhibited series) for one set of V0 values
pair_fit <- function(u, i) bind_rows(
  fit_lineweaver_burk(u$onpg_mM, u$V0) |> mutate(condition = "mm_no_inhibitor", tubes = paste(u$tube, collapse = "")),
  fit_mm_nls(u$onpg_mM, u$V0)          |> mutate(condition = "mm_no_inhibitor", tubes = paste(u$tube, collapse = "")),
  fit_lineweaver_burk(i$onpg_mM, i$V0) |> mutate(condition = "mm_plus_iptg", tubes = paste(i$tube, collapse = "")),
  fit_mm_nls(i$onpg_mM, i$V0)          |> mutate(condition = "mm_plus_iptg", tubes = paste(i$tube, collapse = "")))
summarise_pair <- function(res) {
  res |> select(method, condition, Km, Vmax, r2, n, tubes, lb_slope, lb_intercept, physical, Km_se, Vmax_se) |>
    pivot_wider(names_from = condition, values_from = c(Km, Vmax, r2, n, tubes, lb_slope, lb_intercept, physical, Km_se, Vmax_se)) |>
    transmute(method,
              Km = Km_mm_no_inhibitor, Km_se = Km_se_mm_no_inhibitor, Vmax = Vmax_mm_no_inhibitor, Vmax_se = Vmax_se_mm_no_inhibitor,
              r2 = r2_mm_no_inhibitor, n = n_mm_no_inhibitor, tubes = tubes_mm_no_inhibitor, physical = physical_mm_no_inhibitor,
              Km_app = Km_mm_plus_iptg, Km_app_se = Km_se_mm_plus_iptg, Vmax_app = Vmax_mm_plus_iptg, Vmax_app_se = Vmax_se_mm_plus_iptg,
              r2_app = r2_mm_plus_iptg, n_app = n_mm_plus_iptg, tubes_app = tubes_mm_plus_iptg, physical_app = physical_mm_plus_iptg,
              lb_slope = lb_slope_mm_no_inhibitor, lb_intercept = lb_intercept_mm_no_inhibitor,
              lb_slope_app = lb_slope_mm_plus_iptg, lb_intercept_app = lb_intercept_mm_plus_iptg,
              I_mM = I_mM, Km_ratio = Km_app / Km, Vmax_ratio = Vmax_app / Vmax,
              Ki_competitive = ki_competitive(Km, Km_app, I_mM),
              Ki_from_Vmax_noncompetitive = ki_noncompetitive(Vmax, Vmax_app, I_mM))
}

# Reference dataset: primary analysis and estimator scenarios
ref <- v0 |> filter(data_role == "reference")
sens <- ref |> group_by(estimator) |>
  group_modify(~ summarise_pair(pair_fit(filter(.x, condition == "mm_no_inhibitor") |> mutate(V0 = V0_umol_per_min_assay),
                                         filter(.x, condition == "mm_plus_iptg")    |> mutate(V0 = V0_umol_per_min_assay)))) |>
  ungroup() |> mutate(primary = estimator == PRIMARY & method == "Lineweaver-Burk", V0_units = "umol/min per 12 mL assay")

# Global fits to both series at once (primary V0). Three mechanisms with the
# same data: competitive (shared Vmax; Km raised by 1 + I/Ki), pure
# noncompetitive (shared Km; Vmax lowered by 1 + I/Ki) and mixed (both; nests
# the other two). The competitive and noncompetitive models have the same
# number of parameters, so their residual sums of squares compare directly.
g <- ref |> filter(estimator == PRIMARY) |> mutate(I = if_else(condition == "mm_plus_iptg", iptg_mM, 0), V0 = V0_umol_per_min_assay)
p0 <- sens |> filter(estimator == PRIMARY, method == "Nonlinear MM"); p0_lb <- sens |> filter(estimator == PRIMARY, method == "Lineweaver-Burk")
st_Vmax <- if (!is.na(p0$Vmax)) p0$Vmax else p0_lb$Vmax; st_Km <- if (!is.na(p0$Km)) p0$Km else p0_lb$Km
try_nls <- function(formula, start, lower, upper) suppressWarnings(tryCatch(
  nls(formula, data = g, start = start, algorithm = "port", lower = lower, upper = upper, control = nls.control(maxiter = 1000, warnOnly = TRUE)),
  error = function(e) NULL))
KIP_UPPER <- 500
comp <- try_nls(V0 ~ Vmax * onpg_mM / (Km * (1 + I / Ki) + onpg_mM), list(Vmax = st_Vmax, Km = st_Km, Ki = 0.1),
                lower = c(1e-6, 1e-6, 1e-6), upper = c(50, KM_UPPER_BOUND, 50))
nonc <- try_nls(V0 ~ Vmax * onpg_mM / ((Km + onpg_mM) * (1 + I / Ki)), list(Vmax = st_Vmax, Km = st_Km, Ki = 0.3),
                lower = c(1e-6, 1e-6, 1e-6), upper = c(50, KM_UPPER_BOUND, 50))
mixd <- try_nls(V0 ~ Vmax * onpg_mM / (Km * (1 + I / Ki) + onpg_mM * (1 + I / Kip)), list(Vmax = st_Vmax, Km = st_Km, Ki = 0.1, Kip = 0.6),
                lower = c(1e-6, 1e-6, 1e-6, 1e-6), upper = c(50, KM_UPPER_BOUND, 50, KIP_UPPER))
tidy_global <- function(f, model) {
  co <- if (is.null(f)) NULL else tryCatch(summary(f)$coefficients, error = function(e) NULL)
  if (is.null(co) || !isTRUE(f$convInfo$isConv))
    return(tibble(model = model, parameter = NA, estimate = NA, se = NA, rss = NA, aic = NA, n = nrow(g), converged = FALSE, at_bound = NA))
  tibble(model = model, parameter = rownames(co), estimate = co[, "Estimate"], se = co[, "Std. Error"],
         rss = deviance(f), aic = AIC(f), n = nrow(g), converged = TRUE,
         at_bound = rownames(co) == "Kip" & co[, "Estimate"] >= 0.99 * KIP_UPPER)
}
glob <- bind_rows(tidy_global(comp, "global competitive"), tidy_global(nonc, "global noncompetitive"), tidy_global(mixd, "global mixed"))
write_csv(glob, file.path(dir_proc, "global_fits.csv"), na = "NA")
glob_resid <- bind_rows(
  if (!is.null(comp)) g |> mutate(model = "global competitive", fitted = fitted(comp)),
  if (!is.null(nonc)) g |> mutate(model = "global noncompetitive", fitted = fitted(nonc))) |>
  transmute(model, condition, tube, onpg_mM, V0, fitted, residual = V0 - fitted)
write_csv(glob_resid, file.path(dir_proc, "global_fit_residuals.csv"), na = "NA")

if (!is.null(comp) && isTRUE(comp$convInfo$isConv)) {
  co <- summary(comp)$coefficients
  sens <- bind_rows(sens, tibble(
    estimator = PRIMARY, method = "Global nonlinear competitive",
    Km = co["Km", "Estimate"], Km_se = co["Km", "Std. Error"], Vmax = co["Vmax", "Estimate"], Vmax_se = co["Vmax", "Std. Error"],
    r2 = 1 - deviance(comp) / sum((g$V0 - mean(g$V0))^2), n = nrow(g), tubes = "ABCDEF x 2", physical = TRUE,
    Km_app = co["Km", "Estimate"] * (1 + I_mM / co["Ki", "Estimate"]), Vmax_app = co["Vmax", "Estimate"],
    I_mM = I_mM, Km_ratio = 1 + I_mM / co["Ki", "Estimate"], Vmax_ratio = 1,
    Ki_competitive = co["Ki", "Estimate"], Ki_from_Vmax_noncompetitive = NA_real_, primary = FALSE, V0_units = "umol/min per 12 mL assay"))
}
write_csv(sens, file.path(dir_proc, "sensitivity_analysis.csv"), na = "NA")
write_csv(sens |> select(estimator, method, Km, Km_app, Vmax, Vmax_app, I_mM, Ki_competitive, Ki_from_Vmax_noncompetitive, Km_ratio, Vmax_ratio, r2, r2_app, physical, physical_app, primary),
          file.path(dir_proc, "inhibition_parameters.csv"), na = "NA")

primary_long <- pair_fit(filter(ref, estimator == PRIMARY, condition == "mm_no_inhibitor") |> mutate(V0 = V0_umol_per_min_assay),
                         filter(ref, estimator == PRIMARY, condition == "mm_plus_iptg")    |> mutate(V0 = V0_umol_per_min_assay)) |>
  mutate(estimator = PRIMARY, primary_method = method == "Lineweaver-Burk", condition_label = COND_LABELS[condition], V0_units = "umol/min per 12 mL assay")
write_csv(primary_long, file.path(dir_proc, "kinetic_parameters.csv"), na = "NA")

# Experimental dataset: same pipeline, with and without the anomalous +IPTG tube B
expd  <- v0 |> filter(data_role == "experimental", estimator == PRIMARY)
exclB <- EXPERIMENTAL_EXCLUDE_FROM_FIT
exp_sum <- bind_rows(
  summarise_pair(pair_fit(filter(expd, condition == "mm_no_inhibitor") |> mutate(V0 = V0_umol_per_min_assay),
                          filter(expd, condition == "mm_plus_iptg", !tube %in% exclB$tube) |> mutate(V0 = V0_umol_per_min_assay))) |> mutate(tube_B = "excluded"),
  summarise_pair(pair_fit(filter(expd, condition == "mm_no_inhibitor") |> mutate(V0 = V0_umol_per_min_assay),
                          filter(expd, condition == "mm_plus_iptg") |> mutate(V0 = V0_umol_per_min_assay))) |> mutate(tube_B = "included")) |>
  mutate(data_role = "experimental", estimator = PRIMARY, V0_units = "umol/min per 12 mL assay")
# Uncertainty of Ki from the two separate nonlinear fits (delta method; the fits are independent):
# Ki = I/(r - 1) with r = Km,app/Km, so se(Ki) = I se(r)/(r - 1)^2 and se(r) = r sqrt((se_Km,app/Km,app)^2 + (se_Km/Km)^2).
exp_sum <- exp_sum |> mutate(
  Ki_se = ifelse(method == "Nonlinear MM" & !is.na(Km_se) & !is.na(Km_app_se),
                 I_mM * (Km_ratio * sqrt((Km_app_se / Km_app)^2 + (Km_se / Km)^2)) / (Km_ratio - 1)^2, NA_real_))
# Global competitive model (shared Vmax; Km raised by 1 + I/Ki) fitted to our own two series, with and without tube B
fit_global_exp <- function(d) {
  d <- d |> mutate(I = if_else(condition == "mm_plus_iptg", iptg_mM, 0), V0 = V0_umol_per_min_assay)
  st <- exp_sum |> filter(tube_B == "excluded", method == "Nonlinear MM")
  f <- suppressWarnings(tryCatch(nls(V0 ~ Vmax * onpg_mM / (Km * (1 + I / Ki) + onpg_mM), data = d,
                                     start = list(Vmax = st$Vmax, Km = st$Km, Ki = 0.1), algorithm = "port",
                                     lower = c(1e-6, 1e-6, 1e-6), upper = c(50, KM_UPPER_BOUND, 50), control = nls.control(maxiter = 1000, warnOnly = TRUE)),
                                 error = function(e) NULL))
  if (is.null(f) || !isTRUE(f$convInfo$isConv)) return(NULL)
  co <- summary(f)$coefficients
  tibble(method = "Global nonlinear competitive", Km = co["Km", "Estimate"], Km_se = co["Km", "Std. Error"], Vmax = co["Vmax", "Estimate"], Vmax_se = co["Vmax", "Std. Error"],
         r2 = 1 - deviance(f) / sum((d$V0 - mean(d$V0))^2), n = sum(d$condition == "mm_no_inhibitor"), tubes = paste(d$tube[d$condition == "mm_no_inhibitor"], collapse = ""), physical = TRUE,
         Km_app = co["Km", "Estimate"] * (1 + I_mM / co["Ki", "Estimate"]), Km_app_se = NA_real_, Vmax_app = co["Vmax", "Estimate"], Vmax_app_se = NA_real_,
         r2_app = NA_real_, n_app = sum(d$condition == "mm_plus_iptg"), tubes_app = paste(d$tube[d$condition == "mm_plus_iptg"], collapse = ""), physical_app = TRUE,
         lb_slope = NA_real_, lb_intercept = NA_real_, lb_slope_app = NA_real_, lb_intercept_app = NA_real_,
         I_mM = I_mM, Km_ratio = 1 + I_mM / co["Ki", "Estimate"], Vmax_ratio = 1,
         Ki_competitive = co["Ki", "Estimate"], Ki_from_Vmax_noncompetitive = NA_real_, Ki_se = co["Ki", "Std. Error"], rss = deviance(f))
}
exp_glob <- bind_rows(
  fit_global_exp(expd |> filter(!(condition == "mm_plus_iptg" & tube %in% exclB$tube))) |> mutate(tube_B = "excluded"),
  fit_global_exp(expd) |> mutate(tube_B = "included")) |>
  mutate(data_role = "experimental", estimator = PRIMARY, V0_units = "umol/min per 12 mL assay")
exp_sum <- bind_rows(exp_sum, exp_glob |> select(-rss))
write_csv(exp_sum, file.path(dir_proc, "experimental_secondary_kinetics.csv"), na = "NA")
# Inhibited tube B against its own uninhibited control (same nominal ONPG)
bB <- expd |> filter(condition == "mm_plus_iptg", tube == "B"); uB <- expd |> filter(condition == "mm_no_inhibitor", tube == "B")
write_csv(tibble(quantity = "V0 inhibited B / V0 uninhibited B (same 1.10 mM ONPG)", value = bB$V0_umol_per_min_assay / uB$V0_umol_per_min_assay,
                 V0_inhibited_B = bB$V0_umol_per_min_assay, V0_uninhibited_B = uB$V0_umol_per_min_assay),
          file.path(dir_proc, "experimental_tubeB_control_ratio.csv"), na = "NA")

# Experimental versus reference, tube by tube
cmp <- fits |> filter(n_used > 0) |>
  select(data_role, dataset, condition, tube, V0_dA415_per_min, V0_estimator, a415_10min) |>
  pivot_wider(names_from = data_role, values_from = c(dataset, V0_dA415_per_min, V0_estimator, a415_10min)) |>
  filter(!is.na(V0_dA415_per_min_experimental) | !is.na(V0_dA415_per_min_reference)) |>
  mutate(ratio_experimental_over_reference = V0_dA415_per_min_experimental / V0_dA415_per_min_reference,
         condition_label = CONDITION_LABELS[condition]) |>
  arrange(factor(condition, levels = c("enzyme_dilution", "mm_no_inhibitor", "mm_plus_iptg")), tube)
write_csv(cmp, file.path(dir_proc, "experimental_vs_reference_v0.csv"), na = "NA")

# Tables
pl <- primary_long
gcomp <- glob |> filter(model == "global competitive"); gnon <- glob |> filter(model == "global noncompetitive")
gk <- function(par, col = "estimate", tb = gcomp) tb[[col]][tb$parameter == par]
Ki_lb_val <- sens$Ki_competitive[sens$estimator == PRIMARY & sens$method == "Lineweaver-Burk"]
pm <- function(x, se, d = 3) ifelse(is.na(x), NA_character_, ifelse(is.na(se), sprintf(paste0("%.", d, "f"), x), sprintf(paste0("%.", d, "f ± %.", d, "f"), x, se)))
table5 <- pl |> transmute(
  Condition = condition_label, Method = method,
  `Km` = case_when(method == "Lineweaver-Burk" & condition == "mm_plus_iptg" ~ sprintf("%.3f (app.)", Km),
                   method == "Lineweaver-Burk" ~ sprintf("%.3f", Km), is.na(Km) ~ "n.d.", TRUE ~ pm(Km, Km_se)),
  `Vmax` = case_when(method == "Lineweaver-Burk" & condition == "mm_plus_iptg" ~ sprintf("%.3f (app.)", Vmax),
                     method == "Lineweaver-Burk" ~ sprintf("%.3f", Vmax), is.na(Vmax) ~ "n.d.", TRUE ~ pm(Vmax, Vmax_se)),
  `Ki` = if_else(method == "Lineweaver-Burk" & condition == "mm_plus_iptg", sprintf("%.3f", Ki_lb_val), NA_character_),
  `Fit` = sprintf("R2 %.3f", r2)) |>
  bind_rows(tibble(Condition = "Both series", Method = "Global, competitive", `Km` = pm(gk("Km"), gk("Km", "se")),
                   `Vmax` = pm(gk("Vmax"), gk("Vmax", "se")), `Ki` = pm(gk("Ki"), gk("Ki", "se")), `Fit` = sprintf("RSS %.4f", gcomp$rss[1])),
            tibble(Condition = "Both series", Method = "Global, noncompetitive", `Km` = pm(gk("Km", tb = gnon), gk("Km", "se", gnon)),
                   `Vmax` = pm(gk("Vmax", tb = gnon), gk("Vmax", "se", gnon)), `Ki` = pm(gk("Ki", tb = gnon), gk("Ki", "se", gnon)), `Fit` = sprintf("RSS %.4f", gnon$rss[1])))
prim <- sens |> filter(estimator == PRIMARY)
table5_ki <- prim |> transmute(
  Method = method, `Km (mM)` = round(Km, 3), `Km,app (mM)` = round(Km_app, 3), `Km,app/Km` = round(Km_ratio, 2),
  `Vmax (umol/min)` = round(Vmax, 3), `Vmax,app (umol/min)` = round(Vmax_app, 3), `Vmax,app/Vmax` = round(Vmax_ratio, 2),
  `[IPTG] (mM)` = round(I_mM, 3), `Ki, competitive (mM)` = round(Ki_competitive, 3),
  `Ki if noncompetitive (mM)` = round(Ki_from_Vmax_noncompetitive, 3))
write_table(table5, "table5_kinetic_parameters", digits = 4)
write_table(table5_ki, "table5b_inhibition", digits = 4)
write_table(sens |> transmute(Estimator = sub(":.*$", "", estimator), Method = method, `Km (mM)` = round(Km, 3), `Km,app (mM)` = round(Km_app, 3),
                              `Vmax (umol/min)` = round(Vmax, 3), `Vmax,app (umol/min)` = round(Vmax_app, 3), `Km,app/Km` = round(Km_ratio, 2),
                              `Vmax,app/Vmax` = round(Vmax_ratio, 2), `Ki (mM)` = round(Ki_competitive, 3), `R2 (-I)` = round(r2, 3), `R2 (+I)` = round(r2_app, 3),
                              `Physical (-I / +I)` = paste(physical, physical_app, sep = " / "), Primary = ifelse(primary, "yes", "")),
            "tableS6_sensitivity", digits = 4)
write_table(exp_sum |> transmute(`+IPTG tube B` = tube_B, Method = method, `Km (mM)` = round(Km, 3), `Km,app (mM)` = round(Km_app, 3),
                                 `Vmax (umol/min)` = round(Vmax, 3), `Vmax,app (umol/min)` = round(Vmax_app, 3), `Vmax,app/Vmax` = round(Vmax_ratio, 2),
                                 `Ki (mM)` = round(Ki_competitive, 3), `Ki SE (mM)` = round(Ki_se, 3), `R2 (-I)` = round(r2, 3), `R2 (+I)` = round(r2_app, 3), `Tubes (-I / +I)` = paste(tubes, tubes_app, sep = " / ")),
            "tableS7_experimental_secondary", digits = 4)
write_table(cmp |> transmute(Condition = condition_label, Tube = tube, `V0 reference (dA415/min)` = round(V0_dA415_per_min_reference, 4),
                             `V0 experimental (dA415/min)` = round(V0_dA415_per_min_experimental, 4), `Experimental / reference` = round(ratio_experimental_over_reference, 2),
                             `Estimator, reference` = V0_estimator_reference, `Estimator, experimental` = V0_estimator_experimental,
                             `A415 at 10 min, reference` = a415_10min_reference, `A415 at 10 min, experimental` = a415_10min_experimental),
            "tableS8_experimental_vs_reference", digits = 4)
write_table(glob |> transmute(Model = model, Parameter = parameter, Estimate = round(estimate, 4), SE = round(se, 4), RSS = signif(rss, 4), AIC = round(aic, 2), n, Converged = converged,
                              Note = ifelse(at_bound %in% TRUE, "at upper bound (model reduces to competitive)", "")),
            "tableS9_global_fits", digits = 4)

# Compact Results table for the substrate series: raw absorbances with V0 and reciprocals
tidy <- read_csv(file.path(dir_proc, "absorbance_tidy.csv"), show_col_types = FALSE)
prim_v0 <- ref |> filter(estimator == PRIMARY) |>
  transmute(condition, tube, V0_dA, V0_umol_per_min_assay, origin_assumed, inv_V = 1 / V0_umol_per_min_assay)
table_results_substrate <- tidy |> filter(data_role == "reference", condition != "enzyme_dilution") |>
  select(condition, tube, onpg_mM, time_min, absorbance_415nm) |>
  pivot_wider(names_from = time_min, values_from = absorbance_415nm, names_glue = "{time_min} min") |>
  left_join(prim_v0, by = c("condition", "tube")) |>
  arrange(desc(condition == "mm_no_inhibitor"), tube) |>
  transmute(Series = if_else(condition == "mm_no_inhibitor", "no inhibitor", "+ 0.458 mM IPTG"), Tube = tube,
            `[S] (mM)` = signif(onpg_mM, 4), `2 min`, `4 min`, `6 min`, `8 min`, `10 min`,
            `V0 (dA/min)` = paste0(formatC(V0_dA, digits = 4, format = "g"), if_else(origin_assumed, "†", "")),
            `V0 (umol/min)` = paste0(formatC(V0_umol_per_min_assay, digits = 3, format = "f"), if_else(origin_assumed, "†", "")),
            `1/[S]` = round(1 / onpg_mM, 2), `1/V0` = round(inv_V, 2))
write_table(table_results_substrate, "table_results_substrate", digits = 4)

p <- prim |> filter(method == "Lineweaver-Burk"); q <- prim |> filter(method == "Nonlinear MM")
message(sprintf("06_inhibition.R: LB  Km %.3f -> Km,app %.3f (x%.1f); Vmax %.3f -> %.3f (x%.2f); Ki %.3f mM (competitive eq.)", p$Km, p$Km_app, p$Km_ratio, p$Vmax, p$Vmax_app, p$Vmax_ratio, p$Ki_competitive))
message(sprintf("                 NLS Km %.3f -> Km,app %.3f; Vmax %.3f -> %.3f", q$Km, q$Km_app, q$Vmax, q$Vmax_app))
if (!is.null(comp) && isTRUE(comp$convInfo$isConv)) message(sprintf("                 global competitive: Km %.3f, Vmax %.3f, Ki %.3f, RSS %.4f (AIC %.1f); noncompetitive RSS %.4f (AIC %.1f); mixed AIC %.1f (Ki' %.0f)",
  coef(comp)["Km"], coef(comp)["Vmax"], coef(comp)["Ki"], deviance(comp), AIC(comp),
  if (!is.null(nonc)) deviance(nonc) else NA, if (!is.null(nonc)) AIC(nonc) else NA,
  if (!is.null(mixd)) AIC(mixd) else NA, if (!is.null(mixd)) coef(mixd)["Kip"] else NA))
