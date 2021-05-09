# Load custom config files
set -l custom_config_files ~/.config/fish/aliases/common.fish \
                           ~/.config/fish/aliases/git.fish \
                           ~/.config/fish/theme.fish

for file in $custom_config_files; . $file; end

set -e custom_config_files

# Path
set PATH $HOME/bin /usr/local/bin /usr/local/mysql/bin /usr/local/opt/rabbitmq/sbin /usr/local/opt/mysql-client/bin $HOME/.rvm/bin $PATH

# Fish options
set -g fish_prompt_pwd_dir_length 0

# Set default language to english
set -gx LANG en_US

# Set default editor
set -gx EDITOR /usr/bin/nano

# Google Cloud
set -gx CLOUDSDK_PYTHON "/usr/local/opt/python@3.8/libexec/bin/python"
bass source "/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.bash.inc"
bass source "/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.bash.inc"

# Hook direnv
direnv hook fish | source

rvm default
