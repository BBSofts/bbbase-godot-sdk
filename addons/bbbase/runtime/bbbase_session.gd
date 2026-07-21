extends RefCounted
class_name BBBaseSession
## 현재 로그인 세션. 토큰을 보관하고, 옵션에 따라 ConfigFile(user://) 로 영속화한다.
## provider 는 자유 문자열("guest"/"google"/"apps-in-toss") — 재로그인 UI 분기에 유용.
## 값이 ""(빈 문자열)이면 "로그인 수단 불명" 을 뜻한다(미로그인 또는 세션 손상). 이때는
## 특정 provider 로 자동 로그인하지 말고 반드시 로그인 수단 선택 UI 를 띄워야 한다 —
## "guest" 로 기본값을 두면 실제 구글/앱인토스 유저가 게스트 계정으로 조용히 갈아타는 사고가 난다.

const CONFIG_PATH := "user://bbbase_session.cfg"
const SECTION := "session"

var user_id: String = ""
var access_token: String = ""
var refresh_token: String = ""
var provider: String = ""

var _persist: bool


func _init(persist: bool) -> void:
	_persist = persist
	if _persist:
		_restore()


func is_logged_in() -> bool:
	return access_token != "" and user_id != ""


func set_session(p_provider: String, p_user_id: String, p_access: String, p_refresh: String) -> void:
	provider = p_provider
	user_id = p_user_id
	access_token = p_access
	refresh_token = p_refresh
	if _persist:
		_save()


func update_tokens(p_access: String, p_refresh: String) -> void:
	access_token = p_access
	refresh_token = p_refresh
	if _persist:
		_save()


func clear() -> void:
	user_id = ""
	access_token = ""
	refresh_token = ""
	provider = ""
	if _persist and FileAccess.file_exists(CONFIG_PATH):
		DirAccess.remove_absolute(CONFIG_PATH)


func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value(SECTION, "user_id", user_id)
	cfg.set_value(SECTION, "access_token", access_token)
	cfg.set_value(SECTION, "refresh_token", refresh_token)
	cfg.set_value(SECTION, "provider", provider)
	cfg.save(CONFIG_PATH)


func _restore() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(CONFIG_PATH) != OK:
		return
	user_id = cfg.get_value(SECTION, "user_id", "")
	access_token = cfg.get_value(SECTION, "access_token", "")
	refresh_token = cfg.get_value(SECTION, "refresh_token", "")
	provider = cfg.get_value(SECTION, "provider", "")
