#!/usr/bin/env node
'use strict';
// Turns a pattern-review report into the email sent to whoever pushed. Emits
// the subject line on stdout and writes an HTML body. When the report has
// nothing worth mailing about it prints nothing and exits 0, so the workflow
// can skip sending without treating a quiet push as a failure.
//   node .github/review/render-email.js --report review/report.md --json review/report.json \
//        --findings review/findings.json --verdicts review/verdicts.json \
//        --repo owner/name --sha <sha> --run-url <url> --out review/email.html

const fs = require('fs');

const args = parseArgs(process.argv.slice(2));
if (!args.report || !args.json) die('usage: render-email.js --report report.md --json report.json [--findings f.json] [--verdicts v.json] --repo owner/name --sha SHA [--run-url URL] [--out email.html] [--always]');

const lint = readJson(args.json);
const warnings = lint.findings.filter(f => f.severity === 'warning');
const notices = lint.findings.filter(f => f.severity === 'notice');

let modelStanding = [];
let modelRefuted = [];
let modelSummary = '';
if (args.findings && fs.existsSync(args.findings)) {
    const review = readJson(args.findings);
    modelSummary = typeof review.summary === 'string' ? review.summary : '';
    const verdicts = args.verdicts && fs.existsSync(args.verdicts) ? (readJson(args.verdicts).verdicts || []) : [];
    (review.findings || []).forEach((f, i) => {
        const v = verdicts.find(v => v.index === i);
        if (v && v.verdict === 'refuted') modelRefuted.push({ ...f, reason: v.reason });
        else modelStanding.push({ ...f, reason: v ? v.reason : null });
    });
}

const total = warnings.length + modelStanding.length;
if (total === 0 && !args.always) {
    process.stderr.write('clean push, nothing worth mailing\n');
    process.exit(0);
}

const shortSha = (args.sha || '').slice(0, 7);
const parts = [];
if (modelStanding.length) parts.push(`${modelStanding.length} model`);
if (warnings.length) parts.push(`${warnings.length} pattern`);
const subject = total
    ? `[rgmercs] ${parts.join(' + ')} finding${total === 1 ? '' : 's'} on ${shortSha}`
    : `[rgmercs] pattern review clean on ${shortSha}`;

const commitUrl = `https://github.com/${args.repo}/commit/${args.sha}`;
const h = [];
h.push(`<div style="font:14px -apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif;color:#1f2328;max-width:820px">`);
h.push(`<p style="margin:0 0 14px">Pattern review of <a href="${esc(commitUrl)}" style="color:#0969da">${esc(shortSha)}</a> pushed to <code>main</code> in ${esc(args.repo)}. Advisory only; nothing was blocked.</p>`);

if (modelSummary) h.push(`<p style="margin:0 0 14px;padding:10px 12px;background:#f6f8fa;border-left:3px solid #8250df">${esc(modelSummary)}</p>`);

if (modelStanding.length) {
    h.push(section(`Model review (${modelStanding.length})`));
    h.push(`<p style="margin:0 0 10px;color:#59636e">Each claim cites something in the pre-push tree that the model opened.</p>`);
    for (const f of modelStanding) h.push(card(f, args.repo, args.sha));
}
if (warnings.length) {
    h.push(section(`Pattern challenges (${warnings.length})`));
    h.push(table(['Where', 'Rule', 'Challenge'], warnings.map(f => [loc(f, args.repo, args.sha), code(f.rule), esc(f.message)])));
}
if (modelRefuted.length) {
    h.push(section(`Refuted by the second pass (${modelRefuted.length})`));
    h.push(table(['Where', 'Claim', 'Why dropped'], modelRefuted.map(f => [loc(f, args.repo, args.sha), esc(f.claim), esc(f.reason)])));
}
if (notices.length) {
    h.push(section(`Style notes (${notices.length})`));
    h.push(table(['Where', 'Rule', 'Note'], notices.slice(0, 25).map(f => [loc(f, args.repo, args.sha), code(f.rule), esc(f.message)])));
    if (notices.length > 25) h.push(`<p style="margin:6px 0 0;color:#59636e">${notices.length - 25} more in the run log.</p>`);
}
if (!total) h.push(`<p style="margin:0 0 14px">No challenges. Nothing in this push collides with an existing helper or a convention the codebase follows.</p>`);

