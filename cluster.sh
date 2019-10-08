#!/usr/bin/env bash

tmux neww -a -n Cluster
tmux send-keys "cd $PWD; ./build-dev/dbms/programs/clickhouse server --config etc/config1.xml" C-m
tmux splitw -v
tmux send-keys "./build-dev/dbms/programs/clickhouse server --config etc/config2.xml" C-m
tmux splitw -h
tmux send-keys "sleep 2" C-m
tmux send-keys "./build-dev/dbms/programs/clickhouse client --port 29000" C-m
tmux select-pane -t 1
tmux splitw -h
tmux send-keys "cd zookeeper; bin/zkServer.sh start" C-m
tmux select-pane -t 4
