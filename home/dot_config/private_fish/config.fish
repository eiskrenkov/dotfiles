# Load custom config files
set -l custom_config_files ~/.config/fish/aliases/common.fish \
                           ~/.config/fish/aliases/git.fish \
                           ~/.config/fish/aliases/rails.fish \
                           ~/.config/fish/theme.fish

for file in $custom_config_files; . $file; end

set -e custom_config_files

# Path
set PATH $HOME/bin /usr/local/bin /opt/homebrew/bin /opt/homebrew/bin/fish $HOME/.rvm/bin /opt/homebrew/opt/openssl@3/bin $PATH

# Fish options
set -g fish_prompt_pwd_dir_length 0

# Set default language to english
set -gx LANG en_US

# Set default editor
set -gx EDITOR /usr/bin/nano

set -gx LDFLAGS '-L/opt/homebrew/opt/openssl@3/lib'
set -gx CPPFLAGS '-I/opt/homebrew/opt/openssl@3/include'
set -gx PKG_CONFIG_PATH /opt/homebrew/opt/openssl@3/lib/pkgconfig

# Hook direnv
direnv hook fish | source

# Set fzf options
set -gx FZF_DEFAULT_OPTS '--height 30% --layout=reverse --border'
