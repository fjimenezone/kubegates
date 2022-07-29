#!/usr/bin/env bash

session="workbench"

# set up tmux
tmux start-server

# Create a new tmux session, starting vim from a saved session in the new window
tmux new-session -d -s $session -n k8s

# Select pane 0, source the cluster using an alias kqa
tmux selectp -t 0 
tmux send-keys "kqa" C-m 

# Split window horizontally
tmux splitw -h

# Select second pane
tmux selectp -t 1
tmux send-keys "kstg" C-m

tmux splitw -v
tmux send-keys "kmgt" C-m
tmux selectp -t 0
tmux splitw -v
tmux send-keys "kpro" C-m
tmux selectp -t 0

tmux attach-session -t $session
