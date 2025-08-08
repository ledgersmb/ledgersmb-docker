#!/bin/bash

home_dir="$(dirname $(readlink -f $BASH_SOURCE))"
"$home_dir/config.sh" || { echo "Failed configuration" ; exit 1 }

exec "$home_dir/run.sh"
