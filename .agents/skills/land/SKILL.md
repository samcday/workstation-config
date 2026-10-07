---
name: land
description: >-
  Build, boot-verify, and land workstation-config changes only when the user
  explicitly requests landing.
metadata:
  delta-action: land
---

# Land changes

1. Commit the intended changes.
2. Run `git fetch origin main`, then `GIT_EDITOR=true git rebase origin/main`.
   Resolve clear-cut conflicts automatically; ask the user if the intent is ambiguous.
3. If the changes being landed do not affect image contents, proceed directly to
   step 7.
4. From the repository root, run [`./build-image`](../../../build-image).
   After success, obtain its digest with
   `sudo -n podman image inspect --format '{{.Digest}}' workstation-image:latest`.
   Record the machine, commit, and nonempty `sha256:` digest for verification.
5. Confirm `rpm-ostree status` tracks
   `ostree-unverified-image:containers-storage:localhost/workstation-image:latest`;
   otherwise stop and warn the user. Ask the user to run `sudo rpm-ostree upgrade`, reboot,
   and report when complete. Wait for that confirmation; never upgrade or reboot
   automatically.
6. On the same machine after confirmation, run `rpm-ostree status --json`.
   The deployment with `booted: true` must have a
   `container-image-reference-digest` matching the recorded digest. Stop on a
   mismatch or missing evidence.
   If edits or a later rebase changed image inputs after the build, warn the user that
   the new image may be out of date.
7. Run `git push origin HEAD:main`.
8. Ask the main/parent Delta thread to run
   `GIT_EDITOR=true git pull --rebase --autostash origin main` in its
   `workstation-config` checkout.

If sudo blocks the build or image inspection, stop and remind the user to install
[workstation-image.sudoers](../../../workstation-image.sudoers):
`sudo install -o root -g root -m 0440 workstation-image.sudoers /etc/sudoers.d/workstation-image`.
