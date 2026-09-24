import { StoreError } from './store.mjs';

export function occupiedCells(zone) {
  const shape = zone.shape ?? 'rect';
  const rotation = zone.rotation ?? 0;
  if (!['rect', 'l', 'u'].includes(shape) || ![0, 90, 180, 270].includes(rotation)) throw new StoreError('직사각형·L·U 도형만 사용할 수 있어요.', 400);
  const width = zone.width, height = zone.height;
  const baseWidth = rotation % 180 ? height : width;
  const baseHeight = rotation % 180 ? width : height;
  const notchWidth = shape === 'rect' ? 0 : zone.notchWidth;
  const notchDepth = shape === 'rect' ? 0 : zone.notchDepth;
  if (shape !== 'rect' && (!Number.isInteger(notchWidth) || !Number.isInteger(notchDepth) || notchWidth < 1 || notchDepth < 1 || notchDepth >= baseHeight || notchWidth > baseWidth - (shape === 'u' ? 2 : 1))) throw new StoreError('L/U 도형의 홈 크기를 확인해 주세요.', 400);
  const occupied = new Set();
  for (let y = 0; y < baseHeight; y++) for (let x = 0; x < baseWidth; x++) {
    const removed = shape === 'l' ? x >= baseWidth - notchWidth && y < notchDepth : shape === 'u' ? x >= Math.floor((baseWidth - notchWidth) / 2) && x < Math.floor((baseWidth - notchWidth) / 2) + notchWidth && y < notchDepth : false;
    if (removed) continue;
    let tx = x, ty = y;
    if (rotation === 90) { tx = baseHeight - 1 - y; ty = x; }
    if (rotation === 180) { tx = baseWidth - 1 - x; ty = baseHeight - 1 - y; }
    if (rotation === 270) { tx = y; ty = baseWidth - 1 - x; }
    occupied.add(`${zone.x + tx},${zone.y + ty}`);
  }
  return occupied;
}
