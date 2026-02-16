#!/usr/bin/env bash

echo ${INPUT_RUN} > /tmp/input_run.sh
echo "" >> /tmp/input_run.sh

resolve_workspace_folder() {
  local requested="${INPUT_WORKSPACE_FOLDER:-}"
  if [[ -z "$requested" || "$requested" == "/github/workspace" ]]; then
    local container_id="${HOSTNAME:-}"
    if [[ -n "$container_id" ]]; then
      local host_workspace
      host_workspace="$(docker inspect "$container_id" \
        --format '{{range .Mounts}}{{if eq .Destination "/github/workspace"}}{{.Source}}{{end}}{{end}}' \
        2>/dev/null || true)"
      if [[ -n "$host_workspace" ]]; then
        echo "$host_workspace"
        return
      fi
    fi
  fi
  echo "${requested:-/github/workspace}"
}

WORKSPACE_FOLDER="$(resolve_workspace_folder)"

echo "INPUT_WORKSPACE_FOLDER: ${INPUT_WORKSPACE_FOLDER:-<unset>}"
echo "RESOLVED_WORKSPACE_FOLDER: ${WORKSPACE_FOLDER}"
echo "INPUT_IMAGE: ${INPUT_IMAGE}"
echo "Command to run: ${INPUT_RUN}"

echo "Running command in Docker container..."

docker run \
    --rm \
    -v "/var/run/docker.sock":"/var/run/docker.sock" \
    -v ${WORKSPACE_FOLDER}:/work \
    -u 1001:1001 \
    --workdir /work \
    ${INPUT_OPTIONS} \
    ${INPUT_IMAGE} \
    ${INPUT_SHELL} -euo pipefail <<EOF
${INPUT_RUN}
EOF