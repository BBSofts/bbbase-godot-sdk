extends RefCounted
class_name BBBaseErrorCodes
## 자주 만나는 BBBase 에러코드 상수. 문자열 하드코딩 대신 이 상수로 분기하라.
## 전체 목록은 https://api.bbbase.io/llms.txt 참고. 서버가 새 코드를 추가할 수 있으니
## 여기 없는 code 도 그대로 BBBaseResult.error_code 로 들어온다.

# ── 클라이언트 합성(서버 응답 아님) ──
const NETWORK_ERROR := "NETWORK_ERROR"
const NOT_INITIALIZED := "NOT_INITIALIZED"
const NOT_LOGGED_IN := "NOT_LOGGED_IN"

# ── 서버 ──
const UNKNOWN_COLUMN := "UNKNOWN_COLUMN"
## user 외 entityType 인데 그 scope 의 스키마가 하나도 없음 — 운영자가 먼저 스키마를 정의해야 한다.
const UNKNOWN_ENTITY_TYPE := "UNKNOWN_ENTITY_TYPE"
const DUPLICATE_VALUE := "DUPLICATE_VALUE"
const OPERATION_ID_CONFLICT := "OPERATION_ID_CONFLICT"
const RECORD_NOT_FOUND := "RECORD_NOT_FOUND"
const ENTITY_RECORD_NOT_FOUND := "ENTITY_RECORD_NOT_FOUND"
const RATE_LIMIT_EXCEEDED := "RATE_LIMIT_EXCEEDED"
const TOO_MANY_REQUESTS := "TOO_MANY_REQUESTS"
const LEADERBOARD_SCORE_NOT_FOUND := "LEADERBOARD_SCORE_NOT_FOUND"
const UNAUTHORIZED := "UNAUTHORIZED"
const FORBIDDEN := "FORBIDDEN"
## 운영자가 제재한 계정. 재시도/재로그인해도 계속 실패한다 —
## error_details 의 expires_at(null=영구)·reason 으로 정지 안내를 띄울 것.
const USER_BANNED := "USER_BANNED"
const AUTH_PROVIDER_NOT_CONFIGURED := "AUTH_PROVIDER_NOT_CONFIGURED"

# ── 공유 카운터 ──
## 그런 이름의 카운터가 없음 — 운영자가 먼저 대시보드/CLI 로 등록해야 한다.
const COUNTER_NOT_FOUND := "COUNTER_NOT_FOUND"
## 이 유저가 이번 구간에 더할 수 있는 총량을 다 썼다(429). 재시도하지 말고 UI 로 안내할 것 —
## 다음 구간이 시작되기 전까지 계속 실패한다. error_details 에 perUserLimit / windowKey.
const COUNTER_LIMIT_EXCEEDED := "COUNTER_LIMIT_EXCEEDED"
## delta 가 카운터의 maxDelta 를 넘었다(0·음수도 불가 — 카운터는 올라가기만 한다).
const INVALID_COUNTER_DELTA := "INVALID_COUNTER_DELTA"
