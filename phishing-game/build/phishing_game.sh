#!/bin/sh
printf '\033c\033]0;%s\a' Phishing Game
base_path="$(dirname "$(realpath "$0")")"
"$base_path/phishing_game.x86_64" "$@"
