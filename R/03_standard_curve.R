# 03_standard_curve.R

source(here::here("R", "00_setup.R"))

spec <- read_csv(file.path(dir_proc, "onp_spectrum.csv"), show_col_types = FALSE)
std  <- read_csv(file.path(dir_proc, "onp_standards.csv"), show_col_types = FALSE,
                 col_types = cols(reported_tube = "c", manual_tube = "c", mapping_basis = "c", reported = "l", .default = "d"))

# Spectrum
lmax   <- spec$wavelength_nm[which.max(spec$absorbance)]
a_lmax <- max(spec$absorbance)
near   <- spec |> filter(absorbance >= 0.98 * a_lmax) |> pull(wavelength_nm)
message(sprintf("lambda_max = %d nm (A = %.3f); within 2%% of the maximum: %s nm", lmax, a_lmax, paste(range(near), collapse = "-")))

# Linear region by the increment rule along [ONP], nonzero reported standards only
s <- std |> filter(reported, onp_ml > 0) |> arrange(onp_mM_cuvette)
k <- 3
while (k < nrow(s)) {
  m <- lm(abs_415nm ~ onp_mM_cuvette, s[1:k, ])
  pred <- unname(coef(m)[2]) * (s$onp_mM_cuvette[k + 1] - s$onp_mM_cuvette[k]); obs <- s$abs_415nm[k + 1] - s$abs_415nm[k]
  if (abs(obs - pred) <= max(REL_TOL * pred, ABS_TOL)) k <- k + 1 else break
}
s <- s |> mutate(used_in_fit = row_number() <= k)
m_free   <- lm(abs_415nm ~ onp_mM_cuvette, s |> filter(used_in_fit))
m_origin <- lm(abs_415nm ~ 0 + onp_mM_cuvette, s |> filter(used_in_fit))
eps      <- unname(coef(m_free)[2]) / PATH_LENGTH_CM
eps_se   <- summary(m_free)$coefficients[2, 2]
icpt     <- unname(coef(m_free)[1])
icpt_p   <- summary(m_free)$coefficients[1, 4]
excluded <- s |> filter(!used_in_fit) |>
  mutate(pred = icpt + eps * onp_mM_cuvette, deviation_pct = 100 * (abs_415nm - pred) / pred,
         transmittance_pct = 100 * 10^(-abs_415nm))

# Alternative calibrations
zero_pt <- std |> filter(reported, onp_ml == 0) |> transmute(onp_mM_cuvette, abs_415nm)
fit_variant <- function(d, through_origin = FALSE, label) {
  m <- if (through_origin) lm(abs_415nm ~ 0 + onp_mM_cuvette, d) else lm(abs_415nm ~ onp_mM_cuvette, d)
  co <- summary(m)$coefficients
  tibble(variant = label, n_points = nrow(d), max_mM = max(d$onp_mM_cuvette), max_A = max(d$abs_415nm),
         epsilon = unname(coef(m)[["onp_mM_cuvette"]]), epsilon_se = co["onp_mM_cuvette", "Std. Error"],
         intercept = if (through_origin) 0 else unname(coef(m)[["(Intercept)"]]),
         r2 = if (through_origin) 1 - deviance(m) / sum((d$abs_415nm - mean(d$abs_415nm))^2) else summary(m)$r.squared)
}
variants <- bind_rows(
  fit_variant(s |> filter(used_in_fit), FALSE, "five standards, free intercept (used)"),
  fit_variant(s |> filter(used_in_fit), TRUE,  "five standards, through the origin"),
  fit_variant(bind_rows(zero_pt, s |> filter(used_in_fit)), FALSE, "zero-concentration point + five standards, free intercept"),
  fit_variant(s, FALSE, "all six nonzero standards, free intercept"),
  fit_variant(bind_rows(zero_pt, s), FALSE, "zero point + all six standards, free intercept")) |>
  mutate(Vmax_scale_factor = eps / epsilon)   # Vmax computed with this epsilon relative to the primary one (Km and Ki unchanged)
