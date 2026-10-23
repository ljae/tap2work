# 수정 가능한 멀티미디어 매뉴얼 · 2026-10-23

상태: 웹·운영 DB stable 발행 완료(2026-10-24 KST). 아래 로컬/후보 기록을 거쳐 최종 배포 검증까지 마쳤다. 네이티브 빌드는 이번 범위에 없다.

## 결과와 편집 경로

기존 근무 시작·교대 인수인계, 주방 오픈, 입고 확인, 불만·오주문·환불 요청 응대, 주방 마감의5개 매뉴얼/23단계를 유지하고 사진2종·원본 영상1종·장면별 모션5종을 연결했다. 다른142개 항목은 그대로다. 마켓의 ‘사진·영상·모션 예시’ 필터 → 상세 확인 → 선택 가져오기 → 기존 사장님 검토·등록/OFF → 연필 편집 경로를 사용한다. 마켓/읽기/기존 편집기에서 같은 미디어 렌더러를 쓴다.

공개 원본 도구는 `/manual-media/v1/`이다. ZIP에는 실제 원본 EPUB2종/사진2종/CDC 전체 영상과 편집 가능한 모션JSON·렌더러·편집기·매뉴얼 백업JSON·출처/해시가 들어간다. ZIP의 파일별 이용 조건은 SOURCES.json/README를 따른다. 모션 편집기에서 문구·색·장면 순서·시간을 수정하고 JSON/PNG/지원 영상 형식으로 저장하거나, 수정본 링크를 기존 매뉴얼의 영상 링크 필드에 붙여 넣고 저장한다. 매장 사본을 편집하며 공용 원본은 바꾸지 않는다. 서버 저장 전 브라우저 초안이며 자동 업로드/자동 발행은 없다.

## 실제 확인한 출처와 권한

