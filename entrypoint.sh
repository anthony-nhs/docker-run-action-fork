#!/usr/bin/env bash

echo ${INPUT_RUN} > /tmp/input_run.sh

echo "INPUT_WORKSPACE_FOLDER: ${INPUT_WORKSPACE_FOLDER}"
echo "INPUT_RUN: ${INPUT_RUN}"

echo "Running command in Docker container..."
exec docker run \
    -i \
    --rm \
    -v "/var/run/docker.sock":"/var/run/docker.sock" \
    -v ${INPUT_WORKSPACE_FOLDER}:/work \
    -u 1001:1001 \
    --workdir /work \
    $INPUT_OPTIONS \
    $INPUT_IMAGE \
    $INPUT_SHELL < /tmp/input_run.sh
