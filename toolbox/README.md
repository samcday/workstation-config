# toolbox

Dev tools live in [toolbox](https://containertoolbx.org/) containers, not in
the host image. The Silverblue host image is moving toward stock Fedora. The
tools that used to be layered onto the host are built into container images in
this directory. Pull a new image and create a container to update the tools.
No reboot is needed.

toolbox is **not** a security sandbox. A toolbox container shares `$HOME`, the
host network, the host PID namespace, and `/dev` with the host. It isolates
packages from the OS, not you from the tools. Changes to shared files survive
container removal, so do not use toolbox to run untrusted code.

toolbox is the supported tool. Distrobox is not supported.

## Images

| Image | Purpose | Typical container name |
| --- | --- | --- |
| `ghcr.io/samcday/workstation-config/toolbox:main` | General dev CLIs and toolchains | `dev` |
| `ghcr.io/samcday/workstation-config/toolbox-phosh:main` | phosh, phoc, and phrog development | `phosh` |
| `ghcr.io/samcday/workstation-config/toolbox-kernel:main` | Linux kernel development, virtme-ng | `kernel` |
| `ghcr.io/samcday/workstation-config/toolbox-fedpkg:main` | Fedora packaging, mock | `fedpkg` |

The base image builds from `toolbox/Containerfile`, with its package list in
`toolbox/base/packages.list`. Each variant builds from
`toolbox/<variant>/Containerfile` on top of the base, so it contains
everything in `dev`.

The [Toolbox images workflow](../.github/workflows/toolbox.yml) builds the
base and all three variants when `toolbox/`, that workflow, or
`.github/setup-storage` changes. It also runs weekly on Monday at 09:22 UTC.
Manual runs rebuild all four toolbox images.

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

## Try a draft PR image

CI publishes draft images under `:pr-<number>`. That tag moves when CI builds
the PR again. Use the digest reference from the successful image job's summary
to try one exact build.

Choose an unused container name. Keep your usual container while you test the
candidate. On the host, replace `<digest>` with the digest from CI:

```shell
image=ghcr.io/samcday/workstation-config/toolbox@sha256:<digest>
podman pull "$image"
toolbox create dev-trial --image "$image"
toolbox enter dev-trial
```

For a variant, use its image name and a separate trial container name.
A digest identifies the image contents. It does not verify the cosign signature.
Run your usual builds in the trial container before you replace your daily one.

## Update

First create and test a new container, as in the draft trial above. Save any
needed files that exist only inside the old container. If you want to replace
`dev` after the trial, stop its sessions and run these commands on the host:

```shell
podman pull ghcr.io/samcday/workstation-config/toolbox:main
toolbox rm dev
toolbox create dev --image ghcr.io/samcday/workstation-config/toolbox:main
```

Container removal deletes its local packages, files, and caches. Files in the
shared `$HOME` remain. Toolbox does not refresh existing containers when you
pull an image, and it does not update images automatically.

`toolbox rm` and `toolbox rmi` exit with 0 even when they fail
([toolbox#1731](https://github.com/containers/toolbox/issues/1731)). Read the
output, not the exit code. Remove the old image afterwards:
`toolbox rmi <old-image-id>`, or `podman image prune`.

## Running tools from the host

The tools exist only inside the containers. From a host shell, run one with
`toolbox run -c dev -- <command>`. It runs in the current directory (which
must be under `$HOME`) with the host's `TERM`, `DISPLAY`, `WAYLAND_DISPLAY`,
`SSH_AUTH_SOCK`, and `XDG_*` variables. Other variables are not forwarded.
Agents working on this machine are expected to know this and prefix commands
themselves; there are no wrappers on the host.

## Local build

```shell
podman build -t workstation-toolbox:test toolbox/
```

A variant, built on top of the local base:

```shell
podman build --build-arg BASE=localhost/workstation-toolbox:test -t workstation-toolbox-phosh:test toolbox/phosh/
```

## Add packages

Add a line to `toolbox/base/packages.list`, or to the variant's
`packages.list`. Open a PR. CI builds the base and all toolbox variants.
Nothing on a machine changes until you pull the new image and recreate the
container. No reboot is involved.
