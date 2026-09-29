#!/usr/bin/env python3
"""효과음 절차 생성. 파이썬 표준 라이브러리만 쓴다.

04 아트 오디오 바이블의 효과음 표를 코드로 합성한다. 외부 음원과 생성 API 를 쓰지 않으므로
라이선스 걱정이 없고, 같은 명령이 언제나 같은 파일을 만든다.

    python3 scripts/make_sfx.py [--out game/assets/audio/sfx]
"""
import argparse
import math
import random
import struct
import wave
from pathlib import Path

RATE = 44100


def env_adsr(n, attack, decay, sustain, release):
    """샘플 수 n 에 맞춘 ADSR 포락선. 시간 인자는 초."""
    a, d, r = int(attack * RATE), int(decay * RATE), int(release * RATE)
    s = max(0, n - a - d - r)
    out = []
    for i in range(n):
        if i < a:
            out.append(i / max(a, 1))
        elif i < a + d:
            out.append(1 - (1 - sustain) * (i - a) / max(d, 1))
        elif i < a + d + s:
            out.append(sustain)
        else:
            out.append(sustain * max(0.0, 1 - (i - a - d - s) / max(r, 1)))
    return out


def tone(freq_fn, dur, shape="sine", env=None, harmonics=(1.0,)):
    """freq_fn(t) 로 주파수가 변하는 음. 위상을 적분해 끊김 없이 미끄러진다."""
    n = int(dur * RATE)
    phase = 0.0
    out = []
    for i in range(n):
        t = i / RATE
        phase += 2 * math.pi * freq_fn(t) / RATE
        v = 0.0
        for k, amp in enumerate(harmonics, start=1):
            p = phase * k
            if shape == "sine":
                v += amp * math.sin(p)
            elif shape == "tri":
                v += amp * (2 / math.pi) * math.asin(math.sin(p))
            elif shape == "square":
                v += amp * (1.0 if math.sin(p) >= 0 else -1.0) * 0.5
        out.append(v)
    if env:
        out = [x * e for x, e in zip(out, env(n))]
    return out


def noise(dur, seed, env=None, lowpass=0.2):
    rnd = random.Random(seed)
    n = int(dur * RATE)
    out, prev = [], 0.0
    for _ in range(n):
        prev += lowpass * (rnd.uniform(-1, 1) - prev)
        out.append(prev)
    if env:
        out = [x * e for x, e in zip(out, env(n))]
    return out


def mix(*tracks, gains=None):
    n = max(len(t) for t in tracks)
    gains = gains or [1.0] * len(tracks)
    return [sum(g * (t[i] if i < len(t) else 0.0) for t, g in zip(tracks, gains)) for i in range(n)]


def concat(*tracks):
    out = []
    for t in tracks:
        out.extend(t)
    return out


def silence(dur):
    return [0.0] * int(dur * RATE)


def normalize(samples, peak=0.8):
    m = max(1e-9, max(abs(x) for x in samples))
    return [x * peak / m for x in samples]


def write(path, samples):
    samples = normalize(samples)
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, x)) * 32767)) for x in samples))


def perc(attack=0.002, release=0.1):
    return lambda n: env_adsr(n, attack, 0.0, 1.0, min(release, n / RATE))


