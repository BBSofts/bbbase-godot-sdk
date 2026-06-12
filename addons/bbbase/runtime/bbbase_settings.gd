extends Resource
class_name BBBaseSettings
## BBBase 연결 설정. `res://bbbase_settings.tres` 로 저장되어 런타임에 자동 로드된다
## (에디터 메뉴 BBBase ▸ Settings 로 생성/편집 — 4단계).
##
## API_KEY 는 게임 클라이언트에 임베드되는 공개 취급 키지만, 그래도 소스 형상관리에
## 커밋하지 않는 것을 권장한다(키 로테이션 용이). .gitignore 에 bbbase_settings.tres 추가.

## 런타임이 찾는 설정 리소스 경로.
const RESOURCE_PATH := "res://bbbase_settings.tres"

@export var base_url: String = "https://api.bbbase.io"
@export var project_id: String = ""
@export var api_key: String = ""

@export_group("동작 옵션")
## 요청 타임아웃(초). 0 이면 무제한. (HTTPRequest.timeout 은 Godot 4.1+)
@export var request_timeout_seconds: float = 15.0
## 로그인 토큰을 user:// 에 저장해 앱 재시작 후 세션 복원.
@export var persist_session: bool = true
## SDK 내부 디버그 로그 출력.
@export var verbose_logging: bool = false


## res:// 에서 설정을 로드. 없으면 null.
static func load_from_project() -> BBBaseSettings:
	if not ResourceLoader.exists(RESOURCE_PATH):
		return null
	var res := ResourceLoader.load(RESOURCE_PATH)
	return res as BBBaseSettings


func is_valid() -> bool:
	return base_url != "" and project_id != "" and api_key != ""


## 끝의 슬래시를 제거한 base_url.
func normalized_base_url() -> String:
	return base_url.rstrip("/")
