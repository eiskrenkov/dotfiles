---
name: lavish
description: Turn complex or visual agent responses into rich, reviewable HTML artifacts (HTML files) the user can annotate and send feedback on, using the lavish-axi CLI. Use when about to give a plan, comparison, diagram, table, code diff, report, or anything easier to grasp visually than as prose.
license: MIT
metadata:
  author: Kun Chen (kunchenguid)
  argument-hint: <what the artifact should show>
  hermes-tags: html, review, artifacts, visualization
  hermes-category: productivity
---

# Lavish Editor

Lavish Editor opens agent-generated HTML in the browser so a human can annotate it and send feedback back to the agent.
Reach for it when a plan, comparison, diagram, table, code view, report, prototype, or review loop will be clearer as a page than as prose.

You do not need lavish-axi installed globally - run it as `npx -y lavish-axi ...`. If lavish-axi output shows a follow-up command starting with `lavish-axi`, run it as `npx -y lavish-axi ...` instead.

## Keep the HTML out of your context

A Lavish page is 10-100 KB of HTML, and the CLI guidance behind it is another 20-40 KB. Don't produce either in the main conversation. Split the work:

- **You (main agent)** decide what the page must say, brief the author, give the user the link, poll, decide what to do with feedback, and reply in Lavish.
- **The author** (`lavish-author` subagent) reads the CLI guidance (`--help`, `design`, playbooks), writes and revises the HTML, checks the render, and opens the session in Muxify's Browser. Its procedure is [references/authoring.md](references/authoring.md).

Don't run `lavish-axi --help`, `design` or `playbook` yourself. Never `Read` or `Write` the artifact yourself, except for the tiny anchored edits under [Feedback rounds](#feedback-rounds).

Spawn the author with the Agent tool and `subagent_type: lavish-author` in Claude Code, or with the task tool and the `lavish-author` subagent in opencode. If neither is available, read [references/authoring.md](references/authoring.md) and act as the author yourself, still following its edit-in-place rules.

### The brief

The author knows nothing about this conversation. Give it everything it needs, as compact text, and nothing it doesn't:

- **Goal**: what the reader must understand or decide, and who reads it.
- **Path**: `.lavish/<slug>.html` in the current working directory, unless the user named another location.
- **Kind**: plan, comparison, diagram, table, code, input, explanation or slides - one or several. The author opens the matching playbooks.
- **Design source**: the subject project's CSS or design system (give the path), or "none - use lavish design".
- **Content**: the section outline with the actual facts, numbers, decisions, findings, `path:line` references and diagram nodes and edges. The author should not need to research.
- **Constraints**: anything the user asked for, such as length, sections to leave out, or interactions.

The author returns `path`, `url`, a summary of at most 3 lines, and open questions. Give the user the URL, then start polling.

## Feedback rounds

`npx -y lavish-axi poll <html-file>` long-polls until the user sends feedback.

- Run it in the foreground, or as a tracked background job whose completion wakes you (Claude Code: Bash `run_in_background`). Never use `nohup`, `&` or `disown`.
- There is one listener per session. If the poll dies before feedback arrives, run it again: the feedback stays queued.
- Read the whole response: delivery consumes it.

For each response:

1. Decide what to change. When the feedback is ambiguous, ask in Lavish with `--agent-reply`.
2. Route the edit:
   - **Tiny** (a word or a label, at most ~10 lines in one block): make it yourself. `grep -n` the anchor in the HTML, read only that line range, then apply `Edit`.
   - **Anything else**: send the author the poll response verbatim plus your decisions.
     - Claude Code: continue the same author with `SendMessage`, so it keeps its context.
     - opencode: resume the author task if your task tool supports it. Otherwise spawn a fresh author with the path, the poll response and your decisions.

     Either way, the author edits in place and never rewrites the file.
3. Lavish live-reloads the page. Post a short reply and wait again with `npx -y lavish-axi poll <html-file> --agent-reply "..."`. When you are handing back and not waiting any more, use `npx -y lavish-axi reply <html-file> --agent-reply "..."` instead. For a multi-line reply, use `--agent-reply-file <path>`.

`Send & End` ends the session. Its final feedback is delivered once; after that, stop polling and don't reopen the session uninvited. If the poll returns `browser_disconnected`, ask the user whether to reopen or end the session. Reopening (`--reopen`) is the author's job.

## Request

$ARGUMENTS

If the request above is non-empty, the user invoked `/lavish` explicitly - brief the author to build that artifact.
If it is empty, infer what to visualize from the conversation.
