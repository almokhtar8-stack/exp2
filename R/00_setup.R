# 00_setup.R
# Shared settings for the Experiment 2 analysis: packages, project paths,
# quantities taken from the laboratory manual, dataset roles and provenance,
# the initial-velocity rule, kinetic model functions and the figure theme.
# Every other script sources this file. Nothing derived from the data is
# hard-coded here.

# Package dependencies (installed from CRAN or the distribution's r-cran-* packages)
required_packages <- c("tidyverse", "broom", "patchwork", "scales", "here")
optional_packages <- c("ragg", "systemfonts")   # sharper PNG output; the scripts fall back to grDevices
missing_pkgs <- required_packages[!vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing_pkgs)) {
  stop("Missing R packages: ", paste(missing_pkgs, collapse = ", "),
       ". Install with install.packages(c(", paste0('"', missing_pkgs, '"', collapse = ", "), "))", call. = FALSE)
}
suppressPackageStartupMessages({
  library(tidyverse)
  library(broom)
  library(patchwork)
  library(scales)
  library(here)
})

# Greek letters and symbols in figure text need a UTF-8 locale; some headless sessions default to "C"
if (!grepl("UTF-8|utf8", Sys.getlocale("LC_CTYPE"), ignore.case = TRUE)) {
  for (loc in c("C.UTF-8", "en_US.UTF-8", "en_GB.UTF-8")) {
    if (nzchar(suppressWarnings(tryCatch(Sys.setlocale("LC_CTYPE", loc), error = function(e) "")))) break
  }
}

# Project paths (relative to the project root marked by the .here file)
dir_raw   <- here("data", "raw")
dir_ref   <- here("data", "raw", "reference")
dir_exp   <- here("data", "raw", "experimental")
dir_proc  <- here("data", "processed")
dir_fig   <- here("figures")
dir_supp  <- here("figures", "supplementary")
dir_tab   <- here("tables")
dir_rep   <- here("report")
walk(c(dir_proc, dir_fig, dir_supp, dir_tab, dir_rep), ~ dir.create(.x, showWarnings = FALSE, recursive = TRUE))

# Public location of this repository. NA until the repository has been published;
# the reports then state that publication is pending rather than printing a placeholder URL.
REPOSITORY_URL <- "https://github.com/almokhtar8-stack/exp2"

# Dataset roles. The course instructor (e-mail of 13 September 2026) supplied
# measurements for the Results section and asked that students' own results be
# discussed in the Discussion. The two roles describe origin and analytical
# role, not accuracy or publication status.
#   reference    : course-provided measurements (Part I spectrum, standard curve
#                  and enzyme dilution; Part III substrate series with and
#                  without IPTG); primary kinetic analysis
#   experimental : measurements collected by our laboratory group (instrument
#                  printouts, 7 and 11 September 2026); Discussion, troubleshooting,
#                  secondary analysis
DATA_ROLES <- c(reference = "Reference dataset (course-provided)",
                experimental = "Experimental dataset (our laboratory group)")

# Crosswalk between the labels used in this project and the labels on the source files
DATASET_CROSSWALK <- tribble(
  ~data_role,     ~dataset,                          ~source_label,                                      ~source_file,
  "reference",    "Reference Part I",                "Day1_PartI_ONP_and_enzyme_dilution.docx (tables 1-2)", "data/raw/reference/part1_onp_spectrum.csv; part1_onp_standard_curve.csv",
  "reference",    "Reference Part II",               "Day1_PartI_ONP_and_enzyme_dilution.docx (table 3)",   "data/raw/reference/part2_enzyme_dilution.csv",
  "reference",    "Reference Part III (-IPTG)",      "Day2 pptx / instructor_day2_primary_results.csv: 'No IPTG'", "data/raw/reference/part3_substrate_series.csv",
  "reference",    "Reference Part III (+IPTG)",      "Day2 pptx / instructor_day2_primary_results.csv: '+ IPTG'",  "data/raw/reference/part3_substrate_series.csv",
  "experimental", "Experimental Part II",            "printouts labelled 'Day 1' (red ink), 7 Sep 2026",     "data/raw/experimental/absorbance_raw.csv",
  "experimental", "Experimental Part III (-IPTG)",   "printouts labelled 'Day 2 Blue', 11 Sep 2026",        "data/raw/experimental/absorbance_raw.csv",
  "experimental", "Experimental Part III (+IPTG)",   "printouts labelled 'Day 2 Black', 11 Sep 2026",       "data/raw/experimental/absorbance_raw.csv")

