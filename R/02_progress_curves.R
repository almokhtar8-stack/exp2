# 02_progress_curves.R

source(here::here("R", "00_setup.R"))

tidy <- read_csv(file.path(dir_proc, "absorbance_tidy.csv"), show_col_types = FALSE)

tolerance <- function(pred) pmax(REL_TOL * pred, ABS_TOL)

select_initial_window <- function(t, a) {
  k <- MIN_POINTS; log <- character(0)
  while (k < length(t)) {
    m <- lm(a[1:k] ~ t[1:k]); pred <- unname(coef(m)[2]) * (t[k + 1] - t[k]); obs <- a[k + 1] - a[k]
    log <- c(log, sprintf("t=%g: obs %.3f vs pred %.3f", t[k + 1], obs, pred))
    if (abs(obs - pred) <= tolerance(pred)) k <- k + 1 else break
  }
  list(k = k, log = paste(log, collapse = "; "))
}
curved_from_outset <- function(a) {
  inc <- diff(a); tol <- tolerance(inc[1])
  (inc[1] - inc[2] > tol) & (inc[1] - inc[3] > tol)
}
fit_window <- function(t, a, k) {
  m <- lm(a[1:k] ~ t[1:k]); g <- glance(m)
  tibble(n_used = k, t_first = t[1], t_last = t[k], slope = unname(coef(m)[2]), intercept = unname(coef(m)[1]),
         slope_se = summary(m)$coefficients[2, 2], r2 = g$r.squared,
         rmse = sqrt(deviance(m) / max(df.residual(m), 1)))
}
secant <- function(t, a, t0, t1) {
  a0 <- if (t0 == 0) 0 else a[t == t0]
  (a[t == t1] - a0) / (t1 - t0)
}

curves <- tidy |> filter(measured) |>
  group_by(data_role, dataset, source_label, condition, condition_label, tube, curve_id, onpg_mM, iptg_mM, enzyme_ml, rel_enzyme) |>
  arrange(time_min, .by_group = TRUE) |> nest(.key = "obs") |> ungroup()

fits <- curves |>
  mutate(sel = map(obs, ~ select_initial_window(.x$time_min, .x$absorbance_415nm)),
         win = map2(obs, sel, ~ fit_window(.x$time_min, .x$absorbance_415nm, .y$k)),
         curved = map_lgl(obs, ~ curved_from_outset(.x$absorbance_415nm)),
         rule_log = map_chr(sel, "log"),
         secant_0_2 = map_dbl(obs, ~ secant(.x$time_min, .x$absorbance_415nm, 0, 2)),
         secant_2_4 = map_dbl(obs, ~ secant(.x$time_min, .x$absorbance_415nm, 2, 4)),
         secant_2_6 = map_dbl(obs, ~ secant(.x$time_min, .x$absorbance_415nm, 2, 6)),
         slope_2_6  = map_dbl(obs, ~ fit_window(.x$time_min, .x$absorbance_415nm, 3)$slope),
         slope_all5 = map_dbl(obs, ~ unname(coef(lm(absorbance_415nm ~ time_min, .x))[2])),
         a415_2min  = map_dbl(obs, ~ .x$absorbance_415nm[.x$time_min == 2]),
         a415_10min = map_dbl(obs, ~ .x$absorbance_415nm[.x$time_min == 10]),
         increments = map_chr(obs, ~ paste(fmt_num(diff(.x$absorbance_415nm), 3), collapse = " / "))) |>
  unnest(win) |>
  mutate(
    V0_estimator = if_else(curved, "0-2 min average rate, origin assumed (no initial linear portion)", sprintf("regression 2-%g min", t_last)),
    V0_dA415_per_min = if_else(curved, secant_0_2, slope),
    time_points_used = if_else(curved, "0 (origin), 2", map2_chr(obs, t_last, ~ paste(.x$time_min[.x$time_min <= .y], collapse = ", "))),
    time_points_excluded = if_else(curved, "4, 6, 8, 10 (no linear window: later increments fall below the first)",
                                   map2_chr(obs, t_last, ~ { ex <- .x$time_min[.x$time_min > .y]; if (length(ex)) paste(ex, collapse = ", ") else "none" })),
    origin_assumed = curved,
    note = case_when(
      curved ~ "Second and third increments both below the first by more than the tolerance: no initial linear portion; V0 = A415(2 min)/2 min with A415(0) assumed 0 (origin-assumed average rate over the first interval, not a measured instantaneous rate)",
      data_role == "experimental" & dataset == "Experimental Part III (+IPTG)" & tube == "B" ~ "10-min point excluded (46% of predicted increment); whole curve faster than tube A, see audit",
      time_points_excluded != "none" ~ paste0("Point(s) at ", time_points_excluded, " min departed from the initial trend and were excluded from the regression; raw values retained"),
      TRUE ~ "All five points within the initial linear window"))


