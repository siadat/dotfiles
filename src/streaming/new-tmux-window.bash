#!/bin/bash
set -e

place_holder_command="while :; do clear; sleep 3600; done"
camera_command="while :; do clear; echo -e '\n\n      camera here'; sleep 3600; done"

tmux new-window -c ~/src -n streaming
tmux split-window -l 25% -h "nvim ~/streaming/plan.md"
tmux split-window -l 66% -v "irssi"
tmux split-window -l 50% -v "$camera_command"
tmux select-pane -t '{top-left}'
