# 매뉴얼 고도화 에이전트 실행

2026-10-10. 사용자 요청으로 계획·독립 시안에서 실제 Flutter/서버 구현으로 전환했다. 기존 작업 트리를 보존한다. [전체 계획](MANUAL_NAVIGATION_WORK_PLAN_2026-10-10.md)의 P0–P6를 대체하지 않으며, 첫 구현 묶음은 D-113/D-114 행동 화면·사진 등록이다.

## 역할·모델·파일 소유

| 역할 | 실제 모델 | 작업·소유 범위 |
|---|---|---|
| 총괄 | 현재 대화의 Codex | 계약 결정·질문·Flutter 저장 어댑터/매뉴얼 편집·백업 화면·문서·통합 검증 |
| 행동 화면 | GPT-6.1 Sol / high | tap_workspace, manual_action_* 화면, 직접 실행/실패/접근성 테스트 |
| 사진 클라이언트 | GPT-6.1 Sol / high | 촬영·변환 모듈, PhotoRegistrationField, place_guide, 의존성/카메라 설명, 사진 테스트 |
| 저장·보존 | GPT-6 Astra / high | private Storage/auth 경계, 사진 참조 검증, 매장 삭제 시 정리, API·서버 테스트·migration |

모델 선택은 이번 작업의 배정이며 벤치마크/성능·비용 보장 주장이 아니다. 화면과 변환은 범위가 명확한 구현 모델에, 권한·이력·삭제의 교차 검토는 Astra에 배정했다. 총괄 포함 동시 4개 이내. 공용 파일은 총괄만 수정하고 계약 변경은 메시지로 합의한다. 토큰/비용 실측은 제공되지 않아 비용 수치를 만들지 않는다.

## 구현 계약

- 행동 탐색은 체크를 생성하지 않는다. 실제 저장 성공 후 다음 행동으로 이동하며 실패·되돌리기·마지막 행동은 현재 위치를 유지한다. 기존 실행/측정/이상·권한 검사와 읽기 전용 체험을 재사용한다.
- 사진은 촬영 우선, 앨범 대안. 방향 보정·크기 축소·JPEG 재인코딩 후 변환본만 업로드. 1280px, 목표150KB/상한250KB,1024/800px 대안은 초기 기술값이며 현장 가독성·실기기로 조정한다. 고화질 원본을 Storage에 보관하지 않는다.
- 저장은 변하지 않는 비공개 사진 참조를 사용한다. 앱은 매장 인증 후 이미지 bytes를 읽으며 만료 URL을 본문에 저장하지 않는다. 기존 HTTPS/dataURL 장소 사진은 호환한다. 업로드와 매뉴얼 참조 저장은 별도이며 매뉴얼 저장의 revision 검사를 유지한다.
- 실패·매장 전환·권한 변경 시 초안과 기존 사진을 보호한다. 업로드만으로 실행 체크·매뉴얼 적용 성공을 표시하지 않는다.
- 교체·저장 충돌 때문에 과거 실행이 참조하는 사진을 삭제하지 않는다. 매장 자체 삭제는 기존 계정 삭제 흐름과 연결된 정리 경로가 필요하다. 운영 활성화는 migration/함수/정리 재시도 준비 후 한다.

## 이번에 질의해 확정한 경계

1. 설거지 반복 업무는 시작 준비·교대·마감 때 체크한다. 영업 중에는 필요할 때 안내를 열며 식기마다 또는 일정 간격마다 반복 체크를 강제하지 않는다. 실제 기존 TAP 일정을 자동 일괄 변경하지 않는다.
2. 다른 매장으로 백업 복원할 때 내용은 복원하고 해당 비공개 사진은 새 매장에서 다시 등록한다. 복원 전에 제외할 사진 수를 안내하며 같은 매장 사진 참조와 외부 HTTPS 링크는 유지한다.

## 다음 구현과 결정 지점

