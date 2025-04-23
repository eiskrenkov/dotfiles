# Path
set PATH $HOME/bin /usr/local/bin /opt/homebrew/bin /opt/homebrew/bin/fish /opt/homebrew/opt/openssl@3/bin $PATH

# Set default language to english
set -gx LANG en_US

# Set default editor
set -gx EDITOR /usr/bin/nano

set -gx SHELL $(which fish)
set -gx LDFLAGS '-L/opt/homebrew/opt/openssl@3/lib'
set -gx CPPFLAGS '-I/opt/homebrew/opt/openssl@3/include'
set -gx PKG_CONFIG_PATH /opt/homebrew/opt/openssl@3/lib/pkgconfig

set -gx OPENAI_API_KEY "op://Personal/j2mxdpu7m536rh7rl4dujrj3cq/credential"

# Set fzf options
# set -gx FZF_DEFAULT_OPTS '--height 30% --layout=reverse --border'

# pnpm
set -gx PNPM_HOME "/Users/eiskrenkov/Library/pnpm"
if not string match -q -- $PNPM_HOME $PATH
  set -gx PATH "$PNPM_HOME" $PATH
end
