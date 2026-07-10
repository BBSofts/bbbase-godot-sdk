extends RefCounted
class_name BBBaseLogs
## 로그 수집 — API 키만으로 임의 이벤트 로그를 남긴다(로그인/게임유저 토큰 불필요).
## 로그인 실패처럼 "인증 전/실패 시점" 이벤트를 쌓는 게 주 용도 — 일반 레코드 저장은
## 게임유저 토큰이 필요해서 로그인 전/실패 상황을 못 잡는다.
##
## fire-and-forget 로 쓰길 권장한다: 반환값(BBBaseResult)을 무시해도 되고, 전송이
## 실패해도 게임 흐름(로그인 재시도 등)을 막지 않는다.
##
## ⚠️ 서버는 이 로그를 "신뢰할 수 없는 제보"로 취급한다(API 키는 공개 취급). 게임 상태·과금에
##    반영하지 말고 디버깅·통계 참고용으로만 쓴다.
##
## 예)
## [codeblock]
## var res := await BBBase.auth.login_google(id_token)
## if not res.ok:
##     BBBase.logs.send({
##         "level": "error", "category": "login_fail",
##         "message": res.error_message, "data": { "code": res.status } })
## [/codeblock]

var _client: BBBaseClient


func _init(client: BBBaseClient) -> void:
	_client = client


## 로그 1건 전송. entry 는 아래 필드를 담을 수 있다(전부 선택):
##   level    : "debug"|"info"|"warn"|"error" (생략 시 서버가 info)
##   category : 그룹핑 키 (예: "login_fail")
##   message  : 사람이 읽는 메시지
##   platform : 플랫폼 (생략 시 OS.get_name() 으로 자동 채움)
##   data     : 자유 커스텀 필드(Dictionary)
## 반환은 BBBaseResult(무시 가능). 로그인 여부와 무관하게 API 키만으로 동작한다.
func send(entry: Dictionary) -> BBBaseResult:
	var payload := entry.duplicate(true)
	if not payload.has("platform"):
		payload["platform"] = OS.get_name()
	return await _client.send_project("POST", "/logs", payload, false)


## 편의 오버로드 — level/category/message 를 바로 넘긴다. extra 는 data 로 들어간다.
func log_event(level: String, category: String, message := "", extra: Dictionary = {}) -> BBBaseResult:
	var entry := { "level": level, "category": category }
	if message != "":
		entry["message"] = message
	if not extra.is_empty():
		entry["data"] = extra
	return await send(entry)
