const $ = selector => document.querySelector(selector);
const labels = { confirmed: '확정', proposed: '논의 중', deferred: '보류', superseded: '대체됨' };
const types = { decision: '결정 변경', implementation: '개발', test: '검증', research: '조사', note: '메모' };
let project;
let token;
let preview;
let currentEdit;
let timer;
let lastFocus;
const escapeHtml = value => String(value ?? '').replace(/[&<>"']/g, char => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[char]);
const date = value => value?.length === 10 ? value : new Date(value).toLocaleString('ko-KR', { timeZone: 'Asia/Seoul', month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' });
const badge = status => `<span class="status ${escapeHtml(status)}">${labels[status] || escapeHtml(status)}</span>`;
const activeRoute = () => ['overview', 'decisions', 'history', 'preview'].includes(location.hash.slice(1)) ? location.hash.slice(1) : 'overview';
function toast(message) { $('#toast').textContent = message; $('#toast').classList.add('visible'); clearTimeout(timer); timer = setTimeout(() => $('#toast').classList.remove('visible'), 4500); }
async function api(url, options = {}) {
  const response = await fetch(url, { cache: 'no-store', ...options, headers: { 'Content-Type': 'application/json', 'X-Tab2work-Token': token || '', ...options.headers } });
  const result = await response.json();
  if (!response.ok) { const error = new Error(result.error || '요청을 처리하지 못했어요.'); error.status = response.status; throw error; }
  return result;
}
async function load() {
  try {
    const [state, session, app] = await Promise.all([api('/api/project'), api('/api/session'), api('/api/preview')]);
    project = state; token = session.token; preview = app; render();
  } catch (error) { $('#content').innerHTML = `<div class="error">${escapeHtml(error.message)} 서버가 실행 중인지 확인한 뒤 위의 새로 읽기를 눌러 주세요.</div>`; }
}
function heading(kicker, title, description, action = '') { return `<div class="page-heading"><div><span class="eyebrow">${kicker}</span><h1>${title}</h1><p>${description}</p></div>${action}</div>`; }
function milestones() { return project.milestones.map((item, i) => `<div class="milestone ${escapeHtml(item.status)}"><span class="milestone-mark">${item.status === 'done' ? '✓' : i + 1}</span><div><small>${({ done: '완료', in_progress: '진행 중', planned: '다음 단계' })[item.status]}</small><h3>${escapeHtml(item.title)}</h3><p>${escapeHtml(item.description)}</p></div></div>`).join(''); }
function overview() {
  const pending = project.decisions.filter(item => item.status === 'proposed');
  return `${heading('ONE STEP AT A TIME', '다음 결정을 위한 작업 공간', '지금 만드는 것, 합의한 방향, 달라진 이유를 함께 봅니다.', '<a href="#preview" class="button">Flutter 앱 보기 ↗</a>')}
    <div class="stats"><div class="stat"><span>제품 단계</span><strong style="font-size:20px;margin-top:6px">${escapeHtml(project.product.phase)}</strong></div><div class="stat"><span>확정한 결정</span><strong>${project.decisions.filter(item => item.status === 'confirmed').length}<small style="font-size:13px"> 개</small></strong></div><div class="stat highlight"><span>함께 정할 것</span><strong>${pending.length}<small style="font-size:13px"> 개</small></strong></div><div class="stat"><span>쌓인 개발 기록</span><strong>${project.history.length}<small style="font-size:13px"> 개</small></strong></div></div>
    <div class="grid"><div><section class="panel product-card"><span class="eyebrow">우리가 만들고 있는 경험</span><h2>${escapeHtml(project.product.tagline)}</h2><p>${escapeHtml(project.product.outcome)}</p><div class="chips"><span>Flutter</span><span>한국 F&B</span><span>폰 중심</span><span>첫 출근 + 버디</span></div></section><section class="panel"><div class="panel-title"><h2>다음으로 함께 정할 것</h2><a href="#decisions">전체 보기 ↗</a></div>${pending.map(item => `<button class="decision-mini" data-edit="${item.id}"><span><small>${item.id} · ${escapeHtml(item.category)}</small><strong>${escapeHtml(item.title)}</strong></span>${badge(item.status)}</button>`).join('') || '<p>현재 논의 중인 결정이 없어요.</p>'}</section><div class="backlinks"><a href="/reference/product" target="_blank" rel="noopener">제품 설계 ↗</a><a href="/reference/research" target="_blank" rel="noopener">경쟁 서비스 조사 ↗</a><a href="/reference/readme" target="_blank" rel="noopener">개발 실행 가이드 ↗</a></div></div><section class="panel"><div class="panel-title"><h2>개발 흐름</h2><a href="#history">변경 이력 ↗</a></div>${milestones()}</section></div>`;
}
function decisionCards(reset = false) {
  const search = (reset ? '' : $('#search')?.value || '').trim().toLowerCase();
  const status = reset ? 'all' : $('#status-filter')?.value || 'all';
  const items = project.decisions.filter(item => (status === 'all' || item.status === status) && `${item.id} ${item.category} ${item.title} ${item.decision}`.toLowerCase().includes(search));
  return items.map(item => `<button class="decision-card" data-edit="${item.id}"><span class="card-top" style="width:100%"><span class="meta">${item.id} / ${escapeHtml(item.category)}</span>${badge(item.status)}</span><h2>${escapeHtml(item.title)}</h2><p>${escapeHtml(item.decision)}</p><span class="card-bottom"><span>${date(item.updatedAt)}</span><span>내용과 이유 보기 ↗</span></span></button>`).join('') || '<div class="empty">조건에 맞는 결정사항이 없어요.</div>';
}
function decisions() { return `${heading('DECISION REGISTER', '결정사항', '제안과 확정을 구분하고, 방향이 바뀐 이유까지 남깁니다.', '<button class="button" data-action="new-decision">+ 새 결정사항</button>')}<div class="source-note">웹에서 저장하면 기준 JSON 파일에 바로 반영됩니다. 이전 내용과 변경 이유는 개발 이력에 남아요.</div><div class="filterbar"><input id="search" type="search" placeholder="제목, 내용, 결정 번호로 검색" aria-label="결정 검색"><select id="status-filter" aria-label="결정 상태 필터"><option value="all">모든 상태</option>${Object.entries(labels).map(([value, label]) => `<option value="${value}">${label}</option>`).join('')}</select></div><div class="decision-grid" id="decision-cards">${decisionCards(true)}</div>`; }
function historyItems(reset = false) {
  const filter = reset ? 'all' : $('#history-filter')?.value || 'all';
  const items = [...project.history].reverse().filter(item => filter === 'all' || item.type === filter);
  return items.map(item => `<article class="history-item"><div class="history-meta"><span>${date(item.at)}</span><span>${types[item.type] || escapeHtml(item.type)}</span></div><h2>${escapeHtml(item.title)}</h2><p>${escapeHtml(item.detail)}</p>${item.verification ? `<div class="verification">확인 · ${escapeHtml(item.verification)}</div>` : ''}${item.files?.length ? `<div class="files">${item.files.map(file => `<code>${escapeHtml(file)}</code>`).join('')}</div>` : ''}${item.after ? `<details><summary>변경 전·후 보기</summary><div class="diff"><div><strong>이전 ${item.before ? `· ${labels[item.before.status]}` : ''}</strong>${escapeHtml(item.before ? `${item.before.title}\n${item.before.decision}\n\n근거: ${item.before.reason}` : '새로 등록한 결정입니다.')}</div><div><strong>이후 · ${labels[item.after.status]}</strong>${escapeHtml(`${item.after.title}\n${item.after.decision}\n\n근거: ${item.after.reason}`)}</div></div></details>` : ''}</article>`).join('') || '<div class="empty">이 종류의 기록은 아직 없어요.</div>';
}
function history() { return `${heading('DEVELOPMENT JOURNAL', '개발 이력', '무엇을 바꿨고, 어떻게 확인했는지. 최신 기록부터 보여 줍니다.', '<button class="button" data-action="new-note">+ 개발 기록 남기기</button>')}<div class="filterbar"><select id="history-filter" aria-label="이력 종류 필터"><option value="all">전체 기록</option>${Object.entries(types).map(([key, value]) => `<option value="${key}">${value}</option>`).join('')}</select><span class="eyebrow" style="margin:0">시간 기준 · 서울</span></div><div class="timeline" id="history-items">${historyItems(true)}</div>`; }
function appPreview() { return `${heading('FLUTTER PREVIEW', '앱을 보며 결정하기', '같은 Flutter 코드로 만든 웹 빌드를 폰 크기로 확인합니다.', '<button class="button secondary" data-action="reload-preview">미리보기 새로고침 ↻</button>')}<div class="preview-grid"><section class="preview-copy"><span class="eyebrow">CURRENT BUILD · 매장 운영 0.3</span><h2>우리 팀부터 재료까지,<br>한곳에서 함께.</h2><p>오늘 · 할 일 · 재고/발주 · 우리 팀 · 매장 지도. 우측 상단에서 사장님, 매니저, 조리 담당, 크루 역할을 체험해 보세요.</p><ul><li>시간대·직급별 업무와 누가 확인했는지 봅니다.</li><li>재료를 모아 데모 발주하고 입고를 따로 확인합니다.</li><li>발주 후 정해진 며칠 뒤 재고 확인이 할 일에 나타납니다.</li><li>휴가 공석과 대체 근무를 팀에 공유합니다.</li><li>냉장고·창고·조리기구 위치와 예시 동선을 봅니다.</li></ul><a class="button" href="/app/" target="_blank" rel="noopener">Flutter 앱 별도 창으로 열기 ↗</a><div class="source-note" style="margin-top:18px">두 창을 열어 다른 역할로 확인해 보세요. 매장 샘플 상태는 로컬 서버에 저장되고 약 5초마다 갱신됩니다. 첫 출근 가이드는 오늘 화면에서 열 수 있어요.</div><div class="preview-status">${preview.ready ? `웹 빌드 확인 · ${date(preview.builtAt)}<br>새 코드를 반영하려면 <code>npm run build:app</code> 후 새로고침하세요.` : '아직 웹 빌드가 없어요. <code>npm run build:app</code> 실행 후 새로 읽기를 눌러 주세요.'}</div><p style="margin-top:20px;font-size:12px">실제 발주·결제·로그인·급여·알림은 연결되지 않았어요. 역할 전환은 실제 권한 확인이 아닙니다. 지도와 직원 정보는 샘플이며 웹 검증은 실기기 검증을 대신하지 않아요.</p></section><div class="phone-area"><div class="phone">${preview.ready ? '<iframe id="app-frame" src="/app/" title="tab2work Flutter 앱 미리보기"></iframe>' : '<div class="empty">Flutter 웹 빌드를 기다리고 있어요.</div>'}</div><span class="phone-caption">Flutter web · 공유 매장 체험</span></div></div>`; }
function render() {
  if (!project) return;
  const route = activeRoute();
  document.querySelectorAll('[data-route]').forEach(link => { if (link.dataset.route === route) link.setAttribute('aria-current', 'page'); else link.removeAttribute('aria-current'); });
  $('#revision').textContent = `파일 버전 r${project.revision}`;
  $('#pending-count').textContent = project.decisions.filter(item => item.status === 'proposed').length;
  $('#content').innerHTML = ({ overview, decisions, history, preview: appPreview })[route]();
  document.title = `tab2work · ${({ overview: '프로젝트 현황', decisions: '결정사항', history: '개발 이력', preview: '앱 미리보기' })[route]}`;
}
function field(name, title, value = '', textarea = false, max = 6000) { return `<label class="field"><span>${title}</span>${textarea ? `<textarea name="${name}" required maxlength="${max}">${escapeHtml(value)}</textarea>` : `<input name="${name}" value="${escapeHtml(value)}" required maxlength="${max}">`}</label>`; }
function openEditor(kind, id) {
  lastFocus = document.activeElement;
  const item = project.decisions.find(decision => decision.id === id);
  currentEdit = { kind, id, revision: project.revision };
  $('#editor-form').innerHTML = `<div class="editor-heading"><div><span class="eyebrow">${id || 'NEW ENTRY'} · r${project.revision}</span><h2 id="editor-title">${kind === 'note' ? '개발 기록 남기기' : item ? '결정사항 살펴보기' : '새 결정사항'}</h2></div><button type="button" class="close" data-action="close" aria-label="닫기">×</button></div>${kind === 'note' ? `<label class="field"><span>기록 종류</span><select name="type">${Object.entries(types).filter(([key]) => key !== 'decision').map(([key, label]) => `<option value="${key}">${label}</option>`).join('')}</select></label>${field('title', '기록 제목', '', false, 200)}${field('detail', '무엇을 바꿨거나 논의했나요?', '', true)}${field('verification', '검증 또는 확인 사항', '', true, 2000)}` : `${field('title', '결정 제목', item?.title, false, 200)}<div class="field-row">${field('category', '분류', item?.category || '제품', false, 80)}<label class="field"><span>상태</span><select name="status">${Object.entries(labels).map(([key, value]) => `<option value="${key}" ${(item?.status || 'proposed') === key ? 'selected' : ''}>${value}</option>`).join('')}</select></label></div>${field('decision', '결정 내용', item?.decision, true)}${field('reason', '이 방향을 선택하는 근거', item?.reason, true)}${field('changeReason', item ? '이번에 바꾸는 이유' : '이 결정을 등록하는 이유', '', true, 2000)}${item ? `<p class="save-note">최초 출처 · ${escapeHtml(item.source)}</p>` : ''}`}<p class="form-error" id="form-error" role="alert"></p><div class="editor-actions"><button type="button" class="button secondary" data-action="close">취소</button><button type="submit" class="button" id="save-button">파일에 저장</button></div><p class="save-note">저장 시 기준 파일과 개발 이력이 함께 갱신됩니다. 앱 기능은 별도의 구현이 필요해요.</p>`;
  $('#editor').showModal();
}
$('#editor-form').addEventListener('submit', async event => {
  event.preventDefault();
  const button = $('#save-button'); button.disabled = true; $('#form-error').textContent = '';
  const data = Object.fromEntries(new FormData(event.currentTarget)); data.revision = currentEdit.revision;
  const url = currentEdit.kind === 'note' ? '/api/history' : currentEdit.id ? `/api/decisions/${currentEdit.id}` : '/api/decisions';
  try {
    project = await api(url, { method: currentEdit.id ? 'PATCH' : 'POST', body: JSON.stringify(data) });
    $('#editor').close(); render(); toast(`r${project.revision} 저장 완료 · 파일과 개발 이력에 반영했어요.`);
  } catch (error) {
    $('#form-error').textContent = error.message;
    if (error.status === 409) $('#form-error').textContent += '\n작성한 내용은 이 창에 남아 있습니다. 복사해 둔 뒤 창을 닫고 새로 읽기를 눌러 주세요.';
  } finally { button.disabled = false; }
});
$('#editor').addEventListener('close', () => { if (lastFocus?.isConnected) lastFocus.focus(); else $('#content').focus({ preventScroll: true }); });
document.addEventListener('click', event => {
  const target = event.target.closest('button'); if (!target) return;
  if (target.dataset.edit) openEditor('decision', target.dataset.edit);
  if (target.dataset.action === 'new-decision') openEditor('decision');
  if (target.dataset.action === 'new-note') openEditor('note');
  if (target.dataset.action === 'close') $('#editor').close();
  if (target.dataset.action === 'reload-preview') load();
});
document.addEventListener('input', event => { if (event.target.id === 'search') $('#decision-cards').innerHTML = decisionCards(); });
document.addEventListener('change', event => {
  if (event.target.id === 'status-filter') $('#decision-cards').innerHTML = decisionCards();
  if (event.target.id === 'history-filter') $('#history-items').innerHTML = historyItems();
});
$('#refresh').addEventListener('click', load);
window.addEventListener('hashchange', () => { render(); $('#content').focus({ preventScroll: true }); window.scrollTo(0, 0); });
load();
