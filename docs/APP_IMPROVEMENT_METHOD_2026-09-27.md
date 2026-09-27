# 업무·매뉴얼·직원 중심 앱 개선 방법론

작성일: 2026-09-27 · 상태: 방법론 완료, 세부 설계 제안 포함 · 구현 담당: 후속 Sol 세션

이번 세션의 산출물은 요구사항 명확화, 스킬 선정·설치, 화면/데이터/전환/검증 명세다. 앱 구현·배포는 수행하지 않는다. 아래 `확정`은 사용자 발언·답변이며, `설계 제안`은 구현을 위한 구체안으로 사용자 승인과 구분한다. 숫자 제한·시간·색상 투명도·파일 이름은 별도 표시가 없으면 설계 제안이다.

## 1. 사용자 결정

| 항목 | 상태 | 내용 |
| --- | --- | --- |
| 주요 포커스 | 확정 | 업무 매뉴얼, 업무 관리, 직원 고용 및 채용 |
| 하단 메뉴 | 확정 | 업무 · 매뉴얼 · 직원 · 우리매장, 매출/재고/발주는 우리매장에서 접근 |
| 우리매장 | 확정 | 기존 배치/위치 중심 메뉴를 설정 허브로 확장, POS·배달·직원 구성 등을 선택 위주로 입력 |
| 설정 방식 | 확정 | 업무 유형별 기본 양식 + TAP·Small TAP별 개별 조정 |
| 계층 | 기존 결정 유지 | TAP → Small TAP, BIG TAP은 그룹 필터. 주문처리중 / 할일 / 완료 보드 유지 |
| 채용 | 확정 | 필요 인원·직무·공고 초안까지. 외부 공고 게시·지원자 관리 후속 |
| 시각 방향 | 확정 | 읽기 좋은 폰트, 색과 투명도, 적은 기본 텍스트, 미니멀한 화면 |
| 완료 효과 | 확정 | 완료 글줄이 짧게 내려가며 사라진 뒤 완료 표시로 정리. 기록과 허용된 되돌리기 유지, 동작 줄이기 반영 |
| 초기 필수 입력 | 확정 | 매장명·업종만 필수. POS·배달·직원 등은 건너뛰고 나중에 설정 |
| 세부 설정 범위 | 확정 | 역할·장소·반복·일괄완료, 수량·예상 시간·순서 우선. 사진 제출·관리자 승인·실제 타이머 후속 |
| POS/배달 범위 | 확정 | 사용 정보 설정과 맞춤 업무 양식 추천까지. 자동 연동은 별도 작업 |

첫 근무의 개인 연습·버디 확인, 재고·발주·입고, 배치도는 새 메뉴 안에서 계속 접근한다. 신규 포커스는 기존 통합 운영 기능을 삭제한다는 뜻이 아니다. 이번 사용자 답변이 과거 메뉴 배치 결정에 우선한다.

## 2. 확인한 구현 기반

| 현재 코드 | 확인 내용과 설계 영향 |
| --- | --- |
| `app/lib/main.dart`, `app/pubspec.yaml` | NotoSansKR 번들 폰트, Material 3, 한글 로케일이 이미 있다. 서체 추가 이전에 굵기·행간·정보량을 조정한다. |
| `ui/operations_screen.dart` | 현황/할 일/근무/매장, 전역 매뉴얼 검색, 재고 진입이 한 화면에 모여 있다. 메뉴별 화면을 분리하고 기존 진입 경로를 매핑한다. |
| `ui/tap_workspace.dart`, `ui/tap_card.dart` | TAP/Small TAP, 드래그·완료·열기 분리, 담당 가능자 색, 주문 그룹 진행률이 구현돼 있다. 완료 연출은 실제 변경 명령의 결과에 연결한다. |
| `ui/checklist_editor.dart`, `domain/checklist_draft.dart` | 초안 편집과 제목·매뉴얼·링크 검증이 있다. 초안의 개시 revision을 보존하며 선택형 설정을 확장한다. |
| `ui/catalog_editor.dart`, `developer/operations.mjs` | `save_store`는 사장 전용 이름·안내 저장. 설정 확장은 별도 부분 저장 계약이 적합하다. |
| `developer/checklists.mjs` | 허용 필드를 새 객체로 복사한다. UI에만 필드를 추가하면 저장 시 유실된다. 버전 계산·가져오기·생성·검색·주문 매뉴얼 경로도 함께 점검한다. |
| `developer/operations.mjs` | `ensureDueTasks`가 한국 날짜별 routine을 만든다. 요일 반복은 서버 생성 조건까지 변경해야 실제 기능이 된다. |
| `state/operations_controller.dart`, `domain/operations_repository.dart`, `data/http_operations_repository.dart` | ChangeNotifier와 주입 가능한 통신 경계가 있다. 신규 기능에 타입 모델을 추가하며 점진적으로 확장한다. |
| `developer/supabase_backend.mjs`, `supabase/functions/operations/index.ts` | 클라우드도 공통 operations 로직을 사용하고 RPC로 revision을 검사한다. 로컬만 바꾸고 클라우드 반영을 빠뜨리지 않는다. |

이번 세션은 코드·문서 검토다. 현재 앱의 브라우저 화면이나 실제 기기를 조작해 사용성을 검증한 결과로 해석하지 않는다.

## 3. 스킬 검색·설치·적용 방법

