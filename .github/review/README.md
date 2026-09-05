# Pattern review

Reviewer that runs on every pull request (`.github/workflows/pattern-review.yml`). It only
looks at what the PR adds, and every finding cites the existing helper or convention it is
challenging. It comments; it never blocks.

## Layer 1: helper index

`build-index.js` walks `utils/`, `modules/`, `ui/`, `lib/`, `extras/`, `init.lua`,
`heartbeat.lua` and records every function (exported and local) with file, line, params
and doc summary. Built from the base branch on each run, so "already exists" always means
what was on `main`. `--rev <commit>` reads a git revision instead of the working tree.

## Layer 2: deterministic pass

`lint.js` diffs base..head, scans the added lines, and reports:

- `reuse/*` - a new function shares a name (or a known alias) with an existing helper,
  or re-implements an idiom the codebase routes through a helper.
- `pattern/*` - unguarded TLO string chains, `mq.delay` inside a render function,
  bare module-level locals.
- `style/*`, `naming/*` - the formatter config in `rgmercs.code-workspace`
  (4-space indent, 180 columns, trailing table separator), no `goto`, no em dashes in
  strings, camelCase locals.

Warnings appear as "Challenges" in the PR comment and as inline annotations; notices are
collapsed under "Style notes".

## Layer 3: model pass

When the repository has a `CLAUDE_CODE_OAUTH_TOKEN` secret (a Claude subscription token
from `claude setup-token`; `anthropic_api_key` works the same way), two
`anthropics/claude-code-action` runs follow the deterministic pass:

1. `prompts/reviewer.md` argues the case against the diff: for each change, find the
   helper or pattern in the base tree it should have used, with a `file:line` the model
   actually opened. Evidence or silence.
2. `prompts/refuter.md` takes those findings and tries to knock each one down. Findings
   it refutes are kept in the comment, collapsed, with the reason.

The model sees the base checkout plus `review/` (diff, PR-head copies of changed files,
the helper index, the deterministic report) and has only `Read`, `Grep`, `Glob`. It
never runs PR code and never posts; `render-review.js` turns its structured output into
the "Model review" section of the same sticky comment. `CONVENTIONS.md` is the rulebook
both prompts point at.

Model defaults to `claude-opus-5`; set a repository variable `PATTERN_REVIEW_MODEL` to
change it. The action itself declines to run for PR authors without write access, so
fork PRs from occasional contributors get the deterministic pass only unless a maintainer
runs the workflow on them by hand (Actions tab, Pattern Review, Run workflow, PR number).

## Pushes straight to main

`pattern-review-push.yml` runs the deterministic pass on every push to `main` that touches
Lua (other than `extras/version.lua`), leaves the report as a commit comment, and stages the
diff as an artifact. `pattern-review-push-model.yml` picks that up via `workflow_run`, runs
the two model passes, updates the comment, and can email the result. `#noreview` in the
commit message skips the whole thing.

Email is optional and needs an SMTP account: secrets `SMTP_HOST`, `SMTP_USERNAME`,
`SMTP_PASSWORD`, plus optional `SMTP_PORT` (default 587) and `SMTP_FROM`. Without
`SMTP_HOST` the send step skips. Nothing is sent for a clean push.

Who receives it is controlled by the repository variable `PATTERN_REVIEW_EMAIL`:

- set to a comma-separated list: every review goes to that list, and the pusher is CC'd
  when their commit address is a real mailbox and not already on the list;
- unset: only the pusher gets it, and only when their address is a real mailbox.
  `@users.noreply.github.com` addresses bounce and are never used.

## Running locally

```bash
node .github/review/build-index.js --out /tmp/index.json
node .github/review/lint.js --base main --head HEAD --index /tmp/index.json
```

Add `--strict` to exit non-zero on warnings, `--format github` for annotations,
`--out-md` / `--out-json` for the comment body and machine-readable report.

`replay.js` replays the deterministic pass over merged PRs in history, rebuilding the
index from each PR's own base, for tuning rules:

```bash
node .github/review/replay.js --since 2026-01-01 --out /tmp/replay.json
```
