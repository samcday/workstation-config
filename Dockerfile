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

RUN dnf copr enable -y gmaglione/podman-bootc
RUN dnf copr enable -y samcday/phrog

RUN dnf install -y \
    age \
    android-tools \
    apk-tools \
    bat \
    bind-utils \
    bison \
    bootc \
    butane \
    cage \
    cargo \
    cloc \
    cmake \
    copr-cli \
    codium \
    debootstrap \
    docker \
    fcgiwrap \
    fedora-packager \
    fedora-repos-rawhide \
    fedora-review \
    flex \
    ftp \
    fzf \
    gcc \
    gcc-c++ \
    gcc-gnat \
    gdb \
    git-credential-libsecret \
    git-lfs \
    git-subtree \
    glibc-devel.i686 \
    gnome-bluetooth-libs-devel \
    gnome-console \
    gnome-tweaks \
    golang \
    golang-bin \
    greetd \
    greetd-fakegreet \
    gsound-devel \
    gtkgreet \
    hcloud \
    heimdall \
    helm \
    htop \
    iperf3 \
    java-21-openjdk-devel \
    kubeadm \
    kubectl \
    kubelet \
    libavcodec-freeworld \
    libnotify-devel \
    meson \
    mpv \
    ncurses-devel \
    neofetch \
    net-tools \
    nginx \
    nodejs \
    openssl \
    openssl-devel \
    packit \
    perl-FindBin \
    phrog \
    podman-bootc \
    postgresql \
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
    strace \
    tailscale \
    tcpdump \
    tio \
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
    yt-dlp \
    yq \
    zsh \
    https://github.com/derailed/k9s/releases/download/v0.32.5/k9s_linux_amd64.rpm \
    https://github.com/getsops/sops/releases/download/v3.9.0/sops-3.9.0-1.x86_64.rpm

RUN dnf builddep -y phosh
RUN dnf builddep -y phosh-mobile-settings
RUN dnf builddep -y phrog

RUN dnf upgrade -y --enablerepo=rawhide gmobile
RUN dnf upgrade -y --enablerepo=rawhide phoc

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
