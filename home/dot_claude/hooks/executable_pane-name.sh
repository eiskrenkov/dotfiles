#!/usr/bin/env bash
# Claude Code UserPromptSubmit hook — name the tmux pane (and the session) from
# the first prompt.
#
# Fires the moment a prompt is submitted, before the model replies. On the first
# prompt of a session it asks haiku for a short title, then:
#   - sets the pane's @pane_label to "<base> | <title>" (<base> is whatever
#     launched claude, usually "claude"), rendered as a chip on the pane's top
#     border (see tmux.conf.local); and
#   - appends a custom-title record to the session transcript — the same format
#     `/rename` uses — so `claude --resume` shows the same <title>.
#
# One-shot per session via a marker file. Runs the (slow) generation detached so
# the prompt never waits, and guards against the title-generating `claude -p`
# re-triggering this hook (CLAUDE_PANE_NAMER). Always exits 0 with no stdout — a
# UserPromptSubmit hook's stdout is injected into the prompt, and a naming hiccup
# must never disrupt the session.
#
# Debugging: `touch ~/.claude/pane-name.log` to enable a trace of every run
# (which branch it took and why); `rm` it to disable.

LOG="$HOME/.claude/pane-name.log"
log() { [ -f "$LOG" ] && printf '%s %s\n' "$(date '+%F %T')" "$*" >>"$LOG" 2>/dev/null; return 0; }

# ── Worker mode: generate the title and apply it (runs detached) ──────────────
if [ "${1:-}" = "--worker" ]; then
  pane="$2"
  session="$3"
  transcript="$4"
  ctx="$5"

  prompt="Generate a concise 2-5 word, lowercase, kebab-case title (max 40 chars)
describing this coding session, based on the request below. Reply with ONLY the
title, nothing else.

Request: $ctx"

  # CLAUDE_PANE_NAMER guards the inner claude's own hook against recursion;
  # unsetting TMUX_PANE keeps its pop/status hooks from touching the live pane.
  raw=$(env -u TMUX_PANE CLAUDE_PANE_NAMER=1 claude -p --model haiku "$prompt" 2>/dev/null | head -n 1)
  name=$(printf '%s' "$raw" \
    | tr '[:upper:]' '[:lower:]' \
    | tr -cs 'a-z0-9' '-' \
    | sed 's/^-*//; s/-*$//' \
    | cut -c1-40)
  if [ -z "$name" ]; then
    log "worker: generation produced no title (pane=$pane)"
    exit 0
  fi

  # 1) Pane label chip: "<base> | <title>".
  base=$(tmux show-options -p -t "$pane" -v @pane_label 2>/dev/null)
  base="${base%% | *}"
  [ -n "$base" ] || base="claude"
  tmux set-option -p -t "$pane" @pane_label "$base | $name" 2>/dev/null
  tmux refresh-client -S 2>/dev/null
  log "worker: set pane=$pane label='$base | $name'"

  # 2) Session title for `claude --resume` — same record as /rename. Skip if the
  #    session already has a title (e.g. a manual /rename) so we never clobber it.
  if [ -n "$transcript" ] && [ -f "$transcript" ]; then
    if tail -c 65536 "$transcript" 2>/dev/null | grep -q '"custom-title"'; then
      log "worker: session already titled, left transcript untouched"
    elif jq -cn --arg t "$name" --arg s "$session" \
        '{type:"custom-title",customTitle:$t,sessionId:$s}' >>"$transcript" 2>/dev/null; then
      log "worker: wrote custom-title '$name' to $transcript"
    else
      log "worker: failed writing custom-title to $transcript"
    fi
  fi

  exit 0
fi

# ── Hook mode: decide whether to name, then spawn the worker ──────────────────
input=$(cat 2>/dev/null) || exit 0

if [ -z "${TMUX_PANE:-}" ]; then log "skip: not in tmux"; exit 0; fi
if [ -n "${CLAUDE_PANE_NAMER:-}" ]; then log "skip: own title-generating run"; exit 0; fi
if ! command -v jq >/dev/null 2>&1; then log "skip: jq not on PATH"; exit 0; fi
if ! command -v claude >/dev/null 2>&1; then log "skip: claude not on PATH"; exit 0; fi

session_id=$(printf '%s' "$input" | jq -r '.session_id // .sessionId // empty' 2>/dev/null)
if [ -z "$session_id" ]; then log "skip: no session_id in payload"; exit 0; fi

marker_dir="$HOME/.claude/.pane-named"
marker="$marker_dir/$session_id"
if [ -e "$marker" ]; then log "skip: already named ($session_id)"; exit 0; fi

transcript=$(printf '%s' "$input" | jq -r '.transcript_path // .transcriptPath // empty' 2>/dev/null)

# The submitted prompt is in the payload; fall back to the transcript's first
# user message if it is ever absent.
context=$(printf '%s' "$input" | jq -r '.prompt // empty' 2>/dev/null)
if [ -z "$context" ] && [ -n "$transcript" ] && [ -f "$transcript" ]; then
  context=$(head -n 200 "$transcript" 2>/dev/null | jq -rs '
    [ .[]
      | select(.type == "user")
      | .message.content
      | if type == "array"
        then ([ .[]? | select(.type == "text") | .text ] | join(" "))
        else (. // "") end
    ]
    | map(select(test("\\S")))
    | .[0] // ""
  ' 2>/dev/null)
fi

# Nothing usable yet → leave it for the next prompt (no marker written).
if [ -z "$context" ]; then log "skip: empty prompt/context ($session_id)"; exit 0; fi
context="${context:0:2000}"

mkdir -p "$marker_dir" 2>/dev/null
: >"$marker" 2>/dev/null

log "spawn worker: session=$session_id pane=$TMUX_PANE ctx='${context:0:60}'"
nohup "$0" --worker "$TMUX_PANE" "$session_id" "$transcript" "$context" >/dev/null 2>&1 &

exit 0
