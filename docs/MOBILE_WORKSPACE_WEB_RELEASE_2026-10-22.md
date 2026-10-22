# 휴대폰 작업 공간 웹 배포 — 2026-10-22

사용자의 웹 배포 요청에 따라 D-141 상단 스크롤 접기, 한 열 매뉴얼·폴더 이동·직접 편집, 근무표 UI 개편을 [tap2.work](https://tap2.work/)에 반영했다. 코드 커밋은 `a40eab11cf0943eaa1d897caaff08a4b6fc7cc61`이다.

기존 공개 버전 `034d023`에서 별도 작업 트리 `.local/mobile-space-release`를 만들고 이번 변경 25개 파일만 복사했다. 원래 작업 트리의 미커밋 변경을 보존했다. 웹 배포만 수행했으며 iOS/Android·백엔드·운영 DB·공용 카탈로그는 변경하지 않았다.

## 공개 반영과 검증

- [GitHub Actions 39798383504](https://github.com/ljae/tap2work/actions/runs/39798383504): 전체 run completed/success. Pages 배포 `7255412881`은 2026-10-22 14:53:23 UTC(23:53:23 KST) success. 마지막 조회에서 build job 집계만 in_progress로 늦게 표시됐으나 모든 build step과 deploy job은 success였다.
- 공개 267개 파일의 SHA256이 해당 CI Pages artifact와 전부 일치했다. HTML·버전별 bootstrap/앱 번들·manifest·번역·국기·가상 샘플을 비교했다. Artifact ZIP 자체 SHA256도 GitHub 제공 digest와 일치했다.
- 배포 작업 트리에서 Flutter645개 통과/브라우저 전용3개 제외, 분석 문제 없음, 서버394개 통과, JavaScript/UI 연결92개 검사 통과. CI도 Flutter·분석·서버·Edge·격리 SQL5개·번역·공개 웹 빌드를 모두 통과했다.
- 실제 headless Chrome390×844에서 공개 샘플 진입, 업무 할일/방법 펼침 후 휠 스크롤로 상단 접기, 현재 하단 메뉴로 복귀, 매뉴얼 폴더 선택, 주간/월간 전환과 근무표 설정 메뉴 표시를 확인했다. pageerror0/operations POST0. 캡처를 시각 검토했다. 팝업 옵션 선택 자체는 앞선 위젯 검사 범위이며 이번 브라우저에서는 메뉴 표시까지만 검증했다.

GitHub는 당시 Actions 결과 처리 지연을 [공식 상태 페이지](https://www.githubstatus.com/)에 공지했다. 초기 queued 표시는 실제 진행보다 늦었고, 단계별 결과·artifact·Pages 배포 상태·공개 파일을 함께 확인했다. 자동 브라우저 검사는 처음에 샘플 업무가 짧아 스크롤이 생기지 않아 실패했다. 해당 할일과 방법을 펼쳐 스크롤이 생기는 상태로 수정한 뒤 통과했다. Python artifact 압축 해제의 버전별 filter 인자 차이는 경로·파일 유형을 직접 검증하는 방식으로 수정했다. 제품 코드의 추가 수정은 없었다.

실기기·네이티브 빌드/배포·실계정 저장·원어민 검수는 수행하지 않았다. 비공개 검증 자료는 `.local/mobile-space-deployment-20261022/`에 보존한다.
