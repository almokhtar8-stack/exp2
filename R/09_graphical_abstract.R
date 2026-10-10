# 09_graphical_abstract.R
# Graphical abstract for the journal-style version: reaction scheme, assay
# logic and the two saturation curves of the reference dataset, with the
# headline numbers taken from the processed results.
# Output: figures/graphical_abstract.{png,pdf}
source(here::here("R", "00_setup.R"))
theme_set(theme_nebula_science(base_size = 10))

vals <- read_csv(file.path(dir_fig, "main_figure_values.csv"), show_col_types = FALSE)
V <- function(n) vals$value[vals$name == n]
v0s  <- read_csv(file.path(dir_proc, "v0_scenarios.csv"), show_col_types = FALSE)
glob <- read_csv(file.path(dir_proc, "global_fits.csv"), show_col_types = FALSE)
sens <- read_csv(file.path(dir_proc, "sensitivity_analysis.csv"), show_col_types = FALSE)
PRIMARY <- "P: two-tier rule (primary)"
gc <- glob |> filter(model == "global competitive"); gk <- function(p) gc$estimate[gc$parameter == p]
I_mM <- V("I_mM")
Ki_range <- range(c(V("Ki_lb"), gk("Ki"), sens$Ki_competitive[sens$estimator == "O: two-tier rule, secant corrected for the t = 0 offset" & sens$method == "Lineweaver-Burk"]))
Ki_S <- sens$Ki_competitive[sens$estimator == "S: 0-2 min secant for every curve" & sens$method == "Lineweaver-Burk"]

box <- function(x, y, label, fill, col = "white", size = 3.1, face = "plain") {
  geom_label(aes(x = x, y = y, label = label), fill = fill, colour = col, size = size, family = FIG_FONT, fontface = face,
             label.padding = unit(0.45, "lines"), label.r = unit(0.35, "lines"), label.size = 0, lineheight = 0.95)
}
arrow_seg <- function(x0, x1, y0, y1, col = nebula[["grey"]]) annotate("segment", x = x0, xend = x1, y = y0, yend = y1, colour = col, linewidth = 0.8, arrow = arrow(length = unit(6, "pt"), type = "closed"))

scheme <- ggplot() +
  box(13, 90, "ONPG\n(colourless)", nebula[["mist"]], col = nebula[["ink"]], face = "bold") +
  arrow_seg(25, 47, 90, 90, col = nebula[["violet"]]) +
  annotate("text", x = 36, y = 96.5, label = "β-galactosidase", size = 2.9, family = FIG_FONT, colour = nebula[["violet"]], fontface = "bold") +
  annotate("text", x = 13, y = 80.5, label = "in Z buffer, pH 7.0", size = 2.4, family = FIG_FONT, colour = nebula[["grey"]]) +
  box(61, 90, "ONP (yellow)\n+ galactose", "#F5D33F", col = nebula[["ink"]], face = "bold") +
  annotate("segment", x = 36, xend = 36, y = 78, yend = 88, colour = COND_COLOURS[["mm_plus_iptg"]], linewidth = 0.9, linetype = "11") +
  box(28, 70, "IPTG, a substrate analogue,\nbinds the active site", COND_COLOURS[["mm_plus_iptg"]], size = 2.7, face = "bold") +
  annotate("segment", x = 61, xend = 61, y = 82, yend = 60, colour = nebula[["blue"]], linewidth = 0.8, arrow = arrow(length = unit(6, "pt"), type = "closed")) +
  box(56, 49, paste0("Aliquots stopped with Na₂CO₃\nat 2, 4, 6, 8, 10 min; A₄₁₅ read\nε = ", sprintf("%.2f", V("eps")), " mM⁻¹ cm⁻¹ → μmol ONP min⁻¹"), nebula[["blue"]], size = 2.6) +
  annotate("text", x = 3, y = 29, hjust = 0, vjust = 1, size = 2.9, family = FIG_FONT, colour = nebula[["ink"]], lineheight = 1.15,
           label = paste0(
             "V₀ approximately ∝ enzyme (R² = ", sprintf("%.2f", V("ed_r2")), ")\n",
             "Kₘ = ", sprintf("%.2f", V("lbU_Km")), " mM, Vₘₐₓ = ", sprintf("%.2f", V("lbU_Vmax")), " μmol min⁻¹\n",
             "+ ", sprintf("%.3f", I_mM), " mM IPTG: apparent Kₘ ×", sprintf("%.1f", V("lbI_Km") / V("lbU_Km")), "\n",
             "Kᵢ = ", sprintf("%.2f", Ki_range[1]), "–", sprintf("%.2f", Ki_range[2]), " mM across rule-based estimators\n",
             sprintf("(%.2f mM under the crudest; purified enzyme 0.08 mM)", Ki_S))) +
  annotate("text", x = 3, y = 32.5, hjust = 0, vjust = 0, size = 3.3, family = FIG_FONT, colour = nebula[["violet"]], fontface = "bold",
           label = "Kinetics consistent with competitive inhibition") +
  coord_cartesian(xlim = c(0, 80), ylim = c(0, 100), expand = FALSE, clip = "off") + theme_void()

