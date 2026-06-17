extends Resource
class_name BBBaseSettings
## BBBase 연결 설정. `res://bbbase_settings.tres` 로 저장되어 런타임에 자동 로드된다
## (에디터 메뉴 BBBase ▸ Settings 로 생성/편집 — 4단계).
##
## 개발용/라이브용은 BBBase 에서 각각 별도 프로젝트(project_id + api_key)로 만든다.
## 둘 다 같은 서버(base_url)를 쓰므로 base_url 은 공통 1개, 환경별로는 project_id/api_key
## 쌍만 다르다. [member environment] 가 둘 중 어느 쌍을 쓸지 결정한다.
##
## API_KEY 는 게임 클라이언트에 임베드되는 공개 취급 키지만, 그래도 소스 형상관리에
## 커밋하지 않는 것을 권장한다(키 로테이션 용이). .gitignore 에 bbbase_settings.tres 추가.

## 런타임이 찾는 설정 리소스 경로.
const RESOURCE_PATH := "res://bbbase_settings.tres"

## 활성 환경 선택.
##  - AUTO: 디버그 빌드/에디터면 개발용, 릴리스 export 면 라이브용 (OS.is_debug_build()).
##  - DEVELOPMENT / PRODUCTION: 빌드 종류와 무관하게 강제 고정.
enum BBBaseEnvironment { AUTO, DEVELOPMENT, PRODUCTION }

## 개발용·라이브용 프로젝트가 공유하는 BBBase API 서버. 보통 그대로 둔다.
@export var base_url: String = "https://api.bbbase.io"

@export var environment: BBBaseEnvironment = BBBaseEnvironment.AUTO

@export_group("개발용 프로젝트")
@export var dev_project_id: String = ""
@export var dev_api_key: String = ""

@export_group("라이브용 프로젝트")
@export var prod_project_id: String = ""
@export var prod_api_key: String = ""

@export_group("동작 옵션")
## 요청 타임아웃(초). 0 이면 무제한. (HTTPRequest.timeout 은 Godot 4.1+)
@export var request_timeout_seconds: float = 15.0
## 로그인 토큰을 user:// 에 저장해 앱 재시작 후 세션 복원.
@export var persist_session: bool = true
## SDK 내부 디버그 로그 출력.
@export var verbose_logging: bool = false

@export_group("Legacy (단일 환경)")
## 구버전 호환용. 환경별 값이 비어 있으면 이 값으로 폴백한다. 신규 설정은 위의
## 개발용/라이브용 쌍을 쓰고 이 두 칸은 비워 둔다.
@export var project_id: String = ""
@export var api_key: String = ""


## res:// 에서 설정을 로드. 없으면 null.
static func load_from_project() -> BBBaseSettings:
	if not ResourceLoader.exists(RESOURCE_PATH):
		return null
	var res := ResourceLoader.load(RESOURCE_PATH)
	return res as BBBaseSettings


## 현재 활성 환경이 라이브(운영)인지.
func is_production() -> bool:
	match environment:
		BBBaseEnvironment.DEVELOPMENT:
			return false
		BBBaseEnvironment.PRODUCTION:
			return true
		_:
			return not OS.is_debug_build()


## 현재 환경에 해당하는 project_id (환경별 값이 비면 legacy 로 폴백).
func active_project_id() -> String:
	var v := prod_project_id if is_production() else dev_project_id
	return v if v != "" else project_id


## 현재 환경에 해당하는 api_key (환경별 값이 비면 legacy 로 폴백).
func active_api_key() -> String:
	var v := prod_api_key if is_production() else dev_api_key
	return v if v != "" else api_key


## 사람이 읽을 현재 환경 이름(로그용).
func active_environment_name() -> String:
	return "production" if is_production() else "development"


func is_valid() -> bool:
	return base_url != "" and active_project_id() != "" and active_api_key() != ""


## 끝의 슬래시를 제거한 base_url.
func normalized_base_url() -> String:
	return base_url.rstrip("/")
