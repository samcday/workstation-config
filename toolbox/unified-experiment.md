# Unified toolbox capacity test

The single image fits a standard GitHub-hosted `ubuntu-24.04` runner.
No package pruning or runner disk changes were needed.
This is a capacity result, not a host deployment or landing approval.

## Evidence

[Run 38682068775](https://github.com/samcday/workstation-config/actions/runs/38682068775)
tested commit `d0350935616348f6bfbdb2a6620a3e0dc7f0f42d` on
`try/toolbox-unified`. One job built, tested, pushed, and signed the image.
The runner exposed four CPUs.

Sizes below use GiB (1,073,741,824 bytes).

| Measurement | Result |
| --- | --- |
| Build time | 719 seconds |
| Whole job | 17 minutes 42 seconds |
| Uncompressed image | 13,040,101,223 bytes / 12.145 GiB |
| Compressed registry layers | 4,346,478,117 bytes / 4.048 GiB |
| Layers | 7 |
| Free disk before the build | 92,110,299,136 bytes / 85.784 GiB |
| Free disk after publication | 75,880,493,056 bytes / 70.669 GiB |

Disk measurements are snapshots, not a measurement of peak disk use.
The image contains the union of all 193 explicit package names from the old
base and variants, plus the existing Phosh build dependencies.

The immutable artifact is:

```text
ghcr.io/samcday/workstation-config/toolbox@sha256:fd1b58708d169802514d570af7a4dbe30dddd68e4f16cf21b802a8764e0e59aa
```

## Checks and limits

CI passed native C, Rust, and Go build-and-run checks, an arm64 object
compilation, Phosh dependency checks, kernel tooling checks, and a Rawhide RPM
build. The Mock test rejects any nested Podman invocation.
The resulting image was pushed to GHCR and signed.

A local pull did not complete within ten minutes. No local trial container
was created, and no matching pull process remained afterward.
A real `toolbox create`/`enter` trial of this combined image is therefore
not recorded here. Full Phosh source builds and a kernel VM boot were not
repeated for the combined image.

The final workflow removes the experiment-only push trigger and restores the
inherited tag expression. The image definition and tests are unchanged from
the successful run. The parent PR must run its own CI after integration.

## Rechunking

The largest compressed layer is 3,824,386,786 bytes, or 88% of the image's
compressed layers. A change to the large package-install step can invalidate
that whole layer. Content-based layers can reduce update transfers by keeping
unchanged packages in reusable layers.

Do not reuse the host's `hhd-dev/rechunk` action for this toolbox. Its
[pruning script](https://github.com/hhd-dev/rechunk/blob/5fbe1d3a639615d2548d83bc888360de6267b1a2/1_prune.sh)
moves `/etc` to `/usr/etc`, rewrites users and groups, and moves or removes
other runtime paths. Those are OS-image transformations, not a safe toolbox
repacking step.

[chunkah](https://github.com/coreos/chunkah) supports ordinary OCI images
and preserves file contents and permissions, apart from timestamps. It can
also preserve the original image configuration through `CHUNKAH_CONFIG_STR`.
It is a suitable follow-up to benchmark against two package revisions.

No rechunking is enabled in this change. It is not needed to fit the runner.
Update-byte savings were not measured, and rechunking does not remove the
need for a large first download.
