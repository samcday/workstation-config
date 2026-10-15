---
name: land
description: >-
  Land workstation-config changes through a draft PR, a green CI run, a trial
  by the user, and explicit approval. Use only when the user explicitly
  requests landing.
metadata:
  delta-action: land
---

# Land changes

CI uses two workflows with native path filters:

- `Host image` (`.github/workflows/host.yml`) builds the host image.
- `Toolbox images` (`.github/workflows/toolbox.yml`) builds the base and all
  three toolbox variants.

Each workflow watches its image directory, its own workflow file, and
`.github/setup-storage`. The `push.paths` and `pull_request.paths` lists in
those files are the source of truth. Weekly and manual runs ignore the path
filters and build every image in that workflow.

A `/land` request starts this procedure. It is not approval to merge. A change
merges only after three things, in this order: green CI for the exact
candidate's affected images, a trial by the user, and explicit approval from
the user. If neither workflow matches, record why no image build is needed
and review the diff instead. Never push to `main`, never use `--admin`, and
never bypass or change the repository rules.

The candidate is one PR head commit that CI tested on one `main` commit. Keep
a record of it in the thread:

- The PR number, the head SHA, and the base SHA (the `main` commit that CI
  tested with the head).
- The checkout SHA and its tree SHA (the hash of the files in that commit).
  On a pull request, `actions/checkout` does not check out the head. It checks
  out a synthetic merge commit that GitHub makes from the head and `main`.
- The ID and attempt number of each selected workflow run. A run of a
  different workflow, event, or commit does not count. If no image build is
  selected, record the head tree and the path-filter decision instead.
- The digest of each image that the run pushed. A digest (`sha256:...`) names
  one exact image. A tag such as `pr-<n>` can move, and a local copy of a tag
  can be old.

If the head or `main` moves, or a new selected workflow run or attempt starts,
the record is out of date. Its green result, trial, and approval no longer
count. Start again at step 1.

1. Commit the changes on a branch named for the change, never on `main`. Run
   `git fetch origin main`. Write the branch tip SHA in the thread as the
   pre-rebase tip. Then run `GIT_EDITOR=true git rebase origin/main`. Resolve
   clear-cut conflicts. If the intent is not clear, ask the user.

   If git reports `skipped previously applied commit <SHA>`, `main` has a
   commit with the same patch. So `main` still has that change, unless a
   later commit on `main` reverted or changed it. Do not reapply the commit
   blindly. `git show --stat <SHA>` lists its paths. For those paths, compare
   with `git diff <pre-rebase tip> HEAD -- <paths>` and read the history with
   `git log --oneline origin/main -- <paths>`. If the branch must bring back a
   reverted change, run `git reset --keep <pre-rebase tip>`. Then rebase again
   with `--reapply-cherry-picks`. If the intent is not clear, ask the user.

2. Push the branch with `git push origin <branch>`. If the branch is already
   on `origin` and the rebase changed it, ask the user before you force-push.
   Then use `git push --force-with-lease=<branch>:<last pushed SHA> origin <branch>`.
   Open the PR from this repository, because CI for a PR from a fork cannot
   push images. Open it as a draft:
   `gh pr create --draft --fill --base main --head <branch>`. If the branch
   already has an open PR, use that PR. If that PR is not a draft, run
   `gh pr ready <n> --undo`. Make sure that
   `gh pr view <n> --json isDraft,isCrossRepository,headRefOid` shows `true`,
   `false`, and the SHA that you pushed.

