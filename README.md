# BBBase Godot SDK

BBBase BaaS 공식 Godot SDK (Godot 4.1+, **GDScript**). 게스트/소셜 로그인, 레코드 저장·조회
(compareMode 병합), 리더보드 조회를 **`await`** 로 제공합니다. 외부 의존성 없음(Godot 내장 기능만).

> 이 레포는 [BBSofts/BBBase](https://github.com/BBSofts/BBBase) 모노레포의 `sdk/godot/` 에서
> 자동 동기화됩니다(원본은 모노레포). 직접 수정하지 마세요.

## 설치 (3단계)

1. **SDK 받기** — [zip 다운로드](https://github.com/BBSofts/bbbase-godot-sdk/archive/refs/heads/main.zip)
   후 압축을 풀어 `addons/bbbase` 폴더를 게임 프로젝트의 `res://addons/` 아래로 복사
   (git submodule 로 추가해도 됩니다).
2. **플러그인 활성화** — Project ▸ Project Settings ▸ Plugins 에서 **BBBase** 를 Enable.
   → `BBBase` autoload 싱글톤이 자동 등록됩니다.
3. **설정 입력** — 메뉴 Project ▸ Tools ▸ **"BBBase: 설정 열기/생성"** → `res://bbbase_settings.tres`
   생성 → 인스펙터에 `Base Url` / `Project Id` / `Api Key` 입력 (대시보드 https://bbbase.io 에서 발급).

> API 키는 클라이언트 임베드(공개 취급)지만 `.gitignore` 에 `bbbase_settings.tres` 추가 권장.

## 사용

```gdscript
func _ready() -> void:
    BBBase.init()                                   # res://bbbase_settings.tres 로드

    var login := await BBBase.auth.login_guest()    # 게스트 로그인
    if not login.ok:
        push_error(login.error_code); return

    await BBBase.records.save_mine({ "best_time": 4.35, "stars": 120 })
    var me := await BBBase.records.load_mine()       # me.data (없으면 null)
    var top := await BBBase.leaderboards.get_top_entries("LB_ID", 10)
```

> GDScript 엔 예외가 없어 **모든 호출은 `BBBaseResult` 를 반환**합니다 — `res.ok` 로 분기하고
> 성공 시 `res.data`, 실패 시 `res.error_code` 를 봅니다. 자세한 API 는 `addons/bbbase/README.md` 참고.

## 더 알아보기

- 퀵스타트: https://api.bbbase.io/quickstart/godot
- 연동 규약(전체): https://api.bbbase.io/llms.txt
- 대시보드: https://bbbase.io

## 라이선스

[MIT](LICENSE) © BBSofts
