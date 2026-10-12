// Finding a manual and generating a checklist are separate decisions.
export const manualCategories = [
  {id:'startup',name:'처음 설정',description:'매장 기준과 첫 운영 준비'},
  {id:'periodic',name:'정기 관리',description:'주간·월간 등 정해진 때 확인'},
  {id:'routine',name:'루틴 업무',description:'출근·오픈·영업·교대·마감'},
  {id:'recipe',name:'레시피',description:'메뉴의 재료·분량·방법·품질 기준'},
  {id:'reference',name:'교육·참고',description:'배우거나 필요할 때 찾아보기'},
];
export const manualCategoryIds=manualCategories.map(row=>row.id);
export function manualCategory(value={}) {
  if(value.menuManualId)return 'recipe';
  if(manualCategoryIds.includes(value.manualCategoryOverride))return value.manualCategoryOverride;
  const explicit=value.knowledge?.useCase;
  if(explicit==='training')return 'reference';
  if(manualCategoryIds.includes(explicit))return explicit;
  if(value.knowledge?.topics?.includes('recipe'))return 'recipe';
  if(value.kind==='legal' || value.knowledge?.topics?.includes('compliance') && value.knowledge?.suggestedUse==='reference')return 'startup';
  if(value.sourceId==='food/equipment')return 'periodic';
  if(value.sourceId==='food/incident')return 'reference';
  if(value.settings?.recurrence && value.settings.recurrence.mode!=='daily')return 'periodic';
  if(value.knowledge?.suggestedUse==='reference' || value.settings?.usage==='reference')return 'reference';
  return 'routine';
}
export function defaultManualUsage(value) {
  return manualCategory(value)==='routine' && value.knowledge?.suggestedUse==='routine' ? 'routine' : 'reference';
}
