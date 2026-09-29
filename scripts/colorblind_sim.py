#!/usr/bin/env python3
"""색각 이상 시뮬레이션(A-3 게이트). 실행 화면 캡처를 세 가지 색각으로 바꿔 나란히 붙인다.

Machado, Oliveira, Fernandes(2009)의 심각도 1.0 행렬을 선형 RGB 에 적용한다.
PIL·numpy 가 필요하므로 공용 Playwright 가상환경으로 실행한다.

    ~/.local/share/seorilabs/playwright/venv/bin/python scripts/colorblind_sim.py <입력.png> <출력.png>
"""
import sys

import numpy as np
from PIL import Image

MATRICES = {
    "protanopia": [[0.152286, 1.052583, -0.204868], [0.114503, 0.786281, 0.099216], [-0.003882, -0.048116, 1.051998]],
    "deuteranopia": [[0.367322, 0.860646, -0.227968], [0.280085, 0.672501, 0.047413], [-0.011820, 0.042940, 0.968881]],
    "tritanopia": [[1.255528, -0.076749, -0.178779], [-0.078411, 0.930809, 0.147602], [0.004733, 0.691367, 0.303900]],
}


def to_linear(c):
    return np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)


def to_srgb(c):
    c = np.clip(c, 0, 1)
    return np.where(c <= 0.0031308, c * 12.92, 1.055 * c ** (1 / 2.4) - 0.055)


def simulate(image, matrix):
    rgb = to_linear(np.asarray(image.convert("RGB"), dtype=np.float64) / 255.0)
    out = to_srgb(rgb @ np.array(matrix).T)
    return Image.fromarray((out * 255).round().astype(np.uint8))


def main():
    src, dst = sys.argv[1], sys.argv[2]
    original = Image.open(src).convert("RGB")
    panels = [original] + [simulate(original, m) for m in MATRICES.values()]
    width, height = original.size
    sheet = Image.new("RGB", (width * len(panels) + 20 * (len(panels) - 1), height), "white")
    for i, panel in enumerate(panels):
        sheet.paste(panel, (i * (width + 20), 0))
    sheet.thumbnail((2400, 2400))
    sheet.save(dst)
    print(f"[colorblind] {dst} (원본, " + ", ".join(MATRICES) + ")")


if __name__ == "__main__":
    main()
