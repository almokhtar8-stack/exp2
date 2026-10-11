# 04_enzyme_dilution.R

source(here::here("R", "00_setup.R"))

fits  <- read_csv(file.path(dir_proc, "progress_curve_fits.csv"), show_col_types = FALSE)
calib <- read_csv(file.path(dir_proc, "onp_calibration.csv"), show_col_types = FALSE)
eps   <- calib$value[calib$quantity == "epsilon_A_per_mM_per_cm"]

ed <- fits |> filter(condition == "enzyme_dilution") |>
  group_by(data_role) |>
  mutate(rel_rate = V0_dA415_per_min / V0_dA415_per_min[tube == "A"],
         rate_per_enzyme = rel_rate / rel_enzyme,
         deviation_from_proportional_pct = 100 * (rel_rate - rel_enzyme) / rel_enzyme) |> ungroup()
ed <- bind_cols(ed, convert_v0(ed$V0_dA415_per_min, eps))

fit_prop <- function(d) {
  m0 <- lm(V0_dA415_per_min ~ 0 + rel_enzyme, d); m1 <- lm(V0_dA415_per_min ~ rel_enzyme, d)
  r2m <- function(m) 1 - sum(residuals(m)^2) / sum((d$V0_dA415_per_min - mean(d$V0_dA415_per_min))^2)
  tibble(model = c("proportional (through origin)", "free intercept"),
         slope_dA415_per_min_per_unit_enzyme = c(unname(coef(m0)[1]), unname(coef(m1)[2])),
         slope_se = c(summary(m0)$coefficients[1, 2], summary(m1)$coefficients[2, 2]),
         intercept = c(0, unname(coef(m1)[1])), intercept_p = c(NA, summary(m1)$coefficients[1, 4]),
         r2_about_mean = c(r2m(m0), r2m(m1)), n = nrow(d))
}
edfit <- ed |> group_by(data_role) |> group_modify(~ fit_prop(.x)) |> ungroup() |>
  mutate(slope_umol_per_min_per_unit_enzyme = convert_v0(slope_dA415_per_min_per_unit_enzyme, eps)$V0_umol_per_min_assay)

write_csv(ed, file.path(dir_proc, "enzyme_dilution_results.csv"), na = "NA")
write_csv(edfit, file.path(dir_proc, "enzyme_dilution_fit.csv"), na = "NA")

table4 <- ed |> select(data_role, tube, rel_enzyme, V0_estimator, V0_dA415_per_min, V0_umol_per_min_assay, rel_rate, rate_per_enzyme) |>
  pivot_wider(names_from = data_role, values_from = c(V0_estimator, V0_dA415_per_min, V0_umol_per_min_assay, rel_rate, rate_per_enzyme)) |>
  arrange(tube) |>
  transmute(Tube = tube, `Relative enzyme` = rel_enzyme,
            `V0 (dA415/min)` = round(V0_dA415_per_min_reference, 4),
            `V0 (umol/min)` = round(V0_umol_per_min_assay_reference, 3),
            `Relative rate` = round(rel_rate_reference, 2),
            `Rate / enzyme` = round(rate_per_enzyme_reference, 2),
            `Points used` = sub("regression ", "", V0_estimator_reference),
            `V0 experimental (dA415/min)` = round(V0_dA415_per_min_experimental, 4),
            `Relative rate, experimental` = round(rel_rate_experimental, 2))
write_table(table4, "table4_enzyme_dilution", digits = 4)

# Compact Results table: raw absorbances of the reference curves with V0 and relative rates
tidy <- read_csv(file.path(dir_proc, "absorbance_tidy.csv"), show_col_types = FALSE)
table_results_ed <- tidy |> filter(dataset == "Reference Part II") |>
  select(tube, enzyme_ml, rel_enzyme, time_min, absorbance_415nm) |>
  pivot_wider(names_from = time_min, values_from = absorbance_415nm, names_glue = "{time_min} min") |>
  left_join(ed |> filter(data_role == "reference") |> select(tube, V0_estimator, V0_dA415_per_min, V0_umol_per_min_assay, rel_rate, rate_per_enzyme), by = "tube") |>
  transmute(Tube = tube, `Enzyme (mL)` = enzyme_ml, `Rel. enzyme` = round(rel_enzyme, 2), `2 min`, `4 min`, `6 min`, `8 min`, `10 min`,
            `Points used (min)` = sub(" min$", "", sub("regression ", "", V0_estimator)), `V0 (dA/min)` = round(V0_dA415_per_min, 4),
            `V0 (umol/min)` = round(V0_umol_per_min_assay, 3), `Rel. rate` = round(rel_rate, 2), `Rate/enzyme` = round(rate_per_enzyme, 2))
write_table(table_results_ed, "table_results_enzyme_dilution", digits = 4)

p <- edfit |> filter(data_role == "reference")
message(sprintf("04_enzyme_dilution.R: reference proportional slope %.4f dA415/min per unit enzyme (R2 %.3f); free intercept %.4f (p = %.2f); rate/enzyme range %.2f-%.2f; experimental proportional R2 %.3f",
                p$slope_dA415_per_min_per_unit_enzyme[1], p$r2_about_mean[1], p$intercept[2], p$intercept_p[2],
                min(ed$rate_per_enzyme[ed$data_role == "reference"]), max(ed$rate_per_enzyme[ed$data_role == "reference"]),
                edfit$r2_about_mean[edfit$data_role == "experimental" & edfit$model == "proportional (through origin)"]))
