"""Reject an unsuitable device bundle before packaging it for local re-signing."""
from pathlib import Path
import hashlib
import json
import plistlib
import struct
import sys

ARM64 = 0x0100000C


def has_arm64(path):
    with path.open('rb') as source:
        header = source.read(8)
        if len(header) != 8:
            return False
        if header[:4] in (b'\xcf\xfa\xed\xfe', b'\xce\xfa\xed\xfe'):
            return struct.unpack('<I', header[4:])[0] == ARM64
        if header[:4] in (b'\xfe\xed\xfa\xcf', b'\xfe\xed\xfa\xce'):
            return struct.unpack('>I', header[4:])[0] == ARM64
        if header[:4] in (b'\xca\xfe\xba\xbe', b'\xca\xfe\xba\xbf'):
            count = struct.unpack('>I', header[4:])[0]
            if not 0 < count <= 32:
                return False
            stride = 32 if header[:4] == b'\xca\xfe\xba\xbf' else 20
            table = source.read(count * stride)
            return len(table) == count * stride and any(
                struct.unpack('>I', table[i * stride:i * stride + 4])[0] == ARM64
                for i in range(count)
            )
        return False


def verify(app):
    with (app / 'Info.plist').open('rb') as source:
        info = plistlib.load(source)
    expected = {
        'CFBundleIdentifier': 'cz.radys.gymzapisnik',
        'CFBundleShortVersionString': '1.0.0',
        'CFBundleVersion': '12',
    }
    for key, value in expected.items():
        if info.get(key) != value:
            raise ValueError(f'{key}: expected {value}, got {info.get(key)}')
    if info.get('CFBundleSupportedPlatforms') != ['iPhoneOS']:
        raise ValueError('A physical iPhone build is required; simulator is not allowed.')
    for key in ('NSCameraUsageDescription', 'NSPhotoLibraryUsageDescription'):
        if not info.get(key, '').strip():
            raise ValueError(f'Missing {key}')
    executable = info.get('CFBundleExecutable', '')
    if not executable or Path(executable).name != executable:
        raise ValueError('Invalid bundle executable')
    for relative in (executable, 'Frameworks/App.framework/App', 'Frameworks/Flutter.framework/Flutter'):
        if not has_arm64(app / relative):
            raise ValueError(f'Missing arm64 Mach-O: {relative}')
    return expected


if __name__ == '__main__':
    app = Path(sys.argv[1])
    result = verify(app)
    if len(sys.argv) == 3:
        ipa = Path(sys.argv[2])
        result['sha256'] = hashlib.sha256(ipa.read_bytes()).hexdigest()
        result['signing'] = 'unsigned; re-sign locally with iLoader'
        (ipa.parent / 'ios-build.json').write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
        (ipa.parent / 'SHA256.txt').write_text(f'{result["sha256"]}  {ipa.name}\n', encoding='utf-8')
    print(json.dumps(result))
