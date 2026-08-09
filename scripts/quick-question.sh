#!/usr/bin/env bash

tmux split-window -h -l 30% bash -lc '
       read -r -p "Ask: " question
       opencode --pure run \
         --model github-copilot/gpt-5.4 \
         --variant none \
         "$question" |
         bat --language markdown --style plain --paging=always
     '

