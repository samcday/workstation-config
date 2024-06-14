FROM quay.io/fedora/fedora-silverblue:40

RUN rpm-ostree install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

COPY *.repo /etc/yum.repos.d/

RUN rpm-ostree install \
    android-tools \
    apk-tools \
    bootc \
    butane \
    cage \
    docker \
    fedora-packager \
    fedora-review \
    gnome-console \
    gnome-tweaks \
    go \
    greetd \
    greetd-fakegreet \
    gtkgreet \
    heimdall \
    libavcodec-freeworld \
    neofetch \
    podman-bootc \
    phrog \
    screen \
    seatd \
    tailscale \
    tio \
    usbip \
    vim \
    virt-manager \
    wf-recorder \
    zsh \
    https://github.com/getsops/sops/releases/download/v3.8.1/sops-3.8.1.x86_64.rpm
