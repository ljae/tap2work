import { StoreError } from './store.mjs';
import { occupiedCells } from './layout_geometry.mjs';

const kinds = ['table', 'equipment', 'storage', 'entrance', 'area'];
const icons = { table: '🪑', equipment: '⚙️', storage: '📦', entrance: '🚪', area: '▧' };
function fail(message) { throw new StoreError(message, 400); }
function integer(value, min, max, label) {
  if (!Number.isInteger(value) || value < min || value > max) fail(`${label}: ${min}~${max} 사이의 정수를 입력해 주세요.`);
  return value;
}
function label(value, max, required = true) {
  if (typeof value !== 'string' || value.length > max || (required && !value.trim())) fail('배치 이름과 설명의 길이를 확인해 주세요.');
  return value.trim();
}

// Upgrade the old eight-place kitchen sketch once; preserve IDs, names and notes.
export function ensureLayout(state) {
  if (state.layout) return false;
  state.layout = { name: '우리 매장', columns: 16, rows: 12, updatedAt: null, updatedBy: null };
  state.zones = state.zones.map(zone => ({
    ...zone, kind: ['entrance', 'exit'].includes(zone.id) ? 'entrance' : zone.id === 'storage' ? 'storage' : 'equipment',
    x: Math.round(zone.x * 8), y: Math.round(zone.y * 12), width: 3, height: 2, seats: 0,
  }));
  for (let i = 0; i < 6; i++) {
    state.zones.push({ id: `table-${i + 1}`, name: `${i + 1}번 테이블`, kind: 'table', emoji: icons.table,
      description: '홀 좌석 · 샘플 배치', x: 9 + (i % 2) * 4, y: 1 + Math.floor(i / 2) * 4, width: 3, height: 2, seats: 4 });
  }
  return true;
}

export function validateLayout(input, state) {
  if (!input.layout || typeof input.layout !== 'object') fail('매장 배치를 확인해 주세요.');
  const layout = {
    name: label(input.layout.name, 40),
    columns: integer(input.layout.columns, 8, 30, '가로 칸 수'),
    rows: integer(input.layout.rows, 8, 30, '세로 칸 수'),
  };
  if (!Array.isArray(input.zones) || input.zones.length > 80) fail('배치 항목은 최대 80개까지 설정할 수 있어요.');
  const ids = new Set();
  const tableNames = new Set();
  const zones = input.zones.map(zone => {
    if (!zone || typeof zone !== 'object' || typeof zone.id !== 'string' || !/^[a-zA-Z0-9_-]{1,80}$/.test(zone.id) || ids.has(zone.id)) fail('배치 항목의 식별자가 중복되거나 잘못되었어요.');
    ids.add(zone.id);
    if (!kinds.includes(zone.kind)) fail('테이블·기기·보관·출입구·구역 중에서 선택해 주세요.');
    const result = { id: zone.id, kind: zone.kind, name: label(zone.name, 30), description: label(zone.description, 500, false),
      x: integer(zone.x, 0, layout.columns - 1, '가로 위치'), y: integer(zone.y, 0, layout.rows - 1, '세로 위치'),
      width: integer(zone.width, 1, layout.columns, '가로 크기'), height: integer(zone.height, 1, layout.rows, '세로 크기'),
      seats: zone.kind === 'table' ? integer(zone.seats, 1, 20, '좌석 수') : 0,
      shape: zone.shape ?? 'rect', rotation: zone.rotation ?? 0,
      notchWidth: zone.shape && zone.shape !== 'rect' ? zone.notchWidth : 0,
      notchDepth: zone.shape && zone.shape !== 'rect' ? zone.notchDepth : 0,
      emoji: state.zones.find(old => old.id === zone.id && old.kind === zone.kind)?.emoji || icons[zone.kind],
    };
    if (result.x + result.width > layout.columns || result.y + result.height > layout.rows) fail(`${result.name}이 매장 경계를 벗어나요.`);
    occupiedCells(result);
    if (zone.kind === 'table') {
      if (tableNames.has(result.name)) fail('테이블 이름은 서로 다르게 정해 주세요.');
      tableNames.add(result.name);
    }
    return result;
  });
  for (const zone of state.zones) {
    const replacement = zones.find(z => z.id === zone.id);
    const referenced = [...state.items, ...(state.preparedItems ?? []), ...state.tasks, ...state.taskTemplates].some(item => item.zone === zone.id);
    if (referenced && (!replacement || replacement.kind !== zone.kind)) fail(`${zone.name}은 재고나 업무에 연결되어 있어 삭제하거나 종류를 바꿀 수 없어요. 위치·이름은 바꿀 수 있어요.`);
  }
  for (let i = 0; i < zones.length; i++) {
    for (const other of zones.slice(i + 1)) {
      const z = zones[i];
      // Areas may contain equipment/tables; physical objects may not overlap.
      if (z.kind === 'area' || other.kind === 'area') continue;
      const occupied = occupiedCells(z);
      if ([...occupiedCells(other)].some(cell => occupied.has(cell))) fail(`${z.name}과 ${other.name}의 위치가 겹쳐요.`);
    }
  }
  return { layout, zones };
}
