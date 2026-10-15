---
name: land
description: >-
  Land workstation-config changes through a draft PR, green CI, review, and
  explicit merge approval. Deployment is separate. Use only when the user
  explicitly requests landing.
metadata:
  delta-action: land
---

# Land changes

Landing requires successful CI, review, and explicit merge approval.
It does not require a host reboot, a toolbox trial, or a local image build.
The user updates machines separately and uses the normal image rollback
commands when needed.

A `/land` request starts preparation, not a merge. Never push directly to
`main`. Never bypass or change repository rules. Ask before rewriting
published Git history or force-pushing.

## Prepare and review

1. Read the diff and run the relevant local checks.
2. Inspect the Git remotes and select the source remote, not Delta's `local`
   backlink. The commands below use `origin`.
3. Commit on a branch named for the change, never on `main`.
4. Fetch `origin/main`. If the branch needs an update, merge it with
   `GIT_EDITOR=true git merge origin/main`. Ask about unclear conflicts.
5. Push the branch with `git push origin <branch>`.
6. Reuse its open PR, or create one with
   `gh pr create --draft --fill --base main --head <branch>`.
7. Keep the PR as a draft until approval. Use `gh pr ready <n> --undo` when
   needed.
8. Review `gh pr diff <n>` and resolve any blocking review findings.

Use a branch in this repository. CI cannot publish PR images from a fork.

## Wait for CI

Read the PR head SHA with `gh pr view <n> --json headRefOid`.
The head SHA identifies the commit that needs CI and approval.

Compare the changed paths, including deletions and renames, with the
`pull_request.paths` lists in `.github/workflows/host.yml` and
`.github/workflows/toolbox.yml`. Those lists select the required image builds.
A change to `.github/setup-storage` selects both workflows.

For each selected workflow, find the newest PR run for that head:

```shell
gh run list --workflow <host.yml or toolbox.yml> --event pull_request --commit <head SHA> --json databaseId,attempt,status,conclusion
gh run watch <run ID> --exit-status
```

Make sure that every image job in each selected workflow succeeds, including
its smoke tests and publication steps. A failed, cancelled, missing, or
skipped image job is not a pass. Also wait for any other required checks.
If a run fails, read `gh run view <run ID> --log-failed` and fix the problem.

If no workflow matches the diff, report that no image build is needed.
Do not infer this from a missing run. Native path filters can leave
unconditionally required workflow checks pending. If repository rules block
the PR for that reason, ask the user rather than changing the rules.

## Approve and merge

Show the PR, the head SHA, the CI results, and the review outcome.
Ask: "Approve merging PR #<n> at head `<head SHA>`?"
If the user declines or does not answer, leave the PR as a draft.
If the head changes, repeat CI, review, and approval.

Before merging, make sure that the approved head and CI results are still
current. Respect the repository merge rules. These workflows do not handle
`merge_group` events, so ask before using a merge queue.

After explicit approval, run:

```shell
gh pr ready <n>
gh pr merge <n> --merge --match-head-commit <head SHA> --delete-branch
```

If GitHub refuses the merge, restore the draft state and resolve the cause.
Do not use `--admin` or bypass failed checks.

## Report publication

Read the merge SHA with
`gh pr view <n> --json mergeCommit --jq .mergeCommit.oid`.
Wait for each affected workflow's `push` run on that commit:

```shell
gh run list --workflow <host.yml or toolbox.yml> --event push --commit <merge SHA>
gh run watch <run ID> --exit-status
```

Report the merged commit and the publication results separately.
If publication fails, show the failed step. Do not claim that `:main` updated.
The workflows rebuild after merging. They do not promote the PR images.

Deployment is not part of landing. Do not update, rebase, roll back, or reboot
a machine without a separate request. Do not replace or remove existing
toolbox containers or images without permission. Manual trials are optional,
not a merge requirement.
