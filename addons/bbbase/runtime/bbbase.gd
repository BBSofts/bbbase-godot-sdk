extends Node
## BBBase SDK 진입점(autoload 싱글톤). 앱 시작 시 [method init] 를 한 번 호출한 뒤
## [code]BBBase.auth[/code] / [code]BBBase.records[/code] / [code]BBBase.leaderboards[/code] 로 호출한다.
##
## 예)
## [codeblock]
## BBBase.init()
## await BBBase.auth.login_guest()
## await BBBase.records.save_mine({ "best_time": 4.35, "stars": 120 })
## var me := await BBBase.records.load_mine()
## var top := await BBBase.leaderboards.get_top_entries("LEADERBOARD_ID", 10)
## [/codeblock]

var settings: BBBaseSettings
var auth: BBBaseAuth
var records: BBBaseRecords
var leaderboards: BBBaseLeaderboards
var leagues: BBBaseLeagues

var _client: BBBaseClient
var _session: BBBaseSession


func is_initialized() -> bool:
	return _client != null


## 현재 로그인 상태(편의 접근자).
func is_logged_in() -> bool:
	return auth != null and auth.is_logged_in()


## BBBase 가 발급한 내 게임유저 ID(미로그인이면 "").
func user_id() -> String:
	return auth.get_user_id() if auth != null else ""


## res://bbbase_settings.tres 를 로드해 SDK 를 초기화한다.
## 에디터 메뉴 BBBase ▸ Settings 로 에셋을 먼저 만들어 두어야 한다.
func init() -> void:
	var s := BBBaseSettings.load_from_project()
	if s == null:
		push_error("[BBBase] 설정 에셋을 찾을 수 없습니다. 메뉴 'BBBase ▸ Settings' 로 " +
			"res://bbbase_settings.tres 를 생성하세요.")
		return
	init_with(s)


## 명시적 설정으로 초기화(테스트/멀티환경용).
func init_with(s: BBBaseSettings) -> void:
	if s == null or not s.is_valid():
		push_error("[BBBase] 설정이 비어있습니다. base_url/project_id/api_key 를 확인하세요.")
		return

	settings = s
	_session = BBBaseSession.new(s.persist_session)
	_client = BBBaseClient.new()
	_client.setup(s)
	add_child(_client)
	auth = BBBaseAuth.new(_client, _session)
	records = BBBaseRecords.new(_client, _session)
	leaderboards = BBBaseLeaderboards.new(_client)
	leagues = BBBaseLeagues.new(_client, _session)

	if s.verbose_logging:
		print("[BBBase] initialized. env=%s, project=%s, restoredSession=%s" % [s.active_environment_name(), s.active_project_id(), _session.is_logged_in()])
