# A builder stage exists only to set filesystem modes that COPY --chmod cannot
# express: --chmod applies ONE mode to the file AND the implicitly-created
# /disk directory, and a directory without the execute (search) bit breaks
# CDI's pullMethod=node import — its file server (uid 107) can *list* /disk but
# gets EACCES opening the qcow2, which Go's http.FileServer surfaces as a 403
# to the importer. The directory needs 0555; the disk file itself stays 0444.
FROM busybox:1.36-uclibc AS staging
COPY out/ubuntu-noble-golden.qcow2 /staging/disk/ubuntu-noble.img
RUN chown -R 107:107 /staging/disk \
    && chmod 0555 /staging/disk \
    && chmod 0444 /staging/disk/ubuntu-noble.img

FROM scratch
# KubeVirt runs qemu as uid 107 inside the launcher pod; 107:107 ownership is
# the containerDisk convention. Copying the staging *parent's contents* (note
# the trailing slash) preserves /disk itself with its 0555 107:107 from above —
# COPY --from=…/disk /disk would recreate /disk as root 0755 instead.
COPY --from=staging /staging/ /
