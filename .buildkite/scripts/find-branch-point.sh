#!/bin/bash

# Find branch off point where $1 branch off $2

set -ue

diff -u <(git rev-list --first-parent "$1") \
        <(git rev-list --first-parent "$2") | \
        sed -ne 's/^ //p' | head -1
