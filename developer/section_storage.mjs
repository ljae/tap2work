// One document per domain root: settings writes never rewrite payroll/task history.
export function sectionPatch(previous, next) {
  const changes = {};
  const removed = [];
  for (const [key, value] of Object.entries(next)) {
    if (key !== 'revision' && JSON.stringify(value) !== JSON.stringify(previous[key])) changes[key] = value;
  }
  for (const key of Object.keys(previous)) if (key !== 'revision' && !Object.hasOwn(next, key)) removed.push(key);
  return { changes, removed };
}
