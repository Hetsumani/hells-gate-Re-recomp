#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Dante's Inferno (hells-gate-recomp) - Linux Setup Script
# Clones the ReXGlue SDK (v0.10.0), initializes submodules, applies patches,
# and clones DiligentCore for native Vulkan rendering.
# ==============================================================================

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SDK_DIR="${ROOT_DIR}/thirdparty/rexglue-sdk"
DILIGENT_DIR="${ROOT_DIR}/thirdparty/diligent-core"
TAG="v0.10.0"
PATCH_FILE="${ROOT_DIR}/patches/sdk/rexglue-sdk-v0.10.0.patch"

echo "==> Dante's Inferno - Linux Project Setup <=="

# Check toolchain prerequisites
for tool in git cmake ninja; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "ERROR: Missing required tool '$tool' in PATH." >&2
    exit 1
  fi
done

if ! command -v clang-22 >/dev/null 2>&1 && ! command -v clang >/dev/null 2>&1; then
  echo "ERROR: Clang compiler (clang-22 or clang) not found in PATH." >&2
  echo "Please run ./scripts/install_dantes_nobara.sh first." >&2
  exit 1
fi

echo "==> Prerequisites OK."

mkdir -p "${ROOT_DIR}/thirdparty"

# 1. Clone ReXGlue SDK
if [[ -d "${SDK_DIR}/.git" ]]; then
  echo "==> ReXGlue SDK already cloned at ${SDK_DIR}"
else
  echo "==> Cloning ReXGlue SDK (${TAG}) into thirdparty/rexglue-sdk..."
  git clone --branch "$TAG" --depth 1 https://github.com/rexglue/rexglue-sdk.git "$SDK_DIR"
fi

# 2. Initialize ReXGlue SDK submodules
echo "==> Initializing ReXGlue SDK submodules (this may take a few minutes)..."
git -C "$SDK_DIR" submodule update --init --recursive --depth 1

# 3. Apply ReXGlue SDK patches
if [[ -f "$PATCH_FILE" ]]; then
  echo "==> Checking and applying SDK patches..."
  if git -C "$SDK_DIR" apply --reverse --check "$PATCH_FILE" >/dev/null 2>&1; then
    echo "==> SDK patches already applied."
  else
    if git -C "$SDK_DIR" apply --check "$PATCH_FILE" >/dev/null 2>&1; then
      git -C "$SDK_DIR" apply "$PATCH_FILE"
      echo "==> SDK patches applied successfully."
    elif git -C "$SDK_DIR" apply --3way "$PATCH_FILE" >/dev/null 2>&1; then
      echo "==> SDK patches applied with 3-way merge."
    else
      echo "ERROR: Failed to apply SDK patch to ${SDK_DIR}." >&2
      exit 1
    fi
  fi
fi

# 4. Clone DiligentCore (for native Vulkan renderer)
if [[ -d "${DILIGENT_DIR}/.git" ]]; then
  echo "==> DiligentCore already cloned at ${DILIGENT_DIR}"
else
  echo "==> Cloning DiligentCore into thirdparty/diligent-core..."
  git clone --depth 1 --recurse-submodules https://github.com/DiligentGraphics/DiligentCore.git "$DILIGENT_DIR"
fi

echo ""
echo "==> Setup complete!"
echo "Next step: Run ./scripts/build_linux.sh to build the ReXGlue SDK and Vulkan plugin."
