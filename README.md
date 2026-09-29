# workstation-config

My home desktop and personal laptop run Fedora Silverblue. I'm layering extra changes on top in the Dockerfile, and then booting this image using `rpm-ostree` native OCI container support.

Mostly, the layered changes are some extra package repos and a bunch of extra packages.

The image also carries a [ChatGPT Computer remote control workaround](chatgpt/README.md)
for pairing the Linux desktop clients and controlling active tasks from either machine.

In future, I hope to rebase this image/repo on top of bootc and use that instead.
