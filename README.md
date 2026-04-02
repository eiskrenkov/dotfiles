# Personal Dotfiles

Managed by https://www.chezmoi.io

## Installation

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply eiskrenkov
```

Apply Brewfile

```sh
brew bundle install
```

## Manual stuff

### 1. Set computer name

```sh
scutil --get ComputerName

sudo scutil --set ComputerName "macbook-pro-tds"
sudo scutil --set LocalHostName "macbook-pro-tds"
sudo scutil --set HostName "macbook-pro-tds.local"
```

### 2. Cursor extensions

Export

```sh
./home/script/export_cursor_extensions
```

Import

```sh
./home/script/import_cursor_extensions
```

### 3. Transfer AWS configs

```sh
~/.aws/config
~/.aws/credentials
```

### 4. Reveal "Anywhere" option in System Settings > Privacy & Security > Allow applications from

```sh
sudo spctl --master-disable
```

## Maintenance

Prefill zoxide index

```sh
zoxide add (find ~/dev -mindepth 1 -maxdepth 1 -type d)
```

## Chezmoi Usage

Start tracking file with chezmoi

```sh
# This will copy ~/.bashrc to ~/.local/share/chezmoi/dot_bashrc
chezmoi add ~/.bashrc
```

Edit dotfile

```sh
# This will open ~/.local/share/chezmoi/dot_bashrc in your $EDITOR. Make some changes and save the file.
chezmoi edit ~/.bashrc
```

See what changes chezmoi would make

```sh
chezmoi diff
```

Apply the changes

```sh
# All chezmoi commands accept the -v (verbose) flag to print out exactly what changes they will make to the file system
chezmoi -v apply
```

```
chezmoi cd
```

## Contributing

Not this time 🥲
