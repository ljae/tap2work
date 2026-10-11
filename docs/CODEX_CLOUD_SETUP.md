# tap2work Codex Cloud 개발 환경

2026-10-11 사용자 요청에 따라 GitHub `ljae/tap2work`의 `main`을 연결했다. GitHub Connector는 해당 저장소만 선택했고, 환경 이름은 `tap2work`, 사용 범위는 `Only me`다.

## 사용 경로

- [Codex Cloud 환경 설정](https://chatgpt.com/settings/codex-cloud)
- [설치·검증 작업](https://chatgpt.com/local/01a12b32-4ca9-7092-9db2-fdeb8aa570ae)
- [새 환경 복원 점검 작업](https://chatgpt.com/local/01a12b44-7953-7329-a517-d04ddaf020b4)
- 새 Work 작업에서 Cloud → `tap2work` 환경을 선택한다. 저장된 Install script는 의존성을 준비하고 Start skill은 저장소 지침과 실행 방법을 제공한다.

설치·검증·게시를 완료했고 UI에서 `Environment published` 및 `Published`를 확인했다. 게시한 `tap2work`를 선택해 새 Cloud 작업도 시작했다. 마지막 복원 점검 중 브라우저가 `task space not found: 13`을 반환해 결과 확인을 중단했다. 새 작업의 점검 완료는 아직 확인하지 않았으며, 아래 테스트 결과는 설치 작업의 실제 실행 결과다.

## 도구와 실행 범위

| 항목 | 설정 |
| --- | --- |
| 저장소 | `/workspace/tap2work` |
| 설치 검증 기준 | `31daecaf75155fcc2e9a325844195d11dc70d53e` |
| Flutter / Dart | 3.41.2 / 3.11.0 |
| Node / Deno | 22.23.3 / 2.1.4 |
| SQL 테스트 | PGlite 0.5.8, SDK와 별도 디렉터리 |
| 인터넷 | Package managers + `storage.googleapis.com` |
| 자격증명 | 추가 환경 변수·네트워크 비밀 없음 |

SDK는 `/workspace/toolchains`, 캐시는 `/workspace/cache`, 검증 로그는 `/workspace/setup-logs`에 있다. Flutter 공식 배포 파일의 SHA-256을 확인한 뒤 설치하고 `flutter pub get --enforce-lockfile`로 기존 lockfile을 유지한다.

매 셸에서 Start skill의 환경 설정을 적용한다. 클라우드의 홈 디렉터리가 읽기 전용이므로 다음 캐시 경로가 필요하다.

```bash
export PATH=/workspace/toolchains/flutter/bin:/workspace/toolchains/js/node_modules/.bin:$PATH
export npm_config_cache=/workspace/cache/npm PUB_CACHE=/workspace/cache/pub
export XDG_CONFIG_HOME=/workspace/cache/config ANALYZER_STATE_LOCATION_OVERRIDE=/workspace/cache/analyzer
export DENO_DIR=/workspace/cache/deno CI=true
cd /workspace/tap2work
```

웹 개발·정적 분석·단위 테스트·서버/SQL 테스트는 이 환경에서 수행한다. `npm run build:app` 이후 `npm run dev:console`로 기본 포트 3100의 `/app/`을 연다. 새 작업에서는 프로세스를 다시 시작해야 하며 복원된 PID 파일을 그대로 신뢰하지 않는다. 상세 시작·PID 확인·정상 종료·HTTP readiness 절차는 환경의 Start skill에 저장했다.

실제 공개 웹 빌드 `npm run build:site`에는 기존의 `SUPABASE_URL`과 `SUPABASE_PUBLISHABLE_KEY`가 필요하다. 임의 값을 만들지 않으며 운영 배포는 기존 GitHub Actions 경로를 따른다. iOS 시뮬레이터·Xcode·앱 서명·스토어 업로드는 Mac 작업을 유지한다. Android 스토어 서명 자격증명도 이전하지 않았다.

## 실제 검증

- Flutter 분석: 문제 없음. 테스트 568개 통과, 브라우저 전용 3개 제외.
- 서버 테스트: 381개 통과, 실패·제외 없음.
- JavaScript/UI 연결 78개, Edge smoke, 7개 언어 번역 검사, PGlite SQL 스크립트 5개 통과.
- 개발용 웹 빌드 성공. 콘솔·합성 데모 API·미리보기 HTML/JS/asset manifest HTTP 200.
- 콘솔 시작·PID 단위 종료·재시작 및 설치 스크립트 반복 실행 통과.
- 설치 작업의 추적 저장소 파일 변경 없음. 운영 데이터·Mac 자격증명 이전 없음.

설치 중 발생한 인터넷 프록시 403은 최신 환경 설정을 다시 불러와 UI에서 저장한 뒤 해소됐다. Flutter 배포 목록의 정확한 경로는 `https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json`이다. 과거 실패는 최종 성공 결과와 구분한다.

## 개발 연속성

새 작업은 `AGENTS.md` → `docs/AI_HANDOFF.md` 및 `docs/BACKEND_WATCH_HANDOFF.md` → `docs/project-state.json` → `PRODUCT.md` → `docs/ARCHITECTURE.md` 순서로 시작한다. UI 변경에는 기존 UI 가이드·화면 템플릿·설정 관계표 지침도 적용한다.

GitHub에 반영된 코드가 클라우드 작업의 출발점이다. Mac의 기존 미커밋 변경, `.local` 증거, 인증정보와 운영 데이터는 자동 이전되지 않는다. 환경 생성 자체가 제품 수정·운영 배포·공급처 주문을 의미하지 않는다.
