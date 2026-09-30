# Building Dante's Inferno on Nobara Linux (Vulkan)

This guide explains how to build the native Linux Vulkan port of **Dante's Inferno** (`hells-gate-recomp`) on **Nobara Linux** (Fedora base).

---

## Prerequisites & Architecture

Nobara 44 includes modern development packages in its standard repositories:
- **Clang 22.1+ / LLD 22.1+** (`clang`, `lld`, `llvm`)
- **CMake 4.3+** and **Ninja 1.13+**
- **Vulkan Headers & Loader** (`vulkan-headers`, `vulkan-loader-devel`)
- **X11 / Wayland / Audio development libraries**

---

## Quick Start (Automated Scripts)

### 1. Install Dependencies
Run the Nobara installer script with `sudo`:
```bash
chmod +x ./scripts/install_dantes_nobara.sh
./scripts/install_dantes_nobara.sh
```

*(Or see the manual package list below if you prefer to install packages manually).*

### 2. Set Up the SDK & DiligentCore
Run the native Linux setup script (no PowerShell required):
```bash
chmod +x ./setup.sh
./setup.sh
```
This clones ReXGlue SDK v0.10.0, initializes its submodules, applies project patches, and clones DiligentCore for the native renderer.

### 3. Build SDK Tooling & Recompilation Engine
Run the build script:
```bash
chmod +x ./scripts/build_linux.sh
./scripts/build_linux.sh
```
This builds:
1. `rexglue` CLI (`thirdparty/rexglue-sdk/out/linux-amd64/rexglue`)
2. `rexgpu-xenos` Vulkan GPU plugin (`out/build/linux-release/librexgpu-xenos.so`)

### 4. Provide Game Files & Build the Full Game
When you have your legally extracted Xbox 360 copy of Dante's Inferno:
1. Place extracted game files into the `game/` folder.
2. Confirm that the main executable is at:
   ```text
   game/default.xex
   ```
3. Run `./scripts/build_linux.sh` again. It will automatically detect `game/default.xex`, run ReXGlue codegen, apply generated code patches, and compile the final native Linux executable:
   ```text
   out/build/linux-release/dantes_inferno
   ```

### 5. Run the Game
```bash
./scripts/dantes_inferno_exe.sh
```

---

## Manual Step-by-Step Instructions

If you prefer running each step manually without wrapper scripts:

### Step 1: Install Nobara DNF Packages
```bash
sudo dnf install -y \
  gcc gcc-c++ make cmake ninja-build pkgconf pkgconf-pkg-config git python3 wget \
  clang lld llvm libcxx-devel libcxxabi-devel \
  gtk3-devel libX11-devel libXext-devel libXrandr-devel libXcursor-devel \
  libXi-devel libXinerama-devel libXtst-devel libXScrnSaver-devel libxcb-devel \
  libxkbcommon-devel wayland-devel wayland-protocols-devel alsa-lib-devel \
  pulseaudio-libs-devel vulkan-headers vulkan-loader-devel
```

### Step 2: Clone ReXGlue SDK & Patches
```bash
mkdir -p thirdparty
git clone --branch v0.10.0 --depth 1 https://github.com/rexglue/rexglue-sdk.git thirdparty/rexglue-sdk
git -C thirdparty/rexglue-sdk submodule update --init --recursive --depth 1
git -C thirdparty/rexglue-sdk apply ../../patches/sdk/rexglue-sdk-v0.10.0.patch

# Clone DiligentCore for native renderer support
git clone --depth 1 --recurse-submodules https://github.com/DiligentGraphics/DiligentCore.git thirdparty/diligent-core
```

### Step 3: Configure CMake & Build Tooling
```bash
cmake -B out/build/linux-release \
  -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_COMPILER=/usr/bin/clang-22 \
  -DCMAKE_CXX_COMPILER=/usr/bin/clang++-22 \
  -DCMAKE_CXX_FLAGS="-stdlib=libstdc++ -I$(pwd)/thirdparty/rexglue-sdk/thirdparty/imgui -mssse3 -mavx2" \
  -DREXSDK_DIR=thirdparty/rexglue-sdk

cmake --build out/build/linux-release --target rexglue
cmake --build out/build/linux-release --target rexgpu-xenos
cp thirdparty/rexglue-sdk/out/linux-amd64/lib*.so ./out/build/linux-release/
```

### Step 4: Recompile Dante's Inferno (requires `game/default.xex`)
```bash
# 1. Backup manifest customizations
cp dantes_inferno_manifest.toml dantes_inferno_manifest.toml.back

# 2. Regenerate SDK project files
thirdparty/rexglue-sdk/out/linux-amd64/rexglue init \
  --force \
  --project-name dantes_inferno \
  --project-root . \
  --xex-path game/default.xex \
  --game-root game

# 3. Restore manifest
cp dantes_inferno_manifest.toml.back dantes_inferno_manifest.toml

# 4. Generate C++ sources
cmake -B out/build/linux-release \
  -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_COMPILER=/usr/bin/clang-22 \
  -DCMAKE_CXX_COMPILER=/usr/bin/clang++-22 \
  -DCMAKE_CXX_FLAGS="-stdlib=libstdc++ -I$(pwd)/thirdparty/rexglue-sdk/thirdparty/imgui -mssse3 -mavx2" \
  -DREXSDK_DIR=thirdparty/rexglue-sdk

cmake --build out/build/linux-release --target dantes_inferno_codegen

# 5. Apply generated-code patches
python3 patches/generated/apply_generated_patches.py

# 6. Build the final game binary
cp dantes_inferno_manifest.toml.back dantes_inferno_manifest.toml
cmake --build out/build/linux-release --target dantes_inferno
rm -f dantes_inferno_manifest.toml.back
```