h.push(`<p style="margin:18px 0 0;padding-top:12px;border-top:1px solid #d1d9e0;color:#59636e;font-size:12px">`);
h.push(`Full report on the <a href="${esc(commitUrl)}" style="color:#0969da">commit</a>`);
if (args['run-url']) h.push(` &middot; <a href="${esc(args['run-url'])}" style="color:#0969da">workflow run</a>`);
h.push(` &middot; rules in <code>.github/review/</code>. Reply to nobody; this is automated.`);
h.push(`</p></div>`);

const html = h.join('\n');
if (args.out) fs.writeFileSync(args.out, html + '\n');
process.stdout.write(subject + '\n');

function section(title) { return `<h3 style="margin:20px 0 8px;font-size:15px;border-bottom:1px solid #d1d9e0;padding-bottom:5px">${esc(title)}</h3>`; }

function card(f, repo, sha) {
    const bits = [`<div style="margin:0 0 12px;padding:11px 13px;border:1px solid #d1d9e0;border-radius:6px">`];
    bits.push(`<div style="margin-bottom:6px">${loc(f, repo, sha)}${f.confidence === 'medium' ? ' <span style="color:#9a6700;font-size:12px">(medium confidence)</span>' : ''}</div>`);
    bits.push(`<div style="margin-bottom:6px">${esc(f.claim)}</div>`);
    if (f.existing) bits.push(`<div style="color:#59636e;font-size:13px"><strong>Already exists:</strong> ${esc(f.existing)}</div>`);
    if (f.evidence) bits.push(`<details style="margin-top:6px"><summary style="cursor:pointer;color:#59636e;font-size:13px">Evidence</summary><div style="margin-top:6px;color:#59636e;font-size:13px">${esc(f.evidence)}</div></details>`);
    bits.push(`</div>`);
    return bits.join('');
}

function table(headers, rows) {
    const th = headers.map(x => `<th align="left" style="padding:6px 9px;border-bottom:1px solid #d1d9e0;font-size:13px">${esc(x)}</th>`).join('');
    const tr = rows.map(r => `<tr>${r.map(c => `<td style="padding:6px 9px;border-bottom:1px solid #eaeef2;font-size:13px;vertical-align:top">${c}</td>`).join('')}</tr>`).join('\n');
    return `<table cellspacing="0" cellpadding="0" style="border-collapse:collapse;width:100%;margin:0 0 8px">\n<tr>${th}</tr>\n${tr}\n</table>`;
}

function loc(f, repo, sha) {
    const label = `${f.file}:${f.line}`;
    if (!repo || !sha) return code(label);
    return `<a href="https://github.com/${esc(repo)}/blob/${esc(sha)}/${esc(f.file)}#L${f.line}" style="color:#0969da;font-family:ui-monospace,SFMono-Regular,Menlo,monospace;font-size:12px">${esc(label)}</a>`;
}

function code(s) { return `<code style="font-family:ui-monospace,SFMono-Regular,Menlo,monospace;font-size:12px;background:#f6f8fa;padding:1px 4px;border-radius:3px">${esc(s)}</code>`; }
function esc(s) { return String(s == null ? '' : s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;'); }
function readJson(p) { return JSON.parse(fs.readFileSync(p, 'utf8')); }
function die(msg) { process.stderr.write(msg + '\n'); process.exit(2); }
function parseArgs(argv) {
    const out = {};
    for (let i = 0; i < argv.length; i++) {
        const a = argv[i];
        if (!a.startsWith('--')) continue;
        const key = a.slice(2);
        const next = argv[i + 1];
        if (next === undefined || next.startsWith('--')) out[key] = true;
        else { out[key] = next; i++; }
    }
    return out;
}
