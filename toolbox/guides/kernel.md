# Kernel development

Use the shared `dev` toolbox from the [setup guide](../README.md).
It includes native and cross-compilers, virtme-ng, and b4/lei.
Run builds from a Linux source checkout inside `dev`.

## Build and boot

`vng --build` prepares a configuration and builds the kernel.
From the same source tree, `vng` boots that build in QEMU.
KVM acceleration needs access to the host's `/dev/kvm`.

```shell
vng --build
vng -- uname -r
```

For a normal in-tree build, use:

```shell
make defconfig
make -j$(nproc)
```

User-mode networking works with `vng --net user`. Bridge networking needs
host privileges that a rootless toolbox cannot provide.

## Cross-compilation and Rust

The image contains cross-compilers for ARM, arm64, RISC-V, powerpc64le, and
s390x. The arm64 musl toolchain comes from `samcday/aarch64-linux-musl`.
The packaged Rust tools support the kernel's availability test.

```shell
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu-
make LLVM=1 rustavailable
```

## Host modules and tracing

Any `kernel-devel` package in the container is not necessarily for the
running host kernel. Use matching host headers when they are installed:

```shell
make -C /run/host/usr/lib/modules/$(uname -r)/build M="$PWD"
```

The host kernel controls profiling and tracing permissions. At
`kernel.perf_event_paranoid=2`, unprivileged profiling is limited to the
user-space part of a process. System-wide profiling needs `<=0`, kernel
profiling needs `<=1`, and raw/ftrace tracepoints need `-1`, unless the process
has the required host capabilities.

`bpftrace` cannot load programs when the host disables unprivileged BPF.
`trace-cmd record` needs host privileges. The image does not change these
host settings. See the
[kernel profiling security guide](https://docs.kernel.org/admin-guide/perf-security.html).
