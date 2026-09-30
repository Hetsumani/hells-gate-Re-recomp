#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Dante's Inferno (hells-gate-recomp) - Nobara / Fedora Dependency Installer
# Installs toolchain, Vulkan, and graphics/audio development dependencies via DNF.
# ==============================================================================

if [[ ! -r /etc/os-release ]]; then
  echo "ERROR: Could not detect distribution (/etc/os-release missing)." >&2
  exit 1
fi

. /etc/os-release

echo "==> Detected distribution: ${PRETTY_NAME:-Unknown}"

if [[ "${ID:-}" != "nobara" && "${ID_LIKE:-}" != *"fedora"* && "${ID_LIKE:-}" != *"rhel"* ]]; then
  echo "WARNING: This script is intended for Nobara / Fedora-based systems."
  echo "Detected ID=${ID:-unknown}. Proceeding anyway..."
fi

echo "==> Updating repository metadata..."
sudo dnf check-update || true

echo "==> Installing build tools..."
sudo dnf install -y \
  gcc \
  gcc-c++ \
  make \
  cmake \
  ninja-build \
  pkgconf \
  pkgconf-pkg-config \
  git \
  python3 \
  wget

echo "==> Installing LLVM / Clang toolchain..."
sudo dnf install -y \
  clang \
  lld \
  llvm \
  libcxx-devel \
  libcxxabi-devel

echo "==> Installing graphics, windowing, and audio libraries..."
sudo dnf install -y \
  gtk3-devel \
  libX11-devel \
  libXext-devel \
  libXrandr-devel \
  libXcursor-devel \
  libXi-devel \
  libXinerama-devel \
  libXtst-devel \
  libXScrnSaver-devel \
  libxcb-devel \
  libxkbcommon-devel \
  wayland-devel \
  wayland-protocols-devel \
  alsa-lib-devel \
  pulseaudio-libs-devel \
  vulkan-headers \
  vulkan-loader-devel

echo ""
echo "================ Toolchain Verification ================"
if command -v clang-22 >/dev/null 2>&1; then
  clang-22 --version | head -n 1
elif command -v clang >/dev/null 2>&1; then
  clang --version | head -n 1
fi

cmake --version | head -n 1
ninja --version
python3 --version
echo "========================================================"
echo "==> Nobara dependencies installed successfully!"
echo "==> Next step: run ./setup.sh to clone ReXGlue SDK & DiligentCore."