# Mapping of the experimental printout labels to experimental conditions. Established
# in the data audit from tube count, the manual's enzyme standardisation (standard tube
# A reaches A415 1.2-1.3 at 10 min) and the rate structure of the two Day 2 sets;
# the reference dataset shows the same pattern (see table_audit_experimental).
EXPERIMENTAL_LABEL_MAP <- tibble(
  source_label = c("Day 1", "Day 2 Blue", "Day 2 Black"),
  dataset      = c("Experimental Part II", "Experimental Part III (-IPTG)", "Experimental Part III (+IPTG)"),
  condition    = c("enzyme_dilution", "mm_no_inhibitor", "mm_plus_iptg"))
REFERENCE_LABEL_MAP <- tibble(
  source_condition = c("No IPTG", "+ IPTG"),
  dataset          = c("Reference Part III (-IPTG)", "Reference Part III (+IPTG)"),
  condition        = c("mm_no_inhibitor", "mm_plus_iptg"))
CONDITION_LABELS <- c(
  enzyme_dilution = "Enzyme dilution (Part II)",
  mm_no_inhibitor = "ONPG series, no inhibitor",
  mm_plus_iptg    = "ONPG series + IPTG",
  onp_standard    = "ONP standard curve (Part I)")

# Quantities stated in the laboratory manual
STOCK_ONPG_MM        <- 3.3    # ONPG, 1.0 mg/mL stated as 3.3 mM (Parts II and III)
STOCK_IPTG_MM        <- 5.5    # IPTG, 1.31 mg/mL stated as 5.5 mM (Part III)
STOCK_ONP_MM         <- 1.0    # ONP standard, 1 mM in water (Part I)
REACTION_VOLUME_ML   <- 12.0   # every Part II/III reaction tube sums to 12.0 mL (checked in 01_import_clean.R)
ALIQUOT_ML           <- 2.0    # reaction mixture removed per time point
STOP_NA2CO3_ML       <- 1.0    # 1 M Na2CO3 added to each aliquot
STANDARD_VOLUME_ML   <- 3.0    # Part I standard: ONP + Z buffer (2.0 mL) + 1.0 mL Na2CO3
ASSAY_DILUTION       <- ALIQUOT_ML / (ALIQUOT_ML + STOP_NA2CO3_ML)   # 2/3: [ONP] in cuvette / [ONP] in reaction
TIME_POINTS_MIN      <- c(2, 4, 6, 8, 10)
WAVELENGTH_NM        <- 415
PATH_LENGTH_CM       <- 1
ENZYME_ML_STANDARD   <- 0.2    # enzyme volume in every Part III tube and in Part II tube A
ENZYME_STD_OD_RANGE  <- c(1.20, 1.30)  # manual: enzyme standardised to A415 1.20-1.30 after 10 min in the standard tube
SPECTRUM_TUBE        <- 4      # manual Part I step 2: spectrum recorded on tube 4 (1.0 mL ONP)
ABS_PLAUSIBLE_RANGE  <- c(-0.01, 3.5)  # readings outside this range are flagged by the validation checks
INSTRUMENT_LINEAR_LIMIT_A <- 3.5       # GENESYS 10S UV-Vis specification: photometric linear range up to 3.5 A (at 260 nm)

# Conversion of an initial velocity expressed as dA415/min in the stopped 3.0 mL
# sample into product formed per minute, once epsilon (A per mM per cm) is known:
#   rate in cuvette   (mM/min) = slope / (epsilon x path)
#   rate in reaction  (mM/min) = cuvette rate / ASSAY_DILUTION   (x 1.5)
#   product per assay (umol/min) = reaction rate x 12.0 mL
# The manual's instruction "divide the slope by epsilon" gives the cuvette rate in
# mM/min; the two further factors convert it to an amount per minute.
convert_v0 <- function(slope_dA_per_min, epsilon) {
  cuv <- slope_dA_per_min / (epsilon * PATH_LENGTH_CM)
  rxn <- cuv / ASSAY_DILUTION
  tibble(V0_mM_per_min_cuvette = cuv, V0_uM_per_min_reaction = rxn * 1000,
         V0_umol_per_min_assay = rxn * REACTION_VOLUME_ML,
         V0_umol_per_min_per_mL_enzyme = rxn * REACTION_VOLUME_ML / ENZYME_ML_STANDARD)
}

