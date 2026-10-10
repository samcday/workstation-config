# toolbox

Dev tools live in [toolbox](https://containertoolbx.org/) containers, not in
the host image. The Silverblue host image is moving toward stock Fedora. The
tools that used to be layered onto the host are built into container images in
this directory. One image pull updates the tools. No reboot is needed.

toolbox is **not** a security sandbox. A toolbox container shares `$HOME`, the
host network, the host PID namespace, and `/dev` with the host. It isolates
packages from the OS, not you from the tools.

toolbox is the supported tool. Distrobox is not supported.

## Images

| Image | Purpose | Typical container name |
| --- | --- | --- |
| `ghcr.io/samcday/workstation-config/toolbox:main` | General dev CLIs and toolchains | `dev` |
| `ghcr.io/samcday/workstation-config/toolbox-phosh:main` | phosh, phoc, and phrog development | `phosh` |
| `ghcr.io/samcday/workstation-config/toolbox-kernel:main` | Linux kernel development, virtme-ng | `kernel` |
| `ghcr.io/samcday/workstation-config/toolbox-fedpkg:main` | Fedora packaging, mock | `fedpkg` |

The base image builds from `toolbox/Containerfile`, with package lists in
`toolbox/base/packages.d/*.list`. The `phosh`, `kernel`, and `fedpkg` variants
are planned. Each variant builds from `toolbox/<variant>/Containerfile` on top
of the base, so it contains everything in `dev`.

## First-time setup

toolbox pulls the image during `create`:

```shell
toolbox create dev --image ghcr.io/samcday/workstation-config/toolbox:main
toolbox enter dev
```

Variants follow the same pattern:

```shell
toolbox create phosh --image ghcr.io/samcday/workstation-config/toolbox-phosh:main
```

Toolbox (0.0.99.6 and newer) passes the host NVIDIA driver and CUDA into the
container. You install nothing in the image and configure nothing.

## Update

```shell
podman pull ghcr.io/samcday/workstation-config/toolbox:main
toolbox rm -f dev
toolbox create dev --image ghcr.io/samcday/workstation-config/toolbox:main
```

Containers are disposable. State lives in `$HOME`, which the container shares
with the host. Recreation replaces only the tools in the image. Toolbox does
not refresh images automatically. Run these commands when a new image lands.

`toolbox rm` and `toolbox rmi` exit with 0 even when they fail
([toolbox#1731](https://github.com/containers/toolbox/issues/1731)). Read the
output, not the exit code. Remove the old image afterwards:
`toolbox rmi <old-image-id>`, or `podman image prune`.

## Host shims

`toolbox/shims/install.sh` writes a wrapper to `~/.local/bin/<bin>` for each
tool in the `dev` container. A wrapper runs
`exec toolbox run -c dev -- <bin> "$@"`. Host scripts and agents then use the
container tools without changes. Run the script again after you add tools.
`--prune` removes wrappers for tools that no longer exist in the container.

## Local build

```shell
podman build -t workstation-toolbox:test toolbox/
```

A variant, built on top of the local base:

```shell
podman build --build-arg BASE=localhost/workstation-toolbox:test -t workstation-toolbox-phosh:test toolbox/phosh/
```

## Add packages

Edit a `.list` file in `toolbox/base/packages.d/`, or add one for a variant.
Open a PR. CI builds every image. `/land` is not needed for toolbox-only
changes: the host changes only when you pull a new image, and no reboot is
required.
