FROM scratch
# KubeVirt runs qemu as uid 107 inside the launcher pod; set ownership/mode here
# so no extra RUN layer (and no builder stage) is needed. Requires BuildKit/buildx.
COPY --chown=107:107 --chmod=0440 out/ubuntu-noble-golden.qcow2 /disk/ubuntu-noble.img
