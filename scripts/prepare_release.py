"""Prepare release-only files without printing key material."""
import base64
import json
import os
from pathlib import Path


def properties_value(value: str) -> str:
    return (value.replace('\\', '\\\\').replace('\n', '\\n')
            .replace('\r', '\\r').replace('\t', '\\t').replace(' ', '\\ '))


def main() -> None:
    required = ['BUILD_NUMBER', 'KEYSTORE_BASE64', 'STORE_PASSWORD',
                'KEY_PASSWORD', 'KEY_ALIAS', 'WEATHER_KEY', 'TAGO_KEY',
                'TOUR_KEY', 'KAKAO_KEY', 'RUNNER_TEMP']
    missing = [name for name in required if not os.environ.get(name)]
    if missing:
        raise SystemExit('Missing release configuration: ' + ', '.join(missing))
    number = os.environ['BUILD_NUMBER']
    if not number.isascii() or not number.isdecimal() or not 0 < int(number) <= 2100000000:
        raise SystemExit('BUILD_NUMBER must be a positive Android versionCode')
    temporary = Path(os.environ['RUNNER_TEMP'])
    keystore = temporary / 'jejuflow-release.jks'
    try:
        decoded = base64.b64decode(os.environ['KEYSTORE_BASE64'], validate=True)
    except ValueError:
        raise SystemExit('ANDROID_KEYSTORE_BASE64 is not valid base64') from None
    os.umask(0o077)
    keystore.write_bytes(decoded)
    properties = {'storeFile': str(keystore.resolve()),
                  'storePassword': os.environ['STORE_PASSWORD'],
                  'keyPassword': os.environ['KEY_PASSWORD'],
                  'keyAlias': os.environ['KEY_ALIAS']}
    Path('android/key.properties').write_text(
        ''.join(f'{key}={properties_value(value)}\n' for key, value in properties.items()),
        encoding='utf-8')
    defines = {f'JEJUFLOW_{key}_API_KEY': os.environ[f'{key}_KEY']
               for key in ['WEATHER', 'TAGO', 'TOUR']}
    defines['JEJUFLOW_KAKAOMAP_KEY'] = os.environ['KAKAO_KEY']
    (temporary / 'jejuflow-defines.json').write_text(json.dumps(defines), encoding='utf-8')


if __name__ == '__main__':
    main()
