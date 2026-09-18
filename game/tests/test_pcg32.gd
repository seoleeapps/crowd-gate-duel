class_name TestPcg32
extends RefCounted
## PCG32 골든 테스트. 기대값은 Python 레퍼런스 구현(pcg32_random_r)에서 생성했다.


static func run() -> TestBase:
	var t: TestBase = TestBase.new("pcg32")

	# 공식 PCG 데모 시드 (42, 54)
	var rng: Pcg32 = Pcg32.seeded(42, 54)
	var expected_demo: Array[int] = [0xa15c02b7, 0x7b47f409, 0xba1d3330, 0x83d2f293, 0xbfa4784b, 0xcbed606e]
	for i: int in range(expected_demo.size()):
		t.check_eq(rng.next_u32(), expected_demo[i], "demo seed u32[%d]" % i)

	# 시딩 직후 내부 상태
	var rng_state: Pcg32 = Pcg32.seeded(42, 54)
	t.check_eq(rng_state.state, 1753877967969059832, "state after seed(42,54)")

	# 매치 스타일 시드
	var rng2: Pcg32 = Pcg32.seeded(20260716, 1)
	var expected2: Array[int] = [3412479266, 833419240, 876141294, 3374541807, 2628034002, 2168619404, 4193854044, 2753809674]
	for i: int in range(expected2.size()):
		t.check_eq(rng2.next_u32(), expected2[i], "match seed u32[%d]" % i)

	# next_below 편향 제거 경로
	var rng3: Pcg32 = Pcg32.seeded(987654321, 7)
	var expected3: Array[int] = [15, 24, 18, 32, 23, 17, 10, 27, 20, 46, 24, 42]
	for i: int in range(expected3.size()):
		t.check_eq(rng3.next_below(48), expected3[i], "below48[%d]" % i)

	# Fisher–Yates (47→1) 골든 셔플
	var rng4: Pcg32 = Pcg32.seeded(1122334455667788, 2)
	var deck: Array = []
	for i: int in range(48):
		deck.append(i)
	rng4.shuffle_in_place(deck)
	var expected_deck: Array[int] = [6, 17, 27, 30, 22, 18, 3, 29, 43, 21, 44, 33, 20, 14, 1, 24, 5, 12, 36, 19, 23, 10, 47, 32, 38, 25, 41, 16, 42, 40, 31, 0, 34, 8, 4, 39, 37, 7, 15, 35, 46, 13, 11, 45, 28, 9, 26, 2]
	var deck_matches: bool = true
	for i: int in range(48):
		if int(deck[i]) != expected_deck[i]:
			deck_matches = false
	t.check(deck_matches, "fisher-yates golden shuffle")

	# 상태 스냅샷 재개 결정론
	var rng5: Pcg32 = Pcg32.seeded(777, 3)
	rng5.next_u32()
	var snap: Dictionary = rng5.snapshot()
	var a: int = rng5.next_u32()
	var resumed: Pcg32 = Pcg32.from_state(int(snap["state"]), int(snap["inc"]))
	t.check_eq(resumed.next_u32(), a, "snapshot resume")

	# 셔플 기본 통계: 중복·누락 없음 (10,000회)
	var stat_rng: Pcg32 = Pcg32.seeded(5150, 9)
	var position_sum: Array[int] = []
	position_sum.resize(48)
	position_sum.fill(0)
	var clean: bool = true
	for _round: int in range(10000):
		var cards: Array = []
		for i: int in range(48):
			cards.append(i)
		stat_rng.shuffle_in_place(cards)
		var seen: Dictionary = {}
		for i: int in range(48):
			var value: int = int(cards[i])
			if seen.has(value):
				clean = false
			seen[value] = true
			position_sum[i] += value
	t.check(clean, "shuffle 10k no dup/loss")
	# 위치 평균이 이론값 23.5에서 크게 벗어나지 않는지 (±1.0)
	var mean_ok: bool = true
	for i: int in range(48):
		var mean_x100: int = position_sum[i] / 100  # 10000회 → ×100 스케일 평균
		if mean_x100 < 2250 or mean_x100 > 2450:
			mean_ok = false
	t.check(mean_ok, "shuffle positional mean in range")
	return t
