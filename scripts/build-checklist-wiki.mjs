import { readFile, writeFile } from 'node:fs/promises';
const root = new URL('../docs/wiki/', import.meta.url);
const library = JSON.parse(await readFile(new URL('checklist-library.json', root), 'utf8'));
const tasks = library.industries.flatMap(industry => industry.tasks);
const lines = [
  '# 업종별 업무 노하우 체크리스트 위키', '',
  `검토일: ${library.reviewedAt} · ${library.industries.length - 1}개 업종 + 외식 공통 · ${tasks.length}개 업무 · ${tasks.reduce((sum, task) => sum + task.steps.length, 0)}개 행위 · ${library.sources.length}개 출처/후속 참조`, '',
  '처음 운영하는 사장님과 직원이 업무를 나누고 짧게 방법을 익히기 위한 기본 초안입니다. **폴더 → 업무 카드 → 복수의 행위 → 간단 매뉴얼과 놓치기 쉬운 점**으로 구성합니다. 앱의 `할 일 → 목록 정리 · 업종 가져오기`에서 동일한 자료를 보고 가져올 수 있습니다.', '',
  '## 조사 방법과 근거 범위', '',
  '- 사용자 요청에 따라 aside-browser 스킬을 읽고 `aside guide` 후 공개 자료 조사 세션 `LomGqIsRGaVw04t0`를 실행했습니다. 조사 에이전트가 `402 Insufficient credits`로 종료되어 초기 조사는 공개 웹 검색과 원문 열람으로 진행했습니다. 이후 Aside REPL 직접 브라우저로 S06(배달), S09(제빵), S10(미용), S13(운동시설), S17(한국 안내)의 공식 페이지를 재확인했습니다. S17 첨부 PDF 본문은 읽지 않았습니다.',
  '- 기관·업계협회·제조사의 직접 자료를 우선 확인했습니다. 원문 체크리스트를 복제하지 않고 공통 원칙을 짧게 요약한 뒤, 한국 소규모 매장에 맞춘 업무 분류·수량 대조·인계 흐름을 새로 작성했습니다. 각 업무의 참고 출처가 그 업종의 모든 세부 행위를 검증했다는 뜻은 아닙니다.',
  '- 모든 업종 목록은 **출처 기반 편집 제안(proposed)** 입니다. 실제 사장님·전문가의 검수, 고객 인터뷰, CEO 피드백은 아직 없습니다. 미용·피부·반려동물 등 전문 시술 절차 대신 접수·준비·위생·인계 업무를 다룹니다.',
  '- 해외 기준을 한국 법정 기준으로 옮기지 않았습니다. 온도·시간·약품 농도·장비 설정·보관기한은 현장 책임자가 적용 가능한 기준과 해당 제품·모델 설명서를 확인해 매뉴얼에 넣어야 합니다. 작업 확인은 개인 교육 이수나 버디 확인과 별개입니다.',
  '- S17은 한국 개정 안내 페이지와 첨부 존재만 확인했습니다. S18은 개요만 확인했고 상세 PDF는 403으로 읽지 못했습니다. 둘은 상세 작업 기준으로 사용하지 않았습니다.', '',
  '## 목차', '',
  ...library.industries.map(industry => `- [${industry.name}](#${industry.id}) · ${industry.tasks.length}개 업무`), '',
  '## 매장에 적용하는 방법', '',
  '1. 해당 업종에서 필요한 업무만 골라 가져오고 실제 업무 장소·담당 직급·시간대를 고릅니다. 삭제한 기본 업무만 다시 가져올 수 있으며 기존 수정 내용과 폴더는 유지합니다.',
  '2. 각 행위의 매뉴얼을 매장의 실제 도구와 완료 기준에 맞춥니다. 모르는 작업은 버디에게 먼저 확인하도록 적습니다.',
  '3. 필요 없는 업무·행위를 삭제하고 카드 드래그 또는 이동 메뉴로 순서와 폴더를 정리합니다. 초안 저장 전에는 공유 목록에 반영되지 않습니다.',
  '4. 직원은 행위별로 방법을 읽고 실제 수행 후 확인합니다. 모든 행위를 마치면 업무가 완료됩니다.',
  '5. 시작하지 않은 오늘 업무는 수정본으로 교체됩니다. 시작·완료한 업무는 당시 매뉴얼과 확인 기록을 보존하며 다음 날부터 새 내용이 적용됩니다. 삭제한 미시작 업무는 오늘 목록에서 제외하고 기록은 남깁니다.', '',
  '## 업종별 기본 초안', '',
];
for (const industry of library.industries) {
  lines.push(`<a id="${industry.id}"></a>`, '', `### ${industry.name}`, '', `근거 수준: ${industry.basis}`, '');
  for (const task of industry.tasks) {
    lines.push(`#### ${task.title} · ${task.slot}`, '', `참고: ${task.sourceIds.map(id => { const source = library.sources.find(s => s.id === id); return `[${id} ${source.title}](${source.url})`; }).join(' / ')}. 업무 분해와 운영 팁은 편집 제안입니다.`, '', '| 확인 | 행위 | 간단 매뉴얼 · 방법과 완료 기준 | 놓치기 쉬운 노하우 |', '| --- | --- | --- | --- |');
    for (const step of task.steps) lines.push(`| ☐ | ${step.title} | ${step.manual} | ${step.tip} |`);
    lines.push('');
  }
}
lines.push('## 출처 장부', '', '| ID | 자료 | 지역 | 확인한 범위·제한 |', '| --- | --- | --- | --- |');
for (const source of library.sources) lines.push(`| ${source.id} | [${source.title}](${source.url}) | ${source.region} | ${source.verified} 확인일 ${source.checkedAt}. 경로: ${source.verificationMethod ?? '공개 웹 원문'}. |`);
lines.push('', '## 자료를 계속 모으는 규칙', '',
  '- 편집 원본은 [checklist-library.json](checklist-library.json)입니다. 위키와 앱 기본 목록은 이 파일을 함께 사용합니다. 수정 후 `npm run build:wiki`로 이 Markdown을 다시 만듭니다.',
  '- 새 업종마다 준비·서비스·마감에서 최소 두 업무를 정하고, 업무마다 관찰 가능한 행위 세 개 이상을 작성합니다. 법정·전문 기준은 별도 검증 없이 추가하지 않습니다.',
  '- 출처 장부에 실제 열람 URL·제목·지역·검토일·확인 범위를 남깁니다. 검색 요약만 확인하거나 접근이 막힌 자료는 미확인으로 구분합니다.',
  '- Aside REPL 직접 브라우저로 공식기관·제조사·협회의 공개 원문을 읽기 전용으로 조사하고, 각 업종의 직접 자료를 우선 보완합니다. 외식 공통 원칙을 응용한 업종과 직접 업종 매뉴얼을 구분해 기록합니다.',
  '- 후속 후보: 아이스크림·디저트, 정육·수산 소매, 세차·차량관리, 수선·리페어, 학원, 공방, 셀프사진관. 이름만 늘리지 않고 직접 자료와 구체적 행위가 준비되면 추가합니다.',
  '- 지역·제품 지침 개정 또는 현장 검토가 생기면 출처와 템플릿 버전을 올립니다. 매장이 이미 가져와 수정한 목록은 라이브러리 갱신으로 덮어쓰지 않습니다.', '');
const output = lines.join('\n');
if (process.argv.includes('--check')) {
  const current = await readFile(new URL('CHECKLISTS.md', root), 'utf8');
  if (current !== output) throw new Error('체크리스트 위키를 npm run build:wiki로 갱신해 주세요.');
} else {
  await writeFile(new URL('CHECKLISTS.md', root), output);
}
console.log(`Checklist wiki: ${library.industries.length} collections, ${tasks.length} tasks.`);
