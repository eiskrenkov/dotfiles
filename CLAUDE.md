# chezmoi dotfiles — working notes

This is the source repo for the user's chezmoi-managed dotfiles. `.chezmoiroot`
is `home/`, so all managed files live under `home/`.

## NEVER run `chezmoi apply`

**Do not run `chezmoi apply` — ever, not even scoped to specific paths.
Applying changes to the live machine is ALWAYS the user's job; they run it
themselves.**

Edit the source files under `home/` and stop there. To check your work without
mutating the live system, use read-only commands only:

- `chezmoi execute-template < file` — render a template
- `chezmoi diff` — preview what an apply would change

Likewise, do not run other commands that activate/mutate the live environment
without explicit permission (`chezmoi init`, `tmux source-file`, etc.). Editing
source is fine; activating it is the user's call.
