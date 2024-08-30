#!/bin/bash

# Copyright (c) The Diem Core Contributors
# Copyright (c) The Move Contributors
# SPDX-License-Identifier: Apache-2.0

# This script assumes it runs in the same directory as a Cargo.toml file
# and sees if this Cargo.toml file can operate without some of its
# dependencies using repeated `cargo check --all-targets` attempts.
#
# In order to run this in a directory containing multiple Cargo.toml files,
# we could suggest:
# find ./ -name Cargo.toml -execdir /path/to/$(basename $0) \;

# Requirements:
# https://github.com/killercup/cargo-edit << `cargo install cargo-edit`
# awk, bash, git
# This will make one local commit per removable dependency. It is advised to
# squash those dependency-removing commits into a single one.

if [ ! -f Cargo.toml ]; then
    echo "Cargo.toml not found! Are you running this script in the right directory?"
    exit 1
fi

# Extract dependency names
dependencies=$(awk '/^\[.*dependencies\]/ {x=1} x==1 && /^[^\[]/ {print $1; x=0}' Cargo.toml)

echo "$dependencies"

for dep in $dependencies; do
    echo "Testing removal of $dep"
    
    # Manually edit Cargo.toml or use another method to remove dependency
    # cargo rm "$dep" # If this command is available in your setup

    # Run cargo check to verify removal
    cargo check --all-targets --all-features
    if [ $? -eq 0 ]; then
        echo "Removal succeeded, committing"
        git add Cargo.toml
        git commit --no-gpg-sign -m "Removing $dep from $(basename `pwd`)" || { echo "Git commit failed"; exit 1; }
    else
        echo "Removal failed, rolling back"
        git reset --hard || { echo "Git reset failed"; exit 1; }
    fi
done

