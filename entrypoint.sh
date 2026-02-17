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

DOCKER_ENV_ARGS=()
if [[ -n "${INPUT_ENV:-}" ]]; then
  while IFS= read -r env_line || [[ -n "$env_line" ]]; do
    env_line="${env_line%$'\r'}"
    [[ -z "${env_line//[[:space:]]/}" ]] && continue

    if [[ "$env_line" == *"="* ]]; then
      DOCKER_ENV_ARGS+=(--env "$env_line")
      continue
    fi

    if [[ "$env_line" == *":"* ]]; then
      env_key="${env_line%%:*}"
      env_value="${env_line#*:}"

      env_key="${env_key#"${env_key%%[![:space:]]*}"}"
      env_key="${env_key%"${env_key##*[![:space:]]}"}"
      env_value="${env_value#"${env_value%%[![:space:]]*}"}"

      [[ -z "$env_key" ]] && continue
      DOCKER_ENV_ARGS+=(--env "${env_key}=${env_value}")
    fi
  done <<< "${INPUT_ENV}"
fi

DOCKER_OPTION_ARGS=()
if [[ -n "${INPUT_OPTIONS:-}" ]]; then
  if [[ "${INPUT_OPTIONS}" == *$'\n'* ]]; then
    while IFS= read -r option_line || [[ -n "$option_line" ]]; do
      option_line="${option_line%$'\r'}"
      [[ -z "$option_line" ]] && continue
      DOCKER_OPTION_ARGS+=("$option_line")
    done <<< "${INPUT_OPTIONS}"
  else
    read -r -a DOCKER_OPTION_ARGS <<< "${INPUT_OPTIONS}"
  fi
fi

echo "INPUT_WORKSPACE_FOLDER: ${INPUT_WORKSPACE_FOLDER:-<unset>}"
echo "RESOLVED_WORKSPACE_FOLDER: ${WORKSPACE_FOLDER}"
echo "INPUT_IMAGE: ${INPUT_IMAGE}"
echo "Command to run: ${INPUT_RUN}"

echo "Running command in Docker container..."
exec docker run \
    --rm \
    -v "/var/run/docker.sock":"/var/run/docker.sock" \
    -v ${WORKSPACE_FOLDER}:/work \
    -u 1001:1001 \
    --workdir /work \
    "${DOCKER_ENV_ARGS[@]}" \
    "${DOCKER_OPTION_ARGS[@]}" \
    ghcr.io/nhsdigital/eps-devcontainers/githubactions-${INPUT_IMAGE} \
    ${INPUT_SHELL} -c "${INPUT_RUN}"
