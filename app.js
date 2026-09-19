const $ = selector => document.querySelector(selector);
const storageKey = 'tab2work-demo-v1';
const steps = [
  { id: 'welcome', title: '버디와 주방 둘러보기', subtitle: '사람과 공간부터 익혀요', minutes: 5, tag: '만나기', watch: '오늘 함께할 버디 민지님과 인사해요. 작업 구역, 개인 물품 보관 장소, 비상구를 함께 찾아봐요.', practice: '내가 일할 위치와 이동 동선을 버디에게 설명해 봐요. 모르는 공간이나 장비는 사용하기 전에 물어봐요.', confirm: '오늘의 담당 업무, 버디, 도움을 요청할 방법을 알고 있어요.' },
  { id: 'hygiene', title: '위생과 안전 약속', subtitle: '시작하기 전에, 함께 확인해요', minutes: 10, tag: '살펴보기', watch: '버디에게 매장의 손 씻기, 복장, 식재료 구분, 알레르기 정보 확인 방법을 보여 달라고 해요.', practice: '버디와 준비 상태를 확인하고 매장에서 정한 위생 절차를 따라 해요. 알레르기나 식재료가 불확실하면 작업을 멈추고 물어봐요.', confirm: '매장의 위생 절차를 버디와 확인했고, 불확실할 때 누구에게 물어볼지 알아요.' },
  { id: 'dish', title: '설거지 한 사이클', subtitle: '시범을 보고, 옆에서 따라 해요', minutes: 15, tag: '같이 해보기', watch: '버디가 사용한 식기 수거부터 세척·건조·보관까지 매장의 순서를 보여 줘요. 깨진 식기, 뜨거운 기구, 세제 취급 방법도 확인해요.', practice: '버디가 지켜보는 동안 정해진 식기 한 묶음을 처리해요. 세제나 장비 설정은 임의로 바꾸지 않고 버디의 안내를 받아요.', confirm: '버디와 한 사이클을 연습했고, 도움이 필요한 상황을 구분할 수 있어요.' },
  { id: 'prep', title: '첫 재료 준비', subtitle: '오늘 맡을 간단한 작업 하나', minutes: 15, tag: '같이 해보기', watch: '버디가 오늘 맡길 간단한 재료 준비 한 가지를 보여 줘요. 도구, 분량, 보관 위치와 매장의 표시 방법을 확인해요.', practice: '버디와 같은 작업을 소량으로 해 봐요. 칼이나 장비는 설명과 감독을 받은 범위에서만 사용하고, 결과를 함께 확인해요.', confirm: '오늘 허용된 작업 범위를 알고, 버디와 첫 결과물을 확인했어요.' },
  { id: 'help', title: '바쁠 때 소통하기', subtitle: '모르면 멈추고, 짧게 물어봐요', minutes: 10, tag: '말해보기', watch: '버디와 작업 완료, 도움이 필요할 때, 위험을 발견했을 때의 매장 내 전달 방식을 확인해요.', practice: '“이 작업 끝났어요”, “다음 단계 같이 봐 주세요”를 말해 봐요. 급한 위험은 앱 답장을 기다리지 말고 현장에서 바로 알려요.', confirm: '현장에서 버디에게 도움을 요청하는 방법을 연습했어요.' },
  { id: 'checkin', title: '첫 근무 준비 확인', subtitle: '다음 작업도 버디와 함께', minutes: 5, tag: '돌아보기', watch: '버디와 오늘 연습한 일, 아직 어려운 일, 다음에 같이 할 일을 짧게 이야기해요.', practice: '다음 근무 시간과 담당 버디를 확인해요. 혼자 해도 되는 일과 계속 함께해야 하는 일을 버디가 정해 줘요.', confirm: '버디에게 궁금한 점을 물어봤고, 다음 업무도 버디와 함께 시작할 준비가 됐어요.' }
];
let state = { role: 'starter', practiced: [], approved: [], helpRequested: false, shiftConfirmed: false };
let storageAvailable = true;
try {
  const saved = JSON.parse(localStorage.getItem(storageKey) || 'null');
  if (saved && typeof saved === 'object') {
    state.role = saved.role === 'buddy' ? 'buddy' : 'starter';
    state.practiced = steps.filter(step => Array.isArray(saved.practiced) && saved.practiced.includes(step.id)).map(step => step.id);
    state.approved = state.practiced.filter(id => Array.isArray(saved.approved) && saved.approved.includes(id));
    state.helpRequested = saved.helpRequested === true;
    state.shiftConfirmed = saved.shiftConfirmed === true;
  }
} catch { storageAvailable = false; }
function save() {
  try { localStorage.setItem(storageKey, JSON.stringify(state)); }
  catch { storageAvailable = false; toast('저장 공간을 사용할 수 없어 새로고침하면 진행 상태가 사라져요.'); }
}
const paths = {
  home: '<path d="m3 10 9-7 9 7v10a1 1 0 0 1-1 1h-5v-7H9v7H4a1 1 0 0 1-1-1Z"/>',
  book: '<path d="M12 5v16M12 5C9 3 5 3 2 4v15c3-1 7-1 10 2 3-3 7-3 10-2V4c-3-1-7-1-10 1Z"/>',
  calendar: '<rect x="3" y="5" width="18" height="16" rx="3"/><path d="M7 3v4m10-4v4M3 11h18m-13 5h2m4 0h2"/>',
  team: '<circle cx="9" cy="8" r="3"/><path d="M3 21v-3a6 6 0 0 1 12 0v3M16 5a3 3 0 0 1 0 6m2 4a5 5 0 0 1 3 5"/>',
  arrow: '<path d="M5 12h14m-5-5 5 5-5 5"/>',
  chevron: '<path d="m9 5 7 7-7 7"/>',
  check: '<path d="m5 12 4 4L19 6"/>',
  clock: '<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>',
  pin: '<path d="M19 10c0 5-7 11-7 11S5 15 5 10a7 7 0 0 1 14 0Z"/><circle cx="12" cy="10" r="2"/>',
  chat: '<path d="M21 11a8 8 0 0 1-8 8H8l-5 3v-7a8 8 0 0 1-1-4 9 9 0 0 1 19 0Z"/><path d="M7 10h10m-10 4h6"/>',
  close: '<path d="m6 6 12 12M6 18 18 6"/>'
};
const icon = name => `<svg viewBox="0 0 24 24" aria-hidden="true">${paths[name] || paths.arrow}</svg>`;
const tabs = [['today', '오늘', 'home'], ['learn', '일하는 법', 'book'], ['shifts', '근무표', 'calendar'], ['team', '도움', 'chat']];
let toastTimer;
let installPrompt;
let lastDialogTrigger;
function toast(message) { $('#toast').textContent = message; $('#toast').classList.add('visible'); clearTimeout(toastTimer); toastTimer = setTimeout(() => $('#toast').classList.remove('visible'), 4500); }
function page() { return tabs.some(tab => tab[0] === location.hash.slice(1)) ? location.hash.slice(1) : 'today'; }
function openDialog(content) {
  const dialog = $('#detail-dialog');
  if (!dialog.open) lastDialogTrigger = document.activeElement;
  $('#dialog-content').innerHTML = `<div class="dialog-body"><div class="dialog-top"><span class="eyebrow">TAB2WORK · 한 걸음씩</span><button class="close-button" data-action="close" aria-label="닫기">${icon('close')}</button></div>${content}</div>`;
  if (!dialog.open) dialog.showModal();
}
function closeDialog() { $('#detail-dialog').close(); }
$('#detail-dialog').addEventListener('close', () => {
  if (lastDialogTrigger?.isConnected) lastDialogTrigger.focus();
  else $('#main').focus({ preventScroll: true });
});
function heading(kicker, title, description) { return `<div class="heading"><div><span class="eyebrow">${kicker}</span><h1>${title}</h1><p>${description}</p></div><span class="date-tag">${icon('calendar')} 첫 출근 · 예시 일정</span></div>`; }
function nextStep() { return steps.find(step => !state.practiced.includes(step.id)); }
function status(step) { return state.approved.includes(step.id) ? '버디 확인 완료' : state.practiced.includes(step.id) ? '연습 완료 · 버디 확인 대기' : step.subtitle; }
function stepRows(list = steps) { return `<div class="task-list">${list.map(step => `<button class="task-row" data-step="${step.id}"><span class="step-number ${state.approved.includes(step.id) ? 'done' : ''}">${state.approved.includes(step.id) ? icon('check') : String(steps.indexOf(step) + 1).padStart(2, '0')}</span><span class="task-copy"><strong>${step.title}</strong><small>${status(step)}</small></span><span class="task-duration">${step.minutes}분</span>${icon('chevron')}</button>`).join('')}</div>`; }
function shiftCard() { return `<section class="card shift-card"><div class="shift-heading"><span class="eyebrow">첫 근무</span><span class="pill">버디와 함께</span></div><p class="shift-date">예시 · 첫 출근일</p><div class="shift-time">10:00 — 14:00</div><p class="shift-detail">${icon('pin')}작은주방 · 연남 / 주방</p><p class="shift-detail">${icon('clock')}10:00–11:00 첫 한 시간 배우기</p><div class="dashed"></div><div class="buddy-line"><span class="avatar buddy">민</span><div><strong>오늘의 버디, 민지</strong><p>처음부터 같이 해 볼게요.</p></div><button class="text-button" data-action="help">도움 ${icon('arrow')}</button></div></section>`; }
function today() {
  if (state.role === 'buddy') return buddyDashboard();
  const next = nextStep();
  const allApproved = state.approved.length === steps.length;
  return `${heading('첫 출근, 반가워요', '지우님, 함께 시작해요.', '오늘은 주방 보조 · 한 번에 하나씩 익히면 돼요.')}<div class="arrival-brief"><div>${icon('clock')}<span><strong>10:00 출근</strong><small>14:00까지 · 예시 일정</small></span></div><div>${icon('pin')}<span><strong>작은주방 · 연남</strong><small>민지님과 함께해요</small></span></div></div>
  <div class="dashboard-grid"><div>
    <section class="hero"><div class="hero-top"><span class="pill">${icon('clock')} 지금 할 일 · ${next ? `약 ${next.minutes}분` : '함께 확인'}</span><span class="eyebrow">천천히 해도 괜찮아요</span></div><div class="sprout" aria-hidden="true"><span class="sprout-stem"></span></div><h2>${allApproved ? '첫걸음 완료.<br>다음도 함께해요.' : next ? next.title : '잘 연습했어요.<br>민지님과 확인해요.'}</h2><p>${allApproved ? '정해진 업무부터 버디와 함께 시작해요. 어려우면 언제든 물어봐요.' : next ? `${next.subtitle}.<br>민지님이 옆에서 도와줄 거예요.` : '민지님이 연습한 내용을 함께 살펴볼 거예요. 다시 해 보고 싶은 것도 알려 주세요.'}</p><button class="primary" ${next ? `data-step="${next.id}"` : 'data-action="help"'}>${next ? '어떻게 하는지 보기' : allApproved ? '함께할 다음 일 물어보기' : '같이 봐 달라고 하기'} ${icon('arrow')}</button><div class="hero-bottom"><div class="progress-track" role="progressbar" aria-label="함께 익힌 단계" aria-valuenow="${state.approved.length}" aria-valuemin="0" aria-valuemax="6"><span class="progress-fill" style="width:${state.approved.length / 6 * 100}%"></span></div><span>${state.approved.length}개 함께 익혔어요</span></div></section>
    <div class="section-title"><h2>오늘 배울 것</h2><a class="text-button" href="#learn">전체 6단계 ${icon('arrow')}</a></div>${stepRows(steps.slice(0, 3))}
    <div class="help-card"><span class="help-icon">${icon('chat')}</span><div><strong>모르면, 잠깐 멈춰도 괜찮아요.</strong><p>현장에서 버디에게 먼저 물어봐요.</p></div><button class="text-button" data-action="help">도움 ${icon('arrow')}</button></div>
  </div><div>${shiftCard()}<section class="card note-card"><span class="eyebrow">버디가 남긴 한마디 · 예시</span><blockquote>“빨리 하는 것보다<br>같이 익히는 게 먼저예요.”</blockquote><p>막히는 순간에는 바로 불러 주세요.<br>첫날부터 잘할 필요는 없어요.</p><div class="dashed"></div><p>민지 · 주방 버디</p></section></div></div>`;
}
function learn() { return `${heading('보고 → 같이 해 보고 → 확인받기', '첫 한 시간 배우기', '6개의 짧은 단계로 오늘의 일을 익혀요. 속도는 버디와 맞춰요.')}<div class="learning-header"><span>연습 ${state.practiced.length}/6 · 버디 확인 ${state.approved.length}/6</span><div class="progress-track"><span class="progress-fill" style="width:${state.approved.length / 6 * 100}%"></span></div><span>약 60분</span></div>${stepRows()}<p class="learning-note">시간은 안내용이에요. 이해가 안 되면 더 연습해도 괜찮아요. 이 과정은 매장의 필수 교육이나 자격 확인을 대신하지 않으며, 완료 후에도 정해진 업무를 버디와 함께해요.</p>`; }
function shifts() { return `${heading('일하는 날을 한눈에', '내 근무표', '확정된 시간과 함께할 버디를 확인해요.')}<div class="notice">아래는 체험용 일정이에요. 실제 근무 배정이나 출퇴근 기록은 저장되지 않아요.</div><div class="two-columns"><div>${shiftCard()}<button class="primary dark full" data-action="confirm-shift" style="margin-top:16px" ${state.shiftConfirmed ? 'disabled' : ''}>${state.shiftConfirmed ? '근무 시간 확인했어요' : '근무 시간 확인하기'}</button></div><section class="card schedule-card"><span class="pill">다음 근무 · 예시</span><h2>첫 출근 다음 날</h2><div class="shift-time">11:00 — 15:00</div><p>주방 보조 · 버디 민지와 함께</p><div class="dashed"></div><p>시작 전 5분, 어제 어려웠던 작업을 다시 확인해요.</p><button class="secondary" data-action="schedule-help">근무 시간 상담하기 ${icon('chat')}</button></section></div>`; }
function team() { return `${heading('작은주방 · 연남', '함께 일하는 사람들', '혼자 고민하지 말고, 가까운 버디에게 물어봐요.')}<div class="two-columns"><div class="stack"><section class="card team-person"><span class="avatar buddy">민</span><div><h3>민지</h3><p>오늘의 버디 · 주방 담당</p></div><span class="pill">함께 근무</span></section><section class="card team-person"><span class="avatar">현</span><div><h3>현우</h3><p>매니저 · 일정 상담</p></div></section><section class="card"><span class="eyebrow">팀 공지 · 예시</span><h3 style="margin:14px 0 8px">처음 온 동료에게 먼저 인사해요.</h3><p style="font-size:13px">새 동료의 첫날에는 버디가 동선을 안내하고, 첫 작업은 옆에서 함께해요.</p></section></div><section class="card team-note"><span class="eyebrow">작은 질문도 괜찮아요</span><h2 style="margin-top:22px">“여기, 같이 봐 주세요.”</h2><p>도움이 필요하면 현장에서 바로 불러 주세요. 급한 상황에는 앱 답장을 기다리지 않아요.</p><button class="primary" data-action="help">${icon('chat')} 도움 요청 체험</button>${state.helpRequested ? '<p class="request-status">데모 요청이 있어요. 버디 모드에서 확인할 수 있어요.</p>' : ''}<p class="tiny" style="margin-top:20px">체험 버전에서는 실제 알림이나 메시지가 전송되지 않아요.</p></section></div>`; }
function buddyDashboard() {
  return `${heading('버디 체험 모드', '첫날을 함께 만들어 줘요.', '지우님의 연습을 살펴보고, 함께 확인한 단계만 완료해요.')}<div class="notice">역할 전환은 데모 전용이에요. 실제 서비스에는 로그인, 매장별 권한, 확인 기록이 필요해요.</div><div class="two-columns"><section class="card"><span class="eyebrow">오늘의 신입 · 예시</span><div class="buddy-line" style="margin-top:20px"><span class="avatar buddy">지</span><div><h2>지우</h2><p>주방 보조 · 준비 및 설거지</p></div></div><div class="manager-stat">${state.approved.length}<span style="font-size:20px;color:var(--muted)"> / 6</span></div><p>버디가 확인한 단계</p><p class="manager-note">${state.approved.length === 6 ? '첫 한 시간 확인 완료. 맡길 작업 범위를 정하고 함께 근무를 시작해 주세요.' : '신입이 연습을 마친 단계부터 확인할 수 있어요.'}</p></section><section class="card ${state.helpRequested ? 'pending' : ''}"><span class="eyebrow">도움 요청 · 이 기기에서만</span><h2 style="margin:20px 0 12px">${state.helpRequested ? '지우님이 함께 봐 달래요.' : '대기 중인 요청이 없어요.'}</h2><p>${state.helpRequested ? '현장에서 상황을 확인한 뒤 아래 버튼을 눌러 주세요.' : '신입 모드에서 도움 요청을 체험할 수 있어요.'}</p>${state.helpRequested ? '<button class="primary dark" data-action="resolve-help" style="margin-top:20px">함께 확인했어요</button>' : ''}</section></div><div class="section-title"><h2>단계별 버디 확인</h2><span class="tiny">연습 ${state.practiced.length}/6</span></div><section class="card">${steps.map(step => `<div class="signoff-row"><div><strong>${step.title}</strong><small>${status(step)}</small></div><button class="secondary" data-approve="${step.id}" ${!state.practiced.includes(step.id) || state.approved.includes(step.id) ? 'disabled' : ''}>${state.approved.includes(step.id) ? '확인 완료' : '함께 확인'}</button></div>`).join('')}</section>`;
}
function render(focusMain = false) {
  const current = page();
  const nav = tabs.map(([id, label, glyph], index) => `<a class="nav-link" href="#${id}" ${current === id ? 'aria-current="page"' : ''}>${icon(glyph)}<span>${label}</span><span class="nav-number">0${index + 1}</span></a>`).join('');
  $('#desktop-nav').innerHTML = nav; $('#mobile-nav').innerHTML = nav;
  $('#role-label').textContent = state.role === 'buddy' ? '버디 모드' : '신입 모드';
  $('.profile-button .avatar').textContent = state.role === 'buddy' ? '민' : '지';
  $('#main').innerHTML = `<div class="page-enter">${({ today, learn, shifts, team })[current]()}</div>`;
  document.title = `tab2work — ${tabs.find(tab => tab[0] === current)[1]}`;
  if (focusMain) { $('#main').focus({ preventScroll: true }); window.scrollTo({ top: 0, behavior: 'instant' }); }
}
function showStep(id) {
  const step = steps.find(item => item.id === id);
  if (!step) return;
  const practiced = state.practiced.includes(id);
    openDialog(`<span class="pill">${steps.indexOf(step) + 1} / 6 · ${step.tag} · 약 ${step.minutes}분</span><h2 id="dialog-title" style="margin-top:18px">${step.title}</h2><div class="instruction"><span>01 보기</span><p>${step.watch}</p></div><div class="instruction"><span>02 함께</span><p>${step.practice}</p></div><div class="instruction"><span>03 확인</span><p>${step.confirm}</p></div>${practiced ? `<div class="notice" style="margin-top:16px">${status(step)}. ${state.approved.includes(id) ? '다음 작업도 정해진 범위에서 버디와 함께해요.' : '민지님이 옆에서 함께 확인해 줄 거예요.'}</div>` : state.role === 'buddy' ? '<div class="notice">버디는 시범을 보여 주고 함께 연습해 주세요. 연습 기록은 신입 모드에서 남길 수 있어요.</div>' : `<label class="check-label"><input type="checkbox" id="practice-check"><span>버디와 함께 직접 해봤어요.</span></label>`}<div class="dialog-actions">${!practiced && state.role === 'starter' ? `<button class="primary dark full" data-practice="${id}" disabled>같이 해봤어요 ${icon('arrow')}</button>` : '<button class="primary dark full" data-action="close">확인했어요</button>'}<button class="secondary" data-action="help">도움이 필요해요</button></div>`);
}
function showHelp(schedule = false) {
  openDialog(`<h2 id="dialog-title">${schedule ? '근무 시간을 상의해요.' : '버디와 같이 봐요.'}</h2><p>${schedule ? '실제 서비스에서는 매니저에게 변경이 필요한 시간과 사유를 전달하는 흐름을 만들 예정이에요.' : '주변에 있는 민지님을 먼저 불러 주세요. 급한 위험은 앱을 기다리지 말고 현장에서 바로 알려요.'}</p><div class="notice">이 체험에서는 실제 메시지를 보내지 않아요. 도움 요청은 이 기기에만 저장되며, 버디 모드에서 확인할 수 있어요.</div><div class="dialog-actions"><button class="primary dark full" data-action="request-help">${state.helpRequested ? '기존 데모 요청 확인하기' : '데모 도움 요청 남기기'}</button><button class="secondary" data-action="close">닫기</button></div>`);
}
function rolePicker() { openDialog('<h2 id="dialog-title">어떤 입장에서 볼까요?</h2><p>같은 기기에서 신입과 버디의 흐름을 체험해요. 실제 로그인 기능은 아직 없어요.</p><button class="choice" data-role="starter"><span><strong>신입 직원 · 지우</strong><small>단계별 연습, 근무표, 도움 요청</small></span>' + icon('arrow') + '</button><button class="choice" data-role="buddy"><span><strong>버디 · 민지</strong><small>연습 확인, 첫 근무 지원</small></span>' + icon('arrow') + '</button>'); }
function showAbout() { openDialog('<h2 id="dialog-title">첫 한 시간의 시작점</h2><p>한국의 작은 F&B 주방을 위한 첫 번째 프로토타입이에요. 준비·설거지 업무를 버디와 함께 시작하는 흐름을 담았어요.</p><div class="notice">가상 매장과 예시 인물이에요. 진행 상태는 현재 브라우저에만 저장돼요. 실제 직원 계정, 교육 영상, 알림, 근무 배정, 급여, 법정 서류 기능은 아직 없어요.</div><p>매장의 실제 작업 방식에 맞춘 교육 자료와 버디의 현장 확인이 필요해요.</p><button class="secondary" data-action="reset-prompt">체험 데이터 초기화</button>'); }
document.addEventListener('click', event => {
  const target = event.target.closest('button');
  if (!target || target.disabled) return;
  if (target.dataset.step) return showStep(target.dataset.step);
  if (target.dataset.practice) {
    if (!$('#practice-check')?.checked || state.role !== 'starter') return;
    const id = target.dataset.practice;
    if (!state.practiced.includes(id)) state.practiced.push(id);
    save(); render(); closeDialog(); toast('연습을 기록했어요. 버디의 확인을 기다려요.'); return;
  }
  if (target.dataset.approve && state.role === 'buddy') {
    const step = steps.find(item => item.id === target.dataset.approve);
    if (!step || !state.practiced.includes(step.id)) return;
    openDialog(`<h2 id="dialog-title">${step.title}</h2><p>신입과 실제 작업을 함께 확인했나요?</p><div class="notice">확인할 내용: ${step.confirm}</div><label class="check-label"><input type="checkbox" id="approval-check"><span>현장에서 함께 확인했고, 추가 지원이 필요한 부분을 설명했어요.</span></label><button class="primary dark full" data-signoff="${step.id}" disabled>버디 확인 완료</button>`); return;
  }
  if (target.dataset.signoff && state.role === 'buddy') {
    const id = target.dataset.signoff;
    if (!$('#approval-check')?.checked || !state.practiced.includes(id)) return;
    if (!state.approved.includes(id)) state.approved.push(id);
    save(); render(); closeDialog(); toast('버디 확인을 기록했어요.'); return;
  }
  if (target.dataset.role) { state.role = target.dataset.role === 'buddy' ? 'buddy' : 'starter'; save(); location.hash = 'today'; render(true); closeDialog(); return; }
  const action = target.dataset.action;
  if (action === 'close') closeDialog();
  if (action === 'help' || action === 'schedule-help') showHelp(action === 'schedule-help');
  if (action === 'request-help') { state.helpRequested = true; save(); render(); closeDialog(); toast('이 기기에 데모 요청을 남겼어요. 실제 알림은 전송되지 않아요.'); }
  if (action === 'resolve-help' && state.role === 'buddy') { state.helpRequested = false; save(); render(); toast('함께 확인한 것으로 기록했어요.'); }
  if (action === 'confirm-shift') { state.shiftConfirmed = true; save(); render(); toast('예시 근무 시간을 확인했어요.'); }
  if (action === 'reset-prompt') openDialog('<h2 id="dialog-title">체험 데이터를 지울까요?</h2><p>이 브라우저의 연습 진행, 버디 확인, 도움 요청, 일정 확인 기록이 초기화돼요.</p><div class="dialog-actions"><button class="primary dark full" data-action="reset-confirm">체험 데이터 초기화</button><button class="secondary" data-action="close">취소</button></div>');
  if (action === 'reset-confirm') { state = { role: 'starter', practiced: [], approved: [], helpRequested: false, shiftConfirmed: false }; save(); render(); closeDialog(); toast('체험 데이터를 초기화했어요.'); }
});
document.addEventListener('change', event => {
  if (event.target.id === 'practice-check') { const button = $('[data-practice]'); if (button) button.disabled = !event.target.checked || state.role !== 'starter'; }
  if (event.target.id === 'approval-check') { const button = $('[data-signoff]'); if (button) button.disabled = !event.target.checked; }
});
$('#role-button').addEventListener('click', rolePicker);
$('#about-button').addEventListener('click', showAbout);
window.addEventListener('hashchange', () => render(true));
window.addEventListener('beforeinstallprompt', event => { event.preventDefault(); installPrompt = event; });
$('#install-button').addEventListener('click', async () => {
  if (installPrompt) { await installPrompt.prompt(); installPrompt = null; return; }
  openDialog('<h2 id="dialog-title">폰에서 바로 열어요.</h2><p>지원되는 모바일 브라우저에서는 메뉴의 “홈 화면에 추가”로 바로가기를 만들 수 있어요. iPhone Safari에서는 공유 메뉴를 확인해 주세요.</p><div class="notice">실제 배포는 HTTPS 주소가 필요해요. 현재는 로컬 체험 버전이며, 기기별 설치 동작은 아직 검증하지 않았어요.</div><button class="primary dark full" data-action="close">확인했어요</button>');
});
render();
if (!storageAvailable) toast('저장 공간을 사용할 수 없어 이 화면을 닫으면 진행 상태가 사라질 수 있어요.');
if ('serviceWorker' in navigator && (location.protocol === 'https:' || location.hostname === 'localhost' || location.hostname === '127.0.0.1')) navigator.serviceWorker.register('./sw.js').catch(() => {});
