#!/usr/bin/env bash
set -e

# Configuration
KERNEL_DIR="$(pwd)"
TOOLCHAIN_DIR="/workspaces/toolchains/neutron"
DEFCONFIG="cust_defconfig"
OUT_DIR="${KERNEL_DIR}/out"
ANYKERNEL_DIR="/workspaces/AnyKernel3"
ZIP_DIR="${OUT_DIR}/zip"
DATE="$(date +'%Y%m%d-%H%M')"
ZIP_NAME="ApexKernel-SM6250-${DATE}.zip"

echo "=== ApexKernel Builder (Neutron Clang 18) ==="
echo "Defconfig: ${DEFCONFIG}"
echo "Toolchain: ${TOOLCHAIN_DIR}"
echo "Jobs: $(nproc --all)"

# Export PATH
export PATH="${TOOLCHAIN_DIR}/bin:$PATH"

# Build flags
MAKE_ARGS=(
    O="${OUT_DIR}"
    ARCH=arm64
    SUBARCH=arm64
    CC=clang
    CROSS_COMPILE=aarch64-linux-gnu-
    CROSS_COMPILE_ARM32=arm-linux-gnueabi-
    LD=ld.lld
    AR=llvm-ar
    NM=llvm-nm
    OBJCOPY=llvm-objcopy
    OBJDUMP=llvm-objdump
    STRIP=llvm-strip
)

# 1. Defconfig
echo "--> Generating defconfig..."
make "${MAKE_ARGS[@]}" "${DEFCONFIG}"

# 2. Build kernel
echo "--> Building kernel..."
make -j"$(nproc --all)" "${MAKE_ARGS[@]}" Image.gz-dtb dtbs

# 3. Check build artifact
KERNEL_IMG="${OUT_DIR}/arch/arm64/boot/Image.gz-dtb"
if [ ! -f "${KERNEL_IMG}" ]; then
    echo "ERROR: Kernel image not found at ${KERNEL_IMG}!"
    exit 1
fi
echo "--> Kernel build completed successfully: ${KERNEL_IMG}"

# 4. AnyKernel3 Packaging
echo "--> Packaging with AnyKernel3..."
mkdir -p "${ZIP_DIR}"
rm -f "${ANYKERNEL_DIR}/Image.gz-dtb" "${ANYKERNEL_DIR}/Image.gz" "${ANYKERNEL_DIR}/dtb" "${ANYKERNEL_DIR}/dtbo.img" "${ANYKERNEL_DIR}/"*.zip 2>/dev/null || true
cp "${KERNEL_IMG}" "${ANYKERNEL_DIR}/Image.gz-dtb"
[ -f "${OUT_DIR}/arch/arm64/boot/dts/qcom/cust-atoll-ab.dtb" ] && cp "${OUT_DIR}/arch/arm64/boot/dts/qcom/cust-atoll-ab.dtb" "${ANYKERNEL_DIR}/dtb"

cd "${ANYKERNEL_DIR}"
zip -r9 "${ZIP_DIR}/${ZIP_NAME}" * -x .git README.md *placeholder
cd "${KERNEL_DIR}"

echo "--> AnyKernel3 zip generated at: ${ZIP_DIR}/${ZIP_NAME}"

# 5. Optional Gofile upload
if [ "$1" == "--upload" ] || [ "$1" == "-u" ]; then
    echo "--> Uploading to Gofile..."
    SERVER=$(curl -s https://api.gofile.io/servers | grep -oP '"name":"\K[^"]+' | head -n 1)
    if [ -n "${SERVER}" ]; then
        RESPONSE=$(curl -F "file=@${ZIP_DIR}/${ZIP_NAME}" "https://${SERVER}.gofile.io/contents/uploadfile")
        DOWNLOAD_URL=$(echo "${RESPONSE}" | grep -oP '"downloadPage":"\K[^"]+' || echo "")
        if [ -n "${DOWNLOAD_URL}" ]; then
            echo "=========================================="
            echo " Download URL: ${DOWNLOAD_URL}"
            echo "=========================================="
        else
            echo "Upload completed with response: ${RESPONSE}"
        fi
    else
        echo "Could not resolve Gofile server."
    fi
fi
