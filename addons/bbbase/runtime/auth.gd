extends RefCounted
class_name BBBaseAuth
## 게임유저 인증 — 게스트/구글/앱인토스 로그인, 토큰 회전, 로그아웃.
## 모든 메서드는 await 로 BBBaseResult 를 반환한다.
## 성공 시 res.data = { "userId", "accessToken", "refreshToken" }.

var _client: BBBaseClient
var _session: BBBaseSession


func _init(client: BBBaseClient, session: BBBaseSession) -> void:
	_client = client
	_session = session
	# 영속 세션이 복원돼 있으면 클라이언트에도 토큰을 전파
	if _session.is_logged_in():
		_client.access_token = _session.access_token


func is_logged_in() -> bool:
	return _session.is_logged_in()


func get_user_id() -> String:
	return _session.user_id


## 게스트 로그인. device_id 생략 시 OS.get_unique_id() 사용.
func login_guest(device_id: String = "") -> BBBaseResult:
	if device_id == "":
		device_id = OS.get_unique_id()
	return await _login("guest", "auth/guest", {"deviceId": device_id})


## 구글 계정 로그인. 게임이 받은 idToken 을 즉시 전달하라(만료/캐싱 주의).
func login_google(id_token: String) -> BBBaseResult:
	return await _login("google", "auth/google", {"idToken": id_token})


## 앱인토스 로그인.
func login_apps_in_toss(authorization_code: String, referrer: String = "") -> BBBaseResult:
	var body := {"authorizationCode": authorization_code}
	if referrer != "":
		body["referrer"] = referrer
	return await _login("apps-in-toss", "auth/apps-in-toss", body)


func _login(provider: String, path: String, body: Dictionary) -> BBBaseResult:
	var res := await _client.send_project("POST", "/" + path, body)
	if res.ok and res.data is Dictionary:
		var d: Dictionary = res.data
		_session.set_session(provider, d.get("userId", ""), d.get("accessToken", ""), d.get("refreshToken", ""))
		_client.access_token = _session.access_token
	return res


## 리프레시 토큰으로 액세스 토큰 회전. 보통 401 이후 호출.
func refresh() -> BBBaseResult:
	if _session.refresh_token == "":
		return BBBaseResult.failure(BBBaseErrorCodes.NOT_LOGGED_IN, "리프레시 토큰이 없습니다.", 0)
	var res := await _client.send_project("POST", "/auth/refresh", {"refreshToken": _session.refresh_token})
	if res.ok and res.data is Dictionary:
		var d: Dictionary = res.data
		_session.update_tokens(d.get("accessToken", ""), d.get("refreshToken", ""))
		_client.access_token = _session.access_token
	return res


## 로그아웃 — 서버에 refresh 토큰 무효화 요청 후 로컬 세션 삭제.
## 로컬 정리는 항상 성공으로 간주(서버 실패는 무시).
func logout() -> BBBaseResult:
	var refresh_tok := _session.refresh_token
	_session.clear()
	_client.access_token = ""
	if refresh_tok != "":
		await _client.send_project("POST", "/auth/logout", {"refreshToken": refresh_tok})
	return BBBaseResult.success(null)


# ── 계정 링킹 ────────────────────────────────────────────────
# 현재 로그인된 계정(userId 불변)에 로그인 수단을 추가한다. userId 가 바뀌지 않으므로
# 세이브(레코드)는 그대로 유지되고, 이후 그 수단으로 어느 기기에서든 같은 계정에 로그인할 수 있다.
# 모두 로그인 상태에서 호출해야 한다(미로그인 시 NOT_LOGGED_IN).
# 그 수단이 이미 다른 계정에 묶여 있으면 res.error_code == "IDENTITY_ALREADY_LINKED"(409).
# 상대 계정 id 는 원문(res.raw)의 error.details.conflictUserId 에서 읽는다:
#   var body := JSON.parse_string(res.raw); var other := body["error"]["details"]["conflictUserId"]

## 현재 계정에 게스트(다른 기기 등) 신원을 추가.
func link_guest(device_id: String = "") -> BBBaseResult:
	if device_id == "":
		device_id = OS.get_unique_id()
	return await _link({"provider": "GUEST", "deviceId": device_id})


## 현재 게스트 계정에 구글 계정을 연동(가장 흔한 사용처).
func link_google(id_token: String) -> BBBaseResult:
	return await _link({"provider": "GOOGLE", "idToken": id_token})


## 현재 계정에 앱인토스를 연동.
func link_apps_in_toss(authorization_code: String, referrer: String = "") -> BBBaseResult:
	var body := {"provider": "APPS_IN_TOSS", "authorizationCode": authorization_code}
	if referrer != "":
		body["referrer"] = referrer
	return await _link(body)


func _link(body: Dictionary) -> BBBaseResult:
	if not _session.is_logged_in():
		return BBBaseResult.failure(BBBaseErrorCodes.NOT_LOGGED_IN, "로그인 후 링킹할 수 있습니다.", 0)
	return await _client.send_project("POST", "/auth/link", body, true)


## 링크 해제. provider: "GUEST" | "GOOGLE" | "APPS_IN_TOSS".
## 마지막 남은 수단은 해제할 수 없다(CANNOT_UNLINK_LAST).
func unlink(provider: String) -> BBBaseResult:
	if not _session.is_logged_in():
		return BBBaseResult.failure(BBBaseErrorCodes.NOT_LOGGED_IN, "로그인 후 호출하세요.", 0)
	return await _client.send_project("DELETE", "/auth/link/" + provider, null, true)


## 내 계정 정보. res.data = { "userId", "isGuest", "providers": [...] }.
func get_me() -> BBBaseResult:
	if not _session.is_logged_in():
		return BBBaseResult.failure(BBBaseErrorCodes.NOT_LOGGED_IN, "로그인 후 호출하세요.", 0)
	return await _client.send_project("GET", "/auth/me", null, true)
