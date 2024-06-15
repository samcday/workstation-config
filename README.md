# workstation-config

My home desktop and personal laptop run Fedora Silverblue. I'm layering extra changes on top in the Dockerfile, and then booting this image using `rpm-ostree` native OCI container support.

Mostly, the layered changes are some extra package repos and a bunch of extra packages.

In future, I hope to rebase this image/repo on top of bootc and use that instead.
