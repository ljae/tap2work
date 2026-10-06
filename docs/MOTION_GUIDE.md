# 앱 공통 모션 기준

2026-09-28 사용자 요청으로 앱 전반의 반응과 화면 전환을 통일했다. 기준 구현은 `app/lib/ui/app_motion.dart`와 `design_system.dart`다. 새 화면은 이 컴포넌트를 사용한다.

## 참고한 스킬과 가이드

- [사용자가 지정한 flutter-animating-apps](https://github.com/nexu-io/open-design/blob/main/skills/flutter-animating-apps/SKILL.md)는 upstream 설치를 안내하는 카탈로그다. 확인 당시 `flutter/skills` main에는 해당 이름의 본문이 없었다. 해당 전체 워크플로를 설치·실행했다고 주장하지 않는다.
- 실제 구현에는 프로젝트의 [flutter-animations](../.agents/skills/flutter-animations/SKILL.md)와 implicit/explicit/curves 참조를 적용했다. 상태 기반 애니메이션을 우선하고 controller 수명·dispose·동작 줄이기·테스트를 검증한다.
- [토스 소비자 UX 가이드](https://developers-apps-in-toss.toss.im/landing-page/landing-page-en/design/consumer-ux-guide)는 명확한 동작, 예측 가능한 이동, 사용자를 방해하지 않는 흐름의 기준이다. 아래 시간과 곡선은 tap2work 구현값이며 토스 공식 모션 수치가 아니다. 기존 자체 로고와 초록/코랄 색을 유지한다.

## 적용 범위

| 상호작용 | 공통 구현 | 동작 |
|---|---|---|
| 일반·아이콘 버튼 | `AppMotionScope` / `PressBounce` | 80ms 눌림, 260ms 복원, 0.95 배율. 기본 버튼의 포인터·키보드·비활성 상태를 사용한다. 중복 bounce는 생략한다. |
| 하단 메뉴·설정 행 | `PressBounce`, 공통 duration | 눌림과 선택색 전환. 터치가 스크롤로 바뀌면 복원한다. |
| 모든 선택 chip | `AppMotion.chipStyle` | 선택·해제·활성화 160ms. 필터와 설정이 같은 속도로 반응한다. |
| 업무·매뉴얼·근무표·우리매장, 교육 메뉴 | `AppContentTransition` | 변경된 화면만 240ms 동안 10px 이동하며 나타난다. 이전 화면을 겹쳐서 유지하지 않는다. |
| 근무표 하위 메뉴·매뉴얼 탐색 | `AppContentTransition` | 변경된 선택에 반응한다. 데이터 polling·동일 선택은 다시 재생하지 않는다. |
| 설정·상세·매뉴얼·QR 시트 | `AppMotion.panelStyle` | 진입 360ms, 닫힘 220ms. 초안 취소 확인과 기존 닫기 정책을 유지한다. |
| 모든 확인창·로그인 창 | `showAppDialog` | 진입 240ms, 닫힘 160ms. 명확한 닫기 동작을 유지한다. |
| 보조 팝업·접기/펼치기 목록 | `popUpAnimationStyle`, `ExpansionTileTheme` | 공통 240/160ms와 동작 줄이기를 적용한다. 날짜·시간 선택기의 기본 접근성 동작은 유지한다. |
| 페이지 이동 | `AppPageRoute` | Cupertino 이동, 360/220ms. 동작 줄이기에서는 route 시간도 0이다. |
| 진행률·로딩 | `AppLinearProgress`, `AppCircularProgress`, `WorkspaceSkeleton` | 확정 진행률 변화는 240ms, 비율 미확정은 로딩으로 읽는다. |
| 업무 완료 | `CompletionText`, 기존 성공 trigger | 저장 성공 후 완료 모션을 재생한다. 기존 440ms 효과와 520ms 위치 보존 시간을 토큰으로 관리한다. |

## 구현과 접근성 원칙

- 애니메이션은 표현이다. 저장·발주·급여 계산을 animation callback으로 실행하지 않는다. Supabase의 성공/오류/revision 충돌 계약을 바꾸지 않는다.
- 화면 전환은 현재 내용만 그려 과거 화면의 버튼·접근성 노드가 중복되지 않게 한다. controller를 State가 소유하고 dispose한다.
- `MediaQuery.disableAnimations`가 켜지면 이동·눌림·선택 전환·shimmer를 줄이거나 즉시 완료한다. 로딩은 정적인 표시와 ‘처리 중’ 접근성 이름을 사용하고 가짜 완료율을 알리지 않는다.
- 입력 초안, 포커스, 서버 권한, 클릭 횟수와 스크롤은 유지한다. 표의 모든 셀이나 검색 한 글자마다 별도 진입 효과를 붙이지 않는다.
- 레이아웃/글자 크기를 흔드는 효과, 자동 팝업, 완료 전 축하, 반복 장식 모션을 추가하지 않는다.

## 검증

`app_motion_test.dart`는 키보드/포인터 활성화, 빠른 화면 교체, polling 시 재생 방지, 실행 중 동작 줄이기 전환, 진행률과 확인창을 검사한다. 기존 모션 테스트는 저장 성공 완료 효과와 초안 보호를 검사한다. `tool/reference_ui_review.dart`는 실제 폰트로 전환 중간 프레임과 정지 화면을 캡처한다. 정적 캡처와 widget 테스트는 실기기 프레임 성능 측정을 대신하지 않는다. 실제 실행 결과는 `project-state.json`에 기록한다.

## 가독성·시작 로딩 확장

`showAppSheet`의 키보드 여백은 공통 quick 모션으로, 정산 주기별 컨트롤 높이는 content 모션으로 전환한다. 저장 성공 여부는 변경하지 않는다. 웹 로딩은 Flutter 첫 프레임 이후 240ms fade로 걷히고, 초기화/매장 데이터 로딩은 실제 완료까지 이어진다. CSS `prefers-reduced-motion`과 Flutter `MediaQuery.disableAnimations` 모두 지원한다. [상세 계약](UI_READABILITY_2026-09-28.md).

## 길게 눌러 편집

업무·매뉴얼·근무표의 DirectEditFrame은 편집 권한이 있을 때만 180ms 역방향 반복의 작은 회전을 보여준다. 표시는 테두리와 실제 이름/휴지통/이동 동작을 동반한다. 동작 줄이기에서는 정지 표시, 편집 완료·권한 회수·TickerMode 비활성·dispose 시 중지한다. 화면 전체를 매 프레임 다시 구성하지 않고 AnimatedBuilder child를 재사용한다. `flutter-animations`의 lifecycle/reduced-motion 지침과 `flutter-add-widget-test`의 제스처 검증을 적용했다.

## 2026-10-06 TAP Water

`WaterSearch`는 웃는 물컵 아이콘 옆 검색 입력에 포커스가 생기거나 사라질 때 물결선 위상·진폭과 테두리/표면을 360ms easeOutCubic으로 전환한다. 입력 글자별 반복 재생이나 상시 ticker는 없다. 공통 `AppMotionScope`는 InkRipple을 사용하고 하단 메뉴는 160ms 초록 선택 표면으로 반응한다. 기존 눌림·시트·화면 전환을 함께 유지한다. 동작 줄이기에서는 물결 duration=0, NoSplash로 바뀐다. `water_layout_test.dart`에서 검색 입력/지우기와 reduced motion을 검증한다.
