# Security Policy

## Supported Versions

This project publishes a rolling container image built from the `main` branch and from
`v*` release tags. Only the most recently published image is supported with security
updates; a weekly scheduled build re-scans that image against newly disclosed CVEs.

| Version | Supported |
| ------- | --------- |
| `latest` / newest `v*` tag | :white_check_mark: |
| older tags / `sha-*` builds | :x: |

## Reporting a Vulnerability

Please report suspected vulnerabilities **privately** — do not open a public issue.

Use GitHub's private vulnerability reporting for this repository:
<https://github.com/igladun-oss/ubuntu-nvidia-containerdisk/security/advisories/new>

Include the affected image tag or commit, a description of the issue, and steps to
reproduce. You can expect an acknowledgement within 7 days. Once a fix is available a new
image is published and the advisory is disclosed publicly.

## Supply-chain assurances

Every published image ships with:

- A CycloneDX SBOM, attested against the image digest.
- Trivy vulnerability scanning of the baked disk, captured in the CycloneDX SBOM.
- GitHub Actions pinned to full-length commit SHAs and kept current by Dependabot.
- The upstream Ubuntu base image verified against its published SHA256 checksum.
- CodeQL analysis of the CI workflows and OpenSSF Scorecard monitoring.
