#!/usr/bin/env bash
set -Eeuo pipefail

SOURCE="codefloe.com/crow-plugins"
TARGET="quay.io/amrkmn/crow-plugins"

IMAGES=(
  ansible
  auto-releaser
  clone
  docker-buildx
  renovate
  sccache
)

sync_one() {
  local image="$1"

  for attempt in 1 2 3 4 5; do
    echo "[$(date)] Syncing $image, attempt $attempt"

    if skopeo sync --all \
      --retry-times 5 \
      --src docker \
      --dest docker \
      "$SOURCE/$image" \
      "$TARGET"; then
      return 0
    fi

    echo "[$(date)] Failed $image, retrying..."
    sleep $((attempt * 20))
  done

  echo "[$(date)] Giving up on $image"
  return 1
}

for image in "${IMAGES[@]}"; do
  sync_one "$image"
done
