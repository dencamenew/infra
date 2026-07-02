#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REGISTRY="${REGISTRY:-gitlab.local:5050}"
PROJECT="${PROJECT:-root/terraform}"
IMAGE_PREFIX="${REGISTRY}/${PROJECT}"
GITLAB_REGISTRY_USER="${GITLAB_REGISTRY_USER:-root}"

# In CI, $CI_COMMIT_SHORT_SHA is set automatically. Locally, falls back to
# the current git short SHA, or "dev" if not in a git repo at all.
IMAGE_TAG="${CI_COMMIT_SHORT_SHA:-$(git -C "$ROOT_DIR" rev-parse --short HEAD 2>/dev/null || echo dev)}"

# Skip re-pulling/re-tagging/re-pushing pinned upstream images (postgres,
# redis, mongo, curl) once they already exist in the registry. Set to
# "true" to force a refresh, e.g. after bumping a pinned version.
FORCE_STATIC_IMAGES="${FORCE_STATIC_IMAGES:-false}"

if [[ -z "${GITLAB_REGISTRY_PASSWORD:-}" ]]; then
  echo "GITLAB_REGISTRY_PASSWORD is not set"
  exit 1
fi

echo "$GITLAB_REGISTRY_PASSWORD" | docker login "$REGISTRY" -u "$GITLAB_REGISTRY_USER" --password-stdin

echo "Building images for ${IMAGE_PREFIX} (tag: ${IMAGE_TAG})"

build_and_push_app_image() {
  local name="$1"
  local context="$2"
  shift 2
  local extra_args=("$@")

  docker build "${extra_args[@]}" \
    -t "${IMAGE_PREFIX}/${name}:${IMAGE_TAG}" \
    -t "${IMAGE_PREFIX}/${name}:latest" \
    "${context}"

  docker push "${IMAGE_PREFIX}/${name}:${IMAGE_TAG}"
  docker push "${IMAGE_PREFIX}/${name}:latest"
}

build_and_push_app_image nextapp "${ROOT_DIR}/web/nextapp" \
  --build-arg NEXT_PUBLIC_BACKEND_URL="${NEXT_PUBLIC_BACKEND_URL:-http://api.lab.local/api}" \
  --build-arg NEXT_PUBLIC_WS_URL="${NEXT_PUBLIC_WS_URL:-ws://api.lab.local/ws/api}"

build_and_push_app_image fastapi "${ROOT_DIR}/web/fastapi"
build_and_push_app_image fill-db "${ROOT_DIR}/web/db/fill_db"

docker build \
  -f "${ROOT_DIR}/web/db/gridfs_loader/Dockerfile" \
  -t "${IMAGE_PREFIX}/gridfs-loader:${IMAGE_TAG}" \
  -t "${IMAGE_PREFIX}/gridfs-loader:latest" \
  "${ROOT_DIR}/web/db"
docker push "${IMAGE_PREFIX}/gridfs-loader:${IMAGE_TAG}"
docker push "${IMAGE_PREFIX}/gridfs-loader:latest"

# --- Pinned upstream images: mirrored into the local registry once, not
#     rebuilt or re-tagged on every commit unless FORCE_STATIC_IMAGES=true.
declare -A STATIC_IMAGES=(
  ["postgres:15.4"]="postgres:15.4"
  ["redis:7.0"]="redis:7.0"
  ["mongo:4.4"]="mongo:4.4"
  ["curlimages-curl:8.8.0"]="curlimages/curl:8.8.0"
)

for local_ref in "${!STATIC_IMAGES[@]}"; do
  upstream_ref="${STATIC_IMAGES[$local_ref]}"
  target="${IMAGE_PREFIX}/${local_ref}"

  if [[ "$FORCE_STATIC_IMAGES" != "true" ]] && \
     docker manifest inspect "$target" >/dev/null 2>&1; then
    echo "Skipping ${target}, already present in registry"
    continue
  fi

  docker pull "$upstream_ref"
  docker tag "$upstream_ref" "$target"
  docker push "$target"
done

# Emit for GitLab CI's `artifacts: reports: dotenv:` mechanism so downstream
# jobs (update_manifests) know which tag to roll out.
echo "IMAGE_TAG=${IMAGE_TAG}" > "${ROOT_DIR}/build.env"
echo "Wrote ${ROOT_DIR}/build.env"