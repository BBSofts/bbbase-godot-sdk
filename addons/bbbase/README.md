# BBBase Godot SDK

BBBase BaaS 공식 Godot SDK (Godot 4.1+, **GDScript**). 게스트/소셜 로그인, 레코드 저장·조회
(compareMode 병합), 리더보드 조회를 **`await`** 로 제공한다. REST 직접 호출 대신 설치 후
설정값만 입력하면 된다. 외부 의존성 0 (Godot 내장 `HTTPRequest`/`JSON`/`ConfigFile` 만 사용).

## 설치

1. `addons/bbbase/` 폴더를 게임 프로젝트의 `res://addons/` 아래로 복사
   (또는 Godot **AssetLib** 에서 "BBBase" 검색 → 설치).
2. **Project ▸ Project Settings ▸ Plugins** 에서 **BBBase** 를 **Enable**.
   → `BBBase` autoload 싱글톤이 자동 등록된다.
3. 메뉴 **Project ▸ Tools ▸ "BBBase: 설정 열기/생성"** 클릭 → `res://bbbase_settings.tres`
   가 생성되고 Inspector 에 열린다. `base_url` / `project_id` / `api_key` 입력
   (대시보드 https://bbbase.io 에서 발급).

> API 키는 클라이언트 임베드(공개 취급)지만 `.gitignore` 에 `bbbase_settings.tres` 추가 권장.

## 사용

```gdscript
func _ready() -> void:
    BBBase.init()                                   # res://bbbase_settings.tres 로드

    var login := await BBBase.auth.login_guest()    # 게스트 (기기 식별자 자동)
    # await BBBase.auth.login_google(id_token)      # 구글 (게임이 받은 idToken)
    # await BBBase.auth.login_apps_in_toss(code)    # 앱인토스
    if not login.ok:
        push_error("%s: %s" % [login.error_code, login.error_message]); return

    await BBBase.records.save_mine({ "best_time": 4.35, "stars": 120 })
    var me := await BBBase.records.load_mine()       # me.data = 레코드(없으면 null)
    var top := await BBBase.leaderboards.get_top_entries("LB_ID", 10)
    for row in top.data:
        print("#%s %s %s" % [row.get("rank"), row.get("entityId"), row.get("score")])
```

전체 예제는 `addons/bbbase/samples/quickstart.gd` 참고.

## 반환 규약 — `BBBaseResult`

GDScript 엔 예외가 없어, **모든 호출은 `BBBaseResult` 를 반환**한다.

| 필드 | 의미 |
|---|---|
| `ok: bool` | 성공 여부 |
| `data` | 성공 시 응답(Dictionary/Array). 없거나 204 면 `null` |
| `error_code: String` | 실패 시 에러코드 (`BBBaseErrorCodes` 상수로 분기) |
| `error_message: String` | 사람용 메시지 |
| `status: int` | HTTP 상태. 네트워크 등 합성 에러는 0 |
| `is_network_error: bool` | 연결/타임아웃 실패 여부 |

> `load_*` / `delete_*` 에서 레코드가 없으면 **에러가 아니라** `ok=true, data=null` 로 온다.

## 핵심 규칙

- **저장은 덮어쓰기가 아님** — 컬럼별 compareMode(`NONE`/`MIN`/`MAX`/`INCREMENT`)로 서버가 병합.
  클라이언트는 비교 없이 그냥 저장하면 더 좋은 기록일 때만 갱신된다.
- **에러는 `result.error_code` 로 분기** (`BBBaseErrorCodes` 상수). 메시지는 사람용.
- **userId 는 BBBase 가 발급** — 직접 만들지 말 것. 본인 레코드는 `entity_type="user"` + 내 `user_id()`.
- 컬럼/리더보드/유니크 제약/프로바이더 client ID 는 **운영자가 대시보드·CLI 로 사전 정의**.

## 더 알아보기

- 연동 규약(전체): https://api.bbbase.io/llms.txt
- 정확한 엔드포인트·필드: https://api.bbbase.io/docs-json
