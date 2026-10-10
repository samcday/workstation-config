# kernel toolbox

Linux kernel development toolbox: build, cross-compile, boot-test with
virtme-ng, patch workflow with b4/lei.

    toolbox create kernel --image ghcr.io/samcday/workstation-config/toolbox-kernel:main
    toolbox enter kernel

## Build & boot

    make defconfig && make -j$(nproc) # in-tree build
    vng --build                       # virtme-ng: configure/build/test boot in QEMU
    vng --run arch/x86/boot/bzImage   # boot a built kernel (--verbose for QEMU cmdline)

`vng --run` needs /dev/kvm on the host and works fine inside the toolbox.
Networking: `vng --net user` works; `bridge` does not (rootless limitation).

## Cross-compiling

    make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu-

aarch64 musl toolchains are also installed (COPR samcday/aarch64-linux-musl).

## Out-of-tree modules against the host kernel

kernel-devel is deliberately not installed: it never matches the host kernel.
Use the host's headers instead:

    make -C /run/host/usr/lib/modules/$(uname -r)/build M=$PWD

## Rust

    make LLVM=1 rustavailable

## Tracing limits (gated by host sysctls)

The container shares the host kernel, so the host's sysctls decide what
`perf` and BPF can do, not anything in this image. With Fedora's default
`kernel.perf_event_paranoid = 2`, `perf record` of your own processes works
for user-space events only; `perf -a` and kernel profiling need `<= 1`, and
raw/ftrace tracepoints need `-1` (or `CAP_PERFMON` in the init userns, which a
rootless container does not have). `bpftrace`/`bpftool prog` are blocked while
host `kernel.unprivileged_bpf_disabled = 2` (systemd's default). `trace-cmd
record` needs root on the host. See
<https://docs.kernel.org/admin-guide/perf-security.html>.
