"""Prepare an optional release keystore without printing credentials."""
import base64
import os
from pathlib import Path

names = ('KEYSTORE_BASE64', 'STORE_PASSWORD', 'KEY_PASSWORD', 'KEY_ALIAS')
values = {name: os.environ.get(name, '') for name in names}
info = Path(os.environ['RUNNER_TEMP']) / 'netscan-signing.txt'
if not any(values.values()):
    info.write_text('Preview APK signed with the Android debug key. Not a production release.\n')
elif not all(values.values()):
    raise SystemExit('All four Android signing secrets are required together.')
else:
    def property_escape(value):
        output = []
        for char in value:
            if char in '\\:=#! ':
                output.append('\\' + char)
            elif char in '\n\r\t\f':
                output.append({'\n': '\\n', '\r': '\\r', '\t': '\\t', '\f': '\\f'}[char])
            elif ord(char) > 126:
                encoded = char.encode('utf-16-be')
                output.extend('\\u%04x' % int.from_bytes(encoded[i:i+2], 'big') for i in range(0, len(encoded), 2))
            else:
                output.append(char)
        return ''.join(output)
    key_path = Path(os.environ['RUNNER_TEMP']) / 'netscan-release.jks'
    key_path.write_bytes(base64.b64decode(''.join(values['KEYSTORE_BASE64'].split()), validate=True))
    properties = {'storeFile': str(key_path), 'storePassword': values['STORE_PASSWORD'],
                  'keyPassword': values['KEY_PASSWORD'], 'keyAlias': values['KEY_ALIAS']}
    Path('android/key.properties').write_text('\n'.join(f'{k}={property_escape(v)}' for k, v in properties.items()) + '\n')
    info.write_text('APK signed with the project release key provided through GitHub secrets.\n')
