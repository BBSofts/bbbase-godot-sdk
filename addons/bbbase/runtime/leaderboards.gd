extends RefCounted
class_name BBBaseLeaderboards
## 등록형 리더보드 조회(API 키). 정의 등록은 운영자가 대시보드/CLI 로 미리 한다.
## 점수는 레코드 저장 시 전용 테이블에 자동 동기화된다.
##
## 반환은 BBBaseResult. data 모양은 서버 버전에 따라 배열이거나 {ranks/items/entries:[...]}.

var _client: BBBaseClient


func _init(client: BBBaseClient) -> void:
	_client = client


## Top-N 순위. group_key 를 주면 그룹(예: 길드ID)으로 좁힌 하위 랭킹
## — 리더보드가 groupByCol 로 등록돼 있어야 한다. 빈 문자열이면 전체 랭킹.
## res.data = 원본 응답(JSON). 줄 배열만 필요하면 get_top_entries 사용.
func get_top(leaderboard_id: String, limit := 10, offset := 0, group_key := "") -> BBBaseResult:
	var g := "" if group_key == "" else "&groupKey=" + group_key.uri_encode()
	var path := "/leaderboards/%s/ranks?limit=%d&offset=%d%s" % [leaderboard_id.uri_encode(), limit, offset, g]
	return await _client.send_project("GET", path)


## Top-N 을 순위 줄 배열(Array[Dictionary])로 정규화해 반환.
## 응답이 배열이거나 {items/ranks/entries:[...]} 형태 모두 처리.
func get_top_entries(leaderboard_id: String, limit := 10, offset := 0, group_key := "") -> BBBaseResult:
	var res := await get_top(leaderboard_id, limit, offset, group_key)
	if not res.ok:
		return res
	var arr := _extract_array(res.data)
	return BBBaseResult.success(arr, res.status, res.raw_body)


## 특정 엔티티(보통 내 user_id)의 순위. 점수 없으면 ok=true, data=null.
## group_key 를 주면 그 그룹 내 순위.
func get_rank(leaderboard_id: String, entity_id: String, group_key := "") -> BBBaseResult:
	var g := "" if group_key == "" else "?groupKey=" + group_key.uri_encode()
	var path := "/leaderboards/%s/ranks/%s%s" % [leaderboard_id.uri_encode(), entity_id.uri_encode(), g]
	var res := await _client.send_project("GET", path)
	if not res.ok and (res.status == 404 or res.error_code == BBBaseErrorCodes.LEADERBOARD_SCORE_NOT_FOUND):
		return BBBaseResult.success(null, res.status, res.raw_body)
	return res


func _extract_array(data: Variant) -> Array:
	if data is Array:
		return data
	if data is Dictionary:
		for key in ["items", "ranks", "entries"]:
			if data.get(key) is Array:
				return data[key]
	return []
