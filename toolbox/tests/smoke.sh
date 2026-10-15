#!/bin/bash
# Run inside the image. Use packaged tools, not a shared user toolchain.
set -euo pipefail
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin

test "$(rpm -E %fedora)" = 45
rg --version
cargo --version
go version
kubectl version --client
oras version
sops --version

pkg-config --modversion libphosh-0.45 gtk+-3.0 wlroots-0.20
phoc --version
vng --version
aarch64-linux-gnu-gcc --version
aarch64-linux-musl-gcc --version
mock --version
rpmlint --version
fedpkg --help

python3 - <<'PY'
from mockbuild.config import load_config

for target in ("fedora-45-x86_64", "fedora-rawhide-x86_64"):
    config = load_config("/etc/mock", target)
    assert config["isolation"] == "simple", target
    assert config["use_bootstrap"] is True, target
    assert config["use_bootstrap_image"] is False, target
    print(f"{target}: DNF bootstrap enabled")
PY

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
cd "$work"
export CARGO_HOME="$work/cargo-home"
export GOCACHE="$work/go-cache" GOPATH="$work/go" GOTOOLCHAIN=local

cat > hello.c <<'C'
#include <stdio.h>
int main(void) { puts("C toolchain passed"); return 0; }
C
gcc -Wall -Werror hello.c -o hello
./hello
# Fedora's cross compiler targets kernel work, without a target libc sysroot.
printf 'int toolbox_cross(void) { return 42; }\n' > cross.c
aarch64-linux-gnu-gcc -ffreestanding -c cross.c -o hello-arm64.o
readelf -h hello-arm64.o

cargo new --vcs none --name toolbox_trial rust
cargo run --offline --manifest-path rust/Cargo.toml

cat > hello.go <<'GO'
package main
import "fmt"
func main() { fmt.Println("Go toolchain passed") }
GO
go run hello.go
printf 'Unified toolbox smoke test passed.\n'
