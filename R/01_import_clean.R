# 01_import_clean.R
# Import the reference dataset (course-provided) and the experimental dataset
# (our instrument printouts), validate both against the design in the manual,
# attach tube compositions and reaction concentrations, and write the audit
# tables and the raw-data tables used in the reports.
#
# Inputs : data/raw/reference/*.csv, data/raw/experimental/*.csv, data/raw/tube_compositions.csv
# Outputs: data/processed/absorbance_tidy.csv, onp_spectrum.csv, onp_standards.csv,
#          tube_conditions.csv, standard_tube_comparison.csv, validation_report.csv
#          tables/table_standard_curve_mapping, table_audit_reference, table_audit_experimental,
#          table_dataset_crosswalk, table_tube_compositions,
#          table_r1_spectrum, table_r2_standard_curve, table_r3_enzyme_dilution_raw,
#          table_r4_substrate_series_raw, tableS2_experimental_raw_absorbance
source(here::here("R", "00_setup.R"))

comp <- read_csv(file.path(dir_raw, "tube_compositions.csv"), show_col_types = FALSE,
                 col_types = cols(part = "c", condition = "c", tube = "c", .default = "d"))

# Reference dataset ---------------------------------------------------------
spec <- read_csv(file.path(dir_ref, "part1_onp_spectrum.csv"), show_col_types = FALSE)
std  <- read_csv(file.path(dir_ref, "part1_onp_standard_curve.csv"), show_col_types = FALSE,
                 col_types = cols(reported_tube = "c", manual_tube = "c", mapping_basis = "c", .default = "d"))
ed_r <- read_csv(file.path(dir_ref, "part2_enzyme_dilution.csv"), show_col_types = FALSE)
p3_r <- read_csv(file.path(dir_ref, "part3_substrate_series.csv"), show_col_types = FALSE)

# Cross-check the transcriptions against the course's original files when they are
# present (the originals are not redistributed with the repository)
src_dir <- file.path(dir_ref, "source_files")
if (file.exists(file.path(src_dir, "instructor_part1_values.csv"))) {
  src_csv <- read_csv(file.path(src_dir, "instructor_part1_values.csv"), show_col_types = FALSE)
  chk_spec <- src_csv |> filter(section == "ONP wavelength spectrum") |>
    transmute(wavelength_nm = x_value, abs_src = absorbance) |>
    full_join(spec, by = "wavelength_nm") |> mutate(match = abs(abs_src - absorbance) < 1e-9)
  chk_std <- src_csv |> filter(section == "ONP standard curve tube") |>
    transmute(reported_tube = as.character(x_value), abs_src = absorbance) |>
    full_join(std |> filter(!is.na(reported_tube)) |> select(reported_tube, abs_415nm), by = "reported_tube") |>
    mutate(match = abs(abs_src - abs_415nm) < 1e-9)
  src_p3 <- read_csv(file.path(src_dir, "instructor_day2_primary_results.csv"), show_col_types = FALSE)
  chk_p3 <- full_join(src_p3 |> rename(abs_src = absorbance_415nm), p3_r, by = c("condition", "tube", "time_min")) |>
    mutate(match = abs(abs_src - absorbance_415nm) < 1e-9)
  check_that(all(chk_spec$match) && all(chk_std$match) && all(chk_p3$match),
             "a transcribed reference value differs from the course's source file")
  source_check_note <- "transcription verified value by value against the course's source files"
} else {
  source_check_note <- "course source files not present; transcription not re-verified in this run"
}

# Standard-curve mapping: the course's table lists seven readings (tubes 1-7) while
# the manual describes a blank and seven standards. The reported tube 1 (OD 0) is
# the zero-concentration preparation (confirmed by the instructor); the remaining
# six readings follow the manual's standards 1-6 in order, anchored by the spectrum
# tube: manual tube 4 read 1.723 at 415 nm, identical to reported tube 5.
std <- std |> mutate(total_ml = onp_ml + z_buffer_ml + na2co3_ml,
                     onp_mM_cuvette = STOCK_ONP_MM * onp_ml / total_ml,
                     reported = !is.na(abs_415nm))
