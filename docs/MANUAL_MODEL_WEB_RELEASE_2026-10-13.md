# 매뉴얼 모델 웹 배포 · 2026-10-13

웹 UI와 읽기 전용 가상 매장 초안을 배포했다. 실제 로그인 매장의 신규 135개 카탈로그 발행은 공급자 및 별도 검토자의 정상 인증을 기다린다.

- 첫 구현: `2c8127aee1851f3a28ea1a70a16153bfd01ad87f`, [Pages38282802152](https://github.com/ljae/tap2work/actions/runs/38282802152) 성공.
- 작은 화면 후속: `5f6f0a3447d3155cd881582f10b32245afe1ff21`, [Pages38284243014](https://github.com/ljae/tap2work/actions/runs/38284243014) build/deploy 성공. 사용자 지정 gpt-6.1-sol low 실행.
- operations65 및 catalog-admin7 ACTIVE 확인. account 배포·SQL migration·실제 운영 데이터 변경은 수행하지 않았다.
- 최종 CI: Flutter606 통과/브라우저 전용3skip, Node388, analysis0, UI81, JS·135개 카탈로그·7언어×1971원문 번역 검사, Deno Edge 및 격리 SQL5종 통과.
- 첫 배포와 최종 배포 각각 공개267파일이 실제 CI artifact SHA256과 일치했다.7개 번역 사전은 검증한 소스와 동일하다.

공개 익명 Chrome390px에서 샘플 → 매뉴얼 → 마켓 → 가상 매장 본보기26 TAP/108내용과 AI 검토 초안·번역 원어민 미검수 표시를 확인했다. 최종320×740px 네팔어 화면은 첫 폴더가 온전히 보이고 보기 드롭다운 → 매장 설정 본보기 이동이 동작했다. 첫 폴더의 실제 표시 영역은 x24/y490.4/width272/height135였다. 모션이 끝난 뒤 화면을 확인했다.

공개 read-only 샘플은135개 카탈로그와 fictional-soldam26개/108내용을 포함한다. source release는 `c7eaf2f00bf0c2a095fb75788df356f49637c14366f66fa9681ed4474488a1eb`이다. 실제 DB stable은 기존109개, revision2, release `08a4e0571bd73be229fe8ef551544b3ffa1c35e74b12ed572a0c1bfdd4074667`을 유지했다. 정상 공급자 JWT와 별도 reviewer의 정확한 revision/hash 승인이 없어 신규 발행은 미완료다. 이전 관리자 예외를 재사용하거나 승인 이력을 만들지 않았다.

원어민 검수·현장 레시피/안전 인증·새 네이티브 빌드/배포는 수행하지 않았다. 공개 샘플의 legacy Peak 제목에 대한 브라우저 검증은 주장하지 않는다. 현재 TAP 제목 번역 회귀는 widget 검사로 확인했다. 브라우저 자동화에서 초기 렌더링/샘플 언어 초기화에 따른 locator 대기를 수정했으며, 최종 실제 화면 동작은 위와 같이 확인했다.

비공개 증거: `.local/manual-model-deployment/ci-final.log`, `public-final-verification.json`, `public-compact-ne-320.png`, `public-compact-setup-ne-320.png`. 기존 root 미커밋 변경을 보존하고 격리 `.local/manual-model-release`의 선택 소스만 배포했다.
