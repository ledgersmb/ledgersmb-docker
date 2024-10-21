#!/bin/bash

home_dir="$(dirname `readlink -f $BASH_SOURCE`)"
"$home_dir/config.sh" || (echo "Failed configuration" ; exit)
exec "$home_dir/run.sh"
