# workstation-config

My home desktop and personal laptop run Fedora Silverblue. I'm layering extra changes on top in the Dockerfile, and then booting this image using `rpm-ostree` native OCI container support.

Mostly, the layered changes are some extra package repos and a bunch of extra packages.

The host image is being slimmed toward stock Silverblue: dev tooling is moving out of the Dockerfile and into a separate [Fedora toolbox image](toolbox/README.md), which can be updated with a simple image pull instead of a reboot.

The repository retains a [ChatGPT Computer remote control workaround](chatgpt/README.md)
previously used for pairing the Linux desktop clients and controlling active tasks
from either machine. The image no longer applies it.

In future, I hope to rebase this image/repo on top of bootc and use that instead.