check_that(all(abs(std$total_ml - STANDARD_VOLUME_ML) < 1e-9), "a Part I standard does not total 3.0 mL")
check_that(abs(spec$absorbance[spec$wavelength_nm == WAVELENGTH_NM] -
               std$abs_415nm[std$manual_tube == as.character(SPECTRUM_TUBE)]) < 1e-9,
           "the spectrum reading at 415 nm does not equal the reading mapped to manual tube 4")
write_csv(spec, file.path(dir_proc, "onp_spectrum.csv"))
write_csv(std, file.path(dir_proc, "onp_standards.csv"), na = "NA")

table_map <- std |> transmute(
  `Reported tube (course table)` = ifelse(is.na(reported_tube), "not reported", reported_tube),
  `Manual preparation` = ifelse(manual_tube == "Blank", "Blank (0 mL ONP)", paste0("Standard ", manual_tube)),
  `ONP 1 mM (mL)` = onp_ml, `Z buffer (mL)` = z_buffer_ml, `Na2CO3 1 M (mL)` = na2co3_ml,
  `[ONP] in cuvette (mM)` = round(onp_mM_cuvette, 4),
  `A415 (reported)` = ifelse(is.na(abs_415nm), "none", formatC(abs_415nm, digits = 3, format = "f")),
  `Basis of the mapping` = mapping_basis)
write_table(table_map, "table_standard_curve_mapping", digits = 4)

# Experimental dataset ------------------------------------------------------
raw_e <- read_csv(file.path(dir_exp, "absorbance_raw.csv"), show_col_types = FALSE,
                  col_types = cols(source_label = "c", tube = "c", time_min = "d", absorbance_415nm = "d", note = "c"))
meta  <- read_csv(file.path(dir_exp, "printout_metadata.csv"), show_col_types = FALSE)
check_that(all(raw_e$time_min %in% TIME_POINTS_MIN), "an experimental time point is not in the design")
check_that(all(raw_e$source_label %in% EXPERIMENTAL_LABEL_MAP$source_label), "an experimental printout label is not in the label map")

# Compositions and concentrations ---------------------------------------------
comp <- comp |> mutate(total_ml = z_buffer_ml + onpg_ml + iptg_ml + enzyme_ml + onp_ml + na2co3_ml)
check_that(all(abs(comp$total_ml[comp$part != "Part I"] - REACTION_VOLUME_ML) < 1e-9), "a Part II/III tube does not total 12.0 mL")
check_that(all(abs(comp$total_ml[comp$part == "Part I"] - STANDARD_VOLUME_ML) < 1e-9), "a Part I standard does not total 3.0 mL")
check_that(all(comp$onpg_ml >= 0 & comp$iptg_ml >= 0 & comp$enzyme_ml >= 0), "negative volume in tube compositions")
comp <- comp |>
  mutate(onpg_mM = STOCK_ONPG_MM * onpg_ml / REACTION_VOLUME_ML,
         iptg_mM = STOCK_IPTG_MM * iptg_ml / REACTION_VOLUME_ML,
         rel_enzyme = if_else(condition == "enzyme_dilution", enzyme_ml / max(enzyme_ml[condition == "enzyme_dilution"]), NA_real_))
check_that(all(comp$onpg_mM[comp$part != "Part I"] > 0), "a reaction tube has zero substrate")
message(sprintf("[S] tube B (Part III): %.1f mM x 4.0 mL / %.1f mL = %.3f mM;  [I]: %.1f mM x 1.0 mL / %.1f mL = %.4f mM",
                STOCK_ONPG_MM, REACTION_VOLUME_ML, comp$onpg_mM[comp$condition == "mm_no_inhibitor" & comp$tube == "B"],
                STOCK_IPTG_MM, REACTION_VOLUME_ML, comp$iptg_mM[comp$condition == "mm_plus_iptg" & comp$tube == "A"]))