3. Read the PR diff, including deleted and renamed paths. Compare it with
   each workflow's `pull_request.paths` list. Changes to the shared storage
   helper select both workflows. Do not treat a missing run as a path-filter
   skip unless the diff establishes that no input matched.

   For each selected workflow, find the newest run of the head. Use
   `--workflow host.yml` or `--workflow toolbox.yml`:
   `gh run list --workflow <file> --event pull_request --commit <head SHA> --json databaseId,attempt,status,conclusion`.
   Wait for each run with `gh run watch <run ID> --exit-status`. Read its
   checkout evidence with `gh run view <run ID> --attempt <n> --log`.
   This command shows the full SHA, the tree, and the parents of a commit:
   `gh api repos/samcday/workstation-config/commits/<SHA> --jq '{sha, tree: .commit.tree.sha, parents: [.parents[].sha]}'`.

   CI is green only if all of these are true:

   - Every selected workflow has a successful run. `Host image` must finish
     its `host` job. `Toolbox images` must finish `toolbox` and all three
     `toolbox-variant` jobs. A failed, cancelled, or skipped job is not a
     pass. A workflow that the path filters did not select needs no run.
   - All checkout lines show the same commit. Its first parent is the current
     tip of `main`
     (`gh api repos/samcday/workstation-config/branches/main --jq .commit.sha`),
     not the `baseRefOid` of the PR. Its second parent is the head SHA. Its
     tree is the tree of the head. If the trees differ, the branch does not
     contain that `main`.

   If a job failed, stop. Show the user the log of the failed step
   (`gh run view <run ID> --attempt <n> --log-failed`). A re-run
   (`gh run rerun`) tests the same synthetic merge commit again, even if
   `main` moved. If a SHA or the tree does not match, start again at step 1.
   If all selected runs are green, read each digest from the `Push to GHCR`
   step of the job for that image. Then write the record. If neither workflow
   was selected, record that decision and continue with the diff review.

4. Pause for a trial by the user, also when no images were built. Use the
   recorded digests, never a tag. If no images were built, the trial is a
   review of the diff (`gh pr diff <n>`).

   If the run pushed a host image, the user tries it on a machine that they
   choose. The machines run Fedora Silverblue, and rpm-ostree manages their
   deployments. The user runs:

   ```shell
   sudo rpm-ostree rebase ostree-unverified-registry:ghcr.io/samcday/workstation-config@sha256:<digest>
   systemctl reboot
   ```

   The workflow signs each pushed image with cosign, but
   `ostree-unverified-registry:` does not enforce signatures. The digest makes
   sure that the machine gets the exact image that CI reported. It does not
   prove who made that image. Never upgrade, rebase, roll back, or reboot a
   machine yourself. Do not give a `bootc` command unless the user tells you
   that bootc manages the deployment. An installed `bootc` package does not
   show that.

   After the reboot, run these commands on that machine. If your terminal
   runs on a different machine, ask the user to run them and paste the
   output.

   ```shell
   hostname
   rpm-ostree status --json | jq '.deployments[] | select(.booted) | {ref: .["container-image-reference"], digest: .["container-image-reference-digest"]}'
   ```

   `ref` must be the reference from the rebase command, and `digest` must be
   the recorded host digest. If either one differs or is missing, stop and
   tell the user. Add the hostname and the booted digest to the record.

   If the run pushed toolbox images, try each one that the change affects. A
   change to the base image affects every variant. Give each trial container
   a new name, for example `land-<n>-phosh-<first 12 digest characters>`.
   Never reuse, replace, or remove an existing container, such as `dev`.

   ```shell
   img=ghcr.io/samcday/workstation-config/toolbox[-<variant>]@sha256:<digest>
   podman pull "$img"
   toolbox create --image "$img" <name>
   podman image inspect "$img" --format '{{.Id}}'
   podman container inspect <name> --format '{{.Image}}'
   ```

   The last two commands must print the same image ID. Then do a real task
   that the change is for, with `toolbox run -c <name> -- <command>`. For
   example, run `meson setup` in a phosh checkout for the phosh variant. A
   `--version` command is not enough, because CI runs those already. Then the
   user uses the containers for the trial. Do not remove a container while the
   user uses it.

5. After the trial, show the user the record and the trial results. Ask:
   "Approve merging PR #<n> at head `<head SHA>`?" Only an explicit yes to
   this question is approval. The `/land` request, a yes from before the
   trial, and silence are not approval. If the user declines the trial or the
   merge, leave the PR as a draft and stop. To leave a trial host image, the
   user runs `sudo rpm-ostree rollback` and reboots. Before the reboot,
   `rpm-ostree status` lists the deployment for the next boot first. It must
   be the deployment from before the trial. If the user wants changes, start
   again at step 1.