linear_intercepts <- fits |> filter(!curved) |>
  select(data_role, dataset, tube, n_used, intercept, slope, r2)
offset_summary <- linear_intercepts |> group_by(data_role) |>
  summarise(n_curves = n(), median_intercept = median(intercept), min_intercept = min(intercept), max_intercept = max(intercept),
            median_scenario_shift_dA_per_min = median(intercept) / 2, max_scenario_shift_dA_per_min = max(intercept) / 2, .groups = "drop")
offset_all <- linear_intercepts |> summarise(data_role = "both", n_curves = n(), median_intercept = median(intercept),
                                             min_intercept = min(intercept), max_intercept = max(intercept),
                                             median_scenario_shift_dA_per_min = median(intercept) / 2, max_scenario_shift_dA_per_min = max(intercept) / 2)
offset_summary <- bind_rows(offset_summary, offset_all)
write_csv(offset_summary, file.path(dir_proc, "origin_offset_scenario.csv"))
write_csv(linear_intercepts, file.path(dir_proc, "linear_curve_intercepts.csv"))
MEDIAN_OFFSET_A <- offset_all$median_intercept
fits <- fits |> mutate(secant_0_2_offset_scenario = (a415_2min - MEDIAN_OFFSET_A) / 2)

# Curve with no data (Experimental Part III (+IPTG) tube E)
missing_curve <- tidy |> filter(!measured) |>
  distinct(data_role, dataset, source_label, condition, condition_label, tube, curve_id, onpg_mM, iptg_mM, enzyme_ml, rel_enzyme) |>
  mutate(n_used = 0L, V0_estimator = "none", time_points_used = "none", time_points_excluded = "none", origin_assumed = NA,
         note = "No V0: sample discarded before measurement (all observations NA)")
fits_out <- bind_rows(fits |> select(-obs, -sel), missing_curve) |>
  arrange(desc(data_role == "reference"), dataset, tube)
write_csv(fits_out, file.path(dir_proc, "progress_curve_fits.csv"), na = "NA")

# Regression on every candidate initial window (2-6, 2-8, 2-10 min)
cand <- curves |> mutate(cand = map(obs, function(d) map_dfr(3:nrow(d), ~ fit_window(d$time_min, d$absorbance_415nm, .x) |>
                                                                mutate(window = paste0("2-", d$time_min[.x], " min"))))) |>
  select(data_role, dataset, condition, tube, cand) |> unnest(cand) |>
  left_join(fits |> select(dataset, tube, chosen_t_last = t_last, curved), by = c("dataset", "tube")) |>
  mutate(selected = case_when(curved ~ "origin-assumed 0-2 min estimate used instead", t_last == chosen_t_last ~ "yes", TRUE ~ "")) |>
  select(data_role, dataset, condition, tube, window, n_used, slope, intercept, r2, rmse, selected)
write_csv(cand, file.path(dir_proc, "candidate_windows.csv"), na = "NA")