pts <- v0s |> filter(data_role == "reference", estimator == PRIMARY) |> mutate(condition = factor(condition, levels = names(COND_LABELS)))
Sg <- tibble(S = seq(0.001, 2.3, length.out = 300))
cur <- bind_rows(Sg |> mutate(condition = "mm_no_inhibitor", V = gk("Vmax") * S / (gk("Km") + S)),
                 Sg |> mutate(condition = "mm_plus_iptg", V = gk("Vmax") * S / (gk("Km") * (1 + I_mM / gk("Ki")) + S))) |>
  mutate(condition = factor(condition, levels = names(COND_LABELS)))
mm <- ggplot() +
  geom_hline(yintercept = gk("Vmax"), colour = nebula[["grey"]], linetype = "dashed", linewidth = 0.4) +
  geom_line(data = cur, aes(S, V, colour = condition), linewidth = 1.1) +
  geom_point(data = pts, aes(onpg_mM, V0_umol_per_min_assay, colour = condition, shape = condition, fill = condition), size = 2.4, stroke = 0.5) +
  annotate("text", x = 2.25, y = gk("Vmax") + 0.025, label = "shared Vₘₐₓ (model assumption)", hjust = 1, size = 2.6, family = FIG_FONT, colour = nebula[["grey"]]) +
  annotate("text", x = 1.15, y = 0.49, label = "no inhibitor", hjust = 0, size = 2.9, family = FIG_FONT, colour = COND_COLOURS[["mm_no_inhibitor"]], fontface = "bold") +
  annotate("text", x = 2.25, y = 0.195, label = sprintf("+ %.3f mM IPTG", I_mM), hjust = 1, size = 2.9, family = FIG_FONT, colour = COND_COLOURS[["mm_plus_iptg"]], fontface = "bold") +
  annotate("text", x = 2.25, y = 0.145, label = sprintf("Kₘ %.2f → %.2f mM (apparent)", gk("Km"), gk("Km") * (1 + I_mM / gk("Ki"))), hjust = 1, size = 2.5, family = FIG_FONT, colour = COND_COLOURS[["mm_plus_iptg"]]) +
  scale_colour_manual(values = COND_COLOURS, guide = "none") + scale_fill_manual(values = COND_COLOURS, guide = "none") + scale_shape_manual(values = COND_SHAPES, guide = "none") +
  scale_x_continuous(limits = c(0, 2.3), breaks = c(0, 0.55, 1.1, 1.65, 2.2), expand = expansion(mult = c(0, 0.01))) +
  scale_y_continuous(limits = c(0, 0.6), breaks = seq(0, 0.6, 0.2), expand = expansion(mult = c(0, 0.02))) +
  labs(x = "ONPG concentration (mM)", y = expression(italic(V)[0]~"("*mu*mol~min^-1*")"), subtitle = "Reference dataset; global competitive fit") +
  theme(plot.title = element_blank(), panel.grid.major = element_blank(), plot.margin = margin(4, 8, 4, 4))

ga <- (scheme | mm) + plot_layout(widths = c(1.15, 1)) +
  plot_annotation(title = "Stopped-reaction spectrophotometry of β-galactosidase: substrate saturation\nand kinetic behaviour consistent with competitive inhibition by IPTG",
                  theme = theme(plot.title = element_text(family = FIG_FONT, face = "bold", size = 10.5, colour = nebula[["ink"]], hjust = 0.5, margin = margin(2, 0, 8, 0)),
                                plot.background = element_rect(fill = "white", colour = NA)))
save_figure(ga, "graphical_abstract", 7.2, 3.6)
message("09_graphical_abstract.R: figures/graphical_abstract.{png,pdf}")
