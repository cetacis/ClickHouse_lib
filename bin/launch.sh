#!/usr/bin/env bash

target=$(tmux display -p '#{session_name}:#{window_name}')
b && (
    # tmux send-keys -t $target.1 spiraltest C-m
    tmux send-keys -t $target.1 s C-m
    tmux split-window -v -d -t $target.1
    tmux send-keys -t $target.2 c C-m
    tmux select-pane -t $target.1 -D # select down
)
