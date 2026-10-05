// Account-linked personal data only. Other crew accounts and shared work remain.
export function eraseMemberData(payload, user) {
  const people = (payload.tappers ?? []).filter(row => row.actorId === user.id);
  const ids = new Set(people.map(row => row.id));
  const replacement = `deleted-${crypto.randomUUID()}`;
  const terms = [...new Set([user.id, user.email, user.displayName, ...people.flatMap(p => [p.nickname, p.phone, p.kakaoUrl])])]
    .filter(value => typeof value === 'string' && value.length > 0)
    .sort((a, b) => b.length - a.length);
  const personalSections = new Set(['staffShifts','attendance','payAdjustments','payRecords','laborReviews','crewPatterns','shiftPatterns','shiftRequests','shiftChangeRequests']);
  const isOwn = row => row && typeof row === 'object' && (ids.has(row.tapperId) || row.userId === user.id);
  const scrubText = (text, key='') => {
    text = text.replaceAll(user.id,replacement);
    if (/(^id$|Id$|Ids$|^role$|^rank$|^status$|^type$|^kind$|^action$|^sourceHash$|^date$|^start$|^end$|^at$)/.test(key)) return text;
    for (const term of terms.filter(t=>t!==user.id)) {
      if (term.length > 1) text = text.replaceAll(term,'탈퇴한 크루');
      else if (text === term) text='탈퇴한 크루';
    }
    return text;
  };
  const scrub = (value, key='') => {
    if (typeof value === 'string') return scrubText(value,key);
    if (Array.isArray(value)) {
      // Applies to history snapshots as well as current sections.
      return (personalSections.has(key) ? value.filter(row => !isOwn(row)) : value).map(v=>scrub(v,key));
    }
    if (value && typeof value === 'object') {
      if (value.actorId === user.id && ids.has(value.id)) {
        return {id:value.id, actorId:replacement, nickname:'탈퇴한 크루', rank:'crew', active:false, duties:[]};
      }
      return Object.fromEntries(Object.entries(value).map(([k,v]) => {
        // crewIds maps part IDs to ordered slots; preserve empty slot positions.
        if (k === 'crewIds' && v && !Array.isArray(v) && typeof v==='object') {
          return [k,Object.fromEntries(Object.entries(v).map(([part,list])=>[part,Array.isArray(list)?list.map(id=>ids.has(id)?null:id):list]))];
        }
        if (['crewIds','tapperIds'].includes(k) && Array.isArray(v)) return [k,v.filter(id=>!ids.has(id))];
        if (['replacementTapperId','assignedTapperId'].includes(k) && ids.has(v)) return [k,null];
        return [k.replaceAll(user.id,replacement),scrub(v,k)];
      }));
    }
    return value;
  };
  return scrub(payload);
}
