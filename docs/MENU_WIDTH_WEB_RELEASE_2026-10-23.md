# 네 메뉴 너비 통일·웹 배포 — 2026-10-23

사용자의 메뉴별 width 통일 요청에 따라 업무·매뉴얼·근무표·우리매장과 상단 검색/도구의 본문 최대 폭을1240px, 좌우 여백을24px로 맞췄다. 브랜드와 매뉴얼 외곽은 여백 포함1288px로 중앙 정렬하며 작은 화면에서는 같은 여백 안을 채운다. `AppLayout` 토큰을 사용하고 매뉴얼의 이전880px 제한과 근무표의 무제한 폭을 대체한다. 데이터·저장·상단 접기·폴더 이동·편집·하단 네 메뉴는 유지한다.

[tap2.work](https://tap2.work/)에 코드 `2ad0874edfd663df9ef9bb9401cf9488f478bc51`이 배포됐다. [Actions39800888397](https://github.com/ljae/tap2work/actions/runs/39800888397)의 전체 run/build/deploy 모두 completed/success, Pages배포7255788521은2026-10-23 00:08:41KST success다. 공개267파일이 해당 CI artifact와 SHA256 전부 일치하며 artifact ZIPdigest도 확인했다.

- CI Flutter647개 통과/브라우저 전용3개 제외, 분석 문제0, 서버394개, UI92/JS/Edge/격리SQL5개/번역/웹 빌드 통과.
- 로컬 관련26개와 일반 환경8개 테스트 통과.320/390/1200/1600px×글씨1.0/1.5에서 네 메뉴·검색·브랜드의 실제 좌우/너비와 스크롤·폴더·편집 동작 검사.88widget 캡처 생성, 주요 데스크톱 화면 시각 검토.
- 실제 headless Chrome390×844 공개 샘플에서 업무 펼침→상단 스크롤 접기/복귀, 폴더 선택, 주간/월간·설정 메뉴 표시 확인.1600×900에서는 네 메뉴 전환, 검색 영역의 동일한 위치/너비와 캡처 정렬 확인. 두 실행 모두 pageerror0/operations POST0. 팝업 선택 자체는 기존 위젯 검증 범위다.

초기 검사에서 새 테스트의 WaterSearch import 누락을 수정한 후 통과했다. GitHub Actions 상태 갱신 지연으로 초기queued가 오래 표시됐으나 실제 빌드 로그·artifact·배포 기록과 최종success를 확인했다. 원래 미커밋 작업은 보존했고 별도 작업 트리에서 관련8파일만 배포했다. iOS/Android·백엔드·운영 데이터는 변경하지 않았다. 실기기·네이티브·실계정 저장·원어민 검수는 미수행이다. 비공개 증거 `.local/menu-width-20261022/`, `.local/menu-width-deployment-20261023/`.