- [요청 사례](https://kmong.com/gig/317668): 공개 설명의 ‘FC외식 매니저 실무가이드–오프닝·클로징·매출·직원관리’ 범위를 참고했다. 유료 PDF202쪽은 구매/복제하지 않았다. 공개 설명은 맞춤 제작에 원본 파일을 언급하며 일반 상품의 편집 원본 제공을 확인할 수 없었다.
- [Basic Kitchen and Food Service Management](https://opentextbc.ca/basickitchenandfoodservicemanagement/), [Food Safety, Sanitation, and Personal Hygiene](https://opentextbc.ca/foodsafety/): BC Cook Articulation Committee / BCcampus2015, 후자는 go2HR 공지 포함. CC BY4.0 except otherwise noted. 실제 EPUB 다운로드를 보존하고 각 책 내부 개별 출처/예외 공지를 유지했다. 공개 DOM에 XML 링크가 있었으나 HTTP403으로 다운로드하지 못했다. EPUB을 XML 원본이라고 표시하지 않는다. 해외 수치/법규를 한국의 의무 기준으로 옮기지 않았다.
- [RestaurantKitchen.jpg](https://commons.wikimedia.org/wiki/File:RestaurantKitchen.jpg): Raysonho / Open Grid Scheduler, CC0 1.0.10,189,109바이트 원본 보존. 표시에는 Wikimedia의 공식 축소본을 사용했다.
- [Washing hands (cropped).jpg](https://commons.wikimedia.org/wiki/File:Washing_hands_(cropped).jpg): Sgt. Grace L. Waladkewics / USMC, US federal employee public domain. 공개된 크롭본 원본2,915,174바이트 보존. 크롭 전 사진 원본이라고 주장하지 않는다.
- [Fight Germs. Wash Your Hands!](https://commons.wikimedia.org/wiki/File:Fight_Germs._Wash_Your_Hands!.webm): CDC2017, US federal government public domain. Wikimedia WebM 요청429 후 해당 페이지의 [공식 CDC MP4](https://www.cdc.gov/wcms/video/low-res/cdctv/2017/34753475Handwashing.mp4)8,721,258바이트 전체 영상을 그대로 보존했다. 영어 원본이고 발췌/합성/재더빙하지 않았다. 표지는79초 프레임이다. [CDC 손 씻기 안내](https://www.cdc.gov/clean-hands/about/index.html)도 확인했다.
- TAP Work의 한국어 모션5종·장면JSON·편집 도구는 CC BY4.0. 기존23단계 문구를 간단한 과정 모션으로 표현하며 전문 촬영/현장 검수·기관 보증을 주장하지 않는다. Pretendard는 동봉된 OFL을 따른다.

Ego Lite로 공개 페이지/이용 조건/실제 다운로드를 확인했다. 원본 출처와 수정 여부를 파일과 앱에 함께 표시한다. 변경/재배포 시 CC BY 저자·라이선스·변경 표시를 유지해야 한다.

## 데이터·재생 경계

기존 imageUrl/videoUrl/sourceUrl와 HTTPS2000자 제한, source ID·release/revision CAS, owner 등록 대기/OFF, 개인화와 실행 snapshot 계약을 유지한다. 편집 영상 링크는 장면JSON을 URL fragment에 담고 신뢰된 app-owned player에서만 iframe으로 연다. 사용자 입력은 검증 후 canvas text로만 그린다. 일반 외부 URL은 새 창 링크다. 웹 MP4/WebM은 명시적 열기 후 controls로 재생하고 비활성/해제 시 정지한다. 실패 시 재시도/새 창을 제공한다. 네이티브는 기존 외부 브라우저 방식이며 별도 플레이어 플러그인을 추가하지 않았다.

원본 큰 파일은 사용자가 내려받을 때만 요청한다. 서비스워커/자동 재생/자동 다운로드를 추가하지 않았다. 사용자 수정 링크에는 입력 문구가 들어간다는 안내를 제공한다. 모션은 한국어, CDC 영상은 영어이며 기존7개 본문 번역은 변경하지 않았다.13개 새 고정 UI문구는8언어를 제공한다.

## 검증

- Flutter656pass/3browser-onlyskip, analysis0; 새4개는 exact origin/출처 교체,320px×글자1.5, 마켓 선택 가져오기 pinned release/revision, 선택 단계 영상 변경 시 사진/앞뒤 단계 보존 검증.
- Node398pass. 새4개는 기존147개/23본문 유지,37파일 SHA/크기+ZIP 무결성, 수정 링크 Unicode round-trip/길이·형식 거절, 정상 API 가져오기→개인화→백업/복원→위험 URL 원자적 거절.
- npm check 통과(UI/settings92, market147/release a5458fd3aa6f, media6sources/37files 포함). 기존7개 번역 검사 통과(현재1951문자열/누적2047).
- Ego Lite390×844/DPR2: 원본 목록, 모션 제목 수정, 재생/정지, JSON다운로드, 수정 링크 복사, 영상 내보내기와 가로 overflow0. 실제 내려받은 수정 영상은1280×720/24.98초 MP4(container)/VP9. 기기에 따라 MP4/WebM이 다르며 PNG·JSON·링크 대안이 있다.
- 생성5개 MP4는960×540/24fps/H.264,20/25/25/20/25초. 원본 EPUB2종 mimetype/ZIP 확인. 원본/모션/ZIPmanifest 실제 바이트 검사.
- 초기 새 테스트의 잘못된 revision 사용과 TextFormField test finder 컴파일 오류를 수정 후 위 결과로 재검증했다. 새 소스의 analyzer 경고5개와 미사용 import2개도 최종0개다.
- 독립 현장/원어민 검수, 실기기 Safari, 네이티브 빌드, 실제 매장 저장은 미수행. 웹/운영DB 배포 결과는 아래 후속 기록으로 갱신한다.

비공개 증거: `.local/media-manual-20261023/`. 기존 root dirty 보존, 선택 파일만 `.local/mobile-space-release`에 격리한다. 개인 운영데이터/인증값을 원본 묶음이나 Git에 포함하지 않는다.


## 브라우저 회귀 보완과 발행 승인

Ego Lite에서 접근성을 켠 실제 Flutter 마켓 상세의 사진 semantics가 전체 본문으로 병합되어 HTML 영상 컨트롤을 가리는 문제를 재현했다. 웹 첫 후보18a9410/Actions39973125347는 운영 배포 전에 취소했다. 사진 읽기와 사진 편집 미리보기, 실행 사진의 semantics를 실제 사진 경계로 한정했다. 인접 본문/영상 영역이 이미지 semantics에 들어가지 않는 회귀 테스트를 추가했다. 최종 관련22개/analysis0 통과, 새 웹 빌드36.7초 성공. 최초 테스트에서 SemanticsHandle을 teardown 뒤 해제하던 테스트 오류는 테스트 종료 전 해제로 수정했다.

사용자가 ‘이번5종은 검토자 절차를 생략하고 발행’을 명시 선택했다. 기존 일반 제공자 API 정책을 변경하지 않고 이번 발행만 actor=null 관리자 경계에서 준비했다. 운영 stable147/revision3/394a7e42를 읽어 확인했으며, 정확한 새 발행본a5458fd3와 expectedRevision3/고정 request UUID로 CAS·재시도·불변 생략 이력을 격리 PGlite에서 통과했다. 실제 DB 발행은 새 웹 공개 파일 확인 후 수행한다.

최종 재생 보완: 네이티브 영상의 키 이벤트가 Flutter에서 선택된 상위 접기 컨트롤로 전달되는 경로도 분리했다. HTML video에는 tabindex와 키 이벤트 경계를 두고, Flutter focus는 native media로 보내 KeyEventResult.skipRemainingHandlers로 브라우저 기본 동작을 유지한다. Ego Lite390 접근성 활성 상태에서 VIDEO focus→Space 재생(실제 currentTime 증가)→Space 일시정지와 본문 유지가 통과했다. 수정 프로젝트 player도 실제 키 입력 재생/정지와 편집 링크의 원본 fragment 보존을 확인했다. analysis0, 최종 로컬 웹34.8초 성공. 후보801fb04/7a6cbc1도 최종1f602cf로 교체되어 배포 전 취소됐다. 최종 CI/공개/DB 결과는 완료 후 아래에 기록한다.


## 최종 웹·운영 마켓 발행 완료 · 2026-10-24 KST

- 웹 코드 `1f602cf2ee02dc1aadcb850b95517f230b1e596d`, [Actions39975653653](https://github.com/ljae/tap2work/actions/runs/39975653653) run/build/deploy 성공. Pages7281845086 success2026-10-23T15:17:52Z. CI Flutter657pass/3browser-onlyskip·analysis0·Node398·UI92/JS·Edge·SQL5종·번역7종·웹 빌드 통과.
- [공개 원본 도구](https://tap2.work/manual-media/v1/), [모션 편집기](https://tap2.work/manual-media/v1/studio.html), [ZIP](https://tap2.work/manual-media/v1/source-pack.zip) 제공. 공개39개 미디어/원본/ZIP 파일 SHA256이 선택 소스와 모두 일치했고, 공개 앱16파일(index/version/manifest/실제 loader/main/샘플4/번역7)이 최종 CIartifact12511098710과 일치했다.
- Ego Lite 실제 공개390×844/DPR2에서 원본5카드·가로 overflow0, 기존 로그인 세션의 운영 마켓 필터·가져옴 상태·사진/출처/영상 미리보기를 확인했다. 공개 opening.mp4의 native keyboard 재생(currentTime0.59초)·일시정지·매뉴얼 유지 통과. 실계정 가져오기/편집/완료는 수행하지 않았다. 공개 스모크의 초기 로그인 선택자 대기는 기존 로그인 세션 때문에, 기존 문서 그룹 대기는 ‘가져옴’ 표시 때문에 실패해 현재 화면을 확인한 뒤 읽기만 진행했다.
- 운영 stable147/revision3/394a7e42 →147/revision4/`a5458fd3aa6ff5ec0f5fa5207db9fb10154c8ddac8f1f2ae3fa8002d1d96db76`. 관리자 DB 경계에서 고정 request `8c614f9c-10f4-4aff-85e7-8e72da18297a`/expectedRevision3으로 발행했다. 실제 발행본 전체를 canonical 검증/선택 원본과 비교해 일치를 확인했다. actor=null·draft=null·이번5종에 한정한 사용자 검토 생략 지시가 불변 사건에 있다. 공급자/검토자 신원이나 승인을 만들지 않았고 일반 정책은 유지했다.
- 기존 등록된 연결 매뉴얼은 기존 사장님 검토의 후보 비교/선택 적용, 개인화한 사본은 기존 보존 정책을 따른다. 신규 가져오기는 검토 대기/OFF. 공개 원본 갱신이 매장 수정본이나 이미 생성된 업무를 덮어쓰는 방식으로 계약을 바꾸지 않았다.
- 원래 dirty tree 보존. 선택76개 소스/원본 파일을 격리 워크트리에 복사하고 후속 검증 문서만 추가 기록했다. 원본 묶음에 `.local`/계정/운영자료/인증값을 포함하지 않았다. 최종 결과는 project-state revision340/D-146/M-038.
