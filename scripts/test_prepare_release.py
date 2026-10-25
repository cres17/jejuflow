import base64
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

SCRIPT = Path(__file__).with_name('prepare_release.py').resolve()


class ReleasePreparationTest(unittest.TestCase):
    def run_preparation(self, root, **overrides):
        env = {**os.environ, 'BUILD_NUMBER': '3', 'RUNNER_TEMP': str(root),
               'KEYSTORE_BASE64': base64.b64encode(b'test-keystore').decode(),
               'STORE_PASSWORD': ' leading\\password', 'KEY_PASSWORD': 'key-secret',
               'KEY_ALIAS': 'release', 'WEATHER_KEY': 'weather-secret',
               'TAGO_KEY': 'tago-secret', 'TOUR_KEY': 'tour-secret',
               'KAKAO_KEY': 'kakao-secret', **overrides}
        return subprocess.run([sys.executable, str(SCRIPT)], cwd=root, env=env,
                              capture_output=True, text=True)

    def test_missing_secret_and_invalid_version_do_not_create_signing_files(self):
        for override in [{'KEY_PASSWORD': ''}, {'BUILD_NUMBER': '3; echo unsafe'},
                         {'KEYSTORE_BASE64': 'not-base64'}]:
            with self.subTest(override=override), tempfile.TemporaryDirectory() as directory:
                root = Path(directory)
                (root / 'android').mkdir()
                result = self.run_preparation(root, **override)
                self.assertNotEqual(result.returncode, 0)
                self.assertFalse((root / 'android/key.properties').exists())
                self.assertFalse((root / 'jejuflow-release.jks').exists())
                self.assertNotIn('weather-secret', result.stdout + result.stderr)

    def test_files_contain_expected_values_without_printing_secrets(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / 'android').mkdir()
            result = self.run_preparation(root)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(result.stdout, '')
            self.assertEqual((root / 'jejuflow-release.jks').read_bytes(), b'test-keystore')
            defines = json.loads((root / 'jejuflow-defines.json').read_text())
            self.assertEqual(defines['JEJUFLOW_WEATHER_API_KEY'], 'weather-secret')
            self.assertEqual(defines['JEJUFLOW_KAKAOMAP_KEY'], 'kakao-secret')
            properties = (root / 'android/key.properties').read_text()
            self.assertIn('storePassword=\\ leading\\\\password', properties)


if __name__ == '__main__':
    unittest.main()
