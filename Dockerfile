FROM quay.io/fedora/fedora-silverblue:40

RUN rpm-ostree install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

COPY *.repo /etc/yum.repos.d/

RUN rpm-ostree install \
    android-tools \
    apk-tools \
    bind-utils \
    bootc \
    butane \
    cage \
    cargo \
    cloc \
    cmake \
    copr-cli \
    codium \
    dnf5 \
    dnf5-plugins \
    docker \
    fedora-packager \
    fedora-review \
    gcc \
    gdb \
    git-lfs \
    git-subtree \
    gnome-console \
    gnome-tweaks \
    go \
    greetd \
    greetd-fakegreet \
    gtkgreet \
    heimdall \
    helm \
    libavcodec-freeworld \
    meson \
    mpv \
    neofetch \
    nodejs \
    packit \
    podman-bootc \
    phrog \
    restic \
    ripgrep \
    rust-packaging \
    rust2rpm \
    rustup \
    screen \
    seatd \
    tailscale \
    tio \
    usbip \
    vim \
    virt-manager \
    wf-recorder \
    xmlstarlet \
    yt-dlp \
    zsh \
    https://github.com/derailed/k9s/releases/download/v0.32.4/k9s_linux_amd64.rpm \
    https://github.com/getsops/sops/releases/download/v3.8.1/sops-3.8.1.x86_64.rpm \

    # phosh
    pam-devel \
    callaudiod-devel \
    feedbackd-devel \
    dbus-daemon \
    'pkgconfig(alsa)' \
    'pkgconfig(evince-document-3.0)' \
    'pkgconfig(gcr-3)' \
    'pkgconfig(gio-2.0)' \
    'pkgconfig(gio-unix-2.0)' \
    'pkgconfig(glib-2.0)' \
    'pkgconfig(gnome-desktop-3.0)' \
    'pkgconfig(gobject-2.0)' \
    'pkgconfig(gudev-1.0)' \
    'pkgconfig(gtk+-3.0)' \
    'pkgconfig(gtk4)' \
    'pkgconfig(gtk+-wayland-3.0)' \
    'pkgconfig(libadwaita-1)' \
    'pkgconfig(libhandy-1)' \
    'pkgconfig(libnm)' \
    'pkgconfig(libpulse)' \
    'pkgconfig(libpulse-mainloop-glib)' \
    'pkgconfig(libsystemd)' \
    'pkgconfig(polkit-agent-1)' \
    'pkgconfig(upower-glib)' \
    'pkgconfig(wayland-client)' \
    'pkgconfig(wayland-protocols)' \
    'pkgconfig(libfeedback-0.0)' \
    'pkgconfig(libsecret-1)' \
    'pkgconfig(libecal-2.0)'

# Seems like ld is supposed to be set by update-alternatives, but isn't.
# so: hax.
RUN ln -sf /usr/bin/ld.bfd /usr/bin/ld

# Borrowed from bluefin.
# Fixes broken /usr/bin/swtpm SELinux labels
COPY swtpm-workaround.conf /usr/lib/tmpfiles.d/
COPY swtpm-workaround.service /usr/lib/systemd/system/
