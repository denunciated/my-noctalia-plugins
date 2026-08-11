# Noctalia GitHub Dashboard


## Installation

The plugin itself is in `github-dashboard/`.

### Fish
```fish
sudo pacman -S github-cli xdg-utils
gh auth login
./install.fish
```
### Bash
```bash
sudo pacman -S github-cli xdg-utils
gh auth login
./install.sh
```

### Nushell
```nu
sudo pacman -S github-cli xdg-utils
gh auth login
./install.nu
```
> Note: ``gh auth login`` is shell-independent, so the command is the same for Fish, Bash, and Nushell.
