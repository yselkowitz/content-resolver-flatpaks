#!/bin/bash

# This script runs the content_resolver.py with the right configs and pushes out the results

# Local output dir. Includes a dir for the history data, too.
mkdir -p flatpaks/logs || exit 1
mkdir -p flatpaks/output/history || exit 1

# Build the site
build_started=$(date +"%Y-%m-%d-%H%M")
echo ""
echo "Building..."
echo "$build_started"
echo "(Logging into flatpaks/logs/$build_started.log)"
CMD="./content_resolver.py --dnf-cache-dir /dnf_cachedir flatpaks/configs flatpaks/output" || exit 1
podman run --rm -it --tmpfs /dnf_cachedir -v $PWD:/workspace:z content-resolver-env $CMD > ./flatpaks/logs/$build_started.log || exit 1

# Save the root log cache
cp ./cache_root_log_deps.json flatpaks/output/cache_root_log_deps.json || exit 1
