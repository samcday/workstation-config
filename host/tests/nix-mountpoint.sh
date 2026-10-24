#!/bin/sh
# Run inside the built host image, with a read-only root and no /nix volume:
# podman run --rm --read-only -i --entrypoint /bin/sh IMAGE < host/tests/nix-mountpoint.sh
set -eu

fail() {
    printf '%s\n' "$*" >&2
    exit 1
}

[ -d /nix ] && [ ! -L /nix ] || fail '/nix must be an image-owned directory, not a symlink'
[ "$(stat -c '%u:%g:%a' /nix)" = '0:0:755' ] || fail '/nix must be root:root mode 0755'
[ -z "$(find /nix -mindepth 1 -maxdepth 1 -print -quit)" ] || fail '/nix must not contain image-owned store data'
case ",$(findmnt -n -o OPTIONS /)," in
    *,ro,*) ;;
    *) fail 'run this test with a read-only container root' ;;
esac

# The installed nix-directory.service must skip its chattr/mkdir commands,
# while nix.mount's directory condition must pass before the persistent bind.
if systemd-analyze condition 'ConditionPathExists=!/nix'; then
    fail 'nix-directory.service would still try to modify the read-only root'
fi
systemd-analyze condition 'ConditionPathIsDirectory=/nix'
printf '%s\n' 'Nix mount point checks passed'
