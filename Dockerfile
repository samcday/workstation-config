FROM --platform=linux/amd64 quay.io/fedora/fedora-silverblue:45

RUN dnf -y install \
    https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

COPY RPM-GPG-KEY-chatgpt-3BFA0E4AE8B8CC16A2D9BA684A3B4A566C4660E4.asc /etc/pki/rpm-gpg/
COPY *.repo /etc/yum.repos.d/

RUN dnf copr enable -y gmaglione/podman-bootc
RUN dnf copr enable -y samcday/phosh-nightly
RUN dnf copr enable -y rowanfr/fw-ectool
RUN dnf copr enable -y lizardbyte/beta
RUN dnf copr enable -y samcday/aarch64-linux-musl

# mutter 51.rc gives X11 (Xwayland) windows an empty input region whenever their initial window config
# is postponed: the ShapeInput rect gets intersected with a 0x0 client rect. Steam, Electron/CEF apps
# etc. render fine but every click lands on the window behind (gnome-shell#9389, fixed by mutter!5296,
# commit 9ea6030832, in 51.0). mutter 51.0 ships in the GNOME 51.0 bodhi update, still in testing, so
# pull the whole update from updates-testing before anything else installs against the rc stack. Once
# the base image ships mutter >= 51.0 the guard fails loudly, which is the cue to delete this block.
RUN --mount=type=cache,id=dnfcache,rw,destination=/var/cache/libdnf5 \
    set -eu && \
    rpm -q mutter | grep -q '^mutter-51~rc' && \
    dnf upgrade --refresh -y --enablerepo=updates-testing --advisory=FEDORA-2026-48a7996f9c && \
    rpm -q mutter | grep -q '^mutter-51\.0'

# <NVIDIA-BULLSHIT>
RUN --mount=type=cache,id=dnfcache,rw,destination=/var/cache/libdnf5 \
    dnf install --refresh -y \
      akmods \
      kernel-devel-$(rpm -q --queryformat '%{VERSION}-%{RELEASE}' kernel) \
      kernel-headers

# we isolate this step and run it without scripts because the %post
# is broken:
# `ERROR: Not to be used as root; start as user or 'akmodsbuild' instead.`
RUN --mount=type=cache,id=dnfcache,rw,destination=/var/cache/libdnf5 \
    dnf install --refresh -y --setopt=tsflags=noscripts \
      akmod-nvidia

