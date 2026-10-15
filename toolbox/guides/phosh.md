# Phosh development

Use the shared `dev` toolbox from the [setup guide](../README.md).
It contains build dependencies for phosh, phoc, phrog, libphosh,
phosh-mobile-settings, and gmobile. Run the following commands inside `dev`.

## Build and test

Clone Phosh and build it with Meson. The test command below excludes the
screenshot suite. It uses Xvfb instead of the host display.

```shell
git clone https://gitlab.gnome.org/World/Phosh/phosh
cd phosh
meson setup _build
ninja -C _build
xvfb-run -a meson test --no-suite screenshots -C _build
```

To run Phosh in a nested window, run this from its source tree:

```shell
WLR_BACKENDS=wayland phoc -C data/phoc.ini -E _build/run
```

From a phrog checkout, build and use the fake login mode. Any user works
with password `0` in that mode.

```shell
cargo build
phoc -S -E "target/debug/phrog --fake"
```

Real greetd/seatd login sessions still need host integration.
The nested test does not prove that phrog works as the machine's login greeter.
