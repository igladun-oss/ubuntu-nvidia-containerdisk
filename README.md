# Ubuntu NVIDIA ContainerDisk for KubeVirt

[![Build And Publish](https://github.com/igladun-oss/ubuntu-nvidia-containerdisk/actions/workflows/build-and-publish.yml/badge.svg)](https://github.com/igladun-oss/ubuntu-nvidia-containerdisk/actions/workflows/build-and-publish.yml)
[![CodeQL](https://github.com/igladun-oss/ubuntu-nvidia-containerdisk/actions/workflows/codeql.yml/badge.svg)](https://github.com/igladun-oss/ubuntu-nvidia-containerdisk/actions/workflows/codeql.yml)
[![OpenSSF Scorecard](https://api.securityscorecards.dev/projects/github.com/igladun-oss/ubuntu-nvidia-containerdisk/badge)](https://scorecard.dev/viewer/?uri=github.com/igladun-oss/ubuntu-nvidia-containerdisk)

Boot GPU-passthrough VMs with a working `nvidia-smi` — NVIDIA drivers and the CUDA dev toolkit are pre-baked into the image, so there are no first-boot installs.

This repo bakes an Ubuntu 24.04 cloud image into a [KubeVirt](https://kubevirt.io/) `containerDisk` (a qcow2 shipped inside an OCI image) and publishes it to GHCR.

## What's inside

- **Ubuntu 24.04 LTS (Noble)** cloud image
- **NVIDIA driver 580.105.08** — headless, kernel modules preloaded, GPU-gated systemd load (modules load only when a GPU is present)
- **CUDA 13.0 dev toolkit** (`cuda-toolkit-13-0`) — `nvcc`, headers, and dev libraries (plus the runtime), with `nvcc` on `PATH` via `/etc/profile.d/cuda.sh`
- **NVIDIA Container Toolkit**
- **cloud-init** ready
- Single pinned kernel (no kernel/module skew — the VM cannot boot a kernel that lacks the NVIDIA module)
- 100 GiB virtual disk, sparsified and compressed qcow2

## Quick start

Reference the image directly as a `containerDisk` volume:

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: gpu-vm
spec:
  running: true
  template:
    spec:
      domain:
        devices:
          disks:
            - name: rootdisk
              disk:
                bus: virtio
        # attach a GPU via a permitted hostDevice / gpus entry as configured on your cluster
      volumes:
        - name: rootdisk
          containerDisk:
            image: ghcr.io/igladun-oss/ubuntu-nvidia-containerdisk:latest
```

## Tags

| Tag | Meaning |
|---|---|
| `latest` | Latest build from the default branch |
| `main` | Same as `latest`, built on every push to `main` |
| `sha-<short>` | Immutable build for a specific commit |
| `v*` | Release builds from `v*` git tags |

## Build locally

Needs `curl`, `genisoimage` (or another `mkisofs` provider), `qemu-system-x86_64`, `qemu-img`, OVMF firmware, and Docker with Buildx:

```bash
./scripts/build-image.sh
```

The bake uses hardware KVM acceleration when `/dev/kvm` is writable and falls back to software emulation otherwise.

## Security

Supply-chain hardening and continuous scanning are built into CI:

- **Vulnerability scanning** — the baked qcow2 is scanned with [Trivy](https://github.com/aquasecurity/trivy) (VM mode) and results are uploaded to GitHub [code scanning](https://github.com/igladun-oss/ubuntu-nvidia-containerdisk/security/code-scanning); a weekly scheduled build re-scans the published image against new CVEs.
- **SBOM + attestation** — a CycloneDX SBOM is generated and cryptographically attested against the pushed image digest.
- **Base-image integrity** — the upstream Ubuntu cloud image is verified against its published SHA256 checksum before baking.
- **Pinned actions** — all GitHub Actions are pinned to full-length commit SHAs and kept current by Dependabot.
- **Static analysis** — [CodeQL](https://github.com/igladun-oss/ubuntu-nvidia-containerdisk/actions/workflows/codeql.yml) analyzes the CI workflows and [OpenSSF Scorecard](https://scorecard.dev/viewer/?uri=github.com/igladun-oss/ubuntu-nvidia-containerdisk) tracks the overall posture.

To report a vulnerability, see [`SECURITY.md`](SECURITY.md).
