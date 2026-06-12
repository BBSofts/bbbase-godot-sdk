extends RefCounted
class_name BBBaseResult
## 모든 SDK 호출의 반환 타입. GDScript 엔 예외가 없어 C# SDK 의 BBBaseException 대신
## 이 객체로 성공/실패를 전달한다.
##
## 사용:
## [codeblock]
## var res := await BBBase.records.load_mine()
## if res.ok:
##     print(res.data)
## else:
##     push_warning(res.error_message)
##     if res.error_code == BBBaseErrorCodes.NOT_LOGGED_IN:
##         ...
## [/codeblock]

var ok: bool = false
## 성공 시 서버 응답의 data(보통 Dictionary/Array). 없거나 204 면 null.
var data: Variant = null
var error_code: String = ""
var error_message: String = ""
## HTTP 상태코드. 클라이언트 합성 에러(네트워크 등)는 0.
var status: int = 0
var is_network_error: bool = false
## 디버깅용 원본 응답 본문.
var raw_body: String = ""


static func success(p_data: Variant, p_status: int = 200, p_raw: String = "") -> BBBaseResult:
	var r := BBBaseResult.new()
	r.ok = true
	r.data = p_data
	r.status = p_status
	r.raw_body = p_raw
	return r


static func failure(p_code: String, p_message: String, p_status: int = 0, p_network := false, p_raw := "") -> BBBaseResult:
	var r := BBBaseResult.new()
	r.ok = false
	r.error_code = p_code
	r.error_message = p_message
	r.status = p_status
	r.is_network_error = p_network
	r.raw_body = p_raw
	return r


static func network(p_message: String) -> BBBaseResult:
	return failure(BBBaseErrorCodes.NETWORK_ERROR, p_message, 0, true, "")


## load_*/delete_* 가 404/NOT_FOUND 를 "없음"(ok=true, data=null)으로 다룰지 판단.
func is_not_found() -> bool:
	return status == 404 \
		or error_code == BBBaseErrorCodes.RECORD_NOT_FOUND \
		or error_code == BBBaseErrorCodes.ENTITY_RECORD_NOT_FOUND
