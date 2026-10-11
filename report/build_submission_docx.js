// build_submission_docx.js
// Builds report/experiment_2_submission.docx from report/experiment_2_submission.md
// in the B241 format: Times New Roman 12 pt, 1.5 line spacing, 1-inch margins,
// tables titled above, figures captioned below, cover page with Summary,
// raw-data printouts appended at the end.
//   node report/build_submission_docx.js
const fs = require("fs");
const path = require("path");
const {
  Document, Packer, Paragraph, TextRun, ImageRun, Table, TableRow, TableCell, WidthType,
  AlignmentType, PageBreak, ShadingType, BorderStyle, HeadingLevel, LevelFormat, LineRuleType, ExternalHyperlink
} = require("docx");

const root = path.join(__dirname, "..");
const md = fs.readFileSync(path.join(__dirname, "experiment_2_submission.md"), "utf8").split("\n");
const FONT = "Times New Roman", SIZE = 24 /* half-points: 12 pt */, TABLE_SIZE = 18 /* 9 pt */, LINE = 360 /* 1.5 spacing */;
const PAGE_W = 12240, PAGE_H = 15840, MARGIN = 1440, TEXT_W = PAGE_W - 2 * MARGIN; // US Letter, 1 inch margins

// ---------- inline formatting ----------
const SUB = { "₀": "0", "₁": "1", "₂": "2", "₃": "3", "₄": "4", "₅": "5", "₆": "6", "₇": "7", "₈": "8", "₉": "9", "ₘ": "m", "ₐ": "a", "ₓ": "x", "ᵢ": "i" };
const SUP = { "⁰": "0", "¹": "1", "²": "2", "³": "3", "⁴": "4", "⁵": "5", "⁶": "6", "⁷": "7", "⁸": "8", "⁹": "9", "⁻": "−" };
const SUBPAT = [
  [/K_m,app/g, "K", "m,app"], [/V_max,app/g, "V", "max,app"], [/K_m/g, "K", "m"], [/V_max/g, "V", "max"],
  [/K_i'/g, "K", "i'"], [/K_i/g, "K", "i"], [/k_cat/g, "k", "cat"], [/\[E\]_T/g, "[E]", "T"], [/λ_max/g, "λ", "max"]
];
function baseRuns(text, style) {
  // split into runs handling Unicode sub/superscripts and the X_y patterns
  const out = [];
  // first, protect X_y patterns by converting into markers
  let s = text;
  const marks = [];
  for (const [re, base, sub] of SUBPAT) s = s.replace(re, () => { marks.push([base, sub]); return `\u0001${marks.length - 1}\u0002`; });
  let buf = "", mode = "n";
  const flush = () => { if (buf) { out.push(new TextRun({ text: buf, font: FONT, size: style.size || SIZE, bold: style.bold, italics: style.italics,
      subScript: mode === "sub" || undefined, superScript: mode === "sup" || undefined })); buf = ""; } };
  for (let i = 0; i < s.length; i++) {
    const ch = s[i];
    if (ch === "\u0001") { const j = s.indexOf("\u0002", i); const [b, sub] = marks[parseInt(s.slice(i + 1, j))];
      flush(); mode = "n"; buf = b; flush(); mode = "sub"; buf = sub; flush(); mode = "n"; i = j; continue; }
    const m = SUB[ch] ? "sub" : SUP[ch] ? "sup" : "n";
    if (m !== mode) { flush(); mode = m; }
    buf += m === "sub" ? SUB[ch] : m === "sup" ? SUP[ch] : ch;
  }
  flush();
  return out;
}
function inlineRuns(text, base = {}) {
  // **bold**, *italic*, `code` (rendered plain); http(s) URLs become clickable hyperlinks
  const runs = [];
  const re = /(\*\*[^*]+\*\*|\*[^*]+\*|`[^`]+`|https?:\/\/[^\s)\]>]+)/g;
  let last = 0, m;
  while ((m = re.exec(text)) !== null) {
    if (m.index > last) runs.push(...baseRuns(text.slice(last, m.index), base));
    let tok = m[0];
    if (tok.startsWith("**")) runs.push(...baseRuns(tok.slice(2, -2), { ...base, bold: true }));
    else if (tok.startsWith("*")) runs.push(...baseRuns(tok.slice(1, -1), { ...base, italics: true }));
    else if (tok.startsWith("`")) runs.push(...baseRuns(tok.slice(1, -1), base));
    else {
      let trail = ""; while (/[.,;:]$/.test(tok)) { trail = tok.slice(-1) + trail; tok = tok.slice(0, -1); }  // sentence punctuation stays outside the link
      runs.push(new ExternalHyperlink({ link: tok, children: [new TextRun({ text: tok, font: FONT, size: base.size || SIZE, bold: base.bold, italics: base.italics, style: "Hyperlink" })] }));
      if (trail) runs.push(...baseRuns(trail, base));
    }
    last = m.index + tok.length + (m[0].length - tok.length);
  }
  if (last < text.length) runs.push(...baseRuns(text.slice(last), base));
  return runs;
}
const para = (text, opts = {}) => new Paragraph({ children: inlineRuns(text, opts.run || {}), alignment: opts.align || AlignmentType.JUSTIFIED,
  spacing: { line: opts.line || LINE, after: opts.after ?? 120, before: opts.before ?? 0 }, pageBreakBefore: opts.pageBreakBefore || false, keepNext: opts.keepNext, keepLines: opts.keepLines });

