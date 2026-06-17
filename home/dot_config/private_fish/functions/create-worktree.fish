function create-worktree --description "Create a new git worktree with fzf branch selection"
    # ─── Detect repo context ───────────────────────────────────────────────────
    # Find the bare repo root: a directory whose .git has core.bare=true,
    # walking up from $PWD.
    set -l bare_root ""
    set -l dir $PWD
    while test "$dir" != "/"
        if test -d "$dir/.git"
            set -l core_bare (git -C "$dir" config --get core.bare 2>/dev/null)
            if test "$core_bare" = "true"
                set bare_root $dir
                break
            end
        end
        set dir (dirname "$dir")
    end

    set -l is_bare false
    set -l git_root ""

    if test -n "$bare_root"
        set is_bare true
        set git_root $bare_root
    else
        set -l git_common_dir (git rev-parse --git-common-dir 2>/dev/null)
        set -l common_bare ""
        if test -n "$git_common_dir"
            set common_bare (git -C "$git_common_dir" config --get core.bare 2>/dev/null)
        end

        if test "$common_bare" = "true"
            set is_bare true
            set git_root (dirname "$git_common_dir")
        else
            set git_root (git rev-parse --show-toplevel 2>/dev/null)
            if test -z "$git_root"
                echo "Not in a git repository" >&2
                return 1
            end
        end
    end

    # ─── Pick a branch ─────────────────────────────────────────────────────────
    # All branches (local + remote), with main/master floated to the top.
    set -l branches (git branch -a --format="%(refname:short)" | grep -v '^origin/HEAD' | awk '
        /^(main|master)$/ { default = $0; next }
        { others[NR] = $0 }
        END {
            if (default) print default
            for (i in others) print others[i]
        }
    ')

    if test (count $branches) -eq 0
        echo "No branches found" >&2
        read -P "Press any key to continue..." -n 1 -s key
        return 1
    end

    set -l selected_branch (printf '%s\n' $branches | fzf \
        --prompt="Branch: " \
        --no-sort \
        --border-label ' select branch ')

    if test -z "$selected_branch"
        echo "Cancelled"
        return 1
    end

    # ─── Name the worktree ─────────────────────────────────────────────────────
    # Strip any origin/ prefix; default directory name replaces / with -.
    set -l local_branch (string replace -r '^origin/' '' -- $selected_branch)
    set -l default_name (string replace -a '/' '-' -- $local_branch)

    # Ask for the worktree name (empty = use default, Ctrl+C = cancel)
    read -P "Worktree name (default: $default_name): " -l dir_name
    if test -z "$dir_name"
        set dir_name $default_name
    end

    # ─── Resolve the worktree path ─────────────────────────────────────────────
    set -l abs_path
    if test "$is_bare" = "true"
        set abs_path "$git_root/$dir_name"
    else
        set -l main_worktree_path (git worktree list | head -1 | awk '{print $1}')
        set -l main_repo_name (basename "$main_worktree_path")
        set abs_path (dirname "$git_root")/$main_repo_name-$dir_name
    end

    # ─── Create the worktree ───────────────────────────────────────────────────
    # Reuse an existing local branch if one matches the target name; otherwise
    # create a new branch off the selected ref.
    echo "Creating worktree at $abs_path..."

    if git -C "$git_root" show-ref --verify --quiet "refs/heads/$dir_name"
        echo "Using existing branch '$dir_name'..."
        if not git -C "$git_root" worktree add "$abs_path" "$dir_name" 2>&1
            echo "Failed to create worktree" >&2
            read -P "Press any key to continue..." -n 1 -s key
            return 1
        end
    else
        echo "Creating branch '$dir_name' based on '$selected_branch'..."
        if not git -C "$git_root" worktree add -b "$dir_name" "$abs_path" "$selected_branch" 2>&1
            echo "Failed to create worktree" >&2
            read -P "Press any key to continue..." -n 1 -s key
            return 1
        end
    end

    # Reindex zoxide in the background
    if command -q zoxide-index
        zoxide-index &>/dev/null &
    end

    # Hand off to pop: derives the session name, creates/attaches the tmux
    # session, and records the path in project history
    pop project switch "$abs_path"
end
