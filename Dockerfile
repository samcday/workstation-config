FROM quay.io/fedora/fedora-silverblue:41

RUN rpm-ostree install \
    https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm \
    dnf5 \
    dnf5-plugins

COPY *.repo /etc/yum.repos.d/

RUN dnf copr enable -y gmaglione/podman-bootc
RUN dnf copr enable -y samcday/phrog-nightly
RUN dnf copr enable -y samcday/phosh-nightly

RUN dnf install -y \
    abi-compliance-checker \
    aerc \
    age \
    android-tools \
    apitrace \
    apk-tools \
    arm-none-eabi-gcc \
    bat \
    bind-utils \
    binutils-devel \
    binwalk \
    bison \
    bootc \
    butane \
    cage \
    cargo \
    ccache \
    clangd \
    cloc \
    cmake \
    copr-cli \
    codium \
    debootstrap \
    dejavu-sans-mono-fonts \
    docker \
    docker-buildx \
    d-spy \
    dtc \
    fastfetch \
    fcgiwrap \
    fedora-packager \
    fedora-repos-rawhide \
    fedora-review \
    flex \
    ftp \
    fzf \
    gcc \
    gcc-aarch64-linux-gnu \
    gcc-c++ \
    gcc-gnat \
    gdb \
    giflib-devel \
    git-credential-libsecret \
    git-lfs \
    git-subtree \
    glibc-devel.i686 \
    gnome-bluetooth-libs-devel \
    gnome-calls \
    gnome-console \
    gnome-tweaks \
    golang \
    golang-bin \
    greetd \
    greetd-fakegreet \
    gsound-devel \
    gtk4-devel-tools \
    gtkgreet \
    hcloud \
    heimdall \
    helm \
    htop \
    iperf3 \
    java-21-openjdk-devel \
    kiwi \
    kubeadm \
    kubectl \
    kubelet \
    libavcodec-freeworld \
    jbigkit-devel \
    liblerc-devel \
    libnotify-devel \
    libphosh-devel \
    libsamplerate-devel \
    libunistring-devel \
    libXScrnSaver-devel \
    libXpresent-devel \
    libxkbcommon-x11-devel \
    lshw \
    lstopo \
    meson \
    mpv \
    ncurses-devel \
    net-tools \
    nginx \
    nodejs \
    obs-studio \
    obs-studio-devel \
    openssl \
    openssl-devel \
    openssl-devel-engine \
    packit \
    perl-FindBin \
    phrog \
    pipewire-devel \
    pmbootstrap \
    podman-bootc \
    postgresql \
    python3-dbusmock \
    python3-pip \
    python3-pygments \
    python3-typogrify \
    rclone \
    restic \
    ripgrep \
    rust-packaging \
    rust2rpm \
    rustup \
    screen \
    seatd \
    shellcheck \
    spice-protocol \
    strace \
    sway \
    syncthing \
    tailscale \
    tcpdump \
    tio \
    tmux \
    tofu \
    tpm2-tss-engine \
    tpm2-tss-engine-utilities \
    usbip \
    vim \
    virt-install \
    virt-manager \
    wl-clipboard \
    wf-recorder \
    xmlstarlet \
    xorg-x11-server-Xwayland-devel \
    yt-dlp \
    yq \
    zsh \
    https://github.com/derailed/k9s/releases/download/v0.32.7/k9s_linux_amd64.rpm \
    https://github.com/getsops/sops/releases/download/v3.9.2/sops-3.9.2-1.x86_64.rpm

RUN dnf builddep -y \
    gdm \
    gnome-software \
    phoc \
    phosh \
    phosh-mobile-settings

# Alternatives are broken. Should figure out why.
# for now: hax.
RUN ln -sf /usr/bin/ld.bfd /usr/bin/ld
RUN ln -sf /usr/lib/golang/bin/go /usr/bin/go

# Disable SELinux for now until the underlying relabelling issues are resolved
# (#2)
RUN echo 'SELINUX=disabled' > /etc/selinux/config

# Update initrd to include TPM2 disk unlock and include vfio-pci early (to denylist PCI devices,
# like NVIDIA GPU on my desktop)
COPY dracut.conf /usr/lib/dracut/dracut.conf.d/10-sam.conf
RUN export KERNEL_VERSION="$(rpm -qa kernel --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}')" && \
    stock_arguments=$(lsinitrd "/lib/modules/${KERNEL_VERSION}/initramfs.img"  | grep '^Arguments: ' | sed 's/^Arguments: //') && \
    mkdir -p /tmp/dracut /var/roothome && \
    bash <(/usr/bin/echo "dracut -f /lib/modules/${KERNEL_VERSION}/initramfs.img $stock_arguments") && \
    rm -rf /var/* /tmp/*  && \
    ostree container commit
