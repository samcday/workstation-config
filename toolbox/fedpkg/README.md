# toolbox: Fedora packaging

Fedora packaging container: fedpkg, mock, rpmlint, fedora-review, and the
Koji, COPR and Packit clients, on top of the base workstation toolbox.

## Create and first use

```shell
toolbox create fedpkg --image ghcr.io/samcday/workstation-config/toolbox-fedpkg:main
toolbox enter fedpkg

# toolbox makes your user at create time, so mock group membership is
# per fresh container; a login hint prints until you have run:
sudo usermod -aG mock $USER && toolbox enter fedpkg

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