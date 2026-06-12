extends RefCounted
class_name BBBaseRecords
## 엔티티 레코드 저장/조회/삭제. entityType 은 자유 문자열(user/guild/season 등).
## 본인 데이터는 entity_type="user", entity_id=내 user_id 로 호출 — 이때만 서버가
## 소유권(경로 entityId == 토큰 userId)을 강제한다.
##
## 저장은 단순 덮어쓰기가 아니라 컬럼별 compareMode(NONE/MIN/MAX/INCREMENT)로 병합된다.
## 클라이언트는 "현재 기록이 더 좋은지" 비교할 필요 없이 그냥 저장하면 된다.
##
## 반환은 BBBaseResult. 성공 시 res.data = 레코드 JSON(Dictionary), 없으면 null.

var _client: BBBaseClient
var _session: BBBaseSession


func _init(client: BBBaseClient, session: BBBaseSession) -> void:
	_client = client
	_session = session


# ── 내 레코드(entity_type="user", entity_id=로그인한 내 user_id) 편의 메서드 ──

## 내 유저 레코드 저장. data 는 Dictionary.
func save_mine(data: Dictionary) -> BBBaseResult:
	var uid := _require_user_id()
	if uid == "":
		return BBBaseResult.failure(BBBaseErrorCodes.NOT_LOGGED_IN, "로그인 후에 호출하세요(BBBase.auth.login_...).", 0)
	return await save("user", uid, data)


## 내 유저 레코드 조회(없으면 ok=true, data=null).
func load_mine() -> BBBaseResult:
	var uid := _require_user_id()
	if uid == "":
		return BBBaseResult.failure(BBBaseErrorCodes.NOT_LOGGED_IN, "로그인 후에 호출하세요(BBBase.auth.login_...).", 0)
	return await self.load("user", uid)


# ── 범용 ──

## 레코드 저장(upsert + compareMode 병합). 병합된 최신 레코드를 반환.
func save(entity_type: String, entity_id: String, data: Dictionary) -> BBBaseResult:
	var path := "/entities/%s/%s/record" % [_esc(entity_type), _esc(entity_id)]
	return await _client.send_project("PUT", path, {"data": data}, true)


## 레코드 조회. 없으면 ok=true, data=null(RECORD_NOT_FOUND/404 를 흡수).
func load(entity_type: String, entity_id: String) -> BBBaseResult:
	var path := "/entities/%s/%s/record" % [_esc(entity_type), _esc(entity_id)]
	var res := await _client.send_project("GET", path, null, true)
	if not res.ok and res.is_not_found():
		return BBBaseResult.success(null, res.status, res.raw_body)
	return res


## 레코드 삭제. 없어도 성공으로 간주.
func delete(entity_type: String, entity_id: String) -> BBBaseResult:
	var path := "/entities/%s/%s/record" % [_esc(entity_type), _esc(entity_id)]
	var res := await _client.send_project("DELETE", path, null, true)
	if not res.ok and res.is_not_found():
		return BBBaseResult.success(null, res.status, res.raw_body)
	return res


func _require_user_id() -> String:
	return _session.user_id if _session.is_logged_in() else ""


func _esc(s: String) -> String:
	return s.uri_encode()
