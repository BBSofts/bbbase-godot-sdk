extends RefCounted
class_name BBBaseLeagues
## 리그(티어 사다리 + 주기 승격/강등) 조회(API 키). 리그 정의·승강 규칙은 운영자가
## 대시보드/CLI 로 미리 등록한다. 점수는 records 로 점수 컬럼(기본 league_points)을
## 저장하면 자동 반영되고, league_tier/league_cohort 는 서버가 관리한다(클라가 쓰지 않음).
##
## 반환은 BBBaseResult. get_my_status* 의 data 는 { tier, cohort?, rank, score, total,
## percentile, lastResult } Dictionary, get_my_ranks* 의 data 는 순위 줄 배열(Array[Dictionary]).
## lastResult 는 지난 사이클 결과 { period, tierFrom, tierTo, change, rank, groupSize,
## prevRank, seen }(없으면 null, 서버 JSON 그대로 camelCase) — change=="promote" && !seen 이면
## 승급 연출, 본 뒤 ack_result_mine().

var _client: BBBaseClient
var _session: BBBaseSession


func _init(client: BBBaseClient, session: BBBaseSession) -> void:
	_client = client
	_session = session


# ── 내 현황(로그인한 내 user_id) 편의 메서드 ──

## 내 리그 현황 { tier, cohort?, rank, score, total, percentile }.
func get_my_status_mine(league_id: String) -> BBBaseResult:
	var uid := _require_user_id()
	if uid == "":
		return BBBaseResult.failure(BBBaseErrorCodes.NOT_LOGGED_IN, "로그인 후에 호출하세요(BBBase.auth.login_...).", 0)
	return await get_my_status(league_id, uid)


## 내 그룹(티어 풀=티어, 코호트=방) 안의 랭킹 줄 배열.
func get_my_ranks_mine(league_id: String, limit := 30, offset := 0) -> BBBaseResult:
	var uid := _require_user_id()
	if uid == "":
		return BBBaseResult.failure(BBBaseErrorCodes.NOT_LOGGED_IN, "로그인 후에 호출하세요(BBBase.auth.login_...).", 0)
	return await get_my_ranks(league_id, uid, limit, offset)


## 내 지난 사이클 결과(승급 연출)를 본 뒤 확인 처리(seen=true) — 다음 조회부터 안 뜨게.
## 승급 애니메이션을 보여준 직후 호출한다.
func ack_result_mine(league_id: String) -> BBBaseResult:
	var uid := _require_user_id()
	if uid == "":
		return BBBaseResult.failure(BBBaseErrorCodes.NOT_LOGGED_IN, "로그인 후에 호출하세요(BBBase.auth.login_...).", 0)
	return await ack_result(league_id, uid)


# ── 범용 ──

## 특정 엔티티의 리그 현황 { tier, cohort?, rank, score, total, percentile }.
## 점수가 아직 없으면 ok=true, data=null.
func get_my_status(league_id: String, entity_id: String) -> BBBaseResult:
	var path := "/leagues/%s/me/%s" % [league_id.uri_encode(), entity_id.uri_encode()]
	var res := await _client.send_project("GET", path)
	if not res.ok and (res.status == 404 or res.error_code == BBBaseErrorCodes.LEADERBOARD_SCORE_NOT_FOUND):
		return BBBaseResult.success(null, res.status, res.raw_body)
	return res


## entity_id 의 현재 티어(또는 방) 안의 랭킹 top-N (줄 배열로 정규화).
func get_my_ranks(league_id: String, entity_id: String, limit := 30, offset := 0) -> BBBaseResult:
	var res := await get_my_ranks_raw(league_id, entity_id, limit, offset)
	if not res.ok:
		return res
	var arr := _extract_array(res.data)
	return BBBaseResult.success(arr, res.status, res.raw_body)


## get_my_ranks 의 원본 응답({ items, page }) 버전.
func get_my_ranks_raw(league_id: String, entity_id: String, limit := 30, offset := 0) -> BBBaseResult:
	var path := "/leagues/%s/ranks/%s?limit=%d&offset=%d" % [league_id.uri_encode(), entity_id.uri_encode(), limit, offset]
	return await _client.send_project("GET", path)


## 특정 엔티티의 지난 사이클 결과 확인 처리(seen=true). 결과 없으면 no-op. res.data = { acknowledged }.
func ack_result(league_id: String, entity_id: String) -> BBBaseResult:
	var path := "/leagues/%s/me/%s/ack" % [league_id.uri_encode(), entity_id.uri_encode()]
	return await _client.send_project("POST", path)


func _require_user_id() -> String:
	return _session.user_id if _session.is_logged_in() else ""


func _extract_array(data: Variant) -> Array:
	if data is Array:
		return data
	if data is Dictionary:
		for key in ["items", "ranks", "entries"]:
			if data.get(key) is Array:
				return data[key]
	return []
