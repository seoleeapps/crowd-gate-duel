#!/usr/bin/env python3
"""AAB manifest, release signing and ELF page alignment. Does not access a device."""
import argparse
import hashlib
import json
import re
import struct
import subprocess
import zipfile
from pathlib import Path
from xml.etree import ElementTree as ET
p = argparse.ArgumentParser()
p.add_argument('aab', type=Path)
p.add_argument('--version', required=True)
p.add_argument('--code', required=True)
p.add_argument('--certificate', required=True)
a = p.parse_args()
assert a.aab.stat().st_size <= 80 * 1024 * 1024, 'AAB size exceeds 80MB budget'
manifest = subprocess.check_output(['bundletool', 'dump', 'manifest', '--bundle', str(a.aab)], text=True)
root = ET.fromstring(manifest)
ns = '{http://schemas.android.com/apk/res/android}'
assert root.attrib['package'] == 'com.seoleeapps.crowdgateduel', 'package mismatch'
assert root.attrib[ns+'versionName'] == a.version, 'version mismatch'
assert root.attrib[ns+'versionCode'] == a.code, 'code mismatch'
assert int(root.find('uses-sdk').attrib[ns+'targetSdkVersion']) >= 36, 'target SDK below 36'
app = root.find('application')
assert app.attrib.get(ns+'debuggable', 'false') == 'false', 'debuggable build'
ids = json.loads(Path('game/config/android.json').read_text())
meta = {e.attrib[ns+'name']: e.attrib[ns+'value'] for e in app.findall('meta-data') if ns+'value' in e.attrib}
assert meta.get('com.google.android.gms.ads.APPLICATION_ID') == ids['admob_app_id'], 'AdMob app mismatch'
assert 'org.godotengine.plugin.v2.CrowdGatePlatform' in meta, 'platform plugin missing'
subprocess.run(['jarsigner', '-verify', str(a.aab)], check=True, stdout=subprocess.DEVNULL)
cert = subprocess.check_output(['keytool', '-J-Duser.language=en', '-printcert', '-jarfile', str(a.aab)], text=True)
assert 'Android Debug' not in cert, 'debug certificate'
fingerprint = re.search(r'SHA256:\s*([A-Fa-f0-9:]+)', cert)
assert fingerprint, 'missing signing certificate'
normalize = lambda value: value.replace(':', '').lower()
assert normalize(fingerprint[1]) == normalize(a.certificate), 'certificate mismatch'
compression = subprocess.check_output(['bundletool', 'dump', 'config', '--bundle', str(a.aab)], text=True)
assert 'PAGE_ALIGNMENT_16K' in compression, 'bundle ZIP alignment config below 16KB'
libs = []
with zipfile.ZipFile(a.aab) as bundle:
    for name in bundle.namelist():
        if not name.endswith('.so'):
            continue
        data = bundle.read(name)
        assert data[:5] == b'\x7fELF\x02', f'expected 64-bit ELF: {name}'
        endian = '<' if data[5] == 1 else '>'
        offset = struct.unpack_from(endian+'Q', data, 32)[0]
        size, count = struct.unpack_from(endian+'HH', data, 54)
        for i in range(count):
            row = struct.unpack_from(endian+'IIQQQQQQ', data, offset+i*size)
            if row[0] == 1:
                assert row[7] >= 16384 and (row[2]-row[3]) % 16384 == 0, f'ELF alignment: {name}'
        libs.append(name)
assert libs, 'no native libraries'
print(json.dumps({'aab': str(a.aab), 'sha256': hashlib.sha256(a.aab.read_bytes()).hexdigest(),
                  'package': root.attrib['package'], 'version': a.version, 'code': a.code,
                  'uploadCertificateSha256': fingerprint[1], 'elf16KB': libs}, indent=2))
