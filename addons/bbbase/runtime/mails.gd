extends RefCounted
class_name BBBaseMails
## 우편함(메일) — 게임유저 토큰으로 내 우편을 조회/읽음/수령한다(API 키 + 로그인 필요).
## 발송(개인/전체발송)은 운영자가 대시보드/CLI 로 한다 — 게임 클라는 수령만 한다.
##
## 보상 수령은 서버가 원자적으로 지급한다: claim() 한 번이면 서버가 수령표시와 재화 지급을
## 한 트랜잭션에서 처리한다. 재수령해도 재화는 늘지 않는다(멱등, data.alreadyClaimed=true).
## 수령 후 최신 잔액은 records.load_mine() 으로 다시 읽으면 된다.
##
## 반환은 BBBaseResult.
## - get_mailbox() : data = 우편 배열(Array[Dictionary]) — 각 { id, audience, title, body,
##   attachments{컬럼:수량}, expiresAt, createdAt, read, claimed }.
## - claim(id)     : data = { claimed, alreadyClaimed, attachments }.
## - claim_all()   : data = { claimedCount, totals{컬럼:합계} }.
## - mark_read(id) : data = { read }.

var _client: BBBaseClient
var _session: BBBaseSession


func _init(client: BBBaseClient, session: BBBaseSession) -> void:
	_client = client
	_session = session


## 내 우편함(개인 + 전체발송, 만료 제외). 기본은 미수령만.
## include_claimed=true 면 이미 수령한 우편도 포함한다.
func get_mailbox(include_claimed := false, limit := 50) -> BBBaseResult:
	if not _require_login():
		return _not_logged_in()
	var path := "/mailbox?includeClaimed=%s&limit=%d" % ["true" if include_claimed else "false", limit]
	var res := await _client.send_project("GET", path, null, true)
	if not res.ok:
		return res
	var arr := res.data if res.data is Array else []
	return BBBaseResult.success(arr, res.status, res.raw_body)


## 우편 읽음 표시(멱등). 보상 지급과는 무관하다(수령은 claim).
func mark_read(mail_id: String) -> BBBaseResult:
	if not _require_login():
		return _not_logged_in()
	var path := "/mailbox/%s/read" % mail_id.uri_encode()
	return await _client.send_project("POST", path, null, true)


## 보상 수령(원자적·멱등). 게임의 "수령" 버튼에서 이 한 번만 호출하면 서버가 재화까지 지급한다.
## data.claimed=true 면 이번에 지급됨, data.alreadyClaimed=true 면 이미 받은 우편(재화 불변).
func claim(mail_id: String) -> BBBaseResult:
	if not _require_login():
		return _not_logged_in()
	var path := "/mailbox/%s/claim" % mail_id.uri_encode()
	return await _client.send_project("POST", path, null, true)


## 수령 가능한 우편을 모두 수령. data = { claimedCount, totals }.
func claim_all() -> BBBaseResult:
	if not _require_login():
		return _not_logged_in()
	return await _client.send_project("POST", "/mailbox/claim-all", null, true)


func _require_login() -> bool:
	return _session.is_logged_in()


func _not_logged_in() -> BBBaseResult:
	return BBBaseResult.failure(BBBaseErrorCodes.NOT_LOGGED_IN, "로그인 후에 호출하세요(BBBase.auth.login_...).", 0)
