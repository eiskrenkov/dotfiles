# Personal Dotfiles

Managed by https://www.chezmoi.io

## Installation

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply eiskrenkov
```

## Usage

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