# The 615.71.09 driver deadlocks the display-idle (DIFR) prefetch kthread on
# DPMS wake and the screen never comes back (issue #3, upstream #1289). The fix
# is unmerged PR #1286. rpmfusion's kmodsrc ships the nvidia-modeset OS-agnostic
# layer as a precompiled blob (nv-modeset-kernel.o_binary) so the patch can't
# go through the akmod. Instead: fetch the upstream tree at the matching tag,
# apply the patch, rebuild just that blob and splice it into the kmodsrc tarball
# before akmods runs. Version comes from the installed kmodsrc so it can't
# mismatch. When the patch stops applying (merged, or code drifted) this fails
# loudly, which is the point. Drop this block once the fix is upstream.
COPY nvidia/1286-difr-prefetch-deadlock.patch /tmp/nvidia-difr.patch
RUN --mount=type=cache,id=dnfcache,rw,destination=/var/cache/libdnf5 \
    set -eu && \
    V=$(rpm -q --queryformat '%{VERSION}' xorg-x11-drv-nvidia-kmodsrc) && \
    dnf install -y gcc-c++ patch && \
    cd /tmp && \
    curl -sfL https://github.com/NVIDIA/open-gpu-kernel-modules/archive/refs/tags/$V.tar.gz | tar xz && \
    cd open-gpu-kernel-modules-$V && \
    patch -p1 < /tmp/nvidia-difr.patch && \
    make -C src/nvidia-modeset -j$(nproc) && \
    T=/usr/share/nvidia-kmod-$V/nvidia-kmod-$V-x86_64.tar.xz && \
    mkdir /tmp/kmodsrc && tar xJf $T -C /tmp/kmodsrc && \
    install -m 0644 src/nvidia-modeset/_out/Linux_x86_64/nv-modeset-kernel.o \
      /tmp/kmodsrc/kernel-open/nvidia-modeset/nv-modeset-kernel.o_binary && \
    tar cJf $T -C /tmp/kmodsrc . && \
    cd /tmp && rm -rf /tmp/kmodsrc /tmp/open-gpu-kernel-modules-$V /tmp/nvidia-difr.patch && \
    dnf remove -y gcc-c++

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
    aarch64-linux-musl-toolchain \
    abi-compliance-checker \
    acpica-tools \
    aerc \
    age \
    android-tools \
    apitrace \
    apk-tools \
    aria2 \
    arm-none-eabi-gcc-cs \
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
    calls \
    cargo \
    ccache \
    chatgpt \
    clang-tools-extra \
    claude-desktop-unofficial \
    cloc \
    cmake \
    copr-cli \
    codium \
    coreos-installer \
    debootstrap \
    dejavu-sans-mono-fonts \
    devscripts \
    ddcutil \
    dkms \
    docker-buildx \
    docker-cli \
    docker-compose \
    d-spy \
    dtc \
    dt-schema \
    fastfetch \
    fcgiwrap \
    fedora-packager \
    fedora-repos-rawhide \
    fedora-review \
    fio \
    flatpak-builder \
    flex \
    ftp \
    fw-ectool \
    fzf \
    gamescope \
    gcc \
    gcc-aarch64-linux-gnu \
    gcc-c++ \
    gcc-gnat \
    gdb \
    gdb-gdbserver \
    gh \
    giflib-devel \
    git-credential-libsecret \
    git-lfs \
    git-subtree \
    glibc-devel.i686 \
    gnome-bluetooth-libs-devel \
    gnome-console \
    gnome-shell-extension-appindicator \
    gnome-shell-extension-caffeine \
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
    hwloc-gui \
    iperf3 \
    java-25-openjdk-devel \
    kde-connect \
    kind \
    kiwi-cli \
    kiwi-systemdeps \
    kmscube \
    kubeadm \
    kubectl \
    kubelet \
    kustomize \
    libavcodec-freeworld \
    jbigkit-devel \
    just \
    lei \
    liblerc-devel \
    libnotify-devel \
    libphosh-devel \
    libsamplerate-devel \
    libunistring-devel \
    libxdo-devel \
    libXScrnSaver-devel \
    libXpresent-devel \
    libxkbcommon-x11-devel \
    lshw \
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
    packit \
    dwarves \
    perl-FindBin \
    perl-IPC-Cmd \
    perl-Time-Piece \
    phrog \
    pipewire-devel \
    pipx \
    pmbootstrap \
    podman-bootc \
    postgresql \
    prometheus \
    protobuf-compiler \
    protobuf-devel \
    public-inbox-server \
    python3-dbusmock \
    python3-devel \
    python3-pip \
    python3-pygments \
    python3-typogrify \
    qemu-user-static-arm \
    rclone \
    restic \
    ripgrep \
    rust-srpm-macros \
    rust2rpm \
    rustup \
    screen \
    seatd \
    ShellCheck \
    socat \
    speedtest-cli \
    spice-protocol \
    fuse-sshfs \
    steam \
    strace \
    Sunshine \
    sway \
    swig \
    syncthing \
    tailscale \
    tang \
    tcpdump \
    tftp \
    tftp-server \
    tio \
    tmux \
    opentofu \
    tpm2-tss-engine \
    tpm2-tss-engine-utilities \
    systemd-ukify \
    usbip \
    vim-enhanced \
    virt-install \
    virt-manager \
    virtme-ng \
    waypipe \
    wine \
    wireshark \
    wl-clipboard \
    wf-recorder \
    xapian-core \
    xmlstarlet \
    xorg-x11-server-Xwayland-devel \
    yamllint \
    yt-dlp \
    yq \
    zsh \
    https://github.com/derailed/k9s/releases/download/v0.50.15/k9s_linux_amd64.rpm \
    https://github.com/getsops/sops/releases/download/v3.11.0/sops-3.11.0-1.x86_64.rpm

RUN curl -fsSL https://github.com/oras-project/oras/releases/download/v1.3.4/oras_1.3.4_linux_amd64.tar.gz | tar -xz -C /usr/bin oras

RUN set -eux; \
    for b in cfssl cfssljson multirootca cfssl-bundle cfssl-certinfo cfssl-newkey cfssl-scan; do \
      curl -fsSL -o "/usr/bin/$b" "https://github.com/cloudflare/cfssl/releases/download/v1.6.5/${b}_1.6.5_linux_amd64"; \
      chmod 0755 "/usr/bin/$b"; \
    done; \
    curl -fsSL -o /usr/bin/cfssl-mkbundle https://github.com/cloudflare/cfssl/releases/download/v1.6.5/mkbundle_1.6.5_linux_amd64; \
    chmod 0755 /usr/bin/cfssl-mkbundle

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

