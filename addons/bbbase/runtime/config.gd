extends RefCounted
class_name BBBaseConfig
## 공용 Config(Remote Config) — 프로젝트 전역 설정값을 API 키만으로 읽는다(로그인 불필요).
## 필수 업데이트(최소 요구 버전)·원격 기능 플래그·서버 튜닝값 등에 쓴다. 값은 운영자만
## 대시보드/CLI 로 바꾸고, 게임 클라는 읽기 전용이다.
##
## 읽기는 서버에서 5분 캐시되므로 매우 빠르다. 로그인 화면 이전에 호출해 강제 업데이트를
## 판정할 수 있다(일반 레코드 API 는 게임유저 토큰이 필요해 로그인 전엔 못 쓴다).
##
## 예) 앱 시작 시 강제 업데이트 체크
## [codeblock]
## var res := await BBBase.config.get_value("force_update")
## if res.ok and res.data != null:
##     var cfg: Dictionary = res.data.value
##     if _is_older(app_version, cfg.get("minVersion", "0")):
##         _show_force_update_popup(cfg.get("message", ""), cfg.get("storeUrl", ""))
##         return  # 게임 진입 차단
## [/codeblock]

var _client: BBBaseClient


func _init(client: BBBaseClient) -> void:
	_client = client


## key 단건 조회. 성공 시 res.data = { key, value, updatedAt }(Dictionary).
## 키가 없으면(CONFIG_NOT_FOUND/404) ok=true, data=null 로 흡수한다 — "설정 없음 → 기본 동작".
## API 키만으로 동작하며 게임유저 토큰이 필요 없다(로그인 전 호출 가능).
func get_value(key: String) -> BBBaseResult:
	var path := "/configs/%s" % key.uri_encode()
	var res := await _client.send_project("GET", path, null, false)
	if not res.ok and res.is_not_found():
		return BBBaseResult.success(null, res.status, res.raw_body)
	return res


## 편의 헬퍼 — key 의 value 만 바로 꺼낸다. 없거나 실패면 default 를 반환한다.
## (성공/실패를 세밀히 다루려면 get_value 를 쓰라.)
func get_value_or(key: String, default_value: Variant = null) -> Variant:
	var res := await get_value(key)
	if res.ok and res.data != null and res.data is Dictionary:
		return res.data.get("value", default_value)
	return default_value
