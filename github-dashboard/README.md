# GitHub Dashboard

GitHub Dashboard puts your assigned issues, requested pull-request reviews, open pull requests, and notifications in a Noctalia panel.

## Plugin

| Field | Value |
| --- | --- |
| ID | `denunciated/github-dashboard` |
| Entries | Widget: `github`; panel: `dashboard`; service: `github-service` |

## Requirements

- `gh` — GitHub CLI, authenticated with `gh auth login`
- `xdg-open` — provided by `xdg-utils`, for opening GitHub items in the browser

## Usage

Add the `github` widget through Noctalia's Add Widget interface. Left-click it to open the dashboard; right-click it to refresh GitHub data.

Open the panel directly:

```sh
noctalia msg panel-toggle denunciated/github-dashboard:dashboard
```

## Settings

- `refresh_minutes`: automatic refresh interval, in minutes
- `item_limit`: maximum items loaded per section
- `repositories`: optional `owner/repository` filters; leave empty to include every visible repository
- `show_notifications`: include GitHub notifications
- `show_count`: show the combined count in the bar widget

## Privacy and behavior

The plugin runs the local `gh` executable and keeps authentication under GitHub CLI's control; it does not store a token. It uses `xdg-open` only after you select an item, and holds fetched data only in Noctalia's in-memory plugin state.
