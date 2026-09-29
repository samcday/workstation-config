# ChatGPT Computer remote control

`enable-computer-remote.py` exposes the **Control other devices** tab in the
Linux desktop app's Remote connections settings. This enables the Computer
pairing flow offered by **Devices that can control this PC → Add → Computer**
on the other desktop. It connects to that desktop's running app, allowing the
same active Codex task to be controlled from both computers.

The script supports the reviewed archives from these x86_64 RPMs:

- `chatgpt-26.917.62051-1`: pairing and simultaneous task control validated.
- `chatgpt-26.924.51851-1`: equivalent visibility gate reviewed and archive
  patching validated; interactive pairing has not been retested on this version.

Each entry changes one byte to make `showControlOtherDevices` true, leaving the
feature-flag hook, availability check and authentication flow intact. The script
updates ASAR integrity hashes without changing entry sizes or offsets. It accepts
only reviewed input archives and checks the complete patched archive against
that entry's expected checksum before replacing the file.

The Dockerfile applies this after package installation, alongside the existing
Wayland launcher workaround. The resulting image uses the normal `chatgpt`
launcher and app profile; no separate client copy is needed.

## Updating or removing the workaround

An unreviewed app update, or applying the patch twice, deliberately fails the
build with an unrecognized archive checksum. First check whether the tab is now
available without the patch. If it is, remove the Dockerfile's Computer remote
patch step and this directory. Otherwise inspect the new bundle and add a
`PATCHES` entry with its exact asset path, expression and input/output checksums.
Validate the archive change and retest pairing and simultaneous control. Do not
just replace the input checksum: the bundle and minified variables can change.

To undo the patch in a future image, remove its Dockerfile `COPY`/`RUN` block and
rebuild. This does not remove paired devices from the app's profile.

For a local check, use a writable copy of an unmodified archive:

```sh
cp /usr/lib/chatgpt/resources/app.asar /tmp/chatgpt-test.asar
python3 chatgpt/enable-computer-remote.py /tmp/chatgpt-test.asar
```

The script prints the selected version and verified output checksum. It uses
only the Python 3.11+ standard library. Inspection and validation evidence is
attached to the fix commit in `refs/notes/evidence`:

```sh
git fetch origin refs/notes/evidence:refs/notes/evidence
git log --show-notes=evidence -- chatgpt/
```
