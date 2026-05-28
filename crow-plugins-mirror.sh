#!/usr/bin/env bash
set -Eeuo pipefail

SOURCE="${SOURCE:-codefloe.com/crow-plugins}"
TARGET="${TARGET:-quay.io/amrkmn/crow}"

IMAGES=(ansible auto-releaser clone docker-buildx renovate sccache)

regctl_login() {
  local registry="$1" user="$2" pass="$3" required="${4:-false}"

  if [[ -z "$user" && -z "$pass" ]]; then
    [[ "$required" == true ]] && { echo "Missing credentials for $registry" >&2; exit 1; }
    return 0
  fi

  if [[ -z "$user" || -z "$pass" ]]; then
    echo "Incomplete credentials for $registry" >&2
    exit 1
  fi

  printf '%s\n' "$pass" | regctl registry login "$registry" -u "$user" --pass-stdin
}

retry() {
  local attempts="$1"
  shift

  local attempt
  for ((attempt = 1; attempt <= attempts; attempt++)); do
    if "$@"; then
      return 0
    fi

    if ((attempt == attempts)); then
      return 1
    fi

    sleep $((attempt * 5))
  done
}

regctl_login "${SOURCE%%/*}" "${SOURCE_REGISTRY_USERNAME:-}" "${SOURCE_REGISTRY_PASSWORD:-}"
regctl_login "${TARGET%%/*}" "${TARGET_REGISTRY_USERNAME:-}" "${TARGET_REGISTRY_PASSWORD:-}" true

for image in "${IMAGES[@]}"; do
  mapfile -t tags < <(regctl tag ls "$SOURCE/$image")

  for tag in "${tags[@]}"; do
    retry 5 regctl image copy "$SOURCE/$image:$tag" "$TARGET/$image:$tag"
  done
done
