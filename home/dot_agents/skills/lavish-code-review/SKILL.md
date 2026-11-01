---
name: lavish-code-review
description: Visual code review rendered in Lavish - a "lanes" service-relations diagram, a data & migrations ER diagram, and an API-changes endpoint-card diagram, all in one 4-colour change scheme, plus terse ranked findings with line-level evidence. Use when the user asks to review a PR (link or number) or their local changes and wants it visual, or invokes /lavish-code-review.
argument-hint: <PR url | PR number | empty for local changes>
---

# Lavish code review

Review a change, then show it as one Lavish page: **header → Service relations → Data & migrations → API changes → Findings**. Nothing else: no code diffs.

## 1. Scope the change

Never `git checkout`/`switch` to the reviewed code and never create a worktree. The user's working tree stays untouched. Don't run specs or install dependencies. Say so in the page header: "Not run; from code reading at `<sha>`."

### A PR link or number was given

```bash
gh pr view <n> --json title,body,author,baseRefName,headRefName,headRefOid,additions,deletions,files,commits
gh pr diff <n>
git fetch origin <headRefName> <baseRefName>
```

Read only through the fetched ref:

- `git show FETCH_HEAD:<path>` (or `<headRefOid>:<path>`)
- `git grep -n '<pattern>' <headRefOid> -- <paths>`
- `git diff origin/<base>...<headRefOid>`

Evidence links: `https://github.com/<owner>/<repo>/blob/<headRefOid>/<path>#L<a>-L<b>`.

### No PR given ("review my changes")

Review the local changes against the default branch.

```bash
base=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's@^origin/@@')  # fallback: main, then master
git fetch origin "$base"
mb=$(git merge-base "origin/$base" HEAD)
git diff "$mb"                                # committed on the branch + staged + unstaged
git ls-files --others --exclude-standard      # untracked: read each in full
```

Read changed files from the working tree. Use the old side for comparison: `git show "$mb:<path>"`. Evidence is given as `path:line`.

## 2. Analyse

- Read every changed file and its direct collaborators: callers, callees, base classes, and anything that receives a new argument. You need enough to state how the change plugs into existing flows.
- Hunt for:
  - behaviour changes outside the stated scope (e.g. a new collaborator now reaching existing code paths);
  - per-request or per-record cost (N+1, unbounded reads, missing projection);
  - shared mutable state and ordering contracts;
  - guard edge cases (nil, missing config, data created before the feature existed);
  - consistency nits.
- Map every data store the change touches: tables and their relations, each migration's `up` and `down`, backfill or the lack of one, cache blob shape (e.g. IdentityCache embeds and key versioning), Redis keys, Mongo collections.
- Map every API contract the change touches: request and response fields per endpoint, including other endpoints that share a changed presenter, plus generated docs (swagger/OpenAPI) that should match the code.
- Every claim cites `path:line` at the reviewed sha. Re-check line numbers before writing them. Label unverified reasoning as a question.

## 3. Brief the author

Load the `lavish` skill first: it covers delegating to the `lavish-author` subagent, the poll loop and feedback rounds. You don't build the page: you send the author a page spec. The author's layout rules are in `references/page-rules.md`; don't read them or the template yourself.

The brief:

- **Path**: `.lavish/<pr-N | branch>-review.html` in the repo (`.lavish` is globally gitignored).
- **Kind**: code review page. Tell the author to read `~/.agents/skills/lavish-code-review/references/page-rules.md` and to start from `lanes-template.html` in the same folder.
- **Design source**: the subject project's styling, for example "copy `node_modules/bootstrap/dist/css/bootstrap.min.css` next to the HTML" when the project uses Bootstrap. Otherwise "none - use lavish design".
- **Page spec**: compact text, in the order below. Every item carries a status: `new`, `changed`, `deleted` or `unchanged`.

1. **Header**:
   - PR link (or branch vs base), ticket link if found in the PR body or branch, author, +/−, file count, head sha;
   - one line saying what the change does;
   - "Not run; from code reading at `<sha>`."
2. **Service relations** (lanes):
   - Lanes the change touches: entry / online, shared, background / offline. Data stores go in the rightmost column.
   - Boxes: the namespaced class or module, its status, only the members relevant to the change prefixed `+ ~ −`, and at most 2 short facts. Every box with a change also gets `why:`, 1–3 short sentences on what it now does and why.
   - Edges: `From -> To "call label" status`, with labels of about 35 characters or less.
   - An unchanged class whose behaviour now changes stays `unchanged`: give it a `new` edge into it and a finding badge.
3. **Data & migrations**, only when a data store is touched:
   - the store, and whether relations are DB foreign keys or app-level;
   - touched tables plus one hop, with columns `name type [PK|NN]` and indexes, prefixed `+ ~ −`;
   - FKs as `holder.fk_column -> table N:1`, and invariants the schema can't enforce;
   - migrations in order: timestamp, class, what `up` does, `down` and whether it can fail, a note on locking, backfill or compatibility, and what happens to existing rows;
   - other stores on the path (cache, Redis, Mongo, search), each with a line saying why it's safe.
4. **API changes**, only when a request or response shape or meaning changes:
   - grouped by API kind: client / public with its doc file, then admin, internal, webhook;
   - cards: `VERB /path`, status, other endpoints with the same shape, request or response, and the field tree prefixed `+ ~ −`. Use `~` for a meaning change and say so;
   - any doc (swagger/OpenAPI) value that disagrees with the code;
   - links only where one contract feeds another.
5. **Findings**: `F1…Fn`, fully written in the format below, each with `badge:` naming the box, edge or field line it sits on. Then the "Checked, no issue" lines.

No code diffs, no class-hierarchy sections, no tables that restate a diagram.

### Findings format

Terse. The reader scans; nothing gets repeated.

- A severity: Decide, Perf, Design / Edge, or Nit.
- A title of at most ~8 words that states the problem.
- One or two short sentences: what goes wrong and when. Cut any word that doesn't carry meaning. Don't restate the title or explain the mechanism at length.
- **Evidence**: 1–4 links.
- **Ask** or **Option**: one line, ideally under ~12 words.
- "Checked, no issue": one-liners of ~10 words, no links unless essential.

## 4. Writing

Only meaningful information. No intro, no restating the PR body file by file, no praise, no filler. Use short sentences and put identifiers in `code`. When in doubt, cut. Shorter wins.

## 5. Deliver

The author opens the page through the `lavish` skill flow, in Muxify's Browser, and returns the URL. Wait for feedback with a tracked background poll and route each round as the `lavish` skill's Feedback rounds describe. In the terminal, give the link plus one line per finding.
