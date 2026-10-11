# 05_michaelis_menten.R

source(here::here("R", "00_setup.R"))

fits  <- read_csv(file.path(dir_proc, "progress_curve_fits.csv"), show_col_types = FALSE)
calib <- read_csv(file.path(dir_proc, "onp_calibration.csv"), show_col_types = FALSE)
eps   <- calib$value[calib$quantity == "epsilon_A_per_mM_per_cm"]

# Worked example for the unit conversion (reference, no IPTG, tube A)
exA <- fits |> filter(dataset == "Reference Part III (-IPTG)", tube == "A")
cv  <- convert_v0(exA$V0_dA415_per_min, eps)
message(sprintf("Worked example, tube A (no IPTG): %.4f dA415/min / %.2f A mM^-1 cm^-1 = %.4f mM/min in the cuvette; x 1.5 = %.4f mM/min in the reaction; x 12.0 mL = %.3f umol/min per assay",
                exA$V0_dA415_per_min, eps, cv$V0_mM_per_min_cuvette, cv$V0_uM_per_min_reaction / 1000, cv$V0_umol_per_min_assay))

# V0 under each estimator (both datasets, both substrate conditions)
ESTIMATORS <- c(P = "P: two-tier rule (primary)",
                R = "R: initial-window regression only",
                S = "S: origin-assumed 0-2 min average rate for every curve",
                O = "O: two-tier rule, baseline-offset scenario for the 0-2 min estimates",
                A = "A: all five points for every curve")
v0 <- fits |> filter(condition %in% c("mm_no_inhibitor", "mm_plus_iptg"), n_used > 0) |>
  transmute(data_role, dataset, condition, tube, onpg_mM, iptg_mM, origin_assumed,
            !!ESTIMATORS[["P"]] := V0_dA415_per_min,
            !!ESTIMATORS[["R"]] := slope,
            !!ESTIMATORS[["S"]] := secant_0_2,
            !!ESTIMATORS[["O"]] := if_else(origin_assumed, secant_0_2_offset_scenario, V0_dA415_per_min),
            !!ESTIMATORS[["A"]] := slope_all5) |>
  pivot_longer(-c(data_role, dataset, condition, tube, onpg_mM, iptg_mM, origin_assumed), names_to = "estimator", values_to = "V0_dA")
v0 <- bind_cols(v0, convert_v0(v0$V0_dA, eps) |> select(V0_uM_per_min_reaction, V0_umol_per_min_assay))
write_csv(v0, file.path(dir_proc, "v0_scenarios.csv"), na = "NA")

# Primary uninhibited analysis (reference), V0 in umol/min per assay
u   <- v0 |> filter(data_role == "reference", condition == "mm_no_inhibitor", estimator == ESTIMATORS[["P"]])
lb  <- fit_lineweaver_burk(u$onpg_mM, u$V0_umol_per_min_assay)
nls <- fit_mm_nls(u$onpg_mM, u$V0_umol_per_min_assay)

scen <- v0 |> filter(data_role == "reference", condition == "mm_no_inhibitor") |> group_by(estimator) |>
  group_modify(~ bind_rows(fit_lineweaver_burk(.x$onpg_mM, .x$V0_umol_per_min_assay), fit_mm_nls(.x$onpg_mM, .x$V0_umol_per_min_assay))) |> ungroup() |>
  mutate(condition = "mm_no_inhibitor", primary = estimator == ESTIMATORS[["P"]], V0_units = "umol/min per 12 mL assay", tubes = "ABCDEF")
write_csv(scen, file.path(dir_proc, "kinetic_parameters_no_inhibitor.csv"), na = "NA")

# Fraction of the nominal substrate converted by 2 and 10 min (both datasets)
tidy <- read_csv(file.path(dir_proc, "absorbance_tidy.csv"), show_col_types = FALSE)
depl <- tidy |> filter(condition %in% c("mm_no_inhibitor", "mm_plus_iptg"), measured, time_min %in% c(2, 10)) |>
  mutate(onp_reaction_mM = absorbance_415nm / (eps * PATH_LENGTH_CM * ASSAY_DILUTION),
         percent_converted = 100 * onp_reaction_mM / onpg_mM) |>
  select(data_role, dataset, condition, tube, onpg_mM, time_min, absorbance_415nm, percent_converted) |>
  pivot_wider(names_from = time_min, values_from = c(absorbance_415nm, percent_converted), names_glue = "{.value}_{time_min}min")
write_csv(depl, file.path(dir_proc, "depletion_estimates.csv"), na = "NA")
write_table(depl |> transmute(Dataset = dataset, Tube = tube, `[ONPG]0 (mM)` = round(onpg_mM, 4),
                              `A415 2 min` = absorbance_415nm_2min, `Converted at 2 min (%)` = round(percent_converted_2min, 1),
                              `A415 10 min` = absorbance_415nm_10min, `Converted at 10 min (%)` = round(percent_converted_10min, 1)),
            "tableS5_substrate_depletion", digits = 3)

message(sprintf("05_michaelis_menten.R: no inhibitor (reference), LB Km = %.3f mM, Vmax = %.3f umol/min (R2 %.3f, physical = %s); NLS Km = %.3f +/- %.3f, Vmax = %.3f +/- %.3f",
                lb$Km, lb$Vmax, lb$r2, lb$physical, nls$Km, nls$Km_se, nls$Vmax, nls$Vmax_se))
