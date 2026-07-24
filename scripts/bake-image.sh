#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
WORKDIR="${WORKDIR:-${REPO_ROOT}/out}"

BASE_IMG_URL="${BASE_IMG_URL:-https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img}"
BASE_IMG="${WORKDIR}/ubuntu-noble-base.qcow2"
GOLD_IMG="${WORKDIR}/ubuntu-noble-golden.qcow2"
SEED_ISO="${WORKDIR}/seed.iso"
UEFI_VARS="${WORKDIR}/OVMF_VARS.fd"

DISK_SIZE="${DISK_SIZE:-100G}"
QEMU_MEM="${QEMU_MEM:-8192}"
QEMU_SMP="${QEMU_SMP:-4}"

CLOUD_INIT_DIR="${CLOUD_INIT_DIR:-${REPO_ROOT}/cloud-init}"
USER_DATA="${USER_DATA:-${CLOUD_INIT_DIR}/user-data}"
META_DATA="${META_DATA:-${CLOUD_INIT_DIR}/meta-data}"

need() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing dependency: $1" >&2
    exit 1
  }
}

find_qemu_firmware() {
  local dir
  local code
  local vars

  for dir in \
    /usr/share/OVMF \
    /usr/share/ovmf \
    /usr/share/qemu \
    /opt/homebrew/Cellar/qemu/*/share/qemu \
    /opt/homebrew/share/qemu \
    /usr/local/Cellar/qemu/*/share/qemu \
    /usr/local/share/qemu
  do
    for code in OVMF_CODE_4M.fd OVMF_CODE.fd ovmf_code_x64.bin edk2-x86_64-code.fd; do
      for vars in OVMF_VARS_4M.fd OVMF_VARS.fd ovmf_vars_x64.bin edk2-i386-vars.fd; do
        if [ -f "${dir}/${code}" ] && [ -f "${dir}/${vars}" ]; then
          QEMU_UEFI_CODE="${dir}/${code}"
          QEMU_UEFI_VARS_TEMPLATE="${dir}/${vars}"
          return 0
        fi
      done
    done
  done

  return 1
}

echo "[1/6] Checking local dependencies..."
need curl
need qemu-img
need mkisofs
need qemu-system-x86_64
find_qemu_firmware || {
  echo "Missing OVMF/QEMU firmware files." >&2
  exit 1
}

# Use hardware KVM acceleration when the runner exposes a writable /dev/kvm
# (Blacksmith runners do); fall back to slow-but-correct TCG emulation otherwise.
QEMU_ACCEL="tcg"
if [ -w /dev/kvm ]; then
  QEMU_ACCEL="kvm"
fi
echo "QEMU acceleration: ${QEMU_ACCEL}"

mkdir -p "${WORKDIR}"

test -f "${USER_DATA}" || {
  echo "Missing cloud-init user-data: ${USER_DATA}" >&2
  exit 1
}
test -f "${META_DATA}" || {
  echo "Missing cloud-init meta-data: ${META_DATA}" >&2
  exit 1
}

echo "[2/6] Downloading Ubuntu base image if needed..."
if [ ! -f "${BASE_IMG}" ]; then
  curl -fL -o "${BASE_IMG}" "${BASE_IMG_URL}"
fi

echo "[3/6] Creating fresh golden qcow2..."
cp "${BASE_IMG}" "${GOLD_IMG}"
qemu-img resize "${GOLD_IMG}" "${DISK_SIZE}"

echo "[4/6] Creating cloud-init seed ISO..."
rm -f "${SEED_ISO}" "${UEFI_VARS}"
mkisofs \
  -output "${SEED_ISO}" \
  -volid cidata \
  -joliet \
  -rock \
  -graft-points \
  user-data="${USER_DATA}" \
  meta-data="${META_DATA}" >/dev/null
cp "${QEMU_UEFI_VARS_TEMPLATE}" "${UEFI_VARS}"

echo "[5/6] Booting QEMU to bake the image..."
qemu-system-x86_64 \
  -machine q35 \
  -accel "${QEMU_ACCEL}" \
  -smp "${QEMU_SMP}" \
  -m "${QEMU_MEM}" \
  -drive if=pflash,format=raw,readonly=on,file="${QEMU_UEFI_CODE}" \
  -drive if=pflash,format=raw,file="${UEFI_VARS}" \
  -drive file="${GOLD_IMG}",if=virtio \
  -drive file="${SEED_ISO}",format=raw,if=virtio \
  -netdev user,id=net0 \
  -device virtio-net-pci,netdev=net0 \
  -nographic

echo "[6/6] Sparsify + compress golden qcow2..."
qemu-img convert -O qcow2 -c -o compat=1.1 "${GOLD_IMG}" "${GOLD_IMG}.min"
mv -f "${GOLD_IMG}.min" "${GOLD_IMG}"
qemu-img info "${GOLD_IMG}"

echo "Golden image baked at ${GOLD_IMG}"
