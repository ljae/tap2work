# TAP Work 사진·영상·모션 매뉴얼 원본

이 묶음은 매장별로 수정할 수 있는 예시입니다. 실제 작업의 완료 기록이나 전문·현장 검토 승인을 포함하지 않습니다.

## 사용

1. 앱의 매뉴얼 → 매뉴얼 마켓 → 사진·영상·모션 예시에서 골라 가져옵니다. 가져온 자료는 기존 사장님 검토·등록 흐름을 따릅니다.
2. 앱 연필 버튼에서 본문·팁·사진·영상 링크를 수정하고 저장합니다. 공용 원본, 다른 매장, 과거 업무는 덮어쓰지 않습니다.
3. 모션은 https://tap2.work/manual-media/v1/studio.html 에서 JSON을 불러오거나 예시를 선택합니다. 장면 제목·설명·순서·길이·색상을 바꿉니다.
4. ‘수정본 링크 복사’로 만든 주소를 매뉴얼의 영상 링크에 붙여 넣습니다. 앱에서 저장한 사본으로 재생되며 별도 영상 업로드가 필요하지 않습니다. 링크에는 작성한 문구가 포함됩니다. 2,000자 링크 한도에 맞지 않는 긴 원본은 JSON으로 보관하거나 설명을 줄이세요.
5. JSON 원본·영상(MP4/WebM, 브라우저 지원에 따름)·PNG를 내려받을 수 있습니다. 영상 저장은 실제 길이만큼 화면을 열어 두어야 합니다. JSON은 모든 지원 브라우저에서 계속 편집할 수 있습니다.
6. `manual-backup.json`은 기존 매뉴얼 백업·복원으로 추가할 수 있는 파일입니다. 기존 자료를 덮어쓰지 않고 새 사본으로 추가합니다. 사진·영상은 HTTPS 링크이며 외부 미디어 사용에 네트워크가 필요합니다.

## 실제 수록 파일

- `originals/*.epub`: 발행처에서 받은 편집 가능한 원본 교재. EPUB은 HTML/XML을 담은 공개 전자책 형식입니다. Sigil 같은 EPUB 편집기 또는 ZIP 도구로 원문 구조를 확인할 수 있습니다.
- `originals/kitchen.jpg`: Raysonho가 공개한 원본 사진. `kitchen.jpg`는 Wikimedia가 제공하는 작은 표시용 사본입니다.
- `originals/handwashing.jpg`: Wikimedia에 공개된 손 씻기 사진의 크롭본 원본. `handwashing.jpg`는 Wikimedia 표시용 사본입니다.
- `handwashing.mp4`: CDC 배포 원본 전체 영상, 내용 편집 없음. `handwashing-poster.jpg`는 해당 원본의 79초 지점 프레임입니다.
- `projects.json`, 5개 장면 JSON, `motion.mjs`: TAP Work 모션의 편집 원본과 공통 렌더러. MP4와 브라우저 미리보기는 같은 렌더러를 사용합니다.
- `manuals.json`: 상세 절차 5개, 총 23단계. 기존 원문의 방법·완료 기준·예외·매장 수정 팁을 보존했습니다.
- `SOURCES.json`: 실제 출처, 저자, 사용 조건, 파일별 SHA256과 크기.

## 출처·사용 조건

TAP Work가 이번에 만든 모션·장면·소스 코드는 CC BY 4.0으로 재사용·수정·재배포할 수 있습니다. TAP Work 출처와 변경 여부를 표시하세요. 원자료의 별도 조건을 없애거나 원 제작자가 수정본을 승인한 것으로 표시하지 마세요.

Basic Kitchen and Food Service Management 및 Food Safety, Sanitation, and Personal Hygiene: BC Cook Articulation Committee / BCcampus, 2015, CC BY 4.0(별도 표시 항목 제외). 위생 교재에는 go2HR 저작권 표시가 있습니다. 원본 EPUB과 내부 표지·사진 등의 별도 크레딧을 그대로 보존했습니다. 교재의 해외 법·온도 수치를 한국 의무 기준으로 주장하지 않습니다.

RestaurantKitchen.jpg: Raysonho @ Open Grid Scheduler / Grid Engine, CC0 1.0.
Washing hands (cropped).jpg: Sgt. Grace L. Waladkewics / USMC, Public domain (US). Wikimedia 공개본은 원 사진의 크롭본입니다.
Fight Germs. Wash Your Hands!: Centers for Disease Control and Prevention, 2017, Public domain (US). 동영상은 CDC 공식 MP4 원본과 동일합니다. 기관의 후원·제품 추천·매장 승인으로 표시하지 않습니다.
Pretendard: SIL Open Font License 1.1, FONT-LICENSE.txt 보존.

CC BY 4.0: https://creativecommons.org/licenses/by/4.0/
CC0 1.0: https://creativecommons.org/publicdomain/zero/1.0/

참고 크몽 페이지는 범위·구성만 확인했으며 유료 PDF의 본문·사진·디자인 파일을 복제하지 않았습니다. Pressbooks 페이지에서 XML 링크는 확인했으나 직접 내려받기는 403이었으므로 수록 원본은 실제 다운로드·검증한 EPUB입니다.