# Initial-velocity rule (02_progress_curves.R). The manual asks for V0 from the
# initial linear portion of each progress curve, with the points used identified.
# The rule below applies that instruction identically to every curve:
#   Tier 1  initial linear window: regression on the 2, 4 and 6 min points,
#           extended one point at a time while the next increment lies within
#           REL_TOL of the increment predicted by the current line (or within
#           ABS_TOL absorbance units of it, whichever is larger, so that
#           low-signal curves are not cut by read-out noise). V0 = slope.
#   Tier 2  no initial linear portion: when the second and third increments both
#           fall below the first by more than the tolerance, no linear window
#           can be fitted. V0 is then the 0-2 min average rate, A415(2 min)/2 min,
#           which assumes A415 = 0 at t = 0 because no reading exists there. This
#           is an origin-assumed average rate over the first interval, not a
#           measured instantaneous initial velocity; it is flagged (†) wherever
#           it is used. 02_progress_curves.R adds a sensitivity scenario in
#           which the t = 0 absorbance is set to the median intercept of the
#           curves that are linear (an assumption transferred between
#           reactions, not a measured baseline), carried through as estimator O
#           the sensitivity analysis.
REL_TOL    <- 0.20
ABS_TOL    <- 0.010
MIN_POINTS <- 3

# Observation excluded from the experimental kinetic fits (retained in the raw
# data and in every figure). Experimental Part III (+IPTG) tube B ran faster
# than tube A at half the nominal substrate concentration, so its nominal
# composition cannot be verified.
EXPERIMENTAL_EXCLUDE_FROM_FIT <- tibble(
  dataset = "Experimental Part III (+IPTG)", tube = "B",
  reason  = "V0 exceeds tube A at half the nominal substrate; nominal [S] unverifiable")

# Validation helpers used by the import script
check_that <- function(condition, message) if (!isTRUE(condition)) stop("Data validation failed: ", message, call. = FALSE)
flag_absorbance <- function(a) {
  case_when(is.na(a) ~ "missing",
            a < ABS_PLAUSIBLE_RANGE[1] ~ "below zero",
            a > INSTRUMENT_LINEAR_LIMIT_A ~ "above instrument linear range",
            a > 3 ~ "above 3 A (near linear limit)",
            TRUE ~ "ok")
}

# Figure styling: Scientific Nebula palette on white
# Purple-anchored palette whose data colours stay separable under simulated
# deuteranopia, protanopia and tritanopia (minimum CIE76 distance >= 25 between
# any two tube colours, > 80 between the two conditions); every series also has
# its own marker shape, so no information is carried by colour alone.
nebula <- c(
  violet = "#5B21B6", purple = "#7C3AED", blue = "#0072B2", sky = "#56B4E9", cyan = "#0891B2",
  orange = "#E69F00", vermilion = "#D55E00", magenta = "#C026D3", rose = "#E11D48", indigo = "#312E81",
  ink = "#111827", grey = "#6B7280", pale = "#E5E7EB", mist = "#F3EEFB", bg = "#FFFFFF")
# Six tubes: colour, fillable shape and line type carry the distinction together
TUBE_COLOURS <- c(A = nebula[["violet"]], B = nebula[["blue"]], C = nebula[["sky"]],
                  D = nebula[["orange"]], E = nebula[["rose"]], F = nebula[["ink"]])
TUBE_SHAPES  <- c(A = 21, B = 24, C = 22, D = 23, E = 25, F = 8)
TUBE_LINES   <- c(A = "solid", B = "solid", C = "solid", D = "solid", E = "solid", F = "solid")
COND_COLOURS <- c(mm_no_inhibitor = nebula[["violet"]], mm_plus_iptg = nebula[["vermilion"]])
COND_SHAPES  <- c(mm_no_inhibitor = 21, mm_plus_iptg = 24)
COND_LINES   <- c(mm_no_inhibitor = "solid", mm_plus_iptg = "longdash")
COND_LABELS  <- c(mm_no_inhibitor = "No inhibitor", mm_plus_iptg = "+ 0.458 mM IPTG")
ROLE_COLOURS <- c(reference = nebula[["violet"]], experimental = nebula[["cyan"]])
ROLE_LABELS  <- c(reference = "Reference dataset", experimental = "Experimental dataset")

