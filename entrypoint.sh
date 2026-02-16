#!/usr/bin/env bash

echo "cd work" > /tmp/input_run.sh
echo ${INPUT_RUN} >> /tmp/input_run.sh
chmod +x /tmp/input_run.sh

exec docker run 
    -v "/var/run/docker.sock":"/var/run/docker.sock" \
    -v /tmp/input_run.sh:/tmp/input_run.sh \
    -v ${WORKSPACE_FOLDER}:/work \
    -u 1001:1001 \
    --workdir /work \
    $INPUT_OPTIONS \
    $INPUT_IMAGE \
    -c /tmp/input_run.sh
