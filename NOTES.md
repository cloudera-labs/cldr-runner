# Ansible Builder - Execution Environment

# Ansible Builder

Rebuild the `ansible-builder` image to get to the latest -- `1.2.0` -- version; the current image is *10 months old* and is release `v1.0.0`.  

1. Clone cloudera-labs/ansible-builder
1. Check out release 1.2.0 branch
1. Build the image
   ```bash
    podman build --rm \
        -t ghcr.io/cloudera-labs/ansible-builder:1.2.0 \
        -f Containerfile \
        .
   ```
1. (Push the image to a remote registry if not using locally)
   ```bash
   podman login ghcr.io
   podman push ghcr.io/cloudera-labs/ansible-builder:1.2.0
   podman push ghcr.io/cloudera-labs/ansible-builder:latest
   ```

# Build cldr-runner

(Assumes a minimal Ansible setup with `ansible-builder` installed in the `venv`.)

1. Build `cldr-runner` using the instructions in [BUILDING](builder/BUILDING.md) document.
1. (Optionally) Push the image to a remote registry if not using locally

# Run the playbooks

These images are [Execution Environments](https://ansible-builder.readthedocs.io/en/stable/definition/#) and can be used as the `provision-isolation` container for `ansible-runner`. You can run commands directly from within the container itself, such as:

```bash
# Run inside the container ala cloudera-deploy V1
podman run -it ghcr.io/cloudera-labs/cldr-runner:latest /bin/bash

# Or locally with a specific tagged image
podman run -it localhost/cldr-runner:base-main /bin/bash
```
