#!/usr/bin/env python3
"""실제 등록과 운영 설정이 빠진 출시 후보를 차단한다. 비밀값을 읽거나 출력하지 않는다."""
import argparse
import json
import re
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument('--root', type=Path, default=Path(__file__).resolve().parents[1])
args = parser.parse_args()
root = args.root
blockers = []
config = json.loads((root / 'game/config/android.json').read_text())
for field, pattern in [('admob_app_id', r'ca-app-pub-\d{16}~\d{10}'),
                       ('interstitial_id', r'ca-app-pub-\d{16}/\d{10}')]:
    value = config.get(field, '')
    if not re.fullmatch(pattern, value) or '3940256099942544' in value:
        blockers.append(f'{field}: 운영 식별자 미확인 또는 테스트 값')
if config.get('package') != 'com.seoleeapps.crowdgateduel':
    blockers.append('Android 패키지 불일치')
listing = json.loads((root / 'play-store/google-play.config.json').read_text())
for kind, values in listing['assets'].items():
    for file in values if isinstance(values, list) else [values]:
        if not (root / file).is_file():
            blockers.append(f'{kind}: {file} 없음')
for key in ['dataSafety', 'contentRating', 'koreaGameRating']:
    if not listing['contentDeclarations'].get(key, '').startswith('completed-in-play-console:'):
        blockers.append(f'{key}: 실제 Console 확인 대기')
print(json.dumps({'ready': not blockers, 'blockers': blockers}, ensure_ascii=False, indent=2))
raise SystemExit(bool(blockers))
