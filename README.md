# Noctalia GitHub Dashboard

GitHub Dashboard adds assigned issues, requested pull-request reviews, your open pull requests, and GitHub notifications to Noctalia.

## Installation

Add the GitHub Dashboard source by Left-clicking the **Add Source** button in Noctalia's **Sources** tab or by running the following.

```sh
noctalia msg plugins source add github-dashboard git https://github.com/denunciated/noctalia-github-dashboard-.git
```

Then open **Settings → Plugins**, select the GitHub Dashboard source, and enable **GitHub Dashboard**. It will also be available from the command line:

```sh
noctalia msg plugins enable denunciated/github-dashboard
```

For a local checkout during development:

```sh
noctalia msg plugins source add github-dashboard-dev path /path/to/noctalia-github-dashboard-
noctalia msg plugins enable denunciated/github-dashboard
```

After enabling it, add the `github` widget through Noctalia's Add Widget interface. Left-clicking the widget opens the dashboard.

## Dependencies

This plugin depends on [GitHub CLI](https://github.com/cli/cli) and [xdg-utils](https://www.freedesktop.org/wiki/Software/xdg-utils/) to function:

```sh
sudo pacman -S github-cli xdg-utils
gh auth login
```