# ChatGPT hardcodes X11 ozone, where its stray override-redirect avatarOverlay window renders the app click-through. Force Wayland.
RUN grep -q '^Exec=chatgpt %U' /usr/share/applications/chatgpt.desktop && \
    sed -i 's|^Exec=chatgpt %U|Exec=chatgpt --ozone-platform=wayland %U|' /usr/share/applications/chatgpt.desktop

# Claude Desktop defaults to XWayland on GNOME. On mutter 51, hiding the window to tray and reopening it
# leaves the remapped Xwayland surface without pointer focus (clicks fall through to the window behind).
# CLAUDE_USE_WAYLAND=1 is the launcher's supported switch for native Wayland.
RUN grep -q '^Exec=/usr/bin/claude-desktop-unofficial %u' /usr/share/applications/claude-desktop-unofficial.desktop && \
    sed -i 's|^Exec=/usr/bin/claude-desktop-unofficial %u|Exec=env CLAUDE_USE_WAYLAND=1 /usr/bin/claude-desktop-unofficial %u|' /usr/share/applications/claude-desktop-unofficial.desktop

# GNOME 51: the Fedora 45 rpms of AppIndicator (64) and Caffeine (60) still cap shell-version at 50, so
# the shell refuses to load them ("OUT OF DATE"). Upstream supports 51 (AppIndicator v66, Caffeine master)
# but no rebuilt rpm has landed. Overlay the upstream trees on top of the rpm install, following the
# Fedora specs' install steps. Each block first checks that the rpm's metadata.json still lacks "51";
# once Fedora ships a 51-capable rpm the guard fails loudly, which is the cue to delete that block.
RUN set -eu && \
    ext=/usr/share/gnome-shell/extensions/appindicatorsupport@rgcjonas.gmail.com && \
    jq -e '.["shell-version"] | index("51") | not' $ext/metadata.json >/dev/null && \
    mkdir -p /tmp/appindicator && cd /tmp/appindicator && \
    curl -fsSL https://github.com/ubuntu/gnome-shell-extension-appindicator/archive/refs/tags/v66.tar.gz | tar xz --strip-components=1 && \
    meson setup build --prefix=/usr -Dlocal_install=disabled && \
    ninja -C build install && \
    jq -e '.["shell-version"] | index("51")' $ext/metadata.json >/dev/null && \
    cd / && rm -rf /tmp/appindicator

RUN set -eu && \
    ext=/usr/share/gnome-shell/extensions/caffeine@patapon.info && \
    jq -e '.["shell-version"] | index("51") | not' $ext/metadata.json >/dev/null && \
    mkdir -p /tmp/caffeine && cd /tmp/caffeine && \
    curl -fsSL https://github.com/eonpatapon/gnome-shell-extension-caffeine/archive/be18b3558a250d672a7108f01a8dcf55c0935bc6.tar.gz | tar xz --strip-components=1 && \
    cd caffeine@patapon.info && \
    rm -rf $ext && install -d -m 0755 $ext && \
    cp -r --preserve=timestamps *.js metadata.json icons preferences $ext && \
    install -D -p -m 0644 schemas/org.gnome.shell.extensions.caffeine.gschema.xml /usr/share/glib-2.0/schemas/org.gnome.shell.extensions.caffeine.gschema.xml && \
    for po in locale/*.po; do \
      install -d -m 0755 /usr/share/${po%.po}/LC_MESSAGES && \
      msgfmt -o /usr/share/${po%.po}/LC_MESSAGES/gnome-shell-extension-caffeine.mo $po; \
    done && \
    jq -e '.["shell-version"] | index("51")' $ext/metadata.json >/dev/null && \
    cd / && rm -rf /tmp/caffeine

RUN glib-compile-schemas /usr/share/glib-2.0/schemas

# Update initrd to include TPM2 disk unlock and include vfio-pci early (to denylist PCI devices,
# like NVIDIA GPU on my desktop)
COPY dracut.conf /usr/lib/dracut/dracut.conf.d/10-sam.conf
RUN export DRACUT_NO_XATTR=1 && \
    export KERNEL_VERSION="$(rpm -qa kernel --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}')" && \
    stock_arguments=$(lsinitrd "/lib/modules/${KERNEL_VERSION}/initramfs.img"  | grep '^Arguments: ' | sed 's/^Arguments: //') && \
    mkdir -p /tmp/dracut /var/roothome && \
    bash <(/usr/bin/echo "dracut -f /lib/modules/${KERNEL_VERSION}/initramfs.img $stock_arguments") && \
    rm -rf /var/* /tmp/*  && \
    ostree container commit
