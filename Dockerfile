FROM scratch
# KubeVirt runs qemu as uid 107 inside the launcher pod; set ownership/mode here
# so no extra RUN layer (and no builder stage) is needed. Requires BuildKit/buildx.
# Mode must be world-readable (0444, not 0440): CDI's pullMethod=node import runs
# a file server against this image as a non-107 uid, and a group-only mode makes
# it answer 403 to its own importer (Go http.FileServer maps EACCES to 403).
COPY --chown=107:107 --chmod=0444 out/ubuntu-noble-golden.qcow2 /disk/ubuntu-noble.img
