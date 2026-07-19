extends Node
## BBBase Godot SDK 퀵스타트 — 게스트 로그인 → 레코드 저장/조회 → 리더보드 왕복.
##
## 사용법:
## 1. 에디터 메뉴 BBBase ▸ Settings 로 res://bbbase_settings.tres 를 만들고
##    base_url / project_id / api_key 를 채운다(dev: http://178.105.162.85:4001).
## 2. 이 스크립트를 빈 씬의 루트 Node 에 붙이고 실행한다.
## 3. 출력(Output) 패널에서 왕복 로그를 확인한다.


func _ready() -> void:
	await _run()


func _run() -> void:
	BBBase.init()
	if not BBBase.is_initialized():
		push_error("초기화 실패 — bbbase_settings.tres 를 확인하세요.")
		return

	# 0) 세션 만료 구독(선택이지만 권장). 액세스 토큰 만료(1시간)는 SDK 가 자동으로
	#    refresh 하므로 게임이 신경 쓸 필요 없다. 리프레시 토큰까지 만료돼(오래 미접속)
	#    자동 복구가 불가능할 때만 이 시그널이 오며, 이때 provider 별 재로그인을 띄운다.
	BBBase.session_expired.connect(_on_session_expired)

	# 1) 게스트 로그인
	var login := await BBBase.auth.login_guest()
	if not login.ok:
		push_error("로그인 실패: [%s] %s" % [login.error_code, login.error_message])
		return
	print("✅ 로그인 — userId=", BBBase.user_id())

	# 2) 내 레코드 저장(서버가 compareMode 로 병합)
	var saved := await BBBase.records.save_mine({"best_time": 4.35, "stars": 120})
	if not saved.ok:
		push_error("저장 실패: [%s] %s" % [saved.error_code, saved.error_message])
		return
	print("✅ 저장 — ", saved.data)

	# 3) 내 레코드 조회
	var me := await BBBase.records.load_mine()
	if me.ok:
		print("✅ 조회 — ", me.data)

	# 4) 리더보드 Top-10 (LEADERBOARD_ID 를 실제 정의 ID 로 교체)
	# var top := await BBBase.leaderboards.get_top_entries("LEADERBOARD_ID", 10)
	# if top.ok:
	#     for row in top.data:
	#         print("  #%s  %s  %s" % [row.get("rank"), row.get("entityId"), row.get("score")])

	print("🎉 왕복 완료")


## 세션이 완전히 만료돼 자동 복구가 불가능할 때 호출된다(재로그인 필요).
## provider 로 어떤 로그인 UI 를 띄울지 분기한다.
func _on_session_expired(provider: String) -> void:
	push_warning("세션 만료 — 재로그인이 필요합니다 (provider=%s)" % provider)
	match provider:
		"google":
			pass  # 구글 로그인 UI → 새 idToken 획득 후 BBBase.auth.login_google(id_token)
		"apps-in-toss":
			pass  # 앱인토스 재인증 → BBBase.auth.login_apps_in_toss(code)
		_:
			await BBBase.auth.login_guest()  # 게스트: 같은 deviceId 로 같은 계정 복구
