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
const DUPLICATE_VALUE := "DUPLICATE_VALUE"
const RECORD_NOT_FOUND := "RECORD_NOT_FOUND"
const ENTITY_RECORD_NOT_FOUND := "ENTITY_RECORD_NOT_FOUND"
const RATE_LIMIT_EXCEEDED := "RATE_LIMIT_EXCEEDED"
const TOO_MANY_REQUESTS := "TOO_MANY_REQUESTS"
const LEADERBOARD_SCORE_NOT_FOUND := "LEADERBOARD_SCORE_NOT_FOUND"
const UNAUTHORIZED := "UNAUTHORIZED"
const FORBIDDEN := "FORBIDDEN"
const AUTH_PROVIDER_NOT_CONFIGURED := "AUTH_PROVIDER_NOT_CONFIGURED"