| 순서 | 작업 | 완료 기준/필요한 결정 |
|---|---|---|
| 1 진행 중 | 행동 슬라이드 + 촬영/최적화 + 권한 있는 사진 저장 | 실제 Flutter 진입·성공/실패·좁은 화면·사진/권한 서버 회귀 통과 |
| 2 대기 | 웰컴/업무 ON/지금·다음 업무 연결 | 확정된 별도 웰컴·출퇴근 분리, 크루 계정 연결 검증. 시간 지연/겹침 우선순위 시안 질문 |
| 3 대기 | 버디 및 부재 사유 | 지정 방식·반려/재작업 시안을 먼저 보여주고 질문. 기기 연습과 실제 공유 확인 구별 |
| 4 대기 | TAP별 원본 개선 선택 적용 | 자동 갱신→명시 적용 전환, 개인화 충돌 비교, 생성된 모든 실행 보존 |
| 5 대기 | 영업 전 선택 리마인드 | 늦게 ON한 날의 표시/반복 시안 질문; 모션·정지/자막 동등 제공 |
| 6 병렬 실험 대기 | 플랫폼 안내·이어폰 | Android PiP/iPhone Live Activities와 실제 기기·백그라운드 확인. 일반 앱 동작으로 완료 보고하지 않음 |
| 콘텐츠 | 18매뉴얼/84단계 초안 인수 | 기존 ID/조건 대조, 설거지 식기 종류·잔반 배출처·건조 위치·막힘 예방 상세화. 실제 매장 사진/안전 수치를 꾸며 넣지 않음 |

검증 결과는 작업 종료 시 아래와 canonical history에 기록한다. 운영 배포·스토리지 생성·실기기 촬영은 소스 구현과 별개로 보고한다.

## 구현 결과와 운영 전환 경계

첫 묶음의 실제 앱 코드는 업무의 기존 Task 진입에 연결되어 있다. 생성된 Task/step ID·권한·수량/관찰값·미해결 이상 제한을 그대로 사용한다. 매뉴얼 작성·실행 매뉴얼 바로 수정·장소 편집에서 같은 촬영/변환 모듈을 사용한다. 샘플 모드의 사진 저장소를 실제 인증 서비스처럼 표시하지 않는다.

사진 관련 변경은 선택형 모듈이다. 기존 테스트용 OperationsRepository 구현체에 새 메서드를 강요하지 않고 ManualMediaRepository로 분리했으며, 사진 응답이 운영 snapshot을 대체하지 않도록 했다. 원본 내용 저장과 사진 업로드가 각각 실패할 수 있어 업로드 참조를 초안에 남겨 재시도에 사용한다. 저장을 취소한 미연결 사진의 자동 정리는 아직 없다. 기존 매장/과거 기록을 보호하는 참조 기반 정리는 후속이다.

운영 전환 순서는 다음과 같다. 이번 작업에서는 실행하지 않았다.

1. `supabase/migrations/20261010010000_manual_media.sql` 적용: 비공개 bucket·RLS·삭제 대기 기록.
2. operations와 account 함수를 함께 배포하고 업로드는 비활성으로 유지.
3. 서버 환경에서 `scripts/cleanup-manual-media.mjs` 반복 실행을 구성하고 실패 재시도 확인. `SUPABASE_URL` 및 서버 전용 `SUPABASE_SERVICE_ROLE_KEY` 또는 기존 `SUPABASE_SECRET_KEY`를 사용한다. 실행은 실제 Storage 삭제 작업이므로 테스트 명령으로 돌리지 않는다.
4. 테스트 매장 권한/사진 등록·읽기·복원·매장 삭제 경로 검증 후 Edge 환경의 `TAP2WORK_MANUAL_MEDIA_ENABLED=true` 활성화.
5. 웹 공개 및 iOS/Android 네이티브 빌드·촬영 권한/실기기/HEIC·현장 가독성 검증은 각각 별도 완료로 기록.

