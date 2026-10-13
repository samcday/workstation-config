---
name: land
description: >-
  Land workstation-config changes through a green CI run, only when the user
  explicitly requests landing.
metadata:
  delta-action: land
---

# Land changes

Every image in this repo is built by CI (`.github/workflows/image.yml`). CI
decides for itself which images a change affects, so this skill does not.
Nothing merges to `main` without a green run on the exact commits being merged.

1. Commit the intended changes on a branch named for the change, never on
   `main`. Run `git fetch origin main`, then `GIT_EDITOR=true git rebase
   origin/main`. Resolve clear-cut conflicts automatically; ask the user if
   the intent is ambiguous. If git reports `skipped previously applied
   commit`, the same change was merged and reverted before: rebase with
   `--reapply-cherry-picks` so it is not silently dropped.
2. Push to a branch and open a pull request against `main` with `gh pr create`.
   If one already exists for this branch, push to it instead. Record the PR
   number and the pushed commit hash.
3. Wait for the `Image` workflow run for that commit to finish:
   `gh run watch` on the run `gh run list --commit <hash>` reports, or
   `gh pr checks --watch`. Every job that ran must succeed. A job skipped by
   the path filter is not a failure. If a job fails, stop, show the user the
   failing step's log (`gh run view --log-failed`), and do not merge.
4. If the host image job ran, the user needs to boot the result before it
   lands. CI pushed it as `ghcr.io/samcday/workstation-config:pr-<n>`. Ask the
   user to run `sudo bootc switch ghcr.io/samcday/workstation-config:pr-<n>`
   (or `rpm-ostree rebase` to the same reference), reboot, and report back.
   Wait for that confirmation; never upgrade or reboot automatically. After
   confirmation, run `rpm-ostree status --json` on that machine: the
   deployment with `booted: true` must reference the `pr-<n>` tag and a
   `container-image-reference-digest` matching the one the CI push step
   printed. Stop on a mismatch or missing evidence.
5. If toolbox images ran, pull the one the change was about and make sure it
   works here, the way other machines will use it:
   `toolbox create <name>-pr --image ghcr.io/samcday/workstation-config/toolbox[-<variant>]:pr-<n>`,
   then `toolbox run -c <name>-pr -- <a command the change was meant to
   enable>`, for example `rg --version` for the base or a `meson setup` in a
   phosh checkout for the phosh variant. Remove the test container afterwards
   with `toolbox rm -f <name>-pr`. If the user wants to live with the images
   for a while, stop here, leave the PR as a draft, and resume at step 6 when
   they say so.
6. Merge: `gh pr merge <n> --rebase --delete-branch`. Do not squash (the
   commit hashes CI verified must be what lands). If `main` moved since the
   run, rebase and return to step 3.
7. Ask the main/parent Delta thread to run
   `GIT_EDITOR=true git pull --rebase --autostash origin main` in its
   `workstation-config` checkout. After a host-image merge, remind the user to
   switch the machine back to the `:main` tag once the push build finishes:
   `sudo bootc switch ghcr.io/samcday/workstation-config:main`.

Local host-image builds (`host/build-image`, rootful podman) remain available
for fast iteration before opening a PR, but they are not a substitute for the
CI run and no longer part of landing.
