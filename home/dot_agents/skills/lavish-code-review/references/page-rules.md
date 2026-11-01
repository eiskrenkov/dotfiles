# Page rules

For the author building the lavish-code-review page from the main agent's page spec. Follow `~/.agents/skills/lavish/references/authoring.md` for guidance, opening and revisions. This file adds the page layout.

Start from `lanes-template.html` in this folder: it holds the CSS, arrow markers, legend, lane, node, edge and badge patterns, plus the data, API and findings skeletons. Design source: the subject project's styling as named in the spec, for example `bootstrap.min.css` copied next to the HTML. Otherwise use the lavish CDN fallback.

The page spec gives the content. Your job is layout and rendering, not analysis. If the spec is missing something a rule needs, list it under `questions:` rather than inventing it.

Sections, in order:

1. **Header**:
   - PR link (or branch vs base), ticket link if found in the PR body or branch, author, +/−, file count, head sha;
   - one line saying what the change does;
   - the "not run" note.
2. **Service relations**: the Lanes diagram (rules below).
3. **Data & migrations**: the ER diagram (rules below). Include it whenever the change touches a data store: schema, migration, cache shape, Redis keys, Mongo collections. Omit it only when no store is touched.
4. **API changes**: the endpoint-card diagram (rules below). Include it whenever a request or response shape or meaning changes, for client, admin or internal APIs. Omit it only when no contract changes.
5. **Findings**: ranked `F1…Fn`, then a short "Checked, no issue" list.

No code diffs, no class-hierarchy sections, no tables that restate a diagram. All three diagrams share the legend, the four status colours, the badges and the mechanics below.

### Lanes diagram rules

- One inline SVG that stands on its own: the reader never needs a table.
- **Lanes** have a dashed outline and a small caps label:
  - top: the entry / online path (request handlers, controllers, per-request services);
  - middle: shared code both paths use (builders, factories, base services);
  - bottom: the background / offline path (batch jobs, workers, recalculations).
  - Omit a lane the change doesn't touch. Repositories and data stores go in the rightmost column.
- **Box = class or module.** The title is the namespaced name in bold mono. Inside, list only the members relevant to the change, prefixed `+` new, `~` changed or `−` deleted (no prefix means unchanged context). Add at most 2 short facts, such as read mode, memoization or lifetime ("1 per batch").
- **Exactly four status colours**, applied alike to boxes, arrows and member lines:

  | status | box fill / stroke | arrow / member text |
  |---|---|---|
  | unchanged | `#ffffff` / `#adb5bd` | `#6c757d` / default |
  | new | `#e8f5ee` / `#198754` | `#198754` / `#146c43` |
  | changed | `#fff8e1` / `#d39e00` | `#c99a00` / `#8a6d00` |
  | deleted | `#fdecec` / `#dc3545` | `#dc3545`, dashed / `#b02a37`, struck through |

  Add no other semantic colour. An unchanged class whose behaviour now changes stays white: the new relationship into it is a green arrow, and it carries a finding badge. A removed call is a red dashed arrow with a struck-through label.
- **Hover summaries**: every box with a change (green, yellow, red, or white with a `+ ~ −` line), in all three diagrams, carries `data-why="…"`. That's 1–3 short sentences on the purpose of the change: what it now does and why, not a list of the members already shown. Wrap identifiers in backticks. The template's tooltip script renders it, using the box's `<title>` as the heading.
- **Arrows** are labelled with the call: `find_user_payments(user_id)`, `build(storage: self)`, `values_for`. Keep labels to about 35 characters or less.
- **Finding badges** are a dark circle (`#212529`) with a white number. Place each on the box or edge the finding is about, using the same numbers as the Findings section.
- **Legend** above the diagram: 4 swatches, the `+ ~ −` key and a badge.
- **Mechanics**:
  - `viewBox` about 1160 wide with `width: 100%`, and `svg text { white-space: pre }`.
  - Titles in 12px mono, members in 11px mono, notes in 11px sans.
  - Size boxes from text width: mono is about 7.2px/char at 12px and 6.6px/char at 11px; sans is about 6px/char at 11px.
  - Route edges through free corridors and keep labels off lines and boxes.
- **Render-verify before opening** (when `agent-browser` is on PATH):
  - Take `agent-browser` screenshots of the page and of each diagram scrolled to the top of the viewport.
  - Fix every label, edge or box overlap and any text overflowing its box.

### Data & migrations diagram rules

One SVG, laid out as an ER diagram with a migrations column:

- **Store lane** (left, wide), e.g. `MYSQL · RELATIONS ARE APP-LEVEL, NO DB FOREIGN KEYS`. State whether relations are DB foreign keys or app-level.
  - **Box = table.** The title is the table name in bold mono. Members are columns as `name  type [PK|NN]` and indexes as `uniq (a, b)` / `idx (a)`, prefixed `+ ~ −`. Show only touched tables plus one hop of context (parents and children of the touched ones).
  - **Arrows** go from FK holder to referenced table, labelled `fk_column · N:1`. Prefer vertical edges, which leave room for labels.
  - An invariant the schema can't enforce (e.g. a cycle where two paths should agree) gets a short note in the free space plus the finding badge.
  - A table whose schema is unchanged but whose model rule changed stays white, with a `~` member line and a note such as "model check only, no index".
- **Migrations lane** (right, ~250 wide), titled `MIGRATIONS · IN ORDER`: one card per migration with the timestamp in bold, the class name, `+ ~ −` lines for what `up` does, `↓ down: …` (call out a `down` that can fail), and a one-line note on locking, backfill or data compatibility. Connect cards top to bottom with grey arrows. Add a short plain note on what happens to existing rows.
- **Other stores lane** (bottom strip): one box per other store the change touches or that sits on the changed path (cache/IdentityCache, Redis, Mongo, search). A box is white when untouched, with a line saying why it's safe, e.g. "key hashes the embedded schema → fresh keys on deploy".

### API changes diagram rules

One SVG of endpoint contract cards:

- **Lanes**: client/public API on top (label it with its doc, e.g. `CLIENT API · DOCS/SWAGGER/PUBLIC.YML`), then admin, internal or webhook APIs below. Omit an untouched lane.
- **Box = endpoint.** The title is `VERB /path` in bold mono. Under it, one sans line names other endpoints with the same shape ("also /occurrences, /init") and whether the card shows the request or the response. Members are the field tree, with nesting shown by indentation (`+   type     trigger key`), prefixed `+ ~ −`. Use `~` when the schema is unchanged but the meaning changed, and say so in a note.
- Status colours as everywhere: a new endpoint is green, a changed one yellow, an unchanged one with new behaviour white with green member lines.
- **Doc box**: when the generated docs (swagger/OpenAPI) disagree with the code, add a small box next to the cards quoting the doc value, with the finding badge.
- **Arrows** link cards only where one contract feeds another, e.g. admin save → client response ("saved config → objectives"), or response keys the client sends back.
- Put finding badges on the exact field line they concern.

### Findings format

Terse. The reader scans; nothing gets repeated.

- An `F<n>` badge (`text-bg-dark`) plus a severity badge: Decide (red), Perf (orange), Design / Edge (grey), Nit (light). The left border uses the same colour.
- A title of at most ~8 words that states the problem.
- One or two short sentences: what goes wrong and when. Cut any word that doesn't carry meaning. Don't restate the title or explain the mechanism at length.
- **Evidence**: 1–4 links.
- **Ask** or **Option**: one line, ideally under ~12 words.
- "Checked, no issue": one-liners of ~10 words, no links unless essential.
