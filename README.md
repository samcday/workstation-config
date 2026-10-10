# workstation-config

My home desktop and personal laptop run Fedora Silverblue. I'm layering extra changes on top in the Dockerfile, and then booting this image using `rpm-ostree` native OCI container support.

Mostly, the layered changes are some extra package repos and a bunch of extra packages.

The repository retains a [ChatGPT Computer remote control workaround](chatgpt/README.md)
previously used for pairing the Linux desktop clients and controlling active tasks
from either machine. The image no longer applies it.

In future, I hope to rebase this image/repo on top of bootc and use that instead.
