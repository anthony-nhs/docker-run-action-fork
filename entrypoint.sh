#!/usr/bin/env bash

echo "cd work" > /tmp/input_run.sh
echo ${INPUT_RUN} >> /tmp/input_run.sh
chmod +x /tmp/input_run.sh

echo "contents of /tmp/input_run.sh"
cat /tmp/input_run.sh
echo "Going to run docker run"

exec docker run 
    -v "/var/run/docker.sock":"/var/run/docker.sock" \
    -v /tmp/input_run.sh:/tmp/input_run.sh \
    -v ${INPUT_WORKSPACE_FOLDER}:/work \
    -u 1001:1001 \
    --workdir /work \
    $INPUT_OPTIONS \
    $INPUT_IMAGE \
    -c /tmp/input_run.sh
