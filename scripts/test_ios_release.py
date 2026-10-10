"""Static release gates; these do not replace Xcode or a physical iPhone."""
from pathlib import Path
import plistlib
import struct
import tempfile
import unittest
from verify_ios_app import verify

ROOT = Path(__file__).resolve().parents[1]


class IOSReleaseTests(unittest.TestCase):
    def test_camera_and_gallery_have_permission_explanations(self):
        with (ROOT / 'ios/Runner/Info.plist').open('rb') as source:
            info = plistlib.load(source)
        for key in ('NSCameraUsageDescription', 'NSPhotoLibraryUsageDescription'):
            with self.subTest(key=key):
                self.assertTrue(info.get(key, '').strip(), f'Missing {key}')

    def bundle(self, folder):
        app = Path(folder) / 'Runner.app'
        app.mkdir()
        info = {
            'CFBundleIdentifier': 'cz.radys.gymzapisnik',
            'CFBundleShortVersionString': '1.0.0',
            'CFBundleVersion': '12',
            'CFBundleSupportedPlatforms': ['iPhoneOS'],
            'CFBundleExecutable': 'Runner',
            'NSCameraUsageDescription': 'Camera',
            'NSPhotoLibraryUsageDescription': 'Photos',
        }
        (app / 'Info.plist').write_bytes(plistlib.dumps(info))
        for relative in ('Runner', 'Frameworks/App.framework/App', 'Frameworks/Flutter.framework/Flutter'):
            path = app / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(b'\xcf\xfa\xed\xfe' + struct.pack('<I', 0x0100000C))
        return app, info

    def test_simulator_is_rejected_even_with_arm64(self):
        with tempfile.TemporaryDirectory() as folder:
            app, info = self.bundle(folder)
            info['CFBundleSupportedPlatforms'] = ['iPhoneSimulator']
            (app / 'Info.plist').write_bytes(plistlib.dumps(info))
            with self.assertRaisesRegex(ValueError, 'physical iPhone'):
                verify(app)

    def test_wrong_identity_is_rejected(self):
        with tempfile.TemporaryDirectory() as folder:
            app, info = self.bundle(folder)
            info['CFBundleIdentifier'] = 'com.example.wrong'
            (app / 'Info.plist').write_bytes(plistlib.dumps(info))
            with self.assertRaisesRegex(ValueError, 'CFBundleIdentifier'):
                verify(app)

    def test_missing_flutter_framework_is_rejected(self):
        with tempfile.TemporaryDirectory() as folder:
            app, _ = self.bundle(folder)
            (app / 'Frameworks/Flutter.framework/Flutter').write_bytes(b'invalid')
            with self.assertRaisesRegex(ValueError, 'arm64 Mach-O'):
                verify(app)


if __name__ == '__main__':
    unittest.main()
