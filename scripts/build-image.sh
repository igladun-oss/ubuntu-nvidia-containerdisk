#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

IMAGE_TAG="${IMAGE_TAG:-ghcr.io/igladun-oss/ubuntu-nvidia-containerdisk:latest}"
PLATFORM="${PLATFORM:-linux/amd64}"
PUSH_IMAGE="${PUSH_IMAGE:-false}"
NO_CACHE="${NO_CACHE:-false}"
PULL_BASE="${PULL_BASE:-false}"
SKIP_BAKE="${SKIP_BAKE:-false}"

need() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing dependency: $1" >&2
    exit 1
  }
}

echo "[1/3] Checking Docker Buildx..."
need docker
docker buildx version >/dev/null

cd "${REPO_ROOT}"

if [ "${SKIP_BAKE}" != "true" ]; then
  echo "[2/3] Baking golden qcow2..."
  "${SCRIPT_DIR}/bake-image.sh"
else
  echo "[2/3] Skipping qcow2 bake because SKIP_BAKE=true"
fi

buildx_args=(
  --platform "${PLATFORM}"
  -t "${IMAGE_TAG}"
)

if [ "${NO_CACHE}" = "true" ]; then
  buildx_args+=(--no-cache)
fi

if [ "${PULL_BASE}" = "true" ]; then
  buildx_args+=(--pull)
fi

if [ "${PUSH_IMAGE}" = "true" ]; then
  echo "[3/3] Building and pushing image with Buildx..."
  docker buildx build \
    "${buildx_args[@]}" \
    --push \
    .
  echo "DONE: pushed ${IMAGE_TAG}"
else
  echo "[3/3] Building image locally with Buildx..."
  docker buildx build \
    "${buildx_args[@]}" \
    --load \
    .
  echo "DONE: built locally as ${IMAGE_TAG}"
fi
