#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Dante's Inferno (hells-gate-recomp) - Linux Build Script
# Configures and builds the ReXGlue CLI, Vulkan GPU plugin, and full game
# (when game/default.xex is present).
# ==============================================================================

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

BUILD_TYPE="Release"
for arg in "$@"; do
  case "$arg" in
    --debug)
      BUILD_TYPE="Debug"
      ;;
    --release)
      BUILD_TYPE="Release"
      ;;
    *)
      echo "Unknown option: $arg"
      echo "Usage: $0 [--release | --debug]"
      exit 1
      ;;
  esac
done

BUILD_TYPE_LOWER="$(echo "$BUILD_TYPE" | tr '[:upper:]' '[:lower:]')"
BUILD_DIR="${ROOT_DIR}/out/build/linux-${BUILD_TYPE_LOWER}"

# Find Clang 22 or fallback to clang on PATH
if command -v clang-22 >/dev/null 2>&1; then
  CC="$(command -v clang-22)"
elif command -v clang >/dev/null 2>&1; then
  CC="$(command -v clang)"
else
  echo "ERROR: Clang compiler not found. Run ./scripts/install_dantes_nobara.sh first." >&2
  exit 1
fi

if command -v clang++-22 >/dev/null 2>&1; then
  CXX="$(command -v clang++-22)"
elif command -v clang++ >/dev/null 2>&1; then
  CXX="$(command -v clang++)"
else
  echo "ERROR: Clang++ compiler not found. Run ./scripts/install_dantes_nobara.sh first." >&2
  exit 1
fi

echo "========================================================"
echo " Dante's Inferno - Linux Build (${BUILD_TYPE})"
echo " C Compiler:   $CC"
echo " C++ Compiler: $CXX"
echo " Build Dir:    $BUILD_DIR"
echo "========================================================"

# Check if SDK has been set up
if [[ ! -d "${ROOT_DIR}/thirdparty/rexglue-sdk" ]]; then
  echo "==> thirdparty/rexglue-sdk not found. Running ./setup.sh..."
  ./setup.sh
fi

# 1. Configure CMake
echo "==> Configuring CMake..."
cmake -B "$BUILD_DIR" \
  -G Ninja \
  -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
  -DCMAKE_C_COMPILER="$CC" \
  -DCMAKE_CXX_COMPILER="$CXX" \
  -DCMAKE_CXX_FLAGS="-stdlib=libstdc++ -I${ROOT_DIR}/thirdparty/rexglue-sdk/thirdparty/imgui -mssse3 -mavx2" \
  -DREXSDK_DIR="${ROOT_DIR}/thirdparty/rexglue-sdk"

# 2. Build ReXGlue SDK CLI
echo "==> Building ReXGlue CLI..."
cmake --build "$BUILD_DIR" --target rexglue

# 3. Build Xenos Vulkan GPU plugin
echo "==> Building ReXGlue Xenos Vulkan GPU plugin..."
cmake --build "$BUILD_DIR" --target rexgpu-xenos

# 4. Copy Vulkan plugin shared libraries
echo "==> Copying ReXGlue runtime shared libraries..."
mkdir -p "$BUILD_DIR"
if compgen -G "${ROOT_DIR}/thirdparty/rexglue-sdk/out/linux-amd64/lib*.so" > /dev/null; then
  cp "${ROOT_DIR}"/thirdparty/rexglue-sdk/out/linux-amd64/lib*.so "$BUILD_DIR/"
fi

# 5. Check for game files to compile the full port
if [[ -f "${ROOT_DIR}/game/default.xex" ]]; then
  echo "==> Found game/default.xex! Proceeding with recompilation..."

  # Backup manifest and CMakeLists.txt (rexglue init --force overwrites both)
  cp dantes_inferno_manifest.toml dantes_inferno_manifest.toml.back
  cp CMakeLists.txt CMakeLists.txt.back

  echo "==> Regenerating SDK-managed project files..."
  "${ROOT_DIR}/thirdparty/rexglue-sdk/out/linux-amd64/rexglue" init \
    --force \
    --project-name dantes_inferno \
    --project-root . \
    --xex-path game/default.xex \
    --game-root game

  echo "==> Restoring manifest and project customizations..."
  cp dantes_inferno_manifest.toml.back dantes_inferno_manifest.toml
  cp CMakeLists.txt.back CMakeLists.txt

  echo "==> Generating recompiled C++ sources..."
  cmake -B "$BUILD_DIR" \
    -G Ninja \
    -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
    -DCMAKE_C_COMPILER="$CC" \
    -DCMAKE_CXX_COMPILER="$CXX" \
    -DCMAKE_CXX_FLAGS="-stdlib=libstdc++ -I${ROOT_DIR}/thirdparty/rexglue-sdk/thirdparty/imgui -mssse3 -mavx2" \
    -DREXSDK_DIR="${ROOT_DIR}/thirdparty/rexglue-sdk"

  cmake --build "$BUILD_DIR" --target dantes_inferno_codegen

  echo "==> Applying generated code patches..."
  python3 patches/generated/apply_generated_patches.py

  echo "==> Reconfiguring build system with generated sources..."
  cp dantes_inferno_manifest.toml.back dantes_inferno_manifest.toml
  cp CMakeLists.txt.back CMakeLists.txt
  cmake -B "$BUILD_DIR" \
    -G Ninja \
    -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
    -DCMAKE_C_COMPILER="$CC" \
    -DCMAKE_CXX_COMPILER="$CXX" \
    -DCMAKE_CXX_FLAGS="-stdlib=libstdc++ -I${ROOT_DIR}/thirdparty/rexglue-sdk/thirdparty/imgui -mssse3 -mavx2" \
    -DREXSDK_DIR="${ROOT_DIR}/thirdparty/rexglue-sdk"

  echo "==> Compiling Dante's Inferno Linux binary..."
  cmake --build "$BUILD_DIR" --target dantes_inferno

  rm -f dantes_inferno_manifest.toml.back CMakeLists.txt.back

  echo ""
  echo "========================================================"
  echo " Build Succeeded!"
  echo " Executable: ${BUILD_DIR}/dantes_inferno"
  echo " Run via:    ./scripts/dantes_inferno_exe.sh"
  echo "========================================================"
else
  echo ""
  echo "========================================================"
  echo " ReXGlue SDK CLI and Vulkan GPU plugin built successfully!"
  echo "========================================================"
  echo ""
  echo " NOTE: 'game/default.xex' was not found."
  echo " The compilation tools are ready. When you have your game dump:"
  echo "   1. Place your extracted Xbox 360 game files in 'game/'"
  echo "   2. Ensure the entrypoint executable is at 'game/default.xex'"
  echo "   3. Run this script again: ./scripts/build_linux.sh"
  echo "========================================================"
fi
