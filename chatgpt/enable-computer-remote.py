#!/usr/bin/env python3
"""Expose the Computer controller tab in the tested ChatGPT Linux build."""

import argparse
import hashlib
import json
from pathlib import Path
import shutil
import struct
import tempfile


# chatgpt-26.917.62051-1.x86_64. Both archives were verified during the
# successful laptop/desktop pairing test on 2026-09-28. Review on updates.
ORIGINAL_SHA256 = "f32d90f78c957a06f57e355999e0e8ad7a92f658151162aa5d0f0d2e54bbc9f7"
PATCHED_SHA256 = "01fb03cc1340e0afa9b22b6047dd90628df84a79581d631977299e38f49f72a9"
ASSET = "webview/assets/remote-connections-settings-9071fdb8f430.js"
ORIGINAL_EXPRESSION = b"W=xt(),G=!f,K=v==null"
PATCHED_EXPRESSION = b"W=xt(),G=!0,K=v==null"


def sha256(path):
    with path.open("rb") as source:
        return hashlib.file_digest(source, "sha256").hexdigest()


def require(condition, message):
    if not condition:
        raise ValueError(message)


def patch(archive):
    actual_hash = sha256(archive)
    require(
        actual_hash == ORIGINAL_SHA256,
        f"unrecognized app.asar SHA256 {actual_hash}; expected {ORIGINAL_SHA256}. "
        "Review the ChatGPT update and refresh or remove this workaround",
    )

    with archive.open("rb") as source:
        # ASAR starts with a size pickle, then a header pickle containing JSON.
        _, header_size, _, json_size = struct.unpack("<4I", source.read(16))
        header_bytes = source.read(json_size)
        header = json.loads(header_bytes)
        entry = header
        for component in ASSET.split("/"):
            entry = entry["files"][component]
        asset_offset = 8 + header_size + int(entry["offset"])
        source.seek(asset_offset)
        asset = source.read(entry["size"])

    require(asset.count(ORIGINAL_EXPRESSION) == 1, "controller expression is not unique")
    patched = asset.replace(ORIGINAL_EXPRESSION, PATCHED_EXPRESSION)
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

    # Build a sibling copy, then replace only after it matches the tested output.
    # This preserves the original on any precondition or verification failure.
    with tempfile.TemporaryDirectory(prefix=".computer-remote-", dir=archive.parent) as temporary:
        candidate = Path(temporary) / "app.asar"
        shutil.copy2(archive, candidate)
        with candidate.open("r+b") as output:
            output.seek(16)
            output.write(patched_header)
            output.seek(asset_offset)
            output.write(patched)
        require(sha256(candidate) == PATCHED_SHA256, "patched archive differs from tested output")
        candidate.replace(archive)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("archive", type=Path, help="path to the image's ChatGPT resources/app.asar")
    args = parser.parse_args()
    try:
        patch(args.archive)
    except (OSError, ValueError, KeyError, TypeError, struct.error) as error:
        parser.exit(1, f"Computer remote patch failed: {error}\n")
    print(f"Enabled Computer remote control in {args.archive} (SHA256 {PATCHED_SHA256})")


if __name__ == "__main__":
    main()
