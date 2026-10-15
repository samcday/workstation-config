#!/bin/bash
# Rawhide packaging regression test for the unified toolbox image.
# Run only in a disposable rootless Podman container with --privileged.
# Mock needs namespaces for its chroots. No host home or container storage
# is mounted here. The published image is never modified by this test.
set -euo pipefail

if [ "${FEDPKG_SMOKE_TEST:-}" != 1 ] || [ "$(id -u)" -ne 0 ] ||
    [ ! -e /run/.containerenv ] || [ -e /run/.toolboxenv ]; then
    echo 'Run this only in a disposable Podman container with FEDPKG_SMOKE_TEST=1.' >&2
    exit 2
fi

python3 - <<'PY'
from mockbuild.config import load_config

for target in ("fedora-45-x86_64", "fedora-rawhide-x86_64"):
    config = load_config("/etc/mock", target)
    assert config["isolation"] == "simple", (target, config["isolation"])
    assert config["use_bootstrap"] is True, target
    assert config["use_bootstrap_image"] is False, target
    print(f"{target}: simple isolation, DNF bootstrap enabled")
PY

# Reproduce an unavailable nested Podman without touching any host IPC locks.
# Fail even if Mock catches the error and later falls back successfully.
cat > /usr/bin/podman <<'SH'
#!/bin/sh
touch /tmp/unexpected-nested-podman
echo 'Nested Podman must not be used for the toolbox bootstrap' >&2
exit 99
SH
chmod 0755 /usr/bin/podman

work=$(mktemp -d /var/tmp/fedpkg-smoke.XXXXXX)
useradd --create-home --home-dir "$work/home" --groups mock mock-smoke
mkdir -p "$work/rpmbuild/SPECS" "$work/rpmbuild/SOURCES" "$work/results"
cat > "$work/rpmbuild/SPECS/toolbox-smoke.spec" <<'SPEC'
Name: toolbox-smoke
Version: 1
Release: 1
Summary: A toolbox packaging regression test
License: MIT
BuildArch: noarch

%description
Tests a Rawhide RPM build without nested Podman.

%install
mkdir -p %{buildroot}%{_datadir}/toolbox-smoke
printf 'Rawhide mock build passed\n' > %{buildroot}%{_datadir}/toolbox-smoke/result

%files
%{_datadir}/toolbox-smoke

%changelog
* Wed Oct 14 2026 Toolbox regression test - 1-1
- Exercise DNF bootstrap in the packaging image.
SPEC
chown -R mock-smoke:mock-smoke "$work"

runuser -u mock-smoke -- \
    rpmbuild -bs --define "_topdir $work/rpmbuild" \
    "$work/rpmbuild/SPECS/toolbox-smoke.spec"
runuser -u mock-smoke -- \
    timeout --signal=TERM --kill-after=30s 15m \
    mock -r fedora-rawhide-x86_64 \
    --resultdir "$work/results" \
    --rebuild "$work/rpmbuild/SRPMS/toolbox-smoke-1-1.src.rpm"
test ! -e /tmp/unexpected-nested-podman
rpm -qp --qf '%{NAME} %{VERSION}-%{RELEASE} %{ARCH}\n' \
    "$work/results/toolbox-smoke-1-1.noarch.rpm"
printf 'Rawhide mock RPM build passed without nested Podman.\n'
