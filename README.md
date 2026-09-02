# ApexKernel for Xiaomi SM6250 (Miatoll)

Custom, high-performance Linux 4.14 kernel for Xiaomi SM6250 devices (curtana, curtanain, gram, joyeuse, excalibur), optimized for gaming, responsiveness, 4GB RAM multitasking, and built-in root.

---

## Device & Platform Specs

- **SoC**: Qualcomm Snapdragon 720G / 730 / 732G (SM6250 / atoll)
- **Linux Base**: 4.14.203
- **Target OS**: Android 11 (LineageOS 18.1 / AOSP)
- **Target Defconfig**: `cust_defconfig`
- **Supported Devices (Unified Miatoll)**:
  - Redmi Note 9 Pro / Pro Max (`curtana` / `curtanain` / `excalibur`)
  - Redmi Note 9S (`curtana`)
  - POCO M2 Pro (`gram`)
  - Redmi Note 9 Pro Global (`joyeuse`)

---

## Toolchain Requirements

To build this kernel without compilation errors or LLVM mismatch issues, use **LLVM / Clang 18+**:

- **Recommended Clang**: [Neutron Clang 18+](https://github.com/Neutron-Toolchains/antman) (or AOSP Clang `clang-r487747` / Proton Clang 13+)
- **Host Tools**: `clang`, `ld.lld`, `llvm-ar`, `llvm-nm`, `llvm-objcopy`, `llvm-objdump`, `llvm-strip`
- **Cross Compilers**:
  - 64-bit: `aarch64-linux-gnu-`
  - 32-bit (vDSO/compat): `arm-linux-gnueabi-`

---

## Standalone Build Instructions

### 1. Setup Toolchain Environment

```bash
export TOOLCHAIN_DIR="/path/to/clang"
export PATH="${TOOLCHAIN_DIR}/bin:$PATH"
```

### 2. Compile Kernel & DTBs

```bash
mkdir -p out

make O=out ARCH=arm64 SUBARCH=arm64 cust_defconfig

make -j$(nproc --all) O=out \
    ARCH=arm64 \
    SUBARCH=arm64 \
    CC=clang \
    LD=ld.lld \
    AR=llvm-ar \
    NM=llvm-nm \
    OBJCOPY=llvm-objcopy \
    OBJDUMP=llvm-objdump \
    STRIP=llvm-strip \
    CROSS_COMPILE=aarch64-linux-gnu- \
    CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
    Image.gz-dtb dtbs
```

### 3. Build Artifacts
- **Kernel Image**: `out/arch/arm64/boot/Image.gz-dtb`
- **Device Tree Blob (DTB)**: `out/arch/arm64/boot/dts/qcom/cust-atoll-ab.dtb`

> **Note on AnyKernel3 packaging**: SM6250 recovery flashers expect `Image.gz-dtb` and `dtb`. Do **not** package standalone `Image.gz` in the zip.

---

## Integrating into ROM Source (BoardConfig.mk)

If building inline as part of an Android ROM tree (e.g. LineageOS, PixelExperience, crDroid, Evolution X), configure your device tree `BoardConfig.mk` / `BoardConfigCommon.mk`:

```makefile
# Kernel Source & Configuration
TARGET_KERNEL_ARCH := arm64
TARGET_KERNEL_HEADER_ARCH := arm64
TARGET_KERNEL_SOURCE := kernel/xiaomi/sm6250
TARGET_KERNEL_CONFIG := cust_defconfig

# Output Kernel Image
BOARD_KERNEL_IMAGE_NAME := Image.gz-dtb

# Clang Compilation Flags
TARGET_KERNEL_CLANG_COMPILE := true
TARGET_KERNEL_LLVM_BINUTILS := true

# DTB Configuration
TARGET_KERNEL_ADDITIONAL_FLAGS := \
    DTC_EXT=$(shell pwd)/prebuilts/misc/linux-x86/dtc/dtc
```

---

## Kernel Features & Architecture

### 1. Root & System
- **In-Tree MamboSU (KernelSU `xxksu`)**: Integrated directly in `drivers/kernelsu` with non-intrusive manual hooks in `fs/exec.c`, `fs/open.c`, and `fs/stat.c`.

### 2. Memory & 4GB RAM Optimization
- **ZRAM Compression**: Default compressor hardcoded to **LZ4** for 3–4x faster decompression.
- **Swappiness = 100**: Proactively compresses cold background memory to keep 1.5GB–2GB of raw physical RAM free for heavy games.
- **Single-Page Swap (`page_cluster = 0`)**: Eliminates read-ahead latency on swap-in.
- **Allocation Watermark**: `watermark_scale_factor = 100` for early `kswapd` wake-up to prevent direct reclaim frame drops.
- **VFS Cache**: `vfs_cache_pressure = 50` to maintain game asset directory trees and inodes in memory.

### 3. Networking & Ping
- **BBRplus**: High-throughput, low-loss TCP congestion control driver enabled as default.
- **Fair Queueing**: `CONFIG_NET_SCH_FQ=y` and `CONFIG_NET_SCH_FQ_CODEL=y` to eliminate bufferbloat.
- **Low Ping**: Minimum delayed ACK timeout reduced to 10ms (`HZ/100`).

### 4. Storage & Display Pacing
- **Dynamic Fsync 2.0**: Automatically suspends synchronous storage flushes while screen is active during gameplay; flushes on screen-off.
- **UFS 2.1 Tuning**: 512KB queue readahead and 100ms clock gating delay for seamless continuous asset streaming.

### 5. CPU & GPU Performance
- **WALT Scheduler**: Tuned group upmigration (75% / 60%) and initial task load (35%) to immediately schedule game rendering loops on Big Cortex-A76 cores.
- **Touch Input Boost**: 66ms boost (1.2GHz Little / 1.7GHz Big) on touch events.
- **Devfreq Memlat**: 4ms sampling interval for rapid LPDDR4X bandwidth scaling.
- **Compiler Optimizations**: Native Cortex-A76 microarchitecture flags (`-march=armv8.2-a+crypto+fp16+dotprod+rcpc -mtune=cortex-a76 -falign-functions=32`).

---

## Maintainer

- **Maintainer**: [@Xx_KaKe_xX](https://github.com/KaKE-567)
