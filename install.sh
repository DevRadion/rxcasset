#!/bin/bash

set -e

zig build -Doptimize=ReleaseFast

sudo cp zig-out/bin/assets /usr/local/bin/rxcasset

echo "Done! Use rxcasset to run"
