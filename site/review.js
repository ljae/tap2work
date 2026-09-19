const labels = { confirmed: '확정', proposed: '논의 중', deferred: '보류', superseded: '대체됨' };
const milestoneLabels = { done: '구현 완료', in_progress: '진행 중', planned: '예정' };
const escape = value => String(value ?? '').replace(/[&<>"']/g, char => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[char]);
const date = value => new Date(value).toLocaleDateString('ko-KR', { timeZone: 'Asia/Seoul' });
let project;
function renderDecisions() {
  const filter = document.querySelector('#decision-filter').value;
  const items = project.decisions.filter(item => filter === 'all' || (filter === 'pending' ? ['proposed', 'deferred'].includes(item.status) : item.status === filter));
  document.querySelector('#decision-list').innerHTML = items.map(item => {
    const url = new URL('https://github.com/ljae/tab2work/issues/new');
    url.searchParams.set('template', 'direction-feedback.yml');
    url.searchParams.set('title', `[방향 검토] ${item.id} · ${item.title}`);
    return `<article class="decision"><div class="meta"><span>${escape(item.id)} / ${escape(item.category)}</span><span>${escape(labels[item.status] || item.status)}</span></div><h3>${escape(item.title)}</h3><p>${escape(item.decision)}</p><details><summary>배경과 근거</summary><p>${escape(item.reason)}</p><p>출처 · ${escape(item.source)}</p></details><a href="${escape(url.href)}">이 결정에 의견 남기기 ↗</a></article>`;
  }).join('') || '<p>해당 상태의 결정이 없습니다.</p>';
}
async function load() {
  try {
    const response = await fetch('project-state.json', { cache: 'no-cache' });
    if (!response.ok) throw new Error('기록 응답 오류');
    project = await response.json();
    document.querySelector('#build-status').textContent = `기록 r${project.revision} · ${project.decisions.filter(item => item.status === 'confirmed').length}개 결정 확정`;
    document.querySelector('#version').textContent = `PROJECT RECORD / r${project.revision}`;
    document.querySelector('#milestones').innerHTML = project.milestones.map(item => `<article class="milestone ${escape(item.status)}"><small>${escape(item.id)} · ${escape(milestoneLabels[item.status] || item.status)}</small><h3>${escape(item.title)}</h3><p>${escape(item.description)}</p></article>`).join('');
    renderDecisions();
    document.querySelector('#history').innerHTML = [...project.history].reverse().slice(0, 5).map(item => `<article><time datetime="${escape(item.at)}">${escape(date(item.at))}</time><div><h3>${escape(item.title)}</h3><p>${escape(item.detail)}</p>${item.verification ? `<details><summary>실제 검증 결과</summary><p>${escape(item.verification)}</p></details>` : ''}</div></article>`).join('');
  } catch {
    document.querySelector('#build-status').textContent = '개발 기록을 불러오지 못했습니다.';
    for (const id of ['milestones', 'decision-list', 'history']) document.getElementById(id).innerHTML = '<p>기록을 불러오지 못했습니다. 새로고침하거나 <a href="https://github.com/ljae/tab2work/blob/main/docs/project-state.json">GitHub 기록</a>을 확인해 주세요.</p>';
  }
}
document.querySelector('#decision-filter').addEventListener('change', () => { if (project) renderDecisions(); });
load();
