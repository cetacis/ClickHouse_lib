#!/usr/bin/env bash

set -e

git worktree add src master
cd src
git submodule update --init --recursive
