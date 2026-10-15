# workstation-config

My home desktop and personal laptop run Fedora Silverblue. Every image they use
is defined here and built by CI:

- [host/](host/README.md): the Silverblue image each machine boots. Kept close
  to stock; only what must be in the booted OS is layered on.
- [toolbox/](toolbox/README.md): toolbox container images with the dev tooling.
  A base image plus variants for phosh, kernel, and Fedora packaging work.
  Updated with an image pull, no reboot.

Changes land through a pull request and successful CI runs for the affected
images; see `.agents/skills/land/SKILL.md`. The
[host workflow](.github/workflows/host.yml) and
[toolbox workflow](.github/workflows/toolbox.yml) use native path filters.
Each also rebuilds weekly on Monday at 09:22 UTC and supports manual runs.

The repository retains a [ChatGPT Computer remote control workaround](chatgpt/README.md)
previously used for pairing the Linux desktop clients and controlling active tasks
from either machine. The image no longer applies it.
