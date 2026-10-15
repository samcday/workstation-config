# toolbox

One [toolbox](https://containertoolbx.org/) image contains the general tools,
Phosh build dependencies, kernel toolchains, and Fedora packaging tools.
Use one container named `dev` for all of them. Pull a new image and create a
container to update the tools without a host reboot.

Toolbox is not a security sandbox. A toolbox container shares `$HOME`, the
host network, the host PID namespace, and `/dev` with the host. It isolates
packages from the OS, not you from the tools. Changes to shared files survive
container removal, so do not use toolbox to run untrusted code.

toolbox is the supported tool. Distrobox is not supported.

## Image

`ghcr.io/samcday/workstation-config/toolbox:main` builds from
[Containerfile](Containerfile), with one package list in
[packages.list](packages.list). There are no separate kernel, Phosh, or
packaging images to choose.

The [Toolbox image workflow](../.github/workflows/toolbox.yml) builds the
image when `toolbox/`, that workflow, or
`.github/setup-storage` changes. It also runs weekly on Monday at 09:22 UTC.
Manual runs rebuild the same image.

## First-time setup

Run these commands on the host, without `sudo`. The first `toolbox run`
initializes the container user. The `podman exec` command adds that user to
the container's `mock` group for Fedora packaging, not the host's group.

```shell
toolbox create dev --image ghcr.io/samcday/workstation-config/toolbox:main
toolbox run -c dev -- true
podman exec --user 0 dev usermod -aG mock "$(id -un)"
toolbox enter dev
```

Use the same `dev` container for [Phosh](guides/phosh.md),
[kernel development](guides/kernel.md), and
[Fedora packaging](guides/packaging.md).

Toolbox (0.0.99.6 and newer) passes the host NVIDIA driver and CUDA into the
container. You install nothing in the image and configure nothing.

## Try a draft PR image (optional)

Manual trials are optional. Landing needs successful CI, review, and merge
approval, not a local toolbox trial.
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

A digest identifies the image contents. It does not verify the cosign signature.
Run your usual builds in the trial container before you replace your daily one.
Add the trial user to `mock`, as in first-time setup, before testing packaging.

Existing `phosh`, `kernel`, or `fedpkg` containers keep their old images.
Keep them until the unified container works for your tasks. Removing them is
optional and deletes any state that exists only inside those containers.

## Update

Update the container when you choose. A trial is optional.
Save any needed files that exist only inside the old container.
To replace `dev`, stop its sessions and run these commands on the host:

```shell
podman pull ghcr.io/samcday/workstation-config/toolbox:main
toolbox rm dev
```

Read the removal output. If removal succeeded, repeat
[first-time setup](#first-time-setup) to create `dev` and set its `mock` group.

Container removal deletes its local packages, files, and caches. Files in the
shared `$HOME` remain. Toolbox does not refresh existing containers when you
pull an image, and it does not update images automatically.

`toolbox rm` and `toolbox rmi` exit with 0 even when they fail
([toolbox#1731](https://github.com/containers/toolbox/issues/1731)). Read the
output, not the exit code. If you remove old images, remove only those that no
container still needs with `toolbox rmi <old-image-id>`.

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

CI runs [toolchain smoke tests](tests/smoke.sh) and a
[Rawhide RPM build](tests/mock-build.sh) before publishing.
The Rawhide test changes files in its disposable container. Do not run it in
your working toolbox.

## Add packages

Add a line to `toolbox/packages.list`. Open a PR. CI builds the one image.
Nothing on a machine changes until you pull the new image and recreate the
container. No reboot is involved.