# One tidy table of progress curves for both datasets ----------------------------
ref_tidy <- bind_rows(
  ed_r |> transmute(data_role = "reference", dataset = "Reference Part II", source_label = "Day1_PartI docx, enzyme-dilution table",
                    condition = "enzyme_dilution", tube, time_min, absorbance_415nm),
  p3_r |> rename(source_condition = condition) |> left_join(REFERENCE_LABEL_MAP, by = "source_condition") |>
    transmute(data_role = "reference", dataset, source_label = paste0("Day2 pptx, '", source_condition, "' table"),
              condition, tube, time_min, absorbance_415nm))
exp_tidy <- raw_e |> left_join(EXPERIMENTAL_LABEL_MAP, by = "source_label") |>
  transmute(data_role = "experimental", dataset, source_label, condition, tube, time_min, absorbance_415nm, note)
tidy <- bind_rows(ref_tidy, exp_tidy) |>
  left_join(comp |> filter(part != "Part I") |> select(condition, tube, z_buffer_ml, onpg_ml, iptg_ml, enzyme_ml, onpg_mM, iptg_mM, rel_enzyme),
            by = c("condition", "tube")) |>
  mutate(condition_label = CONDITION_LABELS[condition], measured = !is.na(absorbance_415nm),
         curve_id = paste(dataset, tube), abs_flag = flag_absorbance(absorbance_415nm)) |>
  arrange(desc(data_role == "reference"), dataset, tube, time_min)
check_that(nrow(tidy) == nrow(distinct(tidy, dataset, tube, time_min)), "duplicate observation for a dataset/tube/time")
check_that(all(!is.na(tidy$onpg_mM)), "a progress curve has no tube composition")
check_that(all(tidy$abs_flag[tidy$measured] %in% c("ok", "above 3 A (near linear limit)")), "an absorbance reading is outside the plausible range")
write_csv(tidy, file.path(dir_proc, "absorbance_tidy.csv"), na = "NA")

validation <- bind_rows(
  tibble(check = "Part II/III tubes total 12.0 mL", result = "passed", detail = paste(nrow(filter(comp, part != "Part I")), "tubes")),
  tibble(check = "Part I standards total 3.0 mL", result = "passed", detail = paste(nrow(filter(comp, part == "Part I")), "preparations")),
  tibble(check = "Time points in design (2, 4, 6, 8, 10 min)", result = "passed", detail = paste(nrow(tidy), "observations")),
  tibble(check = "Absorbance readings within plausible range", result = "passed",
         detail = paste0(sum(tidy$measured), " progress-curve readings within range; ", sum(std$abs_415nm > 3, na.rm = TRUE),
                         " standard-curve reading above 3 A (", paste(std$abs_415nm[which(std$abs_415nm > 3)], collapse = ", "), " A, near the instrument's linear limit)")),
  tibble(check = "Missing readings", result = ifelse(any(!tidy$measured), "flagged", "none"),
         detail = paste(unique(tidy$curve_id[!tidy$measured]), collapse = "; ")),
  tibble(check = "Spectrum tube reading equals mapped standard (manual tube 4)", result = "passed", detail = "1.723 at 415 nm in both tables"),
  tibble(check = "Transcriptions against course source files", result = ifelse(grepl("verified", source_check_note), "passed", "skipped"), detail = source_check_note))
write_csv(validation, file.path(dir_proc, "validation_report.csv"))

tube_conditions <- comp |> filter(part != "Part I") |>
  mutate(reference_measured = case_when(condition == "enzyme_dilution" & tube %in% LETTERS[1:5] ~ "measured",
                                        condition != "enzyme_dilution" ~ "measured", TRUE ~ "not in design"),
         experimental_measured = case_when(tube == "F" ~ "not performed",
                                           condition == "mm_plus_iptg" & tube == "E" ~ "sample discarded before measurement",
                                           TRUE ~ "measured"))
write_csv(tube_conditions, file.path(dir_proc, "tube_conditions.csv"), na = "NA")
write_table(DATASET_CROSSWALK |> rename(`Role` = data_role, `Dataset label in this project` = dataset,
                                        `Label on the source` = source_label, `File` = source_file),
            "table_dataset_crosswalk")

