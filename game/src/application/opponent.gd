class_name Opponent
extends RefCounted
## 대국 상대. 기본은 사람이 남긴 선택 기록이고, 기록을 가져오지 못했을 때만 결정론 봇이 대신한다.
##
## 봇에는 표시명을 주지 않는다(DEC-003). 화면은 `is_bot()` 을 보고 봇 배지를 붙인다.
## 이 경계가 무너지면 콘셉트를 폐기한다.

enum Kind { RECORD, BOT }

## 대역별 봇 전략. 낮은 대역은 늘 센 칸을 집는 읽기 쉬운 상대이고,
## 대역 3 부터는 순위를 보고 겹침을 노리거나 피해 사람의 합리적 플레이에 가깝다.
const BOT_STRATEGY_BY_BAND: Array[Strategies.Kind] = [
	Strategies.Kind.MAX_EXPECTED,
	Strategies.Kind.MAX_EXPECTED,
	Strategies.Kind.LEADER_AWARE,
	Strategies.Kind.LEADER_AWARE,
	Strategies.Kind.LEADER_AWARE,
]

var kind: Kind = Kind.BOT
var band: int = 1
var record: ReplayRecord = null


static func from_record(record_in: ReplayRecord) -> Opponent:
	var opponent: Opponent = Opponent.new()
	opponent.kind = Kind.RECORD
	opponent.band = record_in.band
	opponent.record = record_in
	return opponent


static func bot(band_in: int) -> Opponent:
	var opponent: Opponent = Opponent.new()
	opponent.kind = Kind.BOT
	opponent.band = clampi(band_in, 1, BOT_STRATEGY_BY_BAND.size())
	return opponent


func is_bot() -> bool:
	return kind == Kind.BOT


## 봇은 언제나 빈 문자열이다. 사람 표시명을 만들어 붙이지 않는다.
func display_name() -> String:
	return "" if is_bot() else record.display_name


## 구간 index 에서 상대가 고르는 칸. 기록이면 저장된 선택을, 봇이면 그 시점 군중으로 판단한 선택을 낸다.
func pick_at(index: int, gates: Array[Gate], crowd_self: int, crowd_other: int, rng: Pcg32) -> int:
	if not is_bot():
		return record.picks[index]
	var strategy: Strategies.Kind = BOT_STRATEGY_BY_BAND[band - 1]
	return Strategies.pick(strategy, gates, crowd_self, crowd_other, rng)


func to_dict() -> Dictionary:
	if is_bot():
		return {"kind": "bot", "band": band}
	return {"kind": "record", "record": record.to_dict()}


## 복원할 수 없으면 null. 기록 상대를 봇으로 바꿔 복원하면 이미 본 판의 궤적이 달라지므로
## 대체하지 않는다. 호출자는 그 판을 버린다.
static func from_dict(data: Dictionary) -> Opponent:
	match str(data.get("kind", "")):
		"record":
			var restored: ReplayRecord = ReplayRecord.from_dict(data.get("record", {}))
			return Opponent.from_record(restored) if restored != null else null
		"bot":
			return Opponent.bot(int(data.get("band", 1)))
	return null
