function command_palette --description "fzf modal of dotfile features (tmux prefix+P / ⌘⇧P)"
    # ─── Feature registry ─────────────────────────────────────────────────────
    # The single source of truth for the palette. To expose a new feature, add
    # ONE __cp line — that is the whole edit. Fields:
    #   id       short stable key (used only for recency tracking)
    #   label    human-readable name shown in the modal
    #   keybind  matching key (display only; "" if the feature has no keybind)
    #   type     how the choice is run once the popup closes:
    #              popup  → run in a FRESH tmux popup that replaces this one —
    #                       for interactive pickers/TUIs, so they work no matter
    #                       what occupies the active pane (a shell, Claude Code…)
    #              pane   → run the command in the active pane and press Enter
    #                       (only sensible when the pane is a shell at a prompt)
    #              prompt → type the command into the active pane, no Enter
    #                       (for features that still need an argument)
    #              script → run a tmux script in the background — the *same*
    #                       script its keybind runs, so behaviour can't drift
    #              func   → run a fish function in the background, passing the
    #                       active pane's path — like script, but the shared
    #                       source is a fish function (e.g. open-in-sublime-merge)
    #   command  what actually runs; the single source shared with the keybind
    set -l ids; set -l labels; set -l keys; set -l types; set -l cmds
    function __cp --no-scope-shadowing
        set -a ids $argv[1]; set -a labels $argv[2]; set -a keys $argv[3]
        set -a types $argv[4]; set -a cmds $argv[5]
    end
    #    id         label                                   keybind  type    command
    __cp checkout  "Git · smart checkout (branch picker)"   ""       popup   "gco"
    __cp wtcreate  "Git · create worktree (branch picker)"  ""       popup   "create-worktree"
    __cp log       "Git · browse commit log"                ""       popup   "glo"
    __cp pr        "Git · push & open pull request"         ""       pane    "ggpr"
    __cp syncmain  "Git · sync current branch with master"  ""       pane    "gup"
    __cp lazygit   "Git · lazygit"                          "⌘G"     popup   "lazygit"
    __cp smerge    "Git · open Sublime Merge for repo"      "⌘⇧M"    func    "open-in-sublime-merge"
    __cp cursor    "Editor · open / focus Cursor"           "⌘⇧E"    script  "$HOME/.config/tmux/scripts/sync-cursor.sh"
    __cp finder    "Finder · reveal current folder"         ""       func    "reveal-in-finder"
    __cp ports     "Tmux · jump to a listening port"        ""       popup   "ports"
    __cp reload    "Tmux · reload configuration"            ""       func    "tmux-reload"
    __cp project   "Pop · switch project"                   "⌘P"     popup   "pop select"
    __cp worktree  "Pop · switch worktree"                  "⌘O"     popup   "pop worktree --switch"
    __cp dashboard "Pop · dashboard"                        "⌘I"     popup   "pop dashboard"
    __cp czapply   "Chezmoi · apply dotfiles"               ""       pane    "chezmoi apply"
    __cp kubectx   "Kube · switch context"                  ""       popup   "kc"
    __cp dockerup  "Docker · compose up services"           ""       pane    "dup"
    __cp gemstub   "Ruby · stub local gem paths"            ""       prompt  "gemstub stub "
    __cp opencode  "Opencode · web server (start/stop)"     ""       prompt  "opencode-server "
    functions -e __cp

    set -l state_dir "$HOME/.cache/tmux-command-palette"
    mkdir -p $state_dir
    set -l recent_file "$state_dir/recent"

    # The rendezvous files the background dispatcher (palette-dispatch.sh) polls.
    # These use FIXED names — not scoped by pane id — on purpose: display-popup
    # does not format-expand its arguments, so this popup has no reliable way to
    # learn the launching pane's id (run-shell, which starts the dispatcher, DOES
    # expand #{pane_id}, so the dispatcher still knows the real pane for its
    # send-keys). A single user only ever has one palette open at a time, so a
    # shared rendezvous is safe. We only ever *write* these on a definite outcome
    # below — the dispatcher owns clearing stale ones.
    set -l choice_file "$state_dir/choice"
    set -l cancel_file "$state_dir/cancel"

    # ─── Order: most-recently-used first, then the rest alphabetically ─────────
    set -l recent
    test -f $recent_file; and set recent (cat $recent_file)
    set -l ordered
    for id in $recent
        contains -- $id $ids; and set -a ordered $id
    end
    set -l remaining
    for i in (seq (count $ids))
        contains -- $ids[$i] $ordered; or set -a remaining "$labels[$i]\t$ids[$i]"
    end
    for line in (printf '%b\n' $remaining | sort -f)
        set -a ordered (string split \t $line)[2]
    end

    # ─── Render rows: hidden id column, then function name + dim label/keybind ──
    # Primary text is the function/command the row triggers, so the palette
    # doubles as a cheat-sheet for it; the human label and any keybind follow,
    # dimmed. Each column is padded *before* colouring so the label and keybind
    # line up regardless of name length.
    set -l dim (set_color brblack); set -l reset (set_color normal)
    set -l rows
    for id in $ordered
        set -l i (contains -i -- $id $ids)

        # Name = what it triggers. `script` rows run a path, so show its basename;
        # everything else shows the (trimmed) command.
        set -l name (string trim -- $cmds[$i])
        test "$types[$i]" = script; and set name (string replace -r '^.*/' '' -- $name)

        # Dim label = the human label minus its "Category · " prefix; dropped when
        # it would only repeat the name (e.g. lazygit).
        set -l label (string split -m1 ' · ' -- $labels[$i])[-1]
        test "$label" = "$name"; and set label ""

        set -l shown (printf '%-23s' $name)$dim(printf ' %-33s' $label)$keys[$i]$reset
        set -a rows "$id\t$shown"
    end

    # --layout default puts the input at the bottom and grows the list upward,
    # placing the first row (most-recently used) right above the prompt — so the
    # recency order renders with recent items lowest, nearest the input.
    set -l choice (printf '%b\n' $rows | fzf --ansi --no-sort \
        --delimiter \t --with-nth 2 \
        --height 100% --layout default \
        --prompt 'run ❯ ')

    # Dismissed without choosing: tell the dispatcher to stand down and exit.
    if test -z "$choice"
        touch $cancel_file
        return 0
    end

    set -l id (string split \t $choice)[1]
    set -l i (contains -i -- $id $ids)

    # Record recency: chosen id first, previous order after, no duplicates.
    printf '%s\n' $id $recent | awk 'NF && !seen[$0]++' >$recent_file

    # Hand the choice to the dispatcher. Writing this file is the LAST thing we
    # do: the dispatcher detects it, waits for this popup to finish closing, then
    # runs the feature — so interactive fzf popups never nest inside ours.
    printf '%s\n%s\n' $types[$i] $cmds[$i] >$choice_file
end