외부 자료: [Flutter image_picker 공식 패키지](https://pub.dev/packages/image_picker), [image 패키지](https://pub.dev/packages/image), [방향 보정 API](https://pub.dev/documentation/image/latest/image/bakeOrientation.html). 실제 구현 파일과 해결된 의존성은 pubspec.lock이 기준이다.

검토 중 해결한 문제: 오래된 마켓 테스트의 이전 필터 진입 기대값, 잘못된 아이콘/const·import·lint, 시트 종료 애니메이션 중 입력 controller 해제, 사진 저장 revision 지연 초기화, 저장 실패 뒤 중복 업로드. 초기 전체 Flutter 실행은 마켓 테스트4개와 웹 빌드 동시 실행 중 shader asset 오류2개로 실패했다. 필터 시나리오를 최신 UI로 보정하고 빌드/전체 테스트를 순차 실행하여 최종 결과를 별도 기록한다.

## 최종 로컬 검증

- `flutter analyze`: 오류·경고 없음.
- `flutter test`: **428/428 통과**. 처음 실패했던 마켓4개·shader2개도 최종 순차 실행에서 통과.
- `npm run test:console`: **312/312 통과**.
- `npm run check`: 통과. UI/settings 관계 **64개**와 매뉴얼 경로 검증 포함.
- `npm run test:edge`: 통과. 사진 경로의 Buffer 없는 Deno 검사도 별도 통과.
- 격리 SQL: `node scripts/test-manual-media-sql.mjs --pglite-module=/tmp/tap2work-media-sql/node_modules/@electric-sql/pglite/dist/index.js` 통과. 운영 DB에 연결하지 않고 비공개 bucket/RLS·삭제 trigger의 commit/rollback 검증.
- `flutter test tool/manual_navigation_review.dart`: 통과. 320/390/1200px 및390px 1.5배 글자, 실제 Task 진입→행동 화면의 위젯 캡처12장 생성. 320·390·확대 글자 화면을 직접 검토했다. 사진은 가상 도해이며 실제 업장 사진이 아니다.
- 검증 자료: `.local/manual-navigation-implementation/`. 위젯 렌더링 검증으로, 실제 브라우저/네이티브 촬영 검증을 대신하지 않는다.
- 웹 빌드 최종 결과는 canonical history에 기록한다. 네이티브 빌드, 운영 활성화·배포, 실기기/실제 사진 가독성, HEIC 검증은 미수행.

최종 `npm run build:app`: **성공, build/web (59.0초)**. Flutter 전체 테스트를 먼저 끝낸 뒤 빌드했다. canonical revision276에 구현·두 추가 답변·검증·남은 작업을 기록했다. 과거 이력은 보존했다.


## 2026-10-10 웹 우선 배포 준비

사용자 D-118: 웹에서 사진 등록 먼저 활성화, 구버전 네이티브의 새 private 사진 표시·관련 편집 제한은 다음 업데이트에서 해소한다. 행동 슬라이드/사진 첫 묶음의 배포이며 웰컴·버디·시간 안내·선택 업데이트·PiP·음성은 아직 후속이다.

웹 사진 선택은 플러그인 중복 디코딩을 끄고 입력 크기 확인 후 자체 JPEG 최적화를 실행한다. 반환 Blob URL은 성공·실패 모두 finally에서 해제한다. 인쇄 화면은 계정·매장·깊은 snapshot을 initState에서 함께 고정하고 범위가 바뀐 늦은 PDF 결과를 버린다.

예약 삭제는 manual-media-cleanup Edge와 pg_cron/pg_net을 사용한다. 삭제 tombstone이 있을 때만 5분 주기로 Edge를 호출한다. Vault/Edge 전용 비밀키의 5분 HMAC을 요청마다 만들며 재사용 가능한 비밀키를 HTTP 큐에 넣지 않는다. 삭제된 매장의 immutable prefix만 제한된 작업량으로 처리하며 현재 매장 사진·기존 업무 참조는 보존한다.

운영 bucket 비공개/250000byte/JPEG, 삭제 큐와 cron을 구성했다. 합성 사진의 실제 Storage 업로드·서비스 권한 조회·public/anon 거절, pg_net→Edge HMAC→삭제→tombstone 재예약 왕복을 검증했고 합성 fixture를 제거했다. 실제 크루 데이터·일정·카탈로그는 수정하지 않았다. 운영 사용자의 인증된 업로드/실기기 카메라·HEIC를 확인한 것은 아니다. 웹 프런트 배포 결과는 아래 후속 기록을 따른다.

운영 준비 검증: Flutter432통과/브라우저 전용2개는 별도Chrome2통과, Node317통과, 정적 분석/64UI링크/Edge/PGlite2종 통과. operations v56, account v5, cleanup v1 및 활성 cron/flag 확인. 비밀 설정 성공 응답의 빈 본문, digest 응답 필드명 가정은 검증 스크립트에서 수정했다. D109 직원교육/정기관리 분류의 stable 메타데이터 보완은 별도 후속이며 이번 사진 출시로 콘텐츠 정비가 완료된 것은 아니다.

첫 웹 Actions38043540444(2488fd0)는 실제 로컬 웹 사진 검증 중 중단했다. 로컬 Flutter3.41.2의 기존 생성 entrypoint/플러그인 등록 캐시에 ImagePicker가 빠져 있었으며 독립 작업 폴더의 새 빌드에서는 정상 등록됐다. root의 생성 캐시만 .local로 이동하고 native 빌드 산출물은 보존했다. 실제 플러그인을 쓰는 Chrome DOM 검사3개와 체험 재진입 체크 유지/클라우드 새로고침 회귀17개가 통과했다. PUBLIC_REVIEW의 pause/resume은 이미 받은 체험 데이터를 자동 초기화하지 않으며 수동 새로고침·역할 변경·초기 로딩은 유지한다.


## 2026-10-10 웹 배포 완료

https://tap2.work/ — 코드 `135f8ef6739c8d4a96703d28a3fe616c2dbf742a`, [Actions38044078051](https://github.com/ljae/tap2work/actions/runs/38044078051) build/deploy 성공. Flutter435통과/브라우저전용3skip, 별도Chrome3통과, Node317통과, 분석·UI64·Edge·SQL 통과. 공개 index/버전 bootstrap/main/owner샘플/정책/계정삭제/주소검색7파일이 CI artifact SHA256과 일치한다. 실제 공개 Flutter 화면도 브라우저에서 열었고 Ego space6에 결과 페이지를 남겼다.

별도 새 빌드에서 실제 `image/*,capture=environment` 파일 선택→합성 사진 자동변환→미리보기와 체크→자동 다음→이전 완료 상태 유지까지 확인했다. 합성 사진 초안은 저장하지 않고 버렸다. 실제 폰 카메라·HEIC·운영 사용자 인증 사진 업로드·현장 사용성 검증은 별도이며 native 빌드/업로드도 하지 않았다. 구버전 native private 사진 표시/일부 편집 제한은 사용자 D-118에 따라 다음 업데이트 대상이다.

운영 Storage/삭제 outbox/cron/operations/account/cleanup Edge와 업로드 활성화 완료. 자동 cron 실행 성공도 확인했다. 실제 크루/매장 일정/공용 카탈로그를 변경하지 않았다. 전체 웰컴·시간 안내·버디·원본 선택 업데이트·리마인드·PiP/음성 및18/84콘텐츠는 후속이며 M-033은 in_progress다. 검증 산출물: `.local/manual-navigation-deployment/public-verification.json`, `backend-verification.json`, `ci.log`; 배포 작업 폴더 `.local/manual-navigation-web-release`. 원래 작업 폴더의 미커밋 변경은 보존했다.
