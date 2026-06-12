@tool
extends EditorPlugin
## BBBase 에디터 플러그인.
##  - 활성화 시 `BBBase` autoload 싱글톤을 등록한다.
##  - Project ▸ Tools 메뉴에 "BBBase: 설정 열기/생성" 항목을 추가한다.
##    클릭하면 res://bbbase_settings.tres 를 없으면 만들고 Inspector 로 연다.

const AUTOLOAD_NAME := "BBBase"
const AUTOLOAD_PATH := "res://addons/bbbase/runtime/bbbase.gd"
const SETTINGS_PATH := "res://bbbase_settings.tres"
const MENU_ITEM := "BBBase: 설정 열기/생성"

const BBBaseSettingsScript := preload("res://addons/bbbase/runtime/bbbase_settings.gd")


func _enter_tree() -> void:
	# autoload 는 Node 여야 하며, bbbase.gd 가 파사드 겸 싱글톤이다.
	add_autoload_singleton(AUTOLOAD_NAME, AUTOLOAD_PATH)
	add_tool_menu_item(MENU_ITEM, _open_settings)


func _exit_tree() -> void:
	remove_tool_menu_item(MENU_ITEM)
	remove_autoload_singleton(AUTOLOAD_NAME)


## 설정 리소스를 열거나(없으면 기본값으로 생성) Inspector 에 표시한다.
func _open_settings() -> void:
	var settings: Resource
	if ResourceLoader.exists(SETTINGS_PATH):
		settings = ResourceLoader.load(SETTINGS_PATH)
	else:
		settings = BBBaseSettingsScript.new()
		var err := ResourceSaver.save(settings, SETTINGS_PATH)
		if err != OK:
			push_error("[BBBase] 설정 파일 생성 실패 (%d): %s" % [err, SETTINGS_PATH])
			return
		# 새로 만든 파일이 FileSystem 패널에 즉시 보이도록 스캔.
		get_editor_interface().get_resource_filesystem().scan()
		settings = ResourceLoader.load(SETTINGS_PATH)
		print("[BBBase] 설정 파일을 생성했습니다: ", SETTINGS_PATH)

	# Inspector 에 열어 base_url / project_id / api_key 를 바로 입력하게 한다.
	get_editor_interface().edit_resource(settings)
