# Load aliases
for file in (find ~/.config/fish/aliases -type f); source $file; end

# Load theme config
source ~/.config/fish/theme.fish

# Load env variables
source ~/.config/fish/env.fish

# Fish options
set -g fish_prompt_pwd_dir_length 1
set -g full_length_dirs 1

# Hook direnv
direnv hook fish | source

# Mise
mise activate fish | source

# fzf
fzf --fish | source

# zoxide
zoxide init --cmd cd fish | source

# Added by OrbStack: command-line tools and integration
source ~/.orbstack/shell/init2.fish 2>/dev/null || :
