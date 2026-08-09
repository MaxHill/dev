#!/usr/bin/env bash

tmux split-window -h -l 30% bash -lc '
       file=$(mktemp --suffix=.md)
       trap "rm -f \"$file\"" EXIT

       nvim --clean "$file" || exit
       question=$(<"$file")
       [ -n "$question" ] || exit

       opencode --pure run \
         --model github-copilot/gpt-5.4 \
         --variant none \
         "$question" |
         bat --language markdown --style plain --paging=always
     '