# Audit tables ----------------------------------------------------------------------
increments <- function(d) d |> filter(measured) |> group_by(dataset, tube) |> arrange(time_min, .by_group = TRUE) |>
  summarise(increments = paste(fmt_num(diff(absorbance_415nm), 3), collapse = " / "),
            inc2_over_inc1 = diff(absorbance_415nm)[2] / diff(absorbance_415nm)[1],
            last_over_prior = last(diff(absorbance_415nm)) / mean(head(diff(absorbance_415nm), -1)), .groups = "drop")

audit_r <- tidy |> filter(data_role == "reference") |> group_by(dataset, condition_label, tube) |>
  summarise(observed_time_points = paste(time_min[measured], collapse = ", "), n_missing = sum(!measured), .groups = "drop") |>
  left_join(increments(tidy |> filter(data_role == "reference")), by = c("dataset", "tube")) |>
  mutate(source_check = case_when(
    dataset == "Reference Part II" ~ "Transcribed from the course .docx (table absent from the supplied CSV)",
    TRUE ~ "Supplied CSV matches the course .pptx (all 30 values per condition)"),
    observation = case_when(
      dataset == "Reference Part II" & tube == "A" ~ "8-min reading (0.965) far below the 2-6 min trend; 10-min reading returns to it",
      dataset == "Reference Part II" & tube == "C" ~ "8-min reading below trend",
      dataset == "Reference Part II" & tube %in% c("D", "E") ~ "Tubes D (0.25) and E (0.15 relative enzyme) gave nearly equal rates",
      dataset == "Reference Part III (-IPTG)" & tube == "A" ~ "Linear to 10 min",
      dataset == "Reference Part III (-IPTG)" ~ "Rate falls from the first interval onward (increments decline monotonically)",
      dataset == "Reference Part III (+IPTG)" & tube == "A" ~ "Irregular 4-min reading (0.480); later increments below the first",
      dataset == "Reference Part III (+IPTG)" & tube %in% c("B", "C") ~ "Slows after 6 min",
      TRUE ~ "Approximately linear; small increments (read-out resolution 0.001 A matters)"))
write_table(audit_r, "table_audit_reference", digits = 3)

audit_e <- tidy |> filter(data_role == "experimental") |> group_by(dataset, source_label, condition_label, tube) |>
  summarise(observed_time_points = ifelse(any(measured), paste(time_min[measured], collapse = ", "), "none"),
            n_missing = sum(!measured), .groups = "drop") |>
  left_join(increments(tidy |> filter(data_role == "experimental")), by = c("dataset", "tube")) |>
  left_join(meta |> select(source_label, tube, verification, instrument_clock), by = c("source_label", "tube")) |>
  mutate(observation = case_when(
    source_label == "Day 2 Black" & tube == "E" ~ "All five observations missing: sample discarded before measurement (kept NA)",
    source_label == "Day 2 Black" & tube == "B" ~ "Whole curve faster than tube A at half the nominal ONPG; 10-min value 1.106 retained (46% of predicted increment)",
    source_label == "Day 2 Blue"  & tube == "E" ~ "Non-linear from the outset (2nd increment 53% of 1st)",
    source_label == "Day 2 Blue"  & tube == "D" ~ "Decelerates after 6 min",
    source_label == "Day 2 Black" & tube == "A" ~ "Linear to 10 min; ID 3 last digit under photo glare, 0.476 read from the original printout",
    TRUE ~ "Linear to 8 or 10 min"))
write_table(audit_e, "table_audit_experimental", digits = 3)

# The one composition shared by the two datasets: standard tube A (0.2 mL enzyme, 2.20 mM ONPG)
shared <- tidy |> filter(tube == "A", condition %in% c("enzyme_dilution", "mm_no_inhibitor")) |>
  select(data_role, dataset, time_min, absorbance_415nm) |> pivot_wider(names_from = dataset, values_from = absorbance_415nm)
write_csv(shared, file.path(dir_proc, "standard_tube_comparison.csv"), na = "NA")

