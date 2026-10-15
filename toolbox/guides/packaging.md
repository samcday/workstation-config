# Fedora packaging

Use the shared `dev` toolbox from the [setup guide](../README.md).
It contains fedpkg, mock, rpmlint, fedora-review, Koji, COPR, and Packit.
The setup guide adds your container user to the `mock` group.

Inside `dev`, authenticate to Fedora when needed:

```shell
fkinit -u <fas-username>
```

## Daily commands

Run these commands inside `dev`. `fedpkg mockbuild` builds for the branch
that you checked out. An explicit Mock configuration selects a different target.

```shell
fedpkg clone <package> && cd <package>
fedpkg mockbuild
mock -r fedora-rawhide-x86_64 --rebuild <src.rpm>
fedora-review -b <bug-number>
copr-cli build <project> <src.rpm>
```

Mock keeps a bootstrap chroot, a separate environment with the target's
package manager. The image populates it with DNF instead of nested Podman.
The toolbox's DNF and RPM must remain new enough to install those packages.

Toolbox shares host IPC. Nested Podman can fail with
`failed to open 2048 locks in /libpod_lock: permission denied` when the host
owns that lock. Do not delete the host lock or change its permissions.
For an older image, use the supported override:

```shell
fedpkg mockbuild -- --no-bootstrap-image
```

## Retained state

`/var/lib/mock` is container-local, so container removal deletes its caches.
`fedpkg mockbuild` writes results under the package checkout
(`results_<package>/`). Plain `mock` also accepts `--resultdir`.
Keep package checkouts in the shared home directory to retain their results.
