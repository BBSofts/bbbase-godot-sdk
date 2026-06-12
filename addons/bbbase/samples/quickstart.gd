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
