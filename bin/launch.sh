#!/usr/bin/env bash

b && (
    target=$(tmux display -p '#{session_name}:#{window_name}')
    # tmux send-keys -t $target.1 spiraltest C-m
    tmux send-keys -t $target.1 s C-m
    tmux split-window -d -t $target.1 -h
    tmux send-keys -t $target.2 c C-m
    tmux select-pane -t $target.1 -R
)
