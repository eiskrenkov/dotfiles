function ports --description "Find listening ports in tmux panes and switch to them"
  if not set -q TMUX
    echo "Not in a tmux session"
    return 1
  end

  set -l pane_lines (tmux list-panes -a -F '#{pane_pid} #{session_name}:#{window_index}.#{pane_index}')

  set -l entries
  set -l seen
  set -l current_pid ""
  set -l current_cmd ""

  for line in (lsof -iTCP -sTCP:LISTEN -n -P -F pcn 2>/dev/null)
    switch $line
      case 'p*'
        set current_pid (string sub -s 2 $line)
      case 'c*'
        set current_cmd (string sub -s 2 $line)
      case 'n*'
        set -l port (string split ':' (string sub -s 2 $line))[-1]

        set -l key "$port:$current_pid"
        if contains $key $seen
          continue
        end
        set -a seen $key

        set -l check_pid $current_pid
        set -l found_pane ""
        while test "$check_pid" != "1" -a -n "$check_pid" -a "$check_pid" != "0"
          for pane_line in $pane_lines
            set -l parts (string split ' ' $pane_line)
            if test "$parts[1]" = "$check_pid"
              set found_pane $parts[2]
              break
            end
          end
          test -n "$found_pane"; and break
          set check_pid (ps -o ppid= -p $check_pid 2>/dev/null | string trim)
        end

        if test -n "$found_pane"
          set -a entries (string join \t $port $current_cmd $found_pane)
        end
    end
  end

  if test (count $entries) -eq 0
    echo "No listening ports found in tmux panes"
    return 1
  end

  # Plain fzf when launched inside the command palette's popup (can't nest a
  # second popup); a floating `fzf --tmux` popup when run directly in a pane.
  set -l fzf_opts --header="PORT  CMD  PANE"
  set -q CMD_PALETTE_POPUP; or set -a fzf_opts --tmux
  set -l selection (printf '%s\n' $entries | sort -t\t -k1 -n | column -t -s\t | fzf $fzf_opts)

  if test -n "$selection"
    tmux switch-client -t (string match -r '\S+$' $selection)
  end
end
