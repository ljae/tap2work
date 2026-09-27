import { randomUUID } from 'node:crypto';
import { StoreError } from './store.mjs';

const suggestions = [
  { id: 'pos-order-review', title: 'POS 주문 확인', channel: 'pos', role: 'all', slot: '피크',
    steps: ['주문번호·메뉴·수량 확인', '특이 요청 확인', '처리 상태 대조'] },
  { id: 'pos-closing-review', title: 'POS 마감 내용 확인', channel: 'pos', role: 'manager', slot: '마감',
    steps: ['당일 내역 열기', '차이 확인 및 기록', '담당자에게 전달'] },
  { id: 'delivery-order-review', title: '배달 주문 확인', channel: 'delivery', role: 'all', slot: '피크',
    steps: ['배달앱 주문번호·메뉴 확인', '고객 요청사항 확인', '조리 담당에게 전달'] },
  { id: 'delivery-handoff-review', title: '배달 포장·전달 확인', channel: 'delivery', role: 'all', slot: '피크',
    steps: ['주문 내용과 포장 대조', '필요한 동반품 확인', '전달 상대와 주문번호 확인'] },
];

export function recommendedTaps(state) {
  const profile = state.store?.profile ?? {};
  return suggestions.filter(row => profile[row.channel]?.enabled === true).map(row => ({
    ...row, alreadyAdded: state.taskTemplates.some(template => template.recommendationId === row.id && !template.archivedAt),
  }));
}

export function importRecommendedTaps(state, ids) {
  if (!Array.isArray(ids) || !ids.length || ids.length > suggestions.length || new Set(ids).size !== ids.length) throw new StoreError('가져올 업무를 선택해 주세요.', 400);
  const available = recommendedTaps(state);
  if (state.taskTemplates.length + ids.length > 150) throw new StoreError('업무는 최대 150개까지 등록할 수 있어요.', 400);
  for (const id of ids) {
    const row = available.find(item => item.id === id && !item.alreadyAdded);
    if (!row) throw new StoreError('선택한 업무가 이미 등록됐거나 현재 매장 설정과 맞지 않아요.', 409);
    state.taskTemplates.push({
      id: randomUUID(), recommendationId: id, title: row.title, emoji: '📝', folderId: 'general',
      slot: row.slot, requiredRole: row.role, zone: null, version: 1, sourceIds: [],
      steps: row.steps.map(title => ({ id: randomUUID(), title,
        manual: '매장의 승인된 절차와 실제 주문 내용을 확인한 뒤 진행해요.',
        tip: '이 업무의 세부 순서와 완료 기준은 매장에서 확인해 주세요.', tags: [] })),
    });
  }
}
