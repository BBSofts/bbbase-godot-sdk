extends Node
class_name BBBaseClient
## 저수준 HTTP 클라이언트. 헤더 세팅·envelope 파싱·에러를 BBBaseResult 로 변환하는
## 책임만 진다. 보통은 BBBase 파사드를 통해 간접 사용한다.
##
## 호출마다 HTTPRequest 자식 노드를 만들어 await 후 정리한다(간단·동시요청 안전).

## 모든 요청 실패 시 방출(전역 처리/로깅용). 개별 호출은 반환된 BBBaseResult 로 분기.
signal request_failed(result: BBBaseResult)

## 액세스 토큰이 만료돼 refresh 를 시도했으나 그마저 실패(리프레시 토큰 만료/폐기)해
## 세션이 자동 정리됐을 때 방출. provider 로 재로그인 UI 를 분기하라("guest"/"google"/...).
## 보통은 BBBase 파사드의 동명 시그널로 중계돼 게임이 그쪽을 구독한다.
signal session_expired(provider: String)

## 운영자가 이 계정을 제재해 서버가 403 USER_BANNED 로 거절했을 때 1회 방출.
## expires_at 은 ISO 8601 문자열이며 ""(빈 문자열)이면 영구 제재. reason 은 운영자 메모("" 가능).
##
## 게임은 이 시그널을 받으면 플레이를 중단하고 정지 안내 화면을 띄워야 한다 — 제재 집행 자체는
## 서버가 하므로(요청이 전부 403) 저장·랭킹·보상은 이미 막혀 있고, 화면 전환은 게임의 몫이다.
##
## SDK 는 토큰을 지우지 않는다: 서버가 제재 중에도 auth/me 는 열어두므로(계정 상태 조회용)
## 세션을 지우면 그 조회 경로까지 막힌다. 또 기간제 제재가 풀렸을 때 재로그인 없이 복구돼야 한다.
signal banned(expires_at: String, reason: String)

var _settings: BBBaseSettings
## 로그인 후 채워지는 게임유저 토큰(레코드 호출 시 Bearer 로 붙음).
## 새 토큰이 들어오면(=로그인 성공) 제재 래치를 푼다 — 기간제 제재가 만료된 뒤 다시
## 로그인하면 같은 세션에서 banned 를 또 받을 수 있어야 하기 때문.
var access_token: String = "":
	set(value):
		access_token = value
		if value != "":
			_banned_emitted = false

## banned 시그널 중복 방출 방지. 게임이 동시에 여러 요청을 날리면 403 이 여러 번 오는데,
## 정지 안내 팝업이 그만큼 뜨면 안 된다(401 refresh single-flight 와 같은 취지).
var _banned_emitted := false
## 401 자동 refresh 를 위임할 인증 객체(BBBaseAuth). init 후 주입된다.
## 순환 생성을 피하려 생성자 대신 setter 로 늦게 연결한다.
var _auth = null

## refresh 단일화(single-flight): 동시에 여러 요청이 401 이 나도 refresh 는 1번만 돈다.
## (refresh 는 리프레시 토큰을 회전시키므로, 동시 refresh 는 뒤늦은 요청이 이미 폐기된
##  토큰을 써 실패→멀쩡한 세션을 오인 로그아웃시키는 stampede 를 유발한다.)
var _refreshing := false
signal _refresh_done(ok: bool)


func setup(settings: BBBaseSettings) -> void:
	_settings = settings


## init 시점에 BBBaseAuth 를 주입한다(401 자동 refresh+재시도용).
func set_auth(auth) -> void:
	_auth = auth


func _log(msg: String) -> void:
	if _settings != null and _settings.verbose_logging:
		print("[BBBase] ", msg)


## 프로젝트 스코프 경로(/projects/{pid}{sub_path}) 로 요청.
func send_project(method: String, sub_path: String, body: Variant = null, with_user_token := false) -> BBBaseResult:
	var path := "/projects/%s%s" % [_settings.active_project_id(), sub_path]
	return await send(method, path, body, with_user_token)


## 임의 경로로 요청. 결과는 BBBaseResult.
## 인증 요청(with_user_token)이 401 로 실패하면 액세스 토큰 만료로 보고 refresh 를
## 1회 시도한 뒤 새 토큰으로 원 요청을 1회 재시도한다. refresh 마저 실패하면 세션을
## 자동 정리하고 session_expired 를 방출한다(게임은 재로그인만 처리하면 됨).
func send(method: String, path: String, body: Variant = null, with_user_token := false) -> BBBaseResult:
	var res := await _send_once(method, path, body, with_user_token)

	# 자동 refresh 대상: 인증 요청이었고, 붙일 토큰이 있었으며, 401 로 거절됐고,
	# refresh 를 위임할 auth 가 연결돼 있을 때. (refresh 자체 호출은 with_user_token=false
	# 라 이 분기를 타지 않아 재귀하지 않는다.)
	if not (with_user_token and _auth != null and access_token != "" \
			and not res.ok and res.status == 401):
		return res

	var ok := await _refresh_once()
	if ok:
		# 새 토큰으로 원 요청 1회 재시도
		return await _send_once(method, path, body, true)
	# refresh 실패 → 세션은 이미 _refresh_once 안에서 정리·신호됨. 원 401 을 그대로 전파.
	return res


