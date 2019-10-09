#!/usr/bin/env bash

target=$(tmux display -p '#{session_name}:#{window_index}')
b dev && (tmux send-keys -t $target.1 s C-m ; tmux split-window -d -t $target.1 -h ; tmux send-keys -t $target.2 sleep\ 1 C-m c C-m; tmux select-pane -t $target.1 -R)
