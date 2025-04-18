# Load aliases
for file in (find ~/.config/fish/aliases -type f); source $file; end

# Load theme config
source ~/.config/fish/theme.fish

# Path
set PATH $HOME/bin /usr/local/bin /opt/homebrew/bin /opt/homebrew/bin/fish /opt/homebrew/opt/openssl@3/bin $PATH

# Fish options
set -g fish_prompt_pwd_dir_length 1
set -g full_length_dirs 1

# Set default language to english
set -gx LANG en_US

# Set default editor
set -gx EDITOR /usr/bin/nano

set -gx SHELL $(which fish)
set -gx LDFLAGS '-L/opt/homebrew/opt/openssl@3/lib'
set -gx CPPFLAGS '-I/opt/homebrew/opt/openssl@3/include'
set -gx PKG_CONFIG_PATH /opt/homebrew/opt/openssl@3/lib/pkgconfig

# Hook direnv
direnv hook fish | source

# Set fzf options
# set -gx FZF_DEFAULT_OPTS '--height 30% --layout=reverse --border'

# pnpm
set -gx PNPM_HOME "/Users/eiskrenkov/Library/pnpm"
if not string match -q -- $PNPM_HOME $PATH
  set -gx PATH "$PNPM_HOME" $PATH
end

# Mise
mise activate fish | source

# fzf
fzf --fish | source

# zoxide
zoxide init --cmd cd fish | source

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init2.fish 2>/dev/null || :