// ---------- images ----------
function imagePara(relPath, widthIn, align = AlignmentType.CENTER) {
  const p = path.join(__dirname, relPath.replace(/^\.\.\//, "../"));
  const buf = fs.readFileSync(p);
  const ext = p.toLowerCase().endsWith(".png") ? "png" : "jpg";
  // dimensions
  let w, h;
  if (ext === "png") { w = buf.readUInt32BE(16); h = buf.readUInt32BE(20); }
  else { // jpeg SOF
    let i = 2; while (i < buf.length) { if (buf[i] !== 0xFF) { i++; continue; } const marker = buf[i + 1]; const len = buf.readUInt16BE(i + 2);
      if (marker >= 0xC0 && marker <= 0xC3) { h = buf.readUInt16BE(i + 5); w = buf.readUInt16BE(i + 7); break; } i += 2 + len; } }
  const wPx = Math.round(widthIn * 96), hPx = Math.round(wPx * h / w);
  return new Paragraph({ children: [new ImageRun({ type: ext, data: buf, transformation: { width: wPx, height: hPx } })], alignment: align, spacing: { after: 60, line: 240, lineRule: LineRuleType.AUTO }, keepNext: true });
}

// ---------- tables ----------
function mdTable(lines) {
  const rows = lines.map(l => l.replace(/^\|/, "").replace(/\|$/, "").split("|").map(c => c.trim()));
  const header = rows[0], body = rows.slice(2);
  const ncol = header.length;
  // width need: longest body cell, or longest single word of the header (headers may wrap), with a floor of 7 characters
  const need = header.map((h, j) => Math.max(7, Math.max(...h.split(/\s+/).map(w => w.length)) + 2, ...body.map(r => Math.min((r[j] || "").length, 34))));
  const total = need.reduce((a, b) => a + b, 0);
  const widths = need.map(l => Math.round(TEXT_W * l / total));
  widths[ncol - 1] += TEXT_W - widths.reduce((a, b) => a + b, 0);
  const tsize = ncol > 8 ? 16 : TABLE_SIZE;   // 8 pt for wide tables, 9 pt otherwise
  const show = t => (t === "NA" ? "\u2013" : t);
  const keepTogether = body.length <= 8;   // small tables stay on one page; long ones may split (header repeats)
  const cell = (txt, j, isHead, keepNext) => new TableCell({
    width: { size: widths[j], type: WidthType.DXA },
    shading: isHead ? { type: ShadingType.CLEAR, fill: "F4F1FA", color: "auto" } : undefined,
    margins: { top: 15, bottom: 15, left: 60, right: 60 },
    children: [new Paragraph({ children: inlineRuns(show(txt), { size: tsize, bold: isHead }), alignment: AlignmentType.LEFT, spacing: { line: 240, after: 0 }, keepNext })]
  });
  const headerEmpty = header.every(h => h.trim() === "");
  const rowsOut = headerEmpty ? [] : [new TableRow({ tableHeader: true, cantSplit: true, children: header.map((h, j) => cell(h, j, true, keepTogether)) })];
  body.forEach((r, k) => rowsOut.push(new TableRow({ cantSplit: true, children: header.map((_, j) => cell(r[j] || "", j, j === 0 && headerEmpty, keepTogether && k < body.length - 1)) })));
  return new Table({ width: { size: TEXT_W, type: WidthType.DXA }, columnWidths: widths, rows: rowsOut });
}

// ---------- parse markdown ----------
const children = [];
let i = 0, inCover = true, imageRow = [];
const flushImages = () => {
  if (!imageRow.length) return;
  // printout photographs: rows of three, 2.05 in wide each
  for (let k = 0; k < imageRow.length; k += 3) {
    const grp = imageRow.slice(k, k + 3);
    const cells = grp.map(rp => new TableCell({ width: { size: Math.floor(TEXT_W / 3), type: WidthType.DXA }, borders: noBorders,
      children: [imagePara(rp, 2.05)] }));
    while (cells.length < 3) cells.push(new TableCell({ width: { size: Math.floor(TEXT_W / 3), type: WidthType.DXA }, borders: noBorders, children: [new Paragraph("")] }));
    children.push(new Table({ width: { size: TEXT_W, type: WidthType.DXA }, columnWidths: [Math.floor(TEXT_W / 3), Math.floor(TEXT_W / 3), TEXT_W - 2 * Math.floor(TEXT_W / 3)], rows: [new TableRow({ children: cells })], borders: noBorders }));
    children.push(new Paragraph({ spacing: { after: 60 } }));
  }
  imageRow = [];
};
const noBorders = { top: { style: BorderStyle.NONE, size: 0, color: "FFFFFF" }, bottom: { style: BorderStyle.NONE, size: 0, color: "FFFFFF" },
  left: { style: BorderStyle.NONE, size: 0, color: "FFFFFF" }, right: { style: BorderStyle.NONE, size: 0, color: "FFFFFF" },
  insideHorizontal: { style: BorderStyle.NONE, size: 0, color: "FFFFFF" }, insideVertical: { style: BorderStyle.NONE, size: 0, color: "FFFFFF" } };

while (i < md.length) {
  const line = md[i];
  if (line.startsWith("|")) { flushImages(); const tl = []; while (i < md.length && md[i].startsWith("|")) tl.push(md[i++]); children.push(mdTable(tl));
    // spacer after the table, unless a page-breaking heading follows (a spacer alone would make a blank page)
    let nxt = i; while (nxt < md.length && md[nxt].trim() === "") nxt++;
    if (!(nxt < md.length && md[nxt].startsWith("## "))) children.push(new Paragraph({ children: [new TextRun({ text: "", size: 4 })], spacing: { before: 0, after: 80, line: 40, lineRule: LineRuleType.EXACT } }));
    continue; }
  if (line.startsWith("# ")) { children.push(new Paragraph({ children: inlineRuns(line.slice(2), { bold: true, size: 28 }), alignment: AlignmentType.CENTER, spacing: { line: LINE, after: 240, before: 1200 } })); i++; continue; }
  if (line.startsWith("## ")) {
    flushImages();
    const title = line.slice(3);
    const breakBefore = ["Objectives", "Results", "Discussion", "Data and Code Availability", "Raw Data"].includes(title) || (inCover && title !== "Summary");
    if (title === "Objectives") inCover = false;
    children.push(new Paragraph({ children: inlineRuns(title, { bold: true }), heading: HeadingLevel.HEADING_1, alignment: AlignmentType.LEFT,
      spacing: { line: LINE, before: 240, after: 120 }, pageBreakBefore: breakBefore, keepNext: true }));
    i++; continue;
  }
  if (line.startsWith("### ")) { flushImages(); children.push(new Paragraph({ children: inlineRuns(line.slice(4), { bold: true, italics: true }), heading: HeadingLevel.HEADING_2, alignment: AlignmentType.LEFT, spacing: { line: LINE, before: 120, after: 60 }, keepNext: true })); i++; continue; }
  if (/^!\[/.test(line)) {
    const imgs = [...line.matchAll(/!\[[^\]]*\]\(([^)]+)\)/g)].map(m => m[1]);
    if (imgs.length === 1 && imgs[0].includes("figureQ1")) { flushImages(); children.push(imagePara(imgs[0], 4.6)); }
    else if (imgs.length === 1 && imgs[0].includes("figures/")) { flushImages(); children.push(imagePara(imgs[0], 6.5)); }  // main figures are drawn at 6.5 in, the full text width
    else imageRow.push(...imgs);
    i++; continue;
  }
  if (line.trim() === "") { i++; continue; }
  if (/^\d+\. /.test(line) && children.length) { // reference list entries: hanging indent
    flushImages();
    children.push(new Paragraph({ children: inlineRuns(line), alignment: AlignmentType.LEFT, spacing: { line: LINE, after: 60 }, indent: { left: 360, hanging: 360 } })); i++; continue;
  }
  flushImages();
  const isCaption = /^\*\*(Figure|Table) /.test(line);
  const isCoverMeta = inCover && !line.startsWith("**") && !/^Enzyme kinetics/.test(line);
  children.push(para(line, { align: isCoverMeta ? AlignmentType.CENTER : (isCaption ? AlignmentType.LEFT : AlignmentType.JUSTIFIED), after: isCaption ? 60 : 100,
    run: isCaption ? { size: 20 } : {}, line: isCaption ? 276 : LINE, keepNext: /^\*\*Table /.test(line) || /^Day [12] \(/.test(line), keepLines: isCaption }));
  i++;
}
flushImages();

const doc = new Document({
  creator: "Almokhtar Aljarodi", lastModifiedBy: "Almokhtar Aljarodi", title: "Experiment 2: beta-galactosidase kinetics",
  styles: { default: { document: { run: { font: FONT, size: SIZE } } },
    paragraphStyles: [
      { id: "Heading1", name: "Heading 1", basedOn: "Normal", next: "Normal", quickFormat: true, run: { font: FONT, size: SIZE, bold: true, color: "000000" }, paragraph: { spacing: { before: 240, after: 120, line: LINE }, outlineLevel: 0 } },
      { id: "Heading2", name: "Heading 2", basedOn: "Normal", next: "Normal", quickFormat: true, run: { font: FONT, size: SIZE, bold: true, italics: true, color: "000000" }, paragraph: { spacing: { before: 120, after: 60, line: LINE }, outlineLevel: 1 } }
    ],
    characterStyles: [{ id: "Hyperlink", name: "Hyperlink", basedOn: "DefaultParagraphFont", run: { color: "0563C1", underline: { type: "single" } } }] },
  sections: [{ properties: { page: { size: { width: PAGE_W, height: PAGE_H }, margin: { top: MARGIN, bottom: MARGIN, left: MARGIN, right: MARGIN } } }, children }]
});
Packer.toBuffer(doc).then(buf => { const out = path.join(__dirname, "experiment_2_submission.docx"); fs.writeFileSync(out, buf); console.log("wrote", out, Math.round(buf.length / 1024), "kB"); });