# Side-by-side estimators for every curve
est_cmp <- fits |> transmute(data_role, dataset, tube, increments,
                             `secant 0-2 (origin)` = secant_0_2, `secant 2-4` = secant_2_4, `secant 2-6` = secant_2_6,
                             `regression 2-6` = slope_2_6, `regression initial window` = slope, `initial window` = sprintf("2-%g min", t_last),
                             `regression all 5 points` = slope_all5, `rule (V0 used)` = V0_dA415_per_min, `rule estimator` = V0_estimator,
                             `0-2 min estimate, offset scenario` = secant_0_2_offset_scenario)
write_csv(est_cmp, file.path(dir_proc, "v0_estimator_comparison.csv"), na = "NA")

# Residuals of the fitted description (secant for curved curves, regression otherwise)
resid <- fits |> select(data_role, dataset, condition, tube, obs, curved, slope, intercept, t_last, V0_dA415_per_min) |> unnest(obs) |>
  mutate(fitted = if_else(curved, V0_dA415_per_min * time_min, intercept + slope * time_min),
         residual = absorbance_415nm - fitted,
         used_in_fit = if_else(curved, time_min == 2, time_min <= t_last)) |>
  select(data_role, dataset, condition, tube, time_min, absorbance_415nm, fitted, residual, used_in_fit, curved)
write_csv(resid, file.path(dir_proc, "progress_curve_residuals.csv"), na = "NA")

# Tables
mk_v0_table <- function(d) d |> transmute(
  Dataset = dataset, Tube = tube,
  `Concentration variable` = case_when(
    condition == "enzyme_dilution" ~ paste0("relative enzyme ", fmt_num(rel_enzyme, 2)),
    condition == "mm_no_inhibitor" ~ paste0("[ONPG] ", fmt_num(onpg_mM, 4), " mM"),
    TRUE ~ paste0("[ONPG] ", fmt_num(onpg_mM, 4), " mM + [IPTG] ", fmt_num(iptg_mM, 3), " mM")),
  `Increments (A415 per 2 min)` = increments, `V0 estimator` = V0_estimator, `Points used (min)` = time_points_used,
  `V0 (dA415/min)` = round(V0_dA415_per_min, 4), `Regression R2` = ifelse(curved, NA, round(r2, 4)), `Intercept (A415)` = ifelse(curved, NA, round(intercept, 4)),
  Notes = note)
write_table(mk_v0_table(fits_out |> filter(data_role == "reference")), "table_v0_reference", digits = 4)
write_table(mk_v0_table(fits_out |> filter(data_role == "experimental")), "tableS3_v0_experimental", digits = 4)
write_table(cand |> transmute(Role = DATA_ROLES[data_role], Dataset = dataset, Tube = tube, Window = window, n = n_used, `Slope (dA415/min)` = round(slope, 4),
                              Intercept = round(intercept, 4), R2 = round(r2, 4), RMSE = round(rmse, 4), Selected = selected), "tableS4_candidate_windows", digits = 4)
write_table(est_cmp |> mutate(across(where(is.numeric), ~ round(.x, 4))) |> rename(Role = data_role, Dataset = dataset, Tube = tube),
            "tableS4b_estimator_comparison", digits = 4)
write_table(offset_summary |> transmute(Dataset = DATA_ROLES[data_role] |> coalesce("both datasets"), `Linear curves (n)` = n_curves,
                                        `Median intercept (A415)` = round(median_intercept, 4), `Min` = round(min_intercept, 4), `Max` = round(max_intercept, 4),
                                        `Scenario shift of a 0-2 min estimate, median intercept (dA415/min)` = round(median_scenario_shift_dA_per_min, 4),
                                        `Scenario shift, largest intercept (dA415/min)` = round(max_scenario_shift_dA_per_min, 4)),
            "table_origin_offset", digits = 4)

message(sprintf("02_progress_curves.R: %d curves; Tier-2 origin-assumed estimate applied to: %s; intercepts of linear curves: median %.3f A (range %.3f to %.3f)",
                nrow(fits), paste(fits$curve_id[fits$curved], collapse = ", "), offset_all$median_intercept, offset_all$min_intercept, offset_all$max_intercept))