write_csv(variants, file.path(dir_proc, "calibration_variants.csv"))

calibration <- tibble(
  quantity = c("lambda_max_nm", "A_at_lambda_max", "band_within_2pct_nm",
               "epsilon_A_per_mM_per_cm", "epsilon_se", "intercept_A", "intercept_p", "r2", "n_standards_used",
               "linear_range_mM_min", "linear_range_mM_max", "linear_range_A_max",
               "epsilon_through_origin", "epsilon_with_zero_point", "epsilon_all_six",
               "excluded_standard_mM", "excluded_standard_A", "excluded_deviation_pct", "excluded_transmittance_pct",
               "instrument_linear_limit_A"),
  value = c(lmax, a_lmax, NA, eps, eps_se, icpt, icpt_p, summary(m_free)$r.squared, k,
            min(s$onp_mM_cuvette[s$used_in_fit]), max(s$onp_mM_cuvette[s$used_in_fit]), max(s$abs_415nm[s$used_in_fit]),
            unname(coef(m_origin)[1]), variants$epsilon[3], variants$epsilon[4],
            if (nrow(excluded)) excluded$onp_mM_cuvette[1] else NA, if (nrow(excluded)) excluded$abs_415nm[1] else NA,
            if (nrow(excluded)) excluded$deviation_pct[1] else NA, if (nrow(excluded)) excluded$transmittance_pct[1] else NA,
            INSTRUMENT_LINEAR_LIMIT_A),
  text = c(NA, NA, paste(range(near), collapse = "-"), rep(NA, 17)),
  status = "reference dataset (course-provided Part I)")
write_csv(calibration, file.path(dir_proc, "onp_calibration.csv"), na = "NA")
write_csv(s, file.path(dir_proc, "onp_standards_fit.csv"), na = "NA")

table2 <- std |> filter(reported) |> left_join(s |> select(manual_tube, used_in_fit), by = "manual_tube") |>
  transmute(`Reported tube` = reported_tube, `Manual preparation` = ifelse(manual_tube == "Blank", "Blank", paste0("Standard ", manual_tube)),
            `ONP 1 mM (mL)` = onp_ml, `[ONP] in cuvette (mM)` = round(onp_mM_cuvette, 4), `A415` = abs_415nm,
            `A415 / [ONP] (per mM)` = ifelse(onp_ml > 0, round(abs_415nm / onp_mM_cuvette, 2), NA),
            `Fitted` = case_when(onp_ml == 0 ~ "no (zero point)", used_in_fit ~ "yes",
                                 TRUE ~ sprintf("no (%+.0f%%)", excluded$deviation_pct[1])))
write_table(table2, "table2_onp_calibration", digits = 4)
write_table(variants |> transmute(Calibration = variant, `Points` = n_points, `Highest [ONP] (mM)` = round(max_mM, 3), `Highest A415` = max_A,
                                  `Epsilon (A per mM per cm)` = round(epsilon, 3), `SE` = round(epsilon_se, 3), `Intercept (A)` = round(intercept, 4),
                                  `R2` = round(r2, 4), `Vmax relative to primary` = round(Vmax_scale_factor, 3)),
            "tableS_calibration_variants", digits = 4)

message(sprintf("03_standard_curve.R: A415 = %.4f + %.3f [ONP]; R2 = %.4f over %d standards (%.3f-%.3f mM); epsilon = %.2f +/- %.2f A mM^-1 cm^-1 (through origin %.2f; with zero point %.2f; all six %.2f); excluded %.3f mM (A %.3f, %+.0f%%, T = %.2f%%)",
                icpt, eps, summary(m_free)$r.squared, k, min(s$onp_mM_cuvette[s$used_in_fit]), max(s$onp_mM_cuvette[s$used_in_fit]), eps, eps_se,
                coef(m_origin)[1], variants$epsilon[3], variants$epsilon[4], excluded$onp_mM_cuvette[1], excluded$abs_415nm[1], excluded$deviation_pct[1], excluded$transmittance_pct[1]))