def build():
    s = {}
    # 게이트 확약: 짧은 잠금음. 금속성 딸깍 두 겹
    s["lock"] = mix(
        tone(lambda t: 1800, 0.05, env=perc(0.001, 0.05), harmonics=(1, 0.4, 0.2)),
        concat(silence(0.03), tone(lambda t: 1200, 0.06, env=perc(0.001, 0.06), harmonics=(1, 0.3))),
        noise(0.03, 1, env=perc(0.001, 0.03), lowpass=0.6),
        gains=[0.6, 0.7, 0.3],
    )
    # 동시 공개: 종이 뒤집힘. 짧은 잡음 두 번
    s["flip"] = concat(
        noise(0.05, 2, env=perc(0.004, 0.05), lowpass=0.35),
        silence(0.02),
        noise(0.06, 3, env=perc(0.004, 0.06), lowpass=0.25),
    )
    # 양보(내가 먼저 지나감): 위로 스치는 통과음
    s["yield_pass"] = mix(
        tone(lambda t: 520 + 900 * t / 0.28, 0.28, "tri", env=lambda n: env_adsr(n, 0.02, 0.05, 0.7, 0.15)),
        noise(0.28, 4, env=lambda n: env_adsr(n, 0.05, 0.1, 0.4, 0.12), lowpass=0.15),
        gains=[0.7, 0.3],
    )
    # 막힘(앞서 있다가 양보당함): 낮은 둔탁음
    s["yield_block"] = mix(
        tone(lambda t: 110 - 40 * t / 0.3, 0.3, "sine", env=perc(0.003, 0.3), harmonics=(1, 0.5)),
        noise(0.08, 5, env=perc(0.002, 0.08), lowpass=0.08),
        gains=[0.9, 0.5],
    )
    # 동수 반감: 중간 높이의 두 음이 반씩 겹친다
    s["split"] = mix(
        tone(lambda t: 440, 0.35, "tri", env=perc(0.005, 0.35)),
        tone(lambda t: 330, 0.35, "tri", env=perc(0.005, 0.35)),
        gains=[0.5, 0.5],
    )
    # 군중 증가: 상승 음계. 화면이 증가량에 따라 재생 길이와 높이를 바꾼다
    notes = [523.25, 659.25, 783.99, 1046.5, 1318.5]
    s["grow"] = concat(*[tone(lambda t, f=f: f, 0.07, "tri", env=perc(0.004, 0.07), harmonics=(1, 0.25)) for f in notes])
    # 군중 감소: 하강 음
    s["shrink"] = tone(lambda t: 520 * (1 - 0.55 * t / 0.35), 0.35, "tri", env=lambda n: env_adsr(n, 0.01, 0.05, 0.6, 0.2))
    # 빼앗김: 흡입음. 잡음이 점점 커지다 끊긴다
    s["steal"] = mix(
        noise(0.4, 6, env=lambda n: [(i / n) ** 2 for i in range(n)], lowpass=0.3),
        tone(lambda t: 200 + 700 * t / 0.4, 0.4, "sine", env=lambda n: [(i / n) ** 1.5 for i in range(n)]),
        gains=[0.6, 0.4],
    )
    # 방패 반격: 금속 타격음. 비화성 배음이 오래 울린다
    s["counter"] = mix(
        tone(lambda t: 620, 0.6, "sine", env=perc(0.001, 0.6), harmonics=(1, 0.6, 0.0, 0.35, 0.0, 0.2)),
        tone(lambda t: 1470, 0.4, "sine", env=perc(0.001, 0.4)),
        noise(0.03, 7, env=perc(0.001, 0.03), lowpass=0.7),
        gains=[0.6, 0.3, 0.4],
    )
    # 결승 충돌: 충돌음 뒤 0.3초 정적
    s["crash"] = concat(
        mix(
            noise(0.35, 8, env=perc(0.002, 0.35), lowpass=0.12),
            tone(lambda t: 70 - 30 * t / 0.4, 0.4, "sine", env=perc(0.002, 0.4)),
            gains=[0.8, 0.9],
        ),
        silence(0.3),
    )
    # 버튼: 가벼운 클릭
    s["click"] = tone(lambda t: 1000, 0.03, "tri", env=perc(0.001, 0.03))
    # 타이머 경고: 마지막 1초 틱
    s["tick"] = tone(lambda t: 1500, 0.025, "square", env=perc(0.001, 0.025))
    return s


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", default="game/assets/audio/sfx")
    args = parser.parse_args()
    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    for name, samples in build().items():
        write(out / f"{name}.wav", samples)
        print(f"[sfx] {out / name}.wav {len(samples) / RATE:.2f}s")


if __name__ == "__main__":
    main()
