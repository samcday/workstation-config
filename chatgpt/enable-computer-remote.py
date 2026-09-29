#!/usr/bin/env python3
"""Expose the Computer controller tab in reviewed ChatGPT Linux builds."""

import argparse
import hashlib
import json
from pathlib import Path
import shutil
import struct
import tempfile


# Each app update can change both the asset name and minified variable names.
# Keep reviewed input/output pairs; evidence lives in refs/notes/evidence.
PATCHES = {
    "f32d90f78c957a06f57e355999e0e8ad7a92f658151162aa5d0f0d2e54bbc9f7": {
        "version": "26.917.62051",
        "asset": "webview/assets/remote-connections-settings-9071fdb8f430.js",
        "original": b"W=xt(),G=!f,K=v==null",
        "patched": b"W=xt(),G=!0,K=v==null",
        "sha256": "01fb03cc1340e0afa9b22b6047dd90628df84a79581d631977299e38f49f72a9",
    },
    "f6cfcd56db2928e56ec927a5cc20c8714c0bb05d68ce0711c352f8d69862bb47": {
        "version": "26.924.51851",
        "asset": "webview/assets/remote-connections-settings-553ac787b7d0.js",
        "original": b"be=Xr(),K=!g,xe=S==null",
        "patched": b"be=Xr(),K=!0,xe=S==null",
        "sha256": "0e8e836bb5d2fafb2a0ea833b361d172a5750f5b3a7552fbe9b385aa2ecfc121",
    },
}


def sha256(path):
    with path.open("rb") as source:
        return hashlib.file_digest(source, "sha256").hexdigest()


def require(condition, message):
    if not condition:
        raise ValueError(message)


def patch(archive):
    actual_hash = sha256(archive)
    selected = PATCHES.get(actual_hash)
    require(
        selected is not None,
        f"unrecognized app.asar SHA256 {actual_hash}. "
        "Review the ChatGPT update and add a patch entry or remove this workaround",
    )

    with archive.open("rb") as source:
        # ASAR starts with a size pickle, then a header pickle containing JSON.
        _, header_size, _, json_size = struct.unpack("<4I", source.read(16))
        header_bytes = source.read(json_size)
        header = json.loads(header_bytes)
        entry = header
        for component in selected["asset"].split("/"):
            entry = entry["files"][component]
        asset_offset = 8 + header_size + int(entry["offset"])
        source.seek(asset_offset)
        asset = source.read(entry["size"])

    require(asset.count(selected["original"]) == 1, "controller expression is not unique")
    patched = asset.replace(selected["original"], selected["patched"])
    require(len(patched) == len(asset), "patch would change ASAR asset offsets")

    # Keep the feature-flag hook call and all enrollment/authentication checks.
    # Only showControlOtherDevices becomes true. Electron's integrity metadata
    # must describe the edited JavaScript, including its per-block hashes.
    integrity = entry["integrity"]
    require(integrity["algorithm"] == "SHA256", "unexpected ASAR integrity algorithm")
    block_size = integrity["blockSize"]
    integrity["hash"] = hashlib.sha256(patched).hexdigest()
    integrity["blocks"] = [
        hashlib.sha256(patched[start : start + block_size]).hexdigest()
        for start in range(0, len(patched), block_size)
    ]
    patched_header = json.dumps(header, separators=(",", ":"), ensure_ascii=False).encode()
    require(len(patched_header) == len(header_bytes), "patch would resize ASAR header")

    # Build a sibling copy, then replace only after it matches the reviewed output.
    # This preserves the original on any precondition or verification failure.
    with tempfile.TemporaryDirectory(prefix=".computer-remote-", dir=archive.parent) as temporary:
        candidate = Path(temporary) / "app.asar"
        shutil.copy2(archive, candidate)
        with candidate.open("r+b") as output:
            output.seek(16)
            output.write(patched_header)
            output.seek(asset_offset)
            output.write(patched)
        require(sha256(candidate) == selected["sha256"], "patched archive differs from reviewed output")
        candidate.replace(archive)
    return selected


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("archive", type=Path, help="path to the image's ChatGPT resources/app.asar")
    args = parser.parse_args()
    try:
        selected = patch(args.archive)
    except (OSError, ValueError, KeyError, TypeError, struct.error) as error:
        parser.exit(1, f"Computer remote patch failed: {error}\n")
    print(
        f"Enabled Computer remote control in {args.archive} "
        f"(ChatGPT {selected['version']}, SHA256 {selected['sha256']})"
    )


if __name__ == "__main__":
    main()
