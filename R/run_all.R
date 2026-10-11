# run_all.R

scripts <- c("00_setup.R", "01_import_clean.R", "02_progress_curves.R", "03_standard_curve.R",
             "04_enzyme_dilution.R", "05_michaelis_menten.R", "06_inhibition.R",
             "07_generate_figures.R", "07b_supplementary_figures.R",
             "08_assemble_reports.R")
for (s in scripts) {
  message("\n==> ", s)
  source(here::here("R", s), echo = FALSE)
}

run_quiet <- function(cmd, args, wd) {
  old <- setwd(wd); on.exit(setwd(old))
  status <- system2(cmd, args, stdout = FALSE, stderr = FALSE)
  status == 0
}

report_dir <- here::here("report")
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

message("\nAll scripts completed. Outputs: data/processed/, tables/, figures/, report/experiment_2_submission.md")
