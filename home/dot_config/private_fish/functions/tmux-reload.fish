function tmux-reload --description "Reload the tmux configuration (tmux prefix+r)"
    # tmux (prefix+r) and the command palette both call this, so the two can't
    # drift. The active pane's path is passed as $argv[1] for parity with the
    # other palette functions; reload doesn't need it.
    #
    # Mirrors Oh my tmux!'s stock reload: source the config, then flash a message.
    # TMUX_PROGRAM/TMUX_CONF/TMUX_SOCKET are exported into the environment by
    # oh-my-tmux; fall back to sensible defaults when they aren't set (the live
    # $TMUX socket already resolves the right server for a plain `tmux`).
    set -l tmux_bin tmux
    set -q TMUX_PROGRAM; and set tmux_bin $TMUX_PROGRAM
    set -l conf "$HOME/.config/tmux/tmux.conf"
    set -q TMUX_CONF; and set conf $TMUX_CONF

    set -l sock
    set -q TMUX_SOCKET; and set sock -S $TMUX_SOCKET

    $tmux_bin $sock source-file "$conf"
    $tmux_bin $sock display-message "$conf sourced"
end