## refresh 를 single-flight 로 1회만 실행하고 성공 여부를 반환한다.
## 이미 진행 중이면 그 결과를 기다려 공유한다(동시 401 stampede 방지).
func _refresh_once() -> bool:
	if _refreshing:
		return await _refresh_done  # 진행 중인 refresh 의 결과를 공유

	_refreshing = true
	_log("access token 401 → refresh 시도")
	var refreshed: BBBaseResult = await _auth.refresh()
	var ok: bool = refreshed.ok
	if not ok:
		# refresh 실패 = 리프레시 토큰도 만료/폐기 → 세션 정리 + 재로그인 신호
		_log("refresh 실패 → 세션 만료 처리")
		var prov: String = _auth.handle_session_expired()
		session_expired.emit(prov)
	_refreshing = false
	_refresh_done.emit(ok)
	return ok


## 실제 1회 요청. refresh/재시도 래핑은 send 가 담당한다.
func _send_once(method: String, path: String, body: Variant = null, with_user_token := false) -> BBBaseResult:
	var http := HTTPRequest.new()
	add_child(http)
	if _settings.request_timeout_seconds > 0:
		http.timeout = _settings.request_timeout_seconds

	var headers := PackedStringArray()
	headers.append("X-API-Key: " + _settings.active_api_key())
	headers.append("Content-Type: application/json")
	if with_user_token and access_token != "":
		headers.append("Authorization: Bearer " + access_token)

	var body_str := ""
	if body != null:
		body_str = body if body is String else JSON.stringify(body)

	var url := _settings.normalized_base_url() + path
	_log("%s %s" % [method, path])

	var start_err := http.request(url, headers, _method_enum(method), body_str)
	if start_err != OK:
		http.queue_free()
		return _fail(BBBaseResult.network("요청을 시작할 수 없습니다 (%d)" % start_err))

	# request_completed(result, response_code, headers, body)
	var response: Array = await http.request_completed
	http.queue_free()

	var result_code: int = response[0]
	var status_code: int = response[1]
	var raw: String = (response[3] as PackedByteArray).get_string_from_utf8()

	# ── 연결 자체가 실패(네트워크/타임아웃) ──
	if result_code != HTTPRequest.RESULT_SUCCESS:
		return _fail(BBBaseResult.network("연결 실패 (result=%d)" % result_code))

	var parsed: Variant = JSON.parse_string(raw)  # 비-JSON 이면 null

	# ── HTTP 4xx/5xx 또는 success:false ──
	var success_false: bool = parsed is Dictionary and parsed.get("success") == false
	if status_code >= 400 or success_false:
		var code := "HTTP_%d" % status_code
		var msg := "요청 실패 (%d)" % status_code
		var details: Dictionary = {}
		if parsed is Dictionary and parsed.get("error") is Dictionary:
			var e: Dictionary = parsed["error"]
			code = e.get("code", code)
			msg = e.get("message", msg)
			if e.get("details") is Dictionary:
				details = e["details"]
		return _fail(BBBaseResult.failure(code, msg, status_code, false, raw, details))

	# ── 성공 ──
	if parsed is Dictionary:
		return BBBaseResult.success(parsed.get("data"), status_code, raw)
	# 본문이 비었거나(204 등) 비-JSON 성공
	return BBBaseResult.success(null, status_code, raw)


func _fail(res: BBBaseResult) -> BBBaseResult:
	if res.error_code == BBBaseErrorCodes.USER_BANNED and not _banned_emitted:
		_banned_emitted = true
		var exp: String = ""
		var rsn: String = ""
		# details.expiresAt 은 영구 제재면 JSON null 로 온다 → "" 로 정규화.
		if res.error_details.get("expiresAt") is String:
			exp = res.error_details["expiresAt"]
		if res.error_details.get("reason") is String:
			rsn = res.error_details["reason"]
		_log("USER_BANNED 수신 → banned 방출 (expires_at=%s)" % ("영구" if exp == "" else exp))
		banned.emit(exp, rsn)
	request_failed.emit(res)
	return res


func _method_enum(method: String) -> HTTPClient.Method:
	match method.to_upper():
		"GET": return HTTPClient.METHOD_GET
		"POST": return HTTPClient.METHOD_POST
		"PUT": return HTTPClient.METHOD_PUT
		"DELETE": return HTTPClient.METHOD_DELETE
		"PATCH": return HTTPClient.METHOD_PATCH
		_: return HTTPClient.METHOD_GET