6. After approval, and before you mark the PR ready, make sure that all of
   these are true:

   - `main` has server-enforced CI and current-base checks for this PR.
     Do not require both path-filtered image workflows unconditionally:
     GitHub leaves required checks pending when their workflow is skipped.
     These workflows do not provide an always-running aggregate check.
     If repository rules need one, stop and ask the user about that policy.
     The strict policy lets a PR merge only when its branch contains the
     current tip of `main`. For a ruleset,
     `gh api repos/samcday/workstation-config/rules/branches/main` shows the
     required checks and `strict_required_status_checks_policy: true`.
     For branch protection,
     `gh api repos/samcday/workstation-config/branches/main/protection` shows
     the check and `required_status_checks.strict: true`.
   - The rule applies to you. Its ruleset
     (`gh api repos/samcday/workstation-config/rulesets/<ruleset_id>`, with
     the `ruleset_id` of the rule) shows `current_user_can_bypass: never`, or
     the branch protection shows `enforce_admins.enabled: true`.
   - The record is still current. The PR head
     (`gh pr view <n> --json headRefOid`) and the tip of `main` did not move,
     and no newer run or attempt exists.

   If a rule is missing or weaker, stop and ask the user. Do not change the
   rules yourself. If something moved, start again at step 1.

   If `main` uses a merge queue, stop and ask the user about its CI gate.
   These workflows do not handle `merge_group` events, so do not enqueue the
   PR and assume that they will test the queue's candidate. With compatible
   rules and no merge queue, run:

   ```shell
   gh pr ready <n>
   gh pr merge <n> --merge --match-head-commit <head SHA> --delete-branch
   ```

   GitHub refuses this merge if the head moved (`--match-head-commit`) or if
   `main` moved (strict policy). If GitHub refuses, run
   `gh pr ready <n> --undo` and start again at step 1. Do not use `--auto`,
   `--admin`, `--rebase`, or `--squash`.

7. After the merge, make sure that the merge commit matches the record. Get
   its SHA with `gh pr view <n> --json mergeCommit --jq .mergeCommit.oid`, and
   read it with the `gh api` command from step 3. Do not expect its SHA to
   equal the checkout SHA, because GitHub makes a new merge commit. Its tree
   must equal the recorded checkout tree. Its first parent must be the base
   SHA, and its second parent must be the head SHA. If any of this differs,
   tell the user at once. Do not try to repair `main` yourself.

8. Wait for each workflow selected by the merge's changed paths:
   `gh run list --workflow <file> --event push --commit <merge SHA>`, using
   `host.yml` or `toolbox.yml`. Apply the same success checks as step 3.
   If a selected run is missing or fails, show the user the evidence and stop.
   The workflows build the images again on `main`. So the `:main`
   images are new builds of the merged tree, not the images that the user
   tried. Promotion of the tried digests to `:main` is a proposed change. The
   workflow does not do it yet.

   After the host run succeeds, give the user these commands for each host on a
   trial digest. A host on a digest stays on that image until it rebases.

   ```shell
   sudo rpm-ostree rebase ostree-unverified-registry:ghcr.io/samcday/workstation-config:main
   systemctl reboot
   ```

   The user decides when to update the usual toolbox containers, such as
   `dev`, to the new `:main` images. The Update section of
   `toolbox/README.md` has the commands.

   Ask the main/parent Delta thread to run
   `GIT_EDITOR=true git pull --rebase --autostash origin main` in its
   `workstation-config` checkout.

Removing trial containers is a separate, optional step. Offer it after the
trial, and remove only containers that this procedure created. Ask the user
first. `toolbox rm` deletes the state that exists only in the container, for
example packages that the user installed in it. Files in `$HOME` stay. Use
`toolbox rm <name>` without `--force`, so that it does not remove a running
container. `toolbox rm` exits with 0 even when it fails, so read its output.

Local host-image builds (`host/build-image`, rootful podman) help fast
iteration before a PR. They do not replace the CI run, and landing does not
use them.
