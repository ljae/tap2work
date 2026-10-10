// Stable private photo references contain no signed URL or credentials.
export const manualMediaPrefix = 'tap2work-media:';
const referencePattern = /^tap2work-media:([a-zA-Z0-9-]{1,80})\/([a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}\.jpg)$/;
export function parseManualMediaReference(value) {
  if (typeof value !== 'string') return null;
  const match = referencePattern.exec(value);
  return match ? { workspaceId: match[1], path: `${match[1]}/${match[2]}` } : null;
}
