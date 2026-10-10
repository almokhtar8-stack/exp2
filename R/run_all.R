# run_all.R
# Reproduce the complete analysis from the raw data. From the project root:
#   Rscript R/run_all.R
# Each numbered script can also be run on its own, in order. Paths are resolved
# with here::here() from the project root (marked by the .here file).
#
# Steps
#   1. R analysis, figures and report assembly (requires R >= 4.3 and the
#      packages listed in R/00_setup.R).
#   2. Optional typesetting, run only when the tool is on the PATH:
#        xelatex       journal-style manuscript (report/cell_style/) and the
#                      figure booklet (report/experiment_2_figures.tex)
#        node          course-submission .docx (report/build_submission_docx.js;
#                      needs the docx package: `npm install docx` in report/)
#        soffice       PDF of the course submission (LibreOffice, headless)
#      Missing tools are reported, not treated as errors: the Markdown reports,
#      tables and figures are complete after step 1.

scripts <- c("00_setup.R", "01_import_clean.R", "02_progress_curves.R", "03_standard_curve.R",
             "04_enzyme_dilution.R", "05_michaelis_menten.R", "06_inhibition.R",
             "07_generate_figures.R", "07b_supplementary_figures.R", "09_graphical_abstract.R",
             "08_assemble_reports.R")
for (s in scripts) {
  message("\n==> ", s)
  source(here::here("R", s), echo = FALSE)
}
writeLines(capture.output(sessionInfo()), here::here("report", "sessionInfo.txt"))

run_quiet <- function(cmd, args, wd) {
  old <- setwd(wd); on.exit(setwd(old))
  status <- system2(cmd, args, stdout = FALSE, stderr = FALSE)
  status == 0
}

report_dir <- here::here("report")
if (nzchar(Sys.which("xelatex"))) {
  ok1 <- all(vapply(1:2, function(k) run_quiet("xelatex", c("-interaction=nonstopmode", "experiment_2_cell_style.tex"),
                                               file.path(report_dir, "cell_style")), logical(1)))
  ok2 <- all(vapply(1:2, function(k) run_quiet("xelatex", c("-interaction=nonstopmode", "experiment_2_figures.tex"),
                                               report_dir), logical(1)))
  message(if (ok1) "Journal-style PDF: report/cell_style/experiment_2_cell_style.pdf" else "xelatex failed on the journal-style manuscript (see report/cell_style/experiment_2_cell_style.log)")
  message(if (ok2) "Figure booklet: report/experiment_2_figures.pdf" else "xelatex failed on the figure booklet (see report/experiment_2_figures.log)")
} else {
  message("xelatex not found: the journal-style manuscript and figure booklet were not typeset (the .tex files are ready to compile)")
}

if (nzchar(Sys.which("node"))) {
  ok <- run_quiet("node", "build_submission_docx.js", report_dir)
  message(if (ok) "Course submission: report/experiment_2_submission.docx" else "node failed to build the .docx (run `npm install docx` in report/ and retry)")
  if (ok && nzchar(Sys.which("soffice"))) {
    # R prepends its own library path to LD_LIBRARY_PATH, which can stop LibreOffice
    # from loading its libraries; run soffice without it.
    ok_pdf <- if (.Platform$OS.type == "unix") {
      run_quiet("env", c("-u", "LD_LIBRARY_PATH", "soffice", "--headless", "--convert-to", "pdf", "experiment_2_submission.docx"), report_dir)
    } else run_quiet("soffice", c("--headless", "--convert-to", "pdf", "experiment_2_submission.docx"), report_dir)
    message(if (ok_pdf) "Course submission PDF: report/experiment_2_submission.pdf" else "LibreOffice failed to convert the .docx to PDF")
  }
} else {
  message("node not found: the course-submission .docx was not rebuilt (report/experiment_2_submission.md is complete)")
}

if (nzchar(Sys.which("python3")) && nzchar(Sys.which("pandoc"))) {
  ok_supp <- run_quiet("python3", "build_supplementary_pdf.py", report_dir)
  message(if (ok_supp) "Supplementary PDF: report/experiment_2_supplementary.pdf" else "Supplementary PDF not rendered (needs pandoc and Python Playwright with Chromium); report/experiment_2_report_full.md is complete")
}

message("\nAll scripts completed. Outputs: data/processed/, tables/, figures/, report/experiment_2_submission.md, report/experiment_2_report_full.md")