# Raw-data tables for the five datasets (reference, Results section) ----------------
table_r1 <- tibble(` ` = c("Wavelength (nm)", "Absorbance"))
for (k in seq_len(nrow(spec))) table_r1[[paste0(" ", strrep(" ", k))]] <- c(as.character(spec$wavelength_nm[k]), formatC(spec$absorbance[k], digits = 3, format = "f"))
write_table(table_r1, "table_r1_spectrum", digits = 4)

table_r2 <- std |> filter(reported) |> transmute(
  `Reported tube` = reported_tube, `Manual preparation` = ifelse(manual_tube == "Blank", "Blank", paste0("Std ", manual_tube)),
  `ONP 1 mM (mL)` = onp_ml, `Z buffer (mL)` = z_buffer_ml, `Na2CO3 1 M (mL)` = na2co3_ml,
  `[ONP] (mM)` = round(onp_mM_cuvette, 4), `A415` = abs_415nm)
write_table(table_r2, "table_r2_standard_curve", digits = 4)

table_r3 <- tidy |> filter(dataset == "Reference Part II") |>
  select(tube, enzyme_ml, rel_enzyme, time_min, absorbance_415nm) |>
  pivot_wider(names_from = time_min, values_from = absorbance_415nm, names_glue = "{time_min} min") |>
  transmute(Tube = tube, `Enzyme (mL)` = enzyme_ml, `Relative enzyme` = rel_enzyme, `2 min`, `4 min`, `6 min`, `8 min`, `10 min`)
write_table(table_r3, "table_r3_enzyme_dilution_raw", digits = 4)

table_r4 <- tidy |> filter(data_role == "reference", condition != "enzyme_dilution") |>
  select(condition_label, tube, onpg_ml, onpg_mM, iptg_mM, time_min, absorbance_415nm) |>
  pivot_wider(names_from = time_min, values_from = absorbance_415nm, names_glue = "{time_min} min") |>
  arrange(desc(condition_label == "ONPG series, no inhibitor"), tube) |>
  transmute(Condition = condition_label, Tube = tube, `ONPG (mL)` = onpg_ml, `[ONPG] (mM)` = round(onpg_mM, 5), `[IPTG] (mM)` = round(iptg_mM, 3),
            `2 min`, `4 min`, `6 min`, `8 min`, `10 min`)
write_table(table_r4, "table_r4_substrate_series_raw", digits = 4)

tableS2 <- tidy |> filter(data_role == "experimental") |> select(dataset, source_label, condition_label, tube, time_min, absorbance_415nm) |>
  pivot_wider(names_from = time_min, values_from = absorbance_415nm, names_glue = "{time_min} min") |>
  arrange(match(dataset, EXPERIMENTAL_LABEL_MAP$dataset), tube) |>
  rename(Dataset = dataset, `Printout label` = source_label, Condition = condition_label, Tube = tube) |>
  # Printed exactly as the instrument reports them (three decimals), not rounded to significant figures
  mutate(across(ends_with(" min"), ~ ifelse(is.na(.x), NA_character_, formatC(.x, digits = 3, format = "f"))))
write_table(tableS2, "tableS2_experimental_raw_absorbance")

table_comp <- comp |> filter(part != "Part I") |>
  transmute(Part = part, Condition = CONDITION_LABELS[condition], Tube = tube,
            `Z buffer (mL)` = z_buffer_ml, `ONPG 3.3 mM (mL)` = onpg_ml, `IPTG 5.5 mM (mL)` = iptg_ml, `Enzyme (mL)` = enzyme_ml,
            `[ONPG] in reaction (mM)` = round(onpg_mM, 4), `[IPTG] in reaction (mM)` = round(iptg_mM, 4), `Relative enzyme` = rel_enzyme)
write_table(table_comp, "table_tube_compositions", digits = 4)

message("01_import_clean.R: ", sum(tidy$data_role == "reference"), " reference and ", sum(tidy$data_role == "experimental"),
        " experimental observations; ", source_check_note)
