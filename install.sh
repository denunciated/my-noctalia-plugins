#!/usr/bin/env bash

set -e

src="$(dirname "$(realpath "$0")")/github-dashboard"
dst="$HOME/.local/share/noctalia/plugins/github-dashboard"

mkdir -p "$(dirname "$dst")"
rm -rf "$dst"
cp -r "$src" "$dst"

noctalia msg plugins enable denunciated/github-dashboard
noctalia msg config-reload

printf 'Installed denunciated/github-dashboard\n'
printf 'Add the github widget in Noctalia, or open it with:\n'
printf '  noctalia msg panel-toggle denunciated/github-dashboard:dashboard\n'

