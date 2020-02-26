#!/usr/bin/env bash

set -e

git worktree add src master
cd src
HOME=$PWD git submodule update --init --recursive
