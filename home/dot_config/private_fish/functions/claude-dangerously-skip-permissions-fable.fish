function claude-dangerously-skip-permissions-fable --description "Launch Claude Code (Fable), skipping permission prompts"
    # Behind the `cldf` alias. Layers `--model fable` on top of the shared
    # skip-permissions launcher; extra args still pass through to claude.
    claude-dangerously-skip-permissions --model fable $argv
end
