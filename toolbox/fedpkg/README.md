# toolbox: Fedora packaging

Fedora packaging container: fedpkg, mock, rpmlint, fedora-review, and the
Koji, COPR and Packit clients, on top of the base workstation toolbox.

## Create and first use

Run these commands on the host, without `sudo`. The first `toolbox run`
initializes the container user. The `podman exec` command adds that user to
the container's `mock` group, not the host's group.

```shell
toolbox create fedpkg --image ghcr.io/samcday/workstation-config/toolbox-fedpkg:main
toolbox run -c fedpkg -- true
podman exec --user 0 fedpkg usermod -aG mock "$(id -un)"
toolbox enter fedpkg
```

Inside the container, authenticate to Fedora when needed:
```shell
fkinit -u <fas-username>
```

## Daily commands

```shell
fedpkg clone <package> && cd <package>
fedpkg mockbuild                              # build in a mock chroot
mock -r fedora-rawhide-x86_64 --rebuild <src.rpm>
fedora-review -b <bug-number>                 # complete package review
copr-cli build <project> <src.rpm>
```

Mock uses a bootstrap chroot, a separate environment with the target's
package manager. This image populates it with DNF instead of pulling an
OCI image through nested Podman.

Toolbox shares host IPC. Nested Podman can fail with
`failed to open 2048 locks in /libpod_lock: permission denied` when the host
already owns that lock. Do not delete the host lock or change its permissions.

For an older image, pass the supported override for one build:

```shell
fedpkg mockbuild -- --no-bootstrap-image
```

This keeps the bootstrap chroot enabled. It avoids the nested Podman call,
not the separate package build environment. The toolbox base must remain
new enough for its DNF and RPM to install the target's bootstrap packages.

## Mock chroots are container-local

/var/lib/mock is inside the container: `toolbox rm` loses the chroot caches
there. Build results are safe: `fedpkg mockbuild` writes them under the
package checkout (`results_<package>/`), and plain `mock` accepts
`--resultdir`. To keep the chroots too, point mock's `basedir` at the
container-shared `$HOME`. Per mock, the path must be owned by group `mock`,
mode `g+rws`:

```shell
mkdir -p ~/.mock-chroots && sudo chgrp mock ~/.mock-chroots
sudo chmod g+rws ~/.mock-chroots
echo "config_opts['basedir'] = '$HOME/.mock-chroots'" >> ~/.config/mock.cfg
```