pick_font <- function(candidates = c("Liberation Sans", "Helvetica", "Arial", "DejaVu Sans")) {
  if (!requireNamespace("systemfonts", quietly = TRUE)) return("sans")
  hit <- candidates[candidates %in% unique(systemfonts::system_fonts()$family)]
  if (length(hit)) hit[1] else "sans"
}
FIG_FONT <- pick_font()

theme_nebula_science <- function(base_size = 10, base_family = FIG_FONT) {
  theme_minimal(base_size = base_size, base_family = base_family) %+replace%
    theme(
      plot.background   = element_rect(fill = nebula[["bg"]], colour = NA),
      panel.background  = element_rect(fill = nebula[["bg"]], colour = NA),
      panel.grid.major  = element_line(colour = "#ECEEF2", linewidth = 0.3),
      panel.grid.minor  = element_blank(),
      panel.border      = element_blank(),
      axis.line         = element_line(colour = nebula[["ink"]], linewidth = 0.5),
      axis.ticks        = element_line(colour = nebula[["ink"]], linewidth = 0.45),
      axis.ticks.length = unit(2.5, "pt"),
      axis.text         = element_text(colour = nebula[["ink"]], size = rel(0.9)),
      axis.title        = element_text(colour = nebula[["ink"]], size = rel(1.0)),
      axis.title.x      = element_text(margin = margin(t = 5)),
      axis.title.y      = element_text(margin = margin(r = 5), angle = 90),
      plot.title        = element_text(colour = nebula[["ink"]], face = "bold", size = rel(1.05), hjust = 0, margin = margin(b = 2)),
      plot.subtitle     = element_text(colour = nebula[["grey"]], size = rel(0.85), hjust = 0, margin = margin(b = 6)),
      plot.caption      = element_text(colour = nebula[["grey"]], size = rel(0.8), hjust = 0, margin = margin(t = 6)),
      plot.tag          = element_text(colour = nebula[["ink"]], face = "bold", size = rel(1.3)),
      plot.title.position   = "plot",
      plot.caption.position = "plot",
      legend.background = element_blank(),
      legend.key        = element_blank(),
      legend.key.size   = unit(11, "pt"),
      legend.text       = element_text(colour = nebula[["ink"]], size = rel(0.85)),
      legend.title      = element_text(colour = nebula[["ink"]], size = rel(0.85), face = "bold"),
      legend.position   = "right",
      legend.margin     = margin(0, 0, 0, 2),
      strip.background  = element_blank(),
      strip.text        = element_text(colour = nebula[["ink"]], face = "bold", size = rel(0.95), hjust = 0, margin = margin(b = 3)),
      plot.margin       = margin(6, 10, 4, 6),
      complete = TRUE
    )
}
theme_set(theme_nebula_science())

# Output helpers
save_figure <- function(plot, name, width, height, dir = dir_fig) {
  png_path <- file.path(dir, paste0(name, ".png"))
  pdf_path <- file.path(dir, paste0(name, ".pdf"))
  if (requireNamespace("ragg", quietly = TRUE)) {
    ggsave(png_path, plot, width = width, height = height, units = "in", dpi = 600, device = ragg::agg_png, bg = "white")
  } else {
    ggsave(png_path, plot, width = width, height = height, units = "in", dpi = 600, bg = "white")
  }
  ggsave(pdf_path, plot, width = width, height = height, units = "in", device = cairo_pdf, bg = "white")
  invisible(c(png = png_path, pdf = pdf_path))
}

write_table <- function(df, name, digits = 4) {
  # CSV and Markdown copies carry the same rounded values (signif to `digits`)
  df <- df |> mutate(across(where(is.numeric), ~ signif(.x, digits)))
  write_csv(df, file.path(dir_tab, paste0(name, ".csv")), na = "NA")
  fmt <- df |> mutate(across(where(is.numeric),
                             ~ case_when(is.na(.x) ~ "NA",
                                         .x == round(.x) & abs(.x) < 1e6 ~ as.character(round(.x)),
                                         TRUE ~ trimws(formatC(signif(.x, digits), digits = digits, format = "fg", drop0trailing = TRUE)))))
  fmt <- fmt |> mutate(across(where(is.character), ~ ifelse(is.na(.x), "NA", .x)))
  header <- paste0("| ", paste(names(fmt), collapse = " | "), " |")
  sep    <- paste0("|", paste(rep("---", ncol(fmt)), collapse = "|"), "|")
  rows   <- apply(fmt, 1, function(r) paste0("| ", paste(r, collapse = " | "), " |"))
  writeLines(c(header, sep, rows), file.path(dir_tab, paste0(name, ".md")))
  invisible(df)
}
fmt_num <- function(x, digits = 3) formatC(x, digits = digits, format = "f")