검색: `find-skills` 안내에 따라 `npx --yes skills find flutter`, `npx --yes skills find mobile ux accessibility` 실행. Flutter 검색 첫 실행은 npx 캐시 `ENOTEMPTY`로 실패했고 순차 재시도로 성공했다. 앱 의존성을 추가하는 작업과 에이전트 스킬 설치는 구분한다.

| 스킬 | 출처/상태 | 이번 설계에 적용 | Sol에서 읽을 시점 |
| --- | --- | --- | --- |
| `flutter-apply-architecture-best-practices` | [Flutter 공식 저장소](https://github.com/flutter/agent-plugins), 프로젝트 설치 | 설정 초안·화면·통신 책임 분리, 기존 ChangeNotifier/Repository 유지 | 데이터 계약 작성 전 |
| `flutter-build-responsive-layout` | 같은 공식 저장소, 프로젝트 설치 | 실제 사용 가능 너비 기준 레이아웃, 큰 글자·키보드·폼 스크롤 | 메뉴/설정 화면 구현 전 |
| `flutter-add-widget-test` | 같은 공식 저장소, 프로젝트 설치 | 입력→저장→오류, 탐색 복귀, 완료·접근성 검증 | 해당 기능 수용 테스트 작성 전 |
| `flutter-animations` | [madteacher 저장소](https://github.com/madteacher/mad-agents-skills/tree/main/flutter-animations), 프로젝트 설치 | 가장 작은 애니메이션 모델, lifecycle, 단계적 전환, reduced motion | 전환 효과 구현 전 |
| `ui-ux-pro-max` | 기존 사용자 설치본 재사용 | 화면별 정보 우선순위, 폼 상태, 폰트·투명도·명암 기준 | 화면 구조·디자인 토큰 작성 전 |

프로젝트 스킬 경로: `.agents/skills/<name>/SKILL.md`. 소스와 콘텐츠 해시는 `skills-lock.json`, 읽은 파일의 SHA-256 및 재현 안내는 `docs/SKILL_SELECTION_2026-09-27.json`에 보존한다. 기존 UX 스킬 경로는 `/Users/jaelee/.agents/skills/ui-ux-pro-max/SKILL.md`다.

선택 설치 명령:

```sh
npx --yes skills add flutter/agent-plugins --skill flutter-apply-architecture-best-practices flutter-build-responsive-layout flutter-add-widget-test --agent codex -y
npx --yes skills add madteacher/mad-agents-skills --skill flutter-animations --agent codex -y
```

스킬은 근거·작업 절차로 사용한다. Flutter 스킬의 예시 DI 컨테이너·Freezed·라우터 도입을 일괄 필수화하지 않는다. 사용자 요청의 기존 Flutter 구조를 우선하고 단순 불변 Dart 모델과 생성자 주입으로 시작한다. 일부 UX 데이터의 `textScaleFactor` 예시는 현재 SDK의 `TextScaler` 사용 가능 여부를 확인해 수정한다. 스킬 metadata의 모델 이름은 모델 전환 지시가 아니며, 설계는 현재 모델, 구현은 사용자가 선택할 Sol로 진행한다. 스킬 예제를 통째로 앱 코드에 복사하지 않는다.

## 4. 정보 구조와 대표 흐름

```text
업무                 매뉴얼                직원                  우리매장
├ TAP 3열 보드       ├ 전체 검색           ├ 근무표(기본)         ├ 매장 설정(기본)
├ BIG TAP 필터       ├ 유형/역할별 목록    ├ 직원/역할            ├ POS·배달
├ Small TAP          ├ TAP/Small TAP 방법  ├ 교육·버디            ├ 인원·운영시간
└ 업무 설정          └ 편집/기본양식       └ 채용 준비            ├ 배치도
                                                               ├ 메뉴·재료
                                                               └ 운영 현황·재고·발주
```

- 앱 기본 진입은 업무. 관리자도 실제 오늘 업무를 먼저 보고 설정/직원으로 이동한다. 우리매장 제목은 `우리매장`, 설명·접근성 이름에 `매장 설정`을 사용한다.
- 기존 Status의 매출·준비품·인건비·재고 진입은 우리매장 > 운영 현황으로 연결한다. 업무에서 당장 처리할 부족/실사 TAP은 계속 보인다. 사장 전용 인건비 응답 투영도 유지한다.
- 기존 Calendar는 직원 > 근무표. 직원 목록, 채용 준비는 상단 세그먼트/섹션으로 전환한다. 근무표의 06:00–24:00 표시 범위와 실제 영업시간을 혼동하지 않는다.
- 매뉴얼은 업무 체크 화면과 같은 원본을 읽는다. 새 별도 복사본을 만들지 않는다. 업무의 고정 검색은 남겨 두며 결과는 매뉴얼 상세로 연결한다. 매뉴얼에서는 완료 조작을 기본 노출하지 않는다.
- 매뉴얼 목록은 `templateId+stepId`로 중복을 묶고 현재 매장 양식을 우선 표시한다. 오늘 실행 건에서 연 매뉴얼은 그 실행 건의 snapshot을 보여 준다. 양식과 다른 버전이면 `이 업무에 적용된 방법`을 표시한다. 일반 직원이 template 원본 응답을 받지 않아도 서버가 만든 읽기 전용 매뉴얼 projection으로 동일한 검색·목록을 제공한다.
- 기존 기기 로컬 첫 근무 진행은 직원 > 교육과 업무의 필요 시 진입 링크로 연결한다. 직원 관리자가 이를 서버 저장된 교육 성과로 오인할 요약은 만들지 않는다.
- 하단 전환 후 각 메뉴의 스크롤·선택 날짜·필터를 복원한다. 초안 편집은 저장/취소가 분명한 독립 화면이다. 편집 중 이탈 시 저장/버리기/계속 편집 선택을 제공한다.
- 좁은 화면은 4개 라벨을 항상 표시한다. 충분한 너비에서는 같은 메뉴를 rail로 표시할 수 있으나 의미·순서를 동일하게 유지한다. 설정 폼 최대 폭 제안은 640dp, 보드 기존 최대 폭은 1240dp다.

대표 흐름: 사장이 매장을 등록 → POS/배달 사용 정보를 선택 → 해당 업무 양식을 추천받음 → 필요한 양식만 미리보고 가져옴 → TAP 담당·반복을 조정 → Small TAP별 수량/방법을 설정 → 직원은 Small TAP을 열어 수행·완료 → 성공한 행이 짧게 내려가며 완료 상태로 정리된다.

## 5. 우리매장: 입력 설계

긴 단일 폼 대신 `기본정보 / 주문 도구 / 사람과 운영 / 공간과 자료` 묶음을 사용한다. 첫 화면은 아이콘+항목명+현재 값 한 줄, 상세는 선택했을 때 연다. 최초 등록과 이후 변경은 같은 컴포넌트·검증 규칙을 사용한다. 매장명·업종을 저장하면 바로 시작할 수 있고 나머지는 `나중에`로 건너뛴다. 기존 계정은 누락 업종을 설정에서 안내하고 기존 업무 접근을 차단하지 않는다.

| 묶음 | 필드 | 입력 방식·규칙 | 사용처 |
| --- | --- | --- | --- |
| 기본 | 매장명, 업종 | 이름 직접 입력 1~80자; 업종 검색 picker+기타 | 화면 제목, 기본 양식 후보 |
| 기본 | 운영 형태 | 홀/포장/배달 복수 chip | 주문 처리·포장 업무 추천 |
| 기본 | 주소, 찾아오는 설명 | 선택 입력; 주소 텍스트 우선 | 직원 방문 안내·공고 초안. 지도 API·GPS 수집 별도 |
| POS | 사용 여부 | 미설정/사용/미사용. 미설정은 false와 다름 | 관련 설정 펼침 |
| POS | 제품, 모델, 단말 수 | 제품 검색 picker+기타 직접 입력; 모델 선택 입력; 수 stepper | 매장에 맞는 매뉴얼 분류 |
| POS | 쓰는 기능 | 주문접수/결제/영수증/주방출력/마감 체크 chip | 선택한 기능의 업무 양식 추천 |
| POS | 사용 안내 | 매장 메모 및 HTTPS 공식/매장 매뉴얼 링크 | 실제 제품별 절차. API 키·비밀번호 필드 없음 |
| 배달 | 사용 여부, 플랫폼 | 사용 toggle, 플랫폼 복수 선택+기타 | 배달 업무 후보 |
| 배달 | 플랫폼별 상세 | 접수 방식(직접/도구/미설정), 확인 기기, 출력 여부, 배달 방식, 포장·전달 확인 | 플랫폼별 Small TAP 기본값 |
| 직원 | 신고한 직원수 | 정수 stepper+숫자 키보드; 사장 포함 여부 별도 toggle | 초기 규모. 등록된 직원 수와 별도 표시 |
| 직원 | 필요 역할, 목표 인원 | 역할 picker+인원 stepper | 채용 준비의 초깃값. 기존 직급 권한과 분리 |
| 운영 | 영업 요일·시간·휴게 | 요일 chip, time picker, 익일 종료 표시 | 안내와 추천. 기존 근무표 자동 변경 금지 |
| 운영 | 교육 버디 사용 | toggle 및 등록 직원 picker(있을 때만) | 새 직원 교육 설정. 개인 연습/버디 확인 유지 |
| 공간 | 배치도 | 기존 편집기 진입 | `layout`, `zones`의 ID/격자/충돌 규칙 유지 |
| 자료 | 메뉴·재료·준비품 | 기존 각 편집기 진입 | 중복 입력 폼 생성 방지 |

제품·플랫폼 선택 목록은 운영 중인 공급자 계약 목록이 아니다. OKPOS 기존 기록은 사용자에게 현재 값으로 제시해 확인받고 다른 매장에는 자동 적용하지 않는다. 입력 범위는 예를 들어 단말 1~99, 직원 0~999로 제한하되 `설계 제안`이며 법적·사업적 기준으로 표현하지 않는다. 자유 문장은 매장명·기타·특수 지시·메모에 집중한다.

미설정 항목에 처음부터 ‘미사용’을 선택해 놓지 않는다. 설정을 끄면 하위 입력을 접고 값은 보관한다. 저장할 때 적용 결과를 한 줄로 알린다. 배달 OFF가 기존 배달 주문·업무·기록을 삭제하지 않는다. 필요 역할의 목표 인원은 실제 근무 확정이나 채용 공고 게시로 연결되지 않는다.

설정→추천은 결정적인 조건표로 구현한다. 예: 배달 사용+플랫폼 선택 → 접수/포장/전달 양식 후보. 추천에서 `미리보기 → 선택 → 가져오기`를 거치고 중복 template ID와 버전을 검사한다. 필수 레시피 수치나 POS 버튼 위치를 추측해 생성하지 않는다.

## 6. TAP·Small TAP 설정 계약

### 6.1 세 수준의 적용 범위

1. **업무 유형 양식**: 일반 업무/오픈·마감/청소·정비/주문·포장/준비·수량/교육. 시작 구성을 제안하며 실제 매장에 자동 생성하지 않는다.
2. **매장 TAP 템플릿**: 미래에 생성될 업무의 기준. `설정`에서 수정하고 적용 시점을 보여 준다.
3. **오늘 실행 건**: 생성 시 설정·매뉴얼·버전을 snapshot으로 갖는다. 작업 체크와 완료 값은 실행 건에만 저장한다. 첫 구현의 설정 편집은 템플릿에 한정하고 오늘 실행 건에서는 수행·수량·완료·기존 순서 조작만 제공한다. 당일 설정 override 편집은 후속 제안이다.

화면의 기본 설정 진입은 템플릿이다. 새 설정의 저장 버튼 주변에 `이미 만들어진 업무는 유지 · 다음 생성부터 적용`을 보여 준다. routine의 다음 생성은 다음 한국 날짜이며 주문은 다음 주문 생성이다. 기존 매뉴얼 직접 편집의 동작과 새 설정 저장의 적용 시점을 화면·서버 명령에서 구분한다. 새 설정 저장 때문에 같은 날 이미 생성된 업무를 삭제하거나 재생성하지 않는다.

### 6.2 설정 항목과 컨트롤

| 수준 | 항목 | UI와 기본 규칙 |
| --- | --- | --- |
| TAP | 이름·업무 유형·BIG TAP | 짧은 이름 입력, 유형 picker, 기존 그룹 picker |
| TAP | 수행 역할 | 현재 허용 역할 picker. ‘가능한 담당자’와 실제 개인 배정을 구분 |
| TAP | 위치 | zones 검색 picker. 장소가 없으면 ‘위치 나중에’, 가짜 entrance ID를 저장하지 않음 |
| TAP | 반복 | 기존 업무 매일 유지, 새 양식은 매일/요일 선택. ‘사용 중’ toggle로 미래 생성 중지 |
| TAP | 시간대 | 오픈/준비/피크/브레이크/마감 picker. 시계 기준 마감으로 표현하지 않음 |
| TAP | 일괄 완료 | toggle. 새 업무 기본 OFF 제안, 기존 업무 기존 값 보존 |
| TAP | 순서대로 수행 | toggle. ON이면 Small TAP 순서가 실행 조건이 됨. 이때 실행 중 순서 변경은 금지; 템플릿 순서 편집 가능 |
| Small TAP | 이름·방법·팁 | 이름, 짧은 본문, 선택 팁. 상세에서 단계적으로 입력 |
| Small TAP | 완료 방식 | 체크 / 수량 입력 segmented picker |
| Small TAP | 수량·단위 | 수량형에서만 목표(선택), 단위(필수), 소수 허용 표시 |
| Small TAP | 예상 시간 | 사용 toggle + 분 picker/직접 입력. 예상치이며 카운트다운·자동 완료 아님 |
| Small TAP | 역할·위치 | ‘TAP 설정 따름’ 기본; 개별 지정 후 ‘기본값으로’ 복귀 가능 |
| Small TAP | 링크·연관어 | 기존 HTTPS 사진·영상 링크, tag chip. 사진 제출과 구별 |

설정값은 `양식 기본값 → TAP 기본값 → Small TAP 명시 override`로 계산한다. override의 `null`은 상속, 0/false/빈 배열은 실제 값으로 해석한다. 계산 결과는 실행 건 생성 때 고정한다. 상위 변경 시 어떤 Small TAP이 함께 바뀌는지 저장 전 표시한다.

수량형 일반 업무의 실측값은 완료 증빙이다. 재고를 늘리는 명령이 아니다. 준비품 완료는 기존 `finishPreparation`의 실제 완성량, 재고 실사는 기존 `check_stock` 경로를 사용한다. 주문·준비품·실사처럼 시스템이 만든 업무는 연결 ID와 생성 규칙을 읽기 전용으로 보여 준다. 일반 반복 양식으로 전환시키지 않는다.

### 6.3 일괄 완료와 권한

- 일괄 완료는 모든 미완료 단계가 단순 체크이고 실행자가 각 단계 권한을 가지며 순서 제한이 없는 경우에만 가능하다.
- 수량 필수/단계별 역할 제한/순서 강제/준비품 완성 입력이 있으면 TAP 완료 버튼은 필요한 Small TAP으로 안내한다.
- 보드 드롭, TAP 완료, Small TAP 완료가 같은 서버 완료 정책을 통과한다. 드래그로 정책을 우회할 수 없어야 한다.
- 부모 역할과 자식 override는 권한을 자동 확대하는 수단이 아니다. 사장/매니저의 편집 권한, 실제 수행 역할, 인증 매장 소속을 서버에서 검사한다.
- 순서 강제 단계 되돌리기: 이후 완료 단계가 있으면 거절하고 마지막 완료 단계부터 되돌리도록 안내하는 방안을 제안한다. 이후 증빙을 조용히 삭제하지 않는다.
- 기존 되돌리기 범위(본인/리더·당일), 준비품 반영 후 되돌리기 제한, 주문 날짜 처리의 현재 규칙은 회귀 검증한다.

## 7. 화면 밀도·폰트·색상

### 기본 화면에 남기는 정보

- TAP 카드: 완료 조작 / 업무명 / 열기, 아래 줄에는 진행 `2/5`와 역할 또는 담당 가능자 요약. 기존 세 조작의 48dp 영역을 유지한다.
- 주문은 주문 식별·시간·요청사항·채널을 읽을 수 있어야 한다. 글자를 줄이기 위해 필요한 주문 정보를 숨기지 않는다. 전체 주문 진행률은 필터로 잘린 일부 메뉴 기준으로 계산하지 않는다.
- Small TAP: 체크/입력, 짧은 행동 이름, 필요한 값 하나. 예상 시간·링크·팁·전체 매뉴얼은 상세에 둔다. 수량 필수 등 실행 조건은 행에 남긴다.
- 설정 목록: `POS   OKPOS · 1대 >`, `배달   2개 사용 >`처럼 이름+현재 값. 긴 설명은 상세의 도움말로 옮긴다.
- 빈 상태: 원인 한 문장+관련 행동 하나. 오류는 해당 입력 아래; 저장 실패는 초안을 유지하고 재시도 가능. 로딩은 위치가 변하지 않는 자리표시자와 ‘불러오는 중’ 의미를 제공한다.

### 서체 선택

기본안은 번들된 **Noto Sans KR 하나**를 유지하고 굵기 400/500/600/700로 위계를 만든다. 비교 후보는 Pretendard 단일 서체, 또는 한글 Noto Sans KR+플랫폼 영문 서체다. 후속 시각 비교 없이 서체 교체를 확정하지 않는다. 새 폰트 도입 시 공식 배포·라이선스·한글/숫자 포함 범위·웹 초기 크기를 확인한다.

| 용도 | 기본 크기·행간 제안 |
| --- | --- |
| 페이지 제목 | 24 / 1.3, 700 |
| TAP 제목 | 17 / 1.4, 600 |
| 행동·설정 본문 | 16 / 1.5, 400~500 |
| 보조·현재 값 | 14 / 1.45, 400~500 |
| 하단 메뉴 | 13 / 1.3, 600; 큰 글자에서 영역 확장 |

TextScaler를 막거나 FittedBox로 본문을 줄여 배치를 맞추지 않는다. 기본 한 줄 카드 제목은 큰 글자에서 최대 두 줄을 허용하고 상세에서는 전문을 보여 주는 방안을 제안한다. 기존 툴팁 외에 터치 상세로 전문을 읽을 수 있어야 한다.

### 색·투명도 토큰

현재 paper `#F7F5F0`, surface `#FFFFFF`, ink `#18302F`, green `#193B3A`, accent `#B8422C`, muted `#526461`를 기준으로 한다. 배경 tint는 6~10%, 선택 12~16%, 진행 채움 14~20%를 출발값으로 제안한다. 역할/사람 색과 성공 상태를 혼동하지 않도록 완료에는 체크+`완료`를 함께 표시한다.

투명도는 카드 배경·진행 영역·짧은 전환에 사용한다. 정적 본문 전체의 opacity를 낮춰 완료를 표현하지 않는다. 합성된 실제 배경 위에서 작은 글자 4.5:1, 큰 글자 3:1을 확인한다. 이는 [Flutter 접근성 안내](https://docs.flutter.dev/ui/accessibility/ui-design-and-styling)의 대비·큰 글자·터치 목표 지침을 적용한 검증 기준이다.

## 8. 전환 효과 명세

아래 시간과 이동량은 첫 구현의 조정 가능한 제안값이다. 화면에서 구조가 이해되는지가 기준이며 사용자 체감 확인 전 ‘검증 완료’로 기록하지 않는다.

| 상황 | 연출 | 제안 시간/거리 | 구현 방향 |
| --- | --- | --- | --- |
| TAP 열기 | 선택 카드의 제목·색을 유지하며 Small TAP 영역이 펼쳐짐 | 260~320ms, 목록 6~10dp | 현재 같은 route 내 전환이면 bounds/size 전환. route 전환일 때만 Hero |
| Small TAP 나타남 | 처음 보이는 행이 짧은 간격으로 정착 | 행 25~35ms 간격, 전체 360ms 이내 | 하나의 controller+Interval, 첫 6행만 |
| 완료 | 성공한 글줄의 표시 복제본이 아래로 내려가며 fade, 완료 행으로 정착 | 180~240ms, 10~16dp, 총 320ms 이내 | 작은 Slide/Fade, 레이아웃 크기 안정 유지 |
| 부모 TAP 완료 | 보드 완료 열 상태로 정리, 색 채움 안정화 | 200~280ms | stable ID로 위치 전환, 데이터 삭제 금지 |
| 설정 펼침 | 선택한 toggle 아래 관련 입력을 드러냄 | 160~200ms, 4~8dp | AnimatedSize+Fade, 저장 성공 연출과 구분 |
| 설정 저장 | 버튼 저장 상태→체크·‘저장됨’ | 120~180ms | 서버 성공 후에만 성공 표시 |
| 되돌리기 | 미완료 상태로 짧게 복귀 | 140~180ms | 성공 축하 재생 없음 |
| 동작 줄이기 | 위치 이동/순차 등장을 생략 | 0ms | 즉시 상태+접근성 알림 |

완료 흐름은 `idle → submitting → succeeded / failed`다. 누른 순간은 작은 눌림 피드백과 진행 표시만 제공한다. 서버 성공 뒤 현재 사용자가 요청한 항목에 대해 한 번만 완료 효과를 재생한다. `taskId+stepId+명령 ID`로 효과 소비를 관리하며 5초 polling, 재접속, 다른 직원 완료에는 재생하지 않는다. bool만 반환하는 기존 act와 결합할 때도 성공 응답에 해당 대상이 완료됐는지 확인한다.

실패·403·409에서는 원래 행과 값 유지, 충돌 내용과 최신 상태 안내. 타임아웃은 실패 확정이 아닌 결과 불명일 수 있으므로 최신 조회로 확인한 뒤 재시도한다. 애니메이션 callback에서 재고 차감·완료 저장을 호출하지 않는다. 도중 화면 이탈·탭 변경은 효과만 취소하며 서버 결과를 취소 처리하지 않는다.

복제된 시각 요소는 IgnorePointer/ExcludeSemantics로 만들고 실제 완료 행의 접근성 의미는 한 번만 남긴다. 입력 초점이 사라진다면 다음 미완료 행 또는 완료 상태로 이동시킨다. 완료한 글 전체를 영구 제거하거나 길게 잠그지 않는다. 효과 중에도 다른 업무는 조작할 수 있다.

[MediaQuery.disableAnimationsOf](https://api.flutter.dev/flutter/widgets/MediaQuery/disableAnimationsOf.html)를 읽고 설정 변경도 즉시 반영한다. 앱 개인 설정은 `기기 설정 따름 / 효과 줄이기`를 제안하며 공유 매장 설정에 저장하지 않는다. [Hero](https://docs.flutter.dev/ui/animations/hero-animations)는 서로 다른 route의 공유 요소용이다. 현재 TAP 전환 구조에 무조건 붙이지 않는다. [단계적 애니메이션](https://docs.flutter.dev/ui/animations/staggered-animations)은 제한된 행에만 사용한다.

## 9. 데이터·API·이관 상세 제안

### 9.1 최소 데이터 모델

```text
state.store.profileVersion = 1
state.store.profile = {
  industryId?, serviceModes[], address?,
  pos: { configured, enabled?, devices[{id, providerId, customName?, model?, count, functions[], guideUrl?}] },
  delivery: { configured, enabled?, platforms[{id, providerId, customName?, acceptanceMode?, printTicket?, handoffMode?}] },
  staffing: { declaredCount?, includesOwner?, roleTargets[{roleId, count}] },
  hours: { days[{weekday, closed, periods[{start, end, endsNextDay}], breaks[]}] }
}
template.settingsVersion = 1
template.settings = {
  type, enabled, recurrence:{mode:daily|weekly, weekdays[]},
  allowBulkComplete, enforceSequence
}
step.settings = {
  roleOverride?, zoneOverride?, completionKind:check|quantity,
  quantitySpec?:{unit, target?, decimalPlaces}, estimatedMinutes?
}
step.result = { quantity?, completedAt, completedBy, completionSource? }
state.hiringDrafts[] = {
  id, roleId, headcount, employmentType?, weekdays[], timeRange?,
  locationVisibility, responsibilities[], requirements[], note?, status:draft|archived
}
```

기존 title/requiredRole/zone/folderId/slot/steps 및 completedAt/completedBy 필드를 바로 제거하지 않는다. 위 result 구조를 쓰더라도 기존 소비자 호환을 위한 매핑을 정의한다. 물리적 저장 형태는 이중 진실을 만들지 않도록 Sol이 기존 테스트를 기준으로 정한다. 채용 역할 ID와 `owner/manager/crew/cook` 같은 실행 권한 역할은 서로 대체하지 않는다.

선택형 필드는 서버 enum whitelist, 문자열 길이·배열 수·숫자 범위·HTTPS 링크·존재하는 참조 ID를 검증한다. 새 모듈의 권장 경계는 `StoreProfile`, `TapSettings`, `StepSettings`, `HiringDraft`, 각 validator/mapper다. 모든 기존 JSON 화면을 이번 작업에서 일괄 재작성하지 않는다.

### 9.2 저장 계약

- `save_store_profile`: `{revision, section, values}`. 사장 전용 부분 저장; 허용 section만 갱신. 기존 save_store 이름·안내 저장과 상호 보존.
- `save_tap_settings`: `{revision, templateId, settings, stepOverrides[]}`. 리더 권한, 존재하는 template/step ID, 유효한 유형별 옵션을 검증한다. 제목·매뉴얼 편집과 달리 오늘 실행 건을 archive하지 않는다. stepOverrides는 해당 template의 자식에 한정하고 생략과 명시적 상속 초기화를 구분한다. 서버에서 템플릿 version만 증가시키고 실행 건 snapshot은 보존한다.
- `save_checklists`: 기존 계약에 settings 추가. 구형 클라이언트가 새 필드를 누락했을 때 기존 설정을 초기화하지 않도록 보존/기능 버전 검증. 새 클라이언트는 지원하지 않는 서버에서 편집을 막고 안내.
- `complete_step`: `{revision, taskId, stepId, quantity?}`. 기존 특수 업무 경로와 공통 완료 정책을 검증. 수량은 유한한 수, 허용 소수 자리, 유효 범위 검사.
- `save_hiring_draft`/`archive_hiring_draft`: 사장 전용 저장을 기본안으로 한다. 글 생성은 로컬/서버의 결정적 텍스트 조합, 외부 서비스 호출 없음.
- 매니저: 기존 업무 양식·근무 운영 권한 유지. 매장 profile·채용 초안 권한 확대는 기본으로 하지 않음. 직원: 업무 실행·매뉴얼/배치 읽기; 관리 설정과 채용 초안은 서버 응답에서 제외.
- 모든 편집기는 화면 개시 revision을 저장한다. polling으로 최신 revision이 와도 초안의 revision을 교체하지 않는다. 409이면 최신값과 내 초안을 비교하고 재적용한다. 자동 무조건 재시도 금지.
- 성공 응답은 정규화된 저장 결과와 revision을 반환한다. 공개 리뷰에서는 편집 초안 체험만 제공하고 기존 저장소의 쓰기 차단을 유지한다.
- 로컬/클라우드는 공통 검증 함수 사용. private fields는 클라이언트 숨김에 의존하지 않고 snapshot projection에서 제외한다.

### 9.3 이관·반복 생성·기록 보존

1. 프로필 미설정은 unknown으로 이관; 기존 name/note/setup/layout/zones를 보존. 실제 계정의 OKPOS 사용 여부를 샘플 데이터로 추론하지 않는다.
2. 템플릿 설정 없는 기존 업무는 매일·활성·기존 일괄완료 동작으로 해석한다. 단계는 기존 체크 방식, 단 준비품/실사는 기존 특수 수량 규칙 우선.
3. 새 매장의 장소 없는 양식을 위해 nullable zone 지원을 서버·UI·import까지 동일하게 정의한다. 예전 존재하지 않는 entrance fallback을 새 데이터에 적용하지 않는다.
4. 새 설정 저장은 템플릿 version을 증가시키며 오늘 이미 생성된 모든 실행 건을 보존한다. 기존 `saveChecklists`의 미시작 건 아카이브 정책을 새 설정 명령에서 그대로 실행하지 않도록 저장 의도를 분리한다. 기존 매뉴얼 편집 경로는 기존 동작을 유지하되 새 settings snapshot을 유실하지 않아야 한다.
5. `ensureDueTasks`는 Asia/Seoul 요일, enabled, recurrence를 검사한다. 같은 template/date의 활성 실행 건은 최대 하나; 같은 날 완료 건이 있으면 설정 수정만으로 두 번째 업무를 만들지 않는다.
6. 요일/활성 변경은 다음 한국 날짜의 routine 생성부터 적용한다. 오늘 기존 건은 미시작/시작/완료 모두 유지한다. 기존 건이 없는 새 템플릿은 오늘 조건에 맞으면 한 번 생성한다. 저장 시 오늘 생성 여부를 알려 준다. 즉시 적용/기존 건 교체 옵션은 첫 범위에서 생략한다.
7. 반복 요일은 routine용이다. 발주 후 N일 실사(D-017), 주문 메뉴 TAP, 준비품 부족 TAP에 적용하지 않는다. 주문·입고·준비품 원장은 각 기존 중복 방지 규칙 유지.
8. 현재 영업시간을 입력해도 기존 근무 슬롯·배정·야간 근무를 삭제하거나 이동하지 않는다.
9. 순서·완료 정책 추가는 `complete_task`, `complete_step`, `move_tap`, `reopen_step`, 공개 체험 경로 모두 점검한다. 클라이언트 하나만 막는 것은 완료가 아니다.
10. 이관은 멱등, 기존 샘플과 빈 매장 양쪽 fixture로 검증. 생산/로컬 실제 데이터 파일을 테스트로 변경하지 않는다. 서버 버전만 되돌려 새 필드가 유실되지 않도록 백업·호환성 확인 후 rollback 계획을 둔다.

## 10. 직원·채용 준비

직원 메뉴 기본은 현재 근무표다. 직원 등록/직무/고용형태와 교육 진입은 같은 메뉴에 둔다. 필요 인원은 우리매장의 역할별 목표 인원을 가져오고 채용 초안 작성 시 복사한다. ‘직원 등록 수’, ‘신고한 직원수’, ‘특정 시간대 부족 인원’은 서로 다른 값이다. 이 셋을 단순 차감해 확정 채용 인원으로 표시하지 않는다.

공고 초안은 직무, 채용 인원, 고용형태, 요일/시간, 업무, 근무 장소 표시 범위, 요구사항으로 조합한다. 근무조건 미입력은 `미입력`으로 표시한다. 급여·계약·연락처를 추정하지 않는다. 매뉴얼 링크/설명은 사장이 포함할 내용을 직접 선택한다.

완성 초안은 보기/수정/복사까지. 명확한 `공고 초안 · 아직 게시되지 않음` 상태를 보여 준다. 외부 공고 게시·지원자·면접·합격 통보·전자계약·메시지는 후속 로드맵이다. 공고 초안 작성만으로 직원 계정/근무를 만들지 않는다. 이후 실제 지원자 정보를 받기 전 별도 접근·보관 정책을 설계한다.

## 11. Sol 구현 순서와 파일 단위 작업

| 단계 | 결과물 | 주요 수정/추가 후보 | 종료 기준 |
| --- | --- | --- | --- |
| S0 계약 고정 | 설정 schema, 기본값, migration, 권한·완료 정책 표 | `domain/store_profile.dart`, `domain/tap_settings.dart`, `developer/store_profile.mjs`, `developer/task_settings.mjs` | 기존/누락/잘못된 값과 저장 보존 fixture 통과 |
| S1 메뉴 재편 | 업무·매뉴얼·직원·우리매장, 이전 경로 연결 | `ui/operations_screen.dart`, 신규 `manuals_screen.dart`, `staff_workspace.dart`, `store_settings_screen.dart` | 모든 기존 주요 기능 접근, back/filter/date 보존 |
| S2 우리매장 | 최초 등록·설정 수정·조건부 추천 | `catalog_editor.dart`, `cloud_workspace.dart`, 신규 profile 폼/초안 controller, 서버 operations | 재접속 유지, unknown 처리, 권한/409/공개 리뷰 |
| S3 TAP 설정 | 유형·역할·반복·완료 정책, Small TAP override | `checklist_editor.dart`, `checklist_draft.dart`, `checklists.mjs`, `operations.mjs`, `order_taps.mjs` | UI 선택이 서버 행동과 생성에 실제 반영, 역사 보존 |
| S4 직원/채용 | 근무표 통합·교육 진입·초안 작성/복사 | `calendar_screen.dart`, `team_screen.dart`, 신규 `hiring_draft.dart`, `hiring_drafts.mjs` | 권한 투영, 외부 전송 없이 초안 저장/수정 |
| S5 시각·전환 | 타입 스케일·tint·TAP 펼침·완료 효과 | `main.dart`, `components.dart`, `tap_card.dart`, `tap_workspace.dart`, 신규 `motion_tokens.dart` | 저장 성공과 연출 분리, reduced motion, 이탈/연속 조작 |
| S6 통합 검증 | 시나리오·폭·공개빌드·기록 | app/test, developer/test, PRODUCT, project-state | 아래 AC 통과, 미수행/실패 정직하게 기록 |

권장 구현 단위는 S0+S1, S2, S3, S4, S5+S6 순의 리뷰 가능한 변경이다. 각 단위가 동작하는 상태에서 다음으로 진행한다. 신규 의존성은 필요한 경우에만 추가한다. API 모듈 추가 시 npm check에 구문 검사를 포함하고 Edge Function 패키징/import 경로도 확인한다. 인증 계정 저장 검증은 테스트 매장 데이터로 수행한다.

## 12. 검증과 수용 기준

| ID | 관찰 가능한 완료 조건 |
| --- | --- |
| AC-01 | 4개 하단 메뉴에서 이전 업무·매출·재고·발주·지도·근무·첫 근무 기능에 접근한다. 직원에게 사장 전용 금액/초안이 전송되지 않는다. |
| AC-02 | 초기 미설정과 미사용 구분, 입력값 유지, 취소 복원, 키보드가 저장 버튼을 가리지 않음, 새로고침 후 서버 값 유지. |
| AC-03 | POS/배달 조건부 필드·추천이 선택에 맞고 가져오기 중복 방지. 설정 OFF 후 기존 주문/템플릿/기록 보존. |
| AC-04 | TAP 상속/Small TAP override/기본값 복귀가 저장·재조회 후 동일하다. 구형 payload가 신규 필드를 삭제하지 않는다. |
| AC-05 | 요일 반복을 한국 자정 양쪽에서 검사. 활성 업무 중복 생성 없음, 시작/완료 이력 보존. |
| AC-06 | 수량/순서/역할 규칙을 API 직접 요청 및 드래그 일괄완료로 우회할 수 없다. |
| AC-07 | 동시에 편집한 두 세션 중 뒤 저장은 409; 내 초안 유지; 자동 overwrite 없음. 400/403/401/timeout도 의도대로 표시. |
| AC-08 | 일반 수량 체크는 재고 변동 없음. 준비품 완료/주문 사용량/발주 입고는 한 번만 반영. D-017 기한 불변. |
| AC-09 | 완료 성공 1회에 효과 1회. 서버 실패/다른 사용자 변경/polling은 완료 효과 없음. 연속 탭·이탈·즉시 복귀에서 ticker/중복 저장 오류 없음. |
| AC-10 | 동작 줄이기 ON에서는 이동·순차 효과 0. 접근성 완료 알림 1회. TalkBack/VoiceOver 초점과 조작 순서 검토. |
| AC-11 | 320/390/768/1440dp, 글자 100/150/200%, 긴 한글, 빈 목록, 30개 Small TAP, 키보드 열린 폼에서 잘림/overflow 없음. 48dp 조작 유지. |
| AC-12 | 색을 제거해도 선택/미완료/완료 식별 가능. 투명도 합성 배경 대비 확인, 제목/현재값 읽기 가능. |
| AC-13 | 공고 초안은 저장/수정/보관/복사되며 외부 전송·직원 계정 생성 없음. 미입력 조건을 꾸며 쓰지 않음. |
| AC-14 | 공개 빌드는 새 가상 샘플, 저장 API 차단, `.local`/project-state/실제 개인정보/스킬 파일 미포함. |

실행 게이트: 변경 Dart 포맷 → `cd app && flutter analyze` → 관련 테스트 및 최종 `flutter test` → API 변경 후 `npm run test:console` → `npm run check` → `npm run build:site` → `git diff --check`. 시각 확인은 브라우저/가능한 기기에서 별도로 기록한다. 완료 motion은 `pumpAndSettle` 결과만 보지 말고 중간 프레임·실패 분기·동작 줄이기를 검사한다.

정적 screenshot은 가독성·배치 검토용, 실제 애니메이션은 실행 영상/실기기로 평가한다. 프레임 예산은 60Hz 16.7ms를 목표로 profile mode에서 확인하되 기기·브라우저·빌드 모드를 함께 기록한다. 네이티브 빌드/실기기/실계정 검증이 없으면 웹 빌드로 대신 통과 처리하지 않는다.

## 13. 설계 완료와 구현 완료의 구분

이번 방법론 완료 조건: 핵심 질문 답변 반영, 새 메뉴와 필드·상속·저장·전환·채용 범위 명세, 스킬 실제 설치 및 사용 근거, Sol 전달문, canonical 결정 이력, 문서/JSON 검증.

아직 구현되지 않은 것: 새 4메뉴, 우리매장 운영 프로필, TAP 설정 확장, 채용 초안, 새 완료 효과. 구현 후 수용 기준을 통과하기 전 milestone을 done으로 바꾸지 않는다. 이번 세션은 앱 배포 권한 요청이나 배포 실행으로 이어지지 않는다.
