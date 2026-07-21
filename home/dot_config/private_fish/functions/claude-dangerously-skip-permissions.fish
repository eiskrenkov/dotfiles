function claude-dangerously-skip-permissions --description "Launch Claude Code, skipping permission prompts"
    # Shared launcher behind the `cld` alias and the command palette, so the two
    # can't drift. The `-opus`/`-fable` variants build on this by appending a
    # `--model`. Extra args are passed straight through to claude.
    claude --dangerously-skip-permissions $argv
end