# Kinetic models
# Lineweaver-Burk regression (course method): 1/V0 = (Km/Vmax)(1/[S]) + 1/Vmax
fit_lineweaver_burk <- function(S, V0) {
  d <- tibble(inv_S = 1 / S, inv_V = 1 / V0)
  m <- lm(inv_V ~ inv_S, data = d); b <- coef(m); s <- summary(m)$coefficients
  Vmax <- 1 / unname(b[1])
  tibble(method = "Lineweaver-Burk", n = nrow(d), Km = unname(b[2]) * Vmax, Vmax = Vmax,
         lb_slope = unname(b[2]), lb_intercept = unname(b[1]), lb_slope_se = s[2, 2], lb_intercept_se = s[1, 2],
         r2 = summary(m)$r.squared, Km_se = NA_real_, Vmax_se = NA_real_, converged = TRUE,
         physical = unname(b[1]) > 0 & unname(b[2]) > 0, at_bound = FALSE,
         intercept_p = s[1, 4])
}

# Direct nonlinear least squares on the velocity scale (unweighted). A fit that
# runs to the upper bound of Km means that no plateau exists within the tested
# [S] range; such a fit is reported as "no plateau" rather than as a number.
KM_UPPER_BOUND <- 100   # mM
fit_mm_nls <- function(S, V0) {
  d <- tibble(S = S, V0 = V0)
  grid <- expand_grid(Vmax = max(V0) * c(1, 1.5, 2.5, 5), Km = c(0.05, 0.2, 0.5, 1, 2, 5))
  best <- NULL
  for (i in seq_len(nrow(grid))) {
    f <- suppressWarnings(tryCatch(nls(V0 ~ Vmax * S / (Km + S), data = d, start = list(Vmax = grid$Vmax[i], Km = grid$Km[i]),
                                       algorithm = "port", lower = c(1e-6, 1e-6), upper = c(1e3 * max(V0), KM_UPPER_BOUND),
                                       control = nls.control(maxiter = 500, warnOnly = TRUE)), error = function(e) NULL))
    if (!is.null(f) && isTRUE(f$convInfo$isConv) && (is.null(best) || deviance(f) < deviance(best))) best <- f
  }
  empty <- tibble(method = "Nonlinear MM", n = nrow(d), Km = NA_real_, Vmax = NA_real_,
                  lb_slope = NA_real_, lb_intercept = NA_real_, lb_slope_se = NA_real_, lb_intercept_se = NA_real_,
                  r2 = NA_real_, Km_se = NA_real_, Vmax_se = NA_real_, converged = FALSE, physical = NA, at_bound = NA)
  if (is.null(best)) return(empty)
  co <- tryCatch(summary(best)$coefficients, error = function(e) NULL)
  if (is.null(co)) return(empty)
  at_bound <- co["Km", "Estimate"] >= 0.99 * KM_UPPER_BOUND
  tibble(method = "Nonlinear MM", n = nrow(d),
         Km = if (at_bound) NA_real_ else co["Km", "Estimate"], Vmax = if (at_bound) NA_real_ else co["Vmax", "Estimate"],
         lb_slope = NA_real_, lb_intercept = NA_real_, lb_slope_se = NA_real_, lb_intercept_se = NA_real_,
         r2 = 1 - deviance(best) / sum((d$V0 - mean(d$V0))^2),
         Km_se = if (at_bound) NA_real_ else co["Km", "Std. Error"], Vmax_se = if (at_bound) NA_real_ else co["Vmax", "Std. Error"],
         converged = TRUE, physical = !at_bound, at_bound = at_bound)
}

# Ki from the manual's competitive relation Km_app = Km (1 + [I]/Ki), and the Ki a
# pure noncompetitive model would assign to a change in Vmax, Vmax_app = Vmax / (1 + [I]/Ki)
ki_competitive    <- function(Km, Km_app, I) I / ((Km_app / Km) - 1)
ki_noncompetitive <- function(Vmax, Vmax_app, I) I / ((Vmax / Vmax_app) - 1)

message("00_setup.R loaded (figure font: ", FIG_FONT, ")")
