# host

The Fedora Silverblue image that each machine boots, built from
[Containerfile](Containerfile). It holds only what must live in the booted OS:
the NVIDIA kernel module and driver, the initrd (TPM2 unlock, early `vfio-pci`),
sysctls, GNOME Shell extensions, the greetd login stack, device-permission
tools whose udev rules must be on the host, and desktop apps with no Flatpak.

Dev tooling is not here. It lives in the [toolbox images](../toolbox/README.md)
and updates without a reboot.

## Images

The [Host image workflow](../.github/workflows/host.yml) builds
`ghcr.io/samcday/workstation-config:main` for pushes to `main` that change
`host/`, the host workflow, or `.github/setup-storage`.
It also runs weekly on Monday at 09:22 UTC and supports manual runs.
Pull requests build `:pr-<n>`. Both tags are signed with cosign.

A machine tracks the image with bootc or rpm-ostree. To switch a machine to
the CI-built image:

```shell
sudo bootc switch ghcr.io/samcday/workstation-config:main
sudo bootc upgrade   # later: pick up new builds
```

`rpm-ostree rebase ostree-unverified-registry:ghcr.io/samcday/workstation-config:main`
does the same on a machine without bootc.

## Local build

For fast iteration before opening a PR:

```shell
host/build-image
```

This builds `localhost/workstation-image:latest` with rootful podman. It needs
the sudo rule in [workstation-image.sudoers](workstation-image.sudoers):

```shell
sudo install -o root -g root -m 0440 host/workstation-image.sudoers /etc/sudoers.d/workstation-image
```

A machine can boot the local build with
`rpm-ostree rebase ostree-unverified-image:containers-storage:localhost/workstation-image:latest`,
but landing goes through CI, not this.

## Apps moved to Flatpak

These were layered here and now install per machine from Flathub:

```shell
flatpak install flathub com.valvesoftware.Steam com.obsproject.Studio \
  com.vscodium.codium io.mpv.Mpv org.gnome.Calls org.gnome.dspy \
  dev.lizardbyte.app.Sunshine org.virt_manager.virt-manager
```

`virt-manager` stays layered until a libvirt sysext is in place, so skip it
from that line for now.

## Dropped

No longer in the image and not yet replaced: `nginx`, `fcgiwrap`, `minidlna`,
`prometheus`, `tang`, `tftp-server`, `postgresql`, `public-inbox-server`,
`docker-*`, `kubelet`, `kubeadm`, `kind`, `kiwi-*`, `mkosi`, `podman-bootc`,
`coreos-installer`, `qemu-user-static-arm`, `wine`, `gamescope`, `sway`,
`cage`. Daemons among these are candidates for systemd-sysexts; the rest run
from a toolbox or a Flatpak if needed again.
