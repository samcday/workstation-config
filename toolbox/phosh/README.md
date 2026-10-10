# phosh toolbox image

Variant of the [base toolbox image](../Containerfile) for developing phosh, phoc, phrog, libphosh, phosh-mobile-settings and gmobile.

## Create

```shell
podman pull ghcr.io/samcday/workstation-config/toolbox-phosh:main
toolbox create phosh --image ghcr.io/samcday/workstation-config/toolbox-phosh:main
toolbox enter phosh
```

## Build phosh from source

```shell
git clone https://gitlab.gnome.org/World/Phosh/phosh && cd phosh && meson setup _build && ninja -C _build
```

## Run nested under the host GNOME session (from the phosh tree)

```shell
WLR_BACKENDS=wayland phoc -C data/phoc.ini -E _build/run
```

## phrog (from the phrog tree; login: any user, password `0`)

```shell
cargo build
phoc -S -E "target/debug/phrog --fake"
```

## Tests

```shell
xvfb-run -a meson test --no-suite screenshots -C _build
```

## Host-only limits

Real greetd/seatd login sessions can't be tested from the toolbox; phrog as the actual greeter still needs the host image.
