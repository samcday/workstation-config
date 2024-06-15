FROM quay.io/fedora/fedora-silverblue:40

RUN rpm-ostree install \
    https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm \
    # dnf gets pulled in somewhere in the later install. Would be better to ensure it's excluded.
    # Not quite sure how to do that so for now force it to be installed *now*, and then force the
    # /usr/bin/dnf symlink to dnf5.
    dnf \
    dnf5 \
    dnf5-plugins

# That hacky symlink fix mentioned a few lines earlier.
RUN ln -sf /usr/bin/dnf5 /usr/bin/dnf

COPY *.repo /etc/yum.repos.d/

RUN dnf install -y \
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
    htop \
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
    https://github.com/getsops/sops/releases/download/v3.8.1/sops-3.8.1.x86_64.rpm

RUN dnf builddep -y phosh
RUN dnf builddep -y phrog

# Seems like ld is supposed to be set by update-alternatives, but isn't.
# so: hax.
RUN ln -sf /usr/bin/ld.bfd /usr/bin/ld

# Borrowed from bluefin.
# Fixes broken /usr/bin/swtpm SELinux labels
COPY swtpm-workaround.conf /usr/lib/tmpfiles.d/
COPY swtpm-workaround.service /usr/lib/systemd/system/
RUN systemctl enable swtpm-workaround
