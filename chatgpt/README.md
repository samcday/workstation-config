# ChatGPT Computer remote control

`enable-computer-remote.py` exposes the **Control other devices** tab in the
Linux desktop app's Remote connections settings. This enables the Computer
pairing flow offered by **Devices that can control this PC → Add → Computer**
on the other desktop. It connects to that desktop's running app, allowing the
same active Codex task to be controlled from both computers.

Validated on 2026-09-28 with `chatgpt-26.917.62051-1.x86_64`: pairing succeeded
and both machines could drive the same active task simultaneously.

The patch changes one byte in
`webview/assets/remote-connections-settings-9071fdb8f430.js`:

```diff
-W=xt(),G=!f,K=v==null
+W=xt(),G=!0,K=v==null
```

Here `G` controls `showControlOtherDevices`; `f` comes from feature flag
`782640499`. The flag hook remains in place. The separate availability check,
authentication, MFA, enrollment and device-key handling remain unchanged.
The script updates the ASAR integrity hashes without changing entry sizes or
offsets. It accepts only the exact original archive and checks the complete
patched archive against the checksum of the successfully tested client before
replacing the file.

The Dockerfile applies this after package installation, alongside the existing
Wayland launcher workaround. The resulting image uses the normal `chatgpt`
launcher and app profile; no separate client copy is needed.

## Updating or removing the workaround

An app update, or applying the patch twice, deliberately fails the build with
an unrecognized archive checksum. First check whether the tab is now available
without the patch. If it is, remove the Dockerfile's Computer remote patch step
and this directory. Otherwise inspect the new bundle, revalidate pairing and
simultaneous control, and update the asset path, expression and both checksums
only after testing. Do not just relax the checksum guard.

To undo the patch in a future image, remove its Dockerfile `COPY`/`RUN` block and
rebuild. This does not remove paired devices from the app's profile.

For a local check, use a writable copy of an unmodified archive:

```sh
cp /usr/lib/chatgpt/resources/app.asar /tmp/chatgpt-test.asar
python3 chatgpt/enable-computer-remote.py /tmp/chatgpt-test.asar
sha256sum /tmp/chatgpt-test.asar
```

The expected output checksum is
`01fb03cc1340e0afa9b22b6047dd90628df84a79581d631977299e38f49f72a9`.
The script uses only the Python 3.11+ standard library.
