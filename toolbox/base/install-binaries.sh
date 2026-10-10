#!/bin/sh
# GitHub-release binaries the host image fetched with curl. Run as root at
# image build time; the host image pins linux/amd64, so the URLs do too.
#
# Every download is pinned by SHA-256. oras, k9s and sops publish checksum
# files alongside their releases (values below copied from there); cfssl does
# not, so its values were computed from the release assets. The RPMs are not
# GPG-signed by upstream, so the checksum is the only verification. To bump a
# version, update the version and every checksum together.
set -eu

ORAS_VERSION=1.3.4
ORAS_SHA256=f27adb935022d94df8dc77719c322dda592c78a0d57a6f7dcdd8d900b248c454
CFSSL_VERSION=1.6.5
K9S_VERSION=v0.50.15
K9S_SHA256=c734aa5421fdbf09c52fea34848887576d30430a41d070820e1d314e271e81d6
SOPS_VERSION=3.11.0
SOPS_SHA256=2a4530acbd889c6b34c40a815d870e2116f8aaf1bb342ebaa2de11c2ea3655cf

# cfssl v1.6.5 linux_amd64 assets, in the order installed below.
CFSSL_SHA256='
cfssl         ff4d3a1387ea3e1ee74f4bb8e5ffe9cbab5bee43c710333c206d14199543ebdf
cfssljson     09fbcb7a3b3d6394936ea61eabff1e8a59a8ac3b528deeb14cf66cdbbe9a534f
multirootca   16ae8fe2660dbd4b851d4e2041a0bcf3f6a67b8920c1fc3c859777c857284282
cfssl-bundle  8304c84ca5d06edc1f6f7c40afdc71a5da10c03b1960ac6f20a8cb898967e4fa
cfssl-certinfo ebe7cd2d6ad33930fa0db292312ef0acf8ec0e359bc73d4ed8ae7290bd47c955
cfssl-newkey  b83743a1f1801b4151d341c2ae05103f44609cef70bcc2ee803c8594ac8dc84c
cfssl-scan    34b746f1947dc94ec9fac1f66e95d5f871434b1d4ef1f627b127940c302f54e6
mkbundle      a325dbc21d1ee5cffbc0cdf1c7ef5cd5cc117ee1c072609ab0618f1cb2184e85
'

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

# fetch URL SHA256 DEST: download to a temp file (so a failed or truncated
# transfer can never be partially consumed) and verify before moving on.
fetch() {
    curl -fsSL -o "$3" "$1"
    echo "$2  $3" | sha256sum -c --quiet -
}

fetch "https://github.com/oras-project/oras/releases/download/v${ORAS_VERSION}/oras_${ORAS_VERSION}_linux_amd64.tar.gz" \
    "$ORAS_SHA256" "$work/oras.tar.gz"
tar -xz -C /usr/local/bin -f "$work/oras.tar.gz" oras
chmod 0755 /usr/local/bin/oras
echo /usr/local/bin/oras

echo "$CFSSL_SHA256" | while read -r b sum; do
    [ -n "$b" ] || continue
    # Upstream ships mkbundle unprefixed; install it as cfssl-mkbundle.
    case $b in mkbundle) dest=/usr/local/bin/cfssl-mkbundle ;; *) dest=/usr/local/bin/$b ;; esac
    fetch "https://github.com/cloudflare/cfssl/releases/download/v${CFSSL_VERSION}/${b}_${CFSSL_VERSION}_linux_amd64" \
        "$sum" "$dest"
    chmod 0755 "$dest"
    echo "$dest"
done

fetch "https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_linux_amd64.rpm" \
    "$K9S_SHA256" "$work/k9s.rpm"
fetch "https://github.com/getsops/sops/releases/download/v${SOPS_VERSION}/sops-${SOPS_VERSION}-1.x86_64.rpm" \
    "$SOPS_SHA256" "$work/sops.rpm"
dnf install -y "$work/k9s.rpm" "$work/sops.rpm"
echo /usr/bin/k9s
echo /usr/bin/sops
