# 에셋 제작 방식과 권리 근거

04 아트 오디오 바이블의 "생성 자산의 제작 방식과 도구, 권리 근거를 저장소에 함께 기록한다"를 따른다.

| 경로 | 내용 | 만든 방법 | 권리 근거 |
| --- | --- | --- | --- |
| `art/doll.svg`, `art/gate_*.svg`, `art/lock.svg`, `art/bot.svg`, `art/half.svg`, `art/yield.svg`, `art/hand.svg`, `art/toggle_*.svg` | 군중 인형, 게이트 아이콘 4종, 표식, 스위치 | A-1 에서 고른 시안(`docs/game-design/ui/duel-screen-style-options.html`)의 SVG 도형을 옮기거나 같은 문법으로 직접 그림. 이미지 생성기를 쓰지 않음 | 자체 제작 |
| `fonts/Fredoka-Variable.ttf` | 숫자 서체 | Google Fonts 저장소 `ofl/fredoka` | SIL OFL 1.1 (`fonts/Fredoka-OFL.txt`) |
| `fonts/NotoSansKR-Variable.ttf` | 본문 서체 | Google Fonts 저장소 `ofl/notosanskr` | SIL OFL 1.1 (`fonts/NotoSansKR-OFL.txt`) |
| `audio/sfx/*.wav` | 효과음 12종 | `scripts/make_sfx.py` 가 파이썬 표준 라이브러리로 절차 합성. 같은 명령이 같은 파일을 만든다 | 자체 제작 |
| `audio/bgm_home.ogg`, `audio/bgm_duel.ogg` | 홈·대국 배경음악 루프 | Stability AI Stable Audio 2.5 API 생성(2026-09-29) 후 `game-sound-pipeline` 으로 이음매 처리. 프롬프트는 `audio/sound-manifest.json` | Stability AI API 이용 약관 |
| `audio/sting_win.wav`, `audio/sting_lose.wav` | 승리·패배 짧은 악구 | 위와 같음 | Stability AI API 이용 약관 |

생성 원본(`audio/raw/`)은 수십 MB 라 커밋하지 않는다. 다시 만들려면 API 를 다시 호출해야 한다.

```bash
python3 scripts/make_sfx.py                     # 효과음 다시 만들기(무료, 결정론)
python3 ~/.claude/skills/game-sound-pipeline/scripts/generate_sound.py \
  --manifest game/assets/audio/sound-manifest.json --only bgm_duel --force   # 음악 1곡 다시 생성(유료)
```
