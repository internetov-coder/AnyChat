#!/usr/bin/env python3
"""Verify that an APK's v2/v3 signer certificate matches the debug keystore.

Usage:
  verify_apk_signature.py path/to/app.apk [path/to/debug.keystore]

Without a keystore argument only prints the APK certificate fingerprint.
The keystore is read through `keytool` (part of any JDK).
"""
import hashlib
import struct
import subprocess
import sys
import tempfile
from pathlib import Path


def _blob(data: bytes):
    """Read a single length-prefixed blob (4- or 8-byte prefix)."""
    for width in (4, 8):
        if len(data) < width:
            continue
        n = struct.unpack_from("<I" if width == 4 else "<Q", data)[0]
        if n == len(data) - width:
            return data[width:]
    return data


def _seq(data: bytes):
    """Yield (element, ...) for a length-prefixed sequence, trying 4/8-byte
    prefixes; returns the width that consumed the buffer exactly, or None."""
    for width in (4, 8):
        out = []
        pos = 0
        ok = True
        while pos < len(data):
            if pos + width > len(data):
                ok = False
                break
            if width == 4:
                n = struct.unpack_from("<I", data, pos)[0]
            else:
                n = struct.unpack_from("<Q", data, pos)[0]
            pos += width
            if n < 0 or pos + n > len(data):
                ok = False
                break
            out.append(data[pos:pos + n])
            pos += n
        if ok and pos == len(data) and out:
            return width, out
    return None, []


def _signing_block(data: bytes) -> bytes:
    eocd = data.rfind(b"PK\x05\x06")
    if eocd < 0:
        raise ValueError("no ZIP central directory")
    cd = struct.unpack_from("<I", data, eocd + 16)[0]
    if data[cd - 16:cd] != b"APK Sig Block 42":
        raise ValueError("no APK signing block")
    size = struct.unpack_from("<Q", data, cd - 24)[0]
    pairs = data[cd - size:cd - 24]
    if struct.unpack_from("<Q", data, cd - size - 8)[0] != size:
        raise ValueError("corrupt signing block sizes")
    return pairs


def apk_certificates(path: str) -> list[bytes]:
    data = Path(path).read_bytes()
    block = _signing_block(data)
    pos = 0
    values = {}
    while pos < len(block):
        n = struct.unpack_from("<Q", block, pos)[0]
        pos += 8
        pid = struct.unpack_from("<I", block, pos)[0]
        pos += 4
        values[pid] = block[pos:pos + n - 4]
        pos += n - 4
    for scheme in (0x7109871A, 0xF05368C0):  # v2, v3
        value = values.get(scheme)
        if value is None:
            continue
        _, signers = _seq(_blob(value))
        for signer in signers:
            _, parts = _seq(signer)
            if not parts:
                continue
            _, signed = _seq(parts[0])
            if len(signed) < 2:
                continue
            _, certs = _seq(signed[1])
            for cert in certs:
                if cert.startswith(b"\x30"):
                    return [cert]
    raise ValueError("no signer certificate found")


def keystore_cert(path: str) -> bytes:
    with tempfile.NamedTemporaryFile(suffix=".der") as tmp:
        subprocess.run(
            [
                "keytool", "-exportcert",
                "-keystore", path,
                "-storepass", "android",
                "-alias", "androiddebugkey",
                "-file", tmp.name,
            ],
            check=True,
            capture_output=True,
        )
        return Path(tmp.name).read_bytes()


def main(argv: list[str]) -> int:
    if len(argv) < 2:
        print(__doc__)
        return 2
    certs = apk_certificates(argv[1])
    apk_fp = hashlib.sha256(certs[0]).hexdigest()
    print(f"apkcert sha256 {apk_fp}")
    if len(argv) < 3:
        return 0
    ks_fp = hashlib.sha256(keystore_cert(argv[2])).hexdigest()
    print(f"kscert  sha256 {ks_fp}")
    if apk_fp != ks_fp:
        print("MISMATCH: APK is not signed with the expected keystore")
        return 1
    print("MATCH: APK signature comes from the stable debug keystore")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
