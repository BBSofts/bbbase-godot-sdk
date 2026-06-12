extends Node
class_name BBBaseClient
## 저수준 HTTP 클라이언트. 헤더 세팅·envelope 파싱·에러를 BBBaseResult 로 변환하는
## 책임만 진다. 보통은 BBBase 파사드를 통해 간접 사용한다.
##
## 호출마다 HTTPRequest 자식 노드를 만들어 await 후 정리한다(간단·동시요청 안전).

## 모든 요청 실패 시 방출(전역 처리/로깅용). 개별 호출은 반환된 BBBaseResult 로 분기.
signal request_failed(result: BBBaseResult)

var _settings: BBBaseSettings
## 로그인 후 채워지는 게임유저 토큰(레코드 호출 시 Bearer 로 붙음).
var access_token: String = ""


func setup(settings: BBBaseSettings) -> void:
	_settings = settings


func _log(msg: String) -> void:
	if _settings != null and _settings.verbose_logging:
		print("[BBBase] ", msg)


## 프로젝트 스코프 경로(/projects/{pid}{sub_path}) 로 요청.
func send_project(method: String, sub_path: String, body: Variant = null, with_user_token := false) -> BBBaseResult:
	var path := "/projects/%s%s" % [_settings.project_id, sub_path]
	return await send(method, path, body, with_user_token)


## 임의 경로로 요청. 결과는 BBBaseResult.
func send(method: String, path: String, body: Variant = null, with_user_token := false) -> BBBaseResult:
	var http := HTTPRequest.new()
	add_child(http)
	if _settings.request_timeout_seconds > 0:
		http.timeout = _settings.request_timeout_seconds

	var headers := PackedStringArray()
	headers.append("X-API-Key: " + _settings.api_key)
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
		if parsed is Dictionary and parsed.get("error") is Dictionary:
			var e: Dictionary = parsed["error"]
			code = e.get("code", code)
			msg = e.get("message", msg)
		return _fail(BBBaseResult.failure(code, msg, status_code, false, raw))

	# ── 성공 ──
	if parsed is Dictionary:
		return BBBaseResult.success(parsed.get("data"), status_code, raw)
	# 본문이 비었거나(204 등) 비-JSON 성공
	return BBBaseResult.success(null, status_code, raw)


func _fail(res: BBBaseResult) -> BBBaseResult:
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
