FROM quay.io/fedora/fedora-silverblue:40

COPY tailscale.repo /etc/yum.repos.d/
RUN rpm-ostree install \
    bootc \
    cage \
    fedora-packager \
    gnome-console \
    greetd \
    greetd-fakegreet \
    gtkgreet \
    seatd \
    tailscale \
    usbip \
    vim \
    wf-recorder \
    zsh

COPY dracut.conf /usr/lib/dracut/dracut.conf.d/50-sam.conf
RUN set -x; kver=$(ls /usr/lib/modules); dracut -vf /usr/lib/modules/$kver/initramfs.img $kver
