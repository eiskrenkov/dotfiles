function claude-dangerously-skip-permissions-opus --description "Launch Claude Code (Opus), skipping permission prompts"
    # Behind the `cldo` alias. Layers `--model opus` on top of the shared
    # skip-permissions launcher; extra args still pass through to claude.
    claude-dangerously-skip-permissions --model opus $argv
end
