FROM quay.io/fedora/fedora-silverblue:43

RUN dnf -y install \
    https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

COPY *.repo /etc/yum.repos.d/

RUN dnf copr enable -y gmaglione/podman-bootc
RUN dnf copr enable -y samcday/phosh-nightly
RUN dnf copr enable -y rowanfr/fw-ectool
RUN dnf copr enable -y lizardbyte/beta

# <NVIDIA-BULLSHIT>
RUN --mount=type=cache,id=dnfcache,rw,destination=/var/cache/libdnf5 \
    dnf install --refresh -y \
      akmods \
      kernel-devel \
      kernel-headers

# we isolate this step and run it without scripts because the %post
# is broken:
# `ERROR: Not to be used as root; start as user or 'akmodsbuild' instead.`
RUN --mount=type=cache,id=dnfcache,rw,destination=/var/cache/libdnf5 \
    dnf install --refresh -y --setopt=tsflags=noscripts \
      akmod-nvidia

# thanks to pbrezina for this workaround:
# https://github.com/bootc-dev/bootc/discussions/993
RUN akmods --force --kernels `rpm -q --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}' kernel-devel`

RUN --mount=type=cache,id=dnfcache,rw,destination=/var/cache/libdnf5 \
    dnf install --refresh -y  \
      xorg-x11-drv-nvidia \
      xorg-x11-drv-nvidia-cuda \
      xorg-x11-drv-nvidia-power \
      libva-nvidia-driver \
      nvidia-settings \
      nvidia-persistenced
# </NVIDIA-BULLSHIT>

RUN --mount=type=cache,id=dnfcache,rw,destination=/var/cache/libdnf5 \
    dnf install --refresh -y \
    abi-compliance-checker \
    aerc \
    age \
    android-tools \
    apitrace \
    apk-tools \
    arm-none-eabi-gcc \
    asciinema \
    b4 \
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
    coreos-installer \
    debootstrap \
    dejavu-sans-mono-fonts \
    ddcutil \
    docker \
    docker-buildx \
    docker-compose \
    d-spy \
    dtc \
    fastfetch \
    fcgiwrap \
    fedora-packager \
    fedora-repos-rawhide \
    fedora-review \
    fio \
    flex \
    ftp \
    fw-ectool \
    fzf \
    gcc \
    gcc-aarch64-linux-gnu \
    gcc-c++ \
    gcc-gnat \
    gdb \
    gdbserver \
    giflib-devel \
    git-credential-libsecret \
    git-lfs \
    git-subtree \
    glibc-devel.i686 \
    gnome-bluetooth-libs-devel \
    gnome-calls \
    gnome-console \
    gnome-shell-extension-appindicator \
    gnome-tweaks \
    golang \
    golang-bin \
    golang-github-cloudflare-cfssl \
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
    kde-connect \
    kiwi \
    kmscube \
    kubeadm \
    kubectl \
    kubelet \
    kustomize \
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
    minidlna \
    mkosi \
    mpv \
    nbd \
    ncurses-devel \
    net-tools \
    nginx \
    nmap \
    nodejs \
    obs-studio \
    obs-studio-devel \
    openssl \
    openssl-devel \
    openssl-devel-engine \
    packit \
    pahole \
    perl-FindBin \
    perl-IPC-Cmd \
    perl-Time-Piece \
    pipewire-devel \
    pipx \
    pmbootstrap \
    podman-bootc \
    postgresql \
    protobuf-compiler \
    python3-dbusmock \
    python3-devel \
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
    socat \
    speedtest-cli \
    spice-protocol \
    sshfs \
    steam \
    strace \
    Sunshine \
    sway \
    syncthing \
    tailscale \
    tang \
    tcpdump \
    tftp \
    tftp-server \
    tio \
    tmux \
    tofu \
    tpm2-tss-engine \
    tpm2-tss-engine-utilities \
    ukify \
    usbip \
    vim \
    virt-install \
    virt-manager \
    waypipe \
    wine \
    wl-clipboard \
    wf-recorder \
    xmlstarlet \
    xorg-x11-server-Xwayland-devel \
    yt-dlp \
    yq \
    zsh \
    https://github.com/derailed/k9s/releases/download/v0.50.15/k9s_linux_amd64.rpm \
    https://github.com/getsops/sops/releases/download/v3.11.0/sops-3.11.0-1.x86_64.rpm

RUN --mount=type=cache,id=dnfcache,rw,destination=/var/cache/libdnf5 \
    dnf install --enablerepo=updates-testing --refresh --advisory=FEDORA-2026-02a97a390f -y phrog

RUN --mount=type=cache,id=dnfcache,rw,destination=/var/cache/libdnf5 \
    dnf builddep -y \
    gdm \
    gnome-software \
    phoc \
    phosh \
    phosh-mobile-settings

RUN akmods --force --kernels `rpm -q --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}' kernel-devel`

RUN mkdir /nix

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
