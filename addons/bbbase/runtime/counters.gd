extends RefCounted
class_name BBBaseCounters
## 공유 카운터 — 여러 유저가 함께 올리는 숫자(로비 현황판, 커뮤니티 목표, 길드 기여도,
## 난이도별 시도/클리어 수). 카운터 정의(구간·그룹·증가폭 상한·유저당 상한·공개여부)는
## 운영자가 대시보드/CLI 로 미리 등록한다.
##
## ⚠️ 클라는 값을 쓸 수 없고 [b]증가량(+delta)만 요청[/b]한다 — 레코드에 직접 숫자를 쓰던 방식과
##    달리 임의 값(999999)·음수·삭제가 원천 차단된다. 실제 몇이 됐는지는 서버가 정하고,
##    증가 응답의 value 로 돌려준다.
##
## 값은 카운터의 구간(window)별로 따로 쌓인다. DAILY 면 카운터 타임존 자정에 새 구간이
## 시작되고 지난 구간 값은 이력으로 남는다(운영자만 조회). 읽기에는 5초 캐시가 있어 방금
## 올린 값이 아주 잠깐 늦게 보일 수 있다(증가 시 즉시 무효화하므로 보통은 바로 반영된다).
##
## 예) 판이 끝날 때 +1, 로비에서 현황 표시
## [codeblock]
## await BBBase.counters.increment("today_attempts", "easy")
## var res := await BBBase.counters.get_value("today_attempts")
## if res.ok:
##     print("오늘 시도 수: ", res.data.get("total", 0))
## [/codeblock]

var _client: BBBaseClient
var _session: BBBaseSession


func _init(client: BBBaseClient, session: BBBaseSession) -> void:
	_client = client
	_session = session


## 카운터를 delta 만큼 올린다. group 은 카운터에 그룹이 정의돼 있으면 필수이고,
## 없으면 빈 문자열로 둔다(그룹 없는 카운터에 group 을 보내면 400 INVALID_INPUT).
## 성공 시 res.data = { name, group, window, windowKey, value }(value = 증가 후 현재 구간 값).
##
## [b]게임유저 토큰이 필수[/b]다(유저당 상한 판정·제재 적용). 로그인 전에 호출하면 서버에
## 가기 전에 NOT_LOGGED_IN 으로 실패한다 — 값 읽기(get_value)는 로그인 없이도 된다.
##
## 주요 실패:
## [br]· [code]COUNTER_LIMIT_EXCEEDED[/code](429) — 이 유저가 이번 구간에 더할 수 있는 총량을
##   다 썼다. [b]재시도하지 말 것[/b](다음 구간 전까지 계속 실패한다). "오늘은 여기까지"를
##   UI 로 안내하라. res.error_details 에 perUserLimit / windowKey 가 온다.
## [br]· [code]INVALID_COUNTER_DELTA[/code](400) — delta 가 카운터의 maxDelta 를 넘었다(정의 확인).
## [br]· [code]COUNTER_NOT_FOUND[/code](404) — 이름 오타이거나 운영자가 아직 등록하지 않았다.
## [br]· [code]USER_BANNED[/code](403) — 제재된 계정.
func increment(counter_name: String, group := "", delta := 1) -> BBBaseResult:
	if not _session.is_logged_in():
		return BBBaseResult.failure(BBBaseErrorCodes.NOT_LOGGED_IN, "로그인 후에 호출하세요(BBBase.auth.login_...).", 0)
	var path := "/counters/%s/incr" % counter_name.uri_encode()
	var body := { "delta": delta }
	if group != "":
		body["group"] = group
	return await _client.send_project("POST", path, body, true)


## 현재 구간의 값을 읽는다(API 키만 — 로그인 전 로비에서도 호출 가능).
## group 을 주면 그 그룹만, 생략하면 정의된 모든 그룹이 함께 온다.
## 성공 시 res.data = { name, window, windowKey, timezone, values: [ { group, value } ], total }.
## 그룹을 쓰지 않는 카운터는 values 가 [ { "group": null, "value": 12 } ] 한 줄이다.
##
## visibility=OPERATOR 로 등록된 카운터는 게임 키로 못 읽는다(403 FORBIDDEN).
func get_value(counter_name: String, group := "") -> BBBaseResult:
	var path := "/counters/%s/value" % counter_name.uri_encode()
	if group != "":
		path += "?group=%s" % group.uri_encode()
	return await _client.send_project("GET", path, null, false)


## 편의 헬퍼 — 전체 합계(total)만 바로 꺼낸다. 실패하거나 값이 없으면 default_value.
## (성공/실패를 세밀히 다루려면 get_value 를 쓰라.)
func get_total_or(counter_name: String, group := "", default_value := 0) -> int:
	var res := await get_value(counter_name, group)
	if res.ok and res.data is Dictionary:
		return int(res.data.get("total", default_value))
	return default_value
