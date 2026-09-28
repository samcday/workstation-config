# sam-desktop monitor wake failure, 2026-09-27

## Live evidence

Captured over SSH from sam-laptop while the monitor could not wake. The desktop
was running F45 `45.20260923.n.0`, kernel `7.2.7-300.fc45.x86_64`, NVIDIA open
driver `615.71.09`, and an RTX 4090. Boot ID:
`f6fb9b9d20d144e39b50783b49e34a05`.

The previous DIFR patch was already present: the installed module contains its
timeout/reset messages, matches the loaded module's ELF build ID, and the boot log
identifies the locally rebuilt modeset layer. Loaded modeset build ID:
`f42e7e2f26b2712544ef3f6fdc2c34ce49d09848`.

- `nvidia-modeset/kthread_q` (1659) waits in `nvkms_kthread_q_callback`.
- GNOME Shell's main thread (5984) waits on a futex.
- Its KMS thread (6032) consumes one CPU in kernel mode. Ordinary `/proc/.../stack`
  is empty for that running thread; this does not mean the thread is healthy.
- Existing OpenLinkHub temperature-query children (`nvidia-smi`) wait on NVIDIA
  GPU locks. No extra `nvidia-smi` probes were started during this investigation.
- `DisplayConfig.GetCurrentState` times out after four seconds.
- No system suspend occurred in the affected boot.

A diagnostic SysRq `l` CPU backtrace at 08:22:02 AEST captured the KMS thread:

```text
msgqRxGetReadAvailable
GspMsgQueueReceiveStatus
_kgspRpcDrainEvents
kgspRecvPoll_IMPL
_issueRpcAndWait
rpcRmApiControl_GSP
nvRmApiControl
DisplayPort::EvoMainLink::train
DisplayPort::ConnectorImpl::trainLinkOptimized
nvDPPreSetMode
nvSetDispModeEvo
nv_drm_atomic_commit
```

At 08:23:29, the kernel logged `Lost display notification`. A second sample at
08:25:34 still showed the KMS thread in the GSP RPC wait, now called through
`EvoWaitForRasterLock` and `nvEvoEnableMergeModePostModeset`. Some blocked query
processes had been replaced by new ones. Therefore this is a sustained display
failure with some internal progress, not proof of one permanently unchanged RPC.

Raw logs are saved on both machines in
`~/.local/state/nvidia-wake-20260927/`: `host-state.txt`, `cpu-backtrace.log`,
and `cpu-backtrace-later.log`.

## Assessment and candidate

This is an NVIDIA DisplayPort/GSP failure. The captured path differs from the
DIFR prefetch loop addressed by PR #1286. The earlier issue #3 discussion treated
the outer modeset worker stack as sufficient to identify DIFR; it was not.

[Upstream #1392](https://github.com/NVIDIA/open-gpu-kernel-modules/issues/1392)
reports the same DisplayPort training/GSP wait signature and repeated recovery
with 610.57.04 on the same kernel. Thus the earlier argument that rolling back
cannot help because 610 also contains a DIFR bug does not establish that it cannot
help this separate regression.

[PR #1359](https://github.com/NVIDIA/open-gpu-kernel-modules/pull/1359), pinned at
`a2e8b26b20dfb6f2fa3cb8985e3f1126cba38aae`, restores detach bookkeeping when a
DisplayPort monitor powers off. Version 615.71.09 introduced the guard that skips
this cleanup. The patch still rejects attachments while the sink is absent.
It has successful hardware reports, including Fedora/GNOME/RPM Fusion.

This remains a candidate for this machine. The PR's original instrumented failure
was a flush error before hardware training; our captured wait reached training.
Neither a matching symptom nor a successful build proves the same root cause.

## Validation

Both local patches apply to fresh 615.71.09 with `--batch --forward --fuzz=0`.
The resulting DisplayPort file is byte-identical to the pinned PR head. The
[upstream control-flow harness](https://github.com/martinstark/open-gpu-kernel-modules/blob/d9c46a85e3162c9226da6438385e3f3f56ee5494/evidence/pr-1359/test-detach.py)
passes for 610, stock 615, PR #1359, and fresh 615 with both repository patches.
It exercises detach, attachment rejection, mixed requests, existing guards, and
all head masks. This tests software control flow, not firmware or monitor behavior.

An isolated image derived from the installed image was built on sam-desktop. It
rebuilds the modeset blob with both patches, rebuilds/reinstalls the matching akmod,
and regenerates the initramfs. The initramfs remains byte-identical because its
configuration excludes the NVIDIA modules. The build did not upgrade other RPMs.

```text
Tag: localhost/workstation-image:nvidia-dp-1359
Image: 24dc962e07495e7845b6a79e1f5d9f1d06a2b7a1ef2100a94f250f843e47f267
Digest: sha256:ea39e7865f070218c0e37c2b79ce3b8fe2006ebc92ee2099f40c0f2f04ec84d3
Modeset ELF build ID: f6785782f6d3e8036ab42cf072d27234b63cc5cb
Modeset .ko.xz SHA256: 5f8a6c7f86011b78367c062b78dc9bc8fb7166d5a6dabfd7fe8054ecd85350a2
```

Build logs and module/checksum evidence are under the same state directory in
`candidate-build.log` and `verification/`. The desktop also retains the isolated
build context. **Verify the loaded ELF build ID after reboot, not srcversion**:
srcversion stayed unchanged when the precompiled modeset blob changed.

The candidate was successfully staged using `rpm-ostree rebase --cache-only`.
Pending deployment checksum:
`b76076c6f49f0a45dfefede19cf9c4439ca9d16a74e6654a769c2c350aa01ffd`.
The staged module's SHA256 was independently checked against the built module.
Existing local packages, the PipeWire override, and tracked initramfs files are
preserved. At 08:35 AEST the deployment was also manually finalized using
`ostree admin finalize-staged`, which completed successfully and updated/synced
the bootloader. The default deployment is now `staged: false`, and the highest
version BLS entry resolves to the candidate deployment. This avoids relying on
late shutdown finalization while the NVIDIA driver is hung. The host has **not**
rebooted into it; hardware acceptance is pending.

The user's recollection of an earlier skipped update is supported by September
24 logs: an 08:20 deployment was followed by a stalled shutdown without a recorded
finalization, and the 08:24 boot used the old deployment. A later 09:24 shutdown
completed finalization and the 09:25 boot used the updated kernel. The journal
does not independently establish how the stalled shutdown was reset.

Hardware acceptance requires booting the candidate, checking the loaded module
identity, then reproducing physical monitor off/on and normal blank/wake with SSH
available. Check compositor responsiveness as well as the visible result. One
successful wake is a smoke test; repeat cycles and normal use are still needed.

## F44 fallback

The two listed OSTree deployments were both F45. `rpm-ostree rollback` alone would
therefore not return to F44. The complete September 15 F44 workstation image is
still present in rootful Podman storage:

```text
87c43fd7b57e3d55e4dfd6097017ff997b167cf9d2b3a3bcf86a80cb901b5091
```

It is now tagged `localhost/workstation-image:f44-20260915-recovery`.
Its RPM database contains F44 `44.20260915.0`, kernel `7.2.5-200.fc44.x86_64`,
Mutter 50.4, and the matching NVIDIA 610.57.04 driver/userspace/kmod set. A rebase
to this cached image is the fallback if the candidate fails hardware testing;
rebuilding today's F44 repositories would not reproduce that exact driver set.
