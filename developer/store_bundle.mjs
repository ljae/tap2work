import { StoreError } from './store.mjs';

// Editable starter suggestions, not a commercial recipe specification.
// No inferred purchase prices, stock, cooking temperatures or shelf lives.
const recipes = {
 chicken: [['후라이드 치킨','닭고기,튀김가루,식용유','재료를 손질하고 매장 배합으로 튀김옷을 준비해요. 승인한 튀김 기준으로 조리하고 익힘·기름 빠짐을 확인해요.'],['양념치킨','닭고기,튀김가루,식용유,양념소스','치킨을 매장 튀김 기준으로 조리한 뒤 정한 양의 소스를 고르게 버무려요.']],
 korean: [['제육볶음','돼지고기,양파,대파,고추장','돼지고기와 채소를 손질하고 매장 양념 배합으로 볶아요. 익힘과 간을 확인해 담아요.'],['된장찌개','된장,두부,애호박,양파','육수와 된장 배합을 확인하고 손질한 재료를 순서대로 넣어 끓여요.']],
 donkatsu: [['등심 돈까스','돼지등심,밀가루,달걀,빵가루,식용유,돈까스소스','등심을 손질하고 밀가루·달걀·빵가루 순으로 입혀요. 매장 튀김 기준으로 익혀 잘라 담아요.'],['치즈 돈까스','돼지등심,치즈,밀가루,달걀,빵가루,식용유','손질한 고기에 치즈를 넣고 가장자리를 여민 뒤 튀김옷을 입혀요. 매장 기준으로 익힘을 확인해요.']],
 snack: [['떡볶이','떡,어묵,고추장,대파','매장 배합의 양념과 육수에 떡·어묵을 넣어 익히고 농도를 맞춰요.'],['김밥','쌀,김,단무지,당근,달걀','밥과 속재료를 매장 기준으로 준비하고 정한 양을 김에 펼쳐 말아요.']],
 bbq: [['삼겹살 구이','삼겹살,상추,마늘,쌈장','고기와 곁들임을 정한 양으로 준비하고 매장 구이 기준으로 제공해요.'],['돼지갈비','돼지갈비,간장,양파,마늘','고기를 손질하고 매장 양념 배합으로 준비해 구이 기준에 따라 익혀요.']],
 sushi: [['연어초밥','연어,쌀,배합초,와사비','생식용 원료와 매장 위생 기준을 확인해요. 초밥용 밥과 생선을 정한 양으로 성형해요.'],['우동','우동면,우동육수,대파','육수와 고명을 준비하고 면을 매장 기준으로 익혀 담아요.']],
 chinese: [['짜장면','중화면,춘장,돼지고기,양파','춘장과 손질한 재료로 매장 기준의 소스를 만들고 익힌 면에 담아요.'],['볶음밥','쌀,달걀,대파,당근','밥과 손질한 재료를 매장 배합에 맞춰 볶고 제공 상태를 확인해요.']],
 pizza: [['마르게리타 피자','피자도우,토마토소스,모차렐라치즈,바질','도우에 소스와 토핑을 배합표대로 올리고 매장 오븐 기준으로 구워요.'],['페퍼로니 피자','피자도우,토마토소스,모차렐라치즈,페퍼로니','도우에 소스·치즈·페퍼로니를 정한 양으로 올려 매장 기준으로 구워요.']],
 bonejjim: [['감자탕','돼지등뼈,감자,우거지,들깨가루','등뼈를 매장 전처리 기준으로 준비해요. 육수·양념과 채소를 넣고 승인한 기준으로 끓여요.'],['뼈해장국','돼지등뼈,우거지,대파','전처리한 뼈와 육수를 매장 분량으로 나누고 채소·양념을 넣어 끓여요.']],
 banchan: [['달걀말이','달걀,당근,대파,식용유','손질한 채소와 달걀물을 섞고 매장 기준으로 익혀 말아요.'],['멸치볶음','멸치,간장,설탕,식용유','멸치를 손질하고 매장 양념 배합에 맞춰 볶아 소분해요.']],
 cafe: [['아메리카노','원두,정수','매장 추출 기준으로 커피를 추출하고 정한 물 배합으로 제공해요.'],['카페라테','원두,우유','매장 기준으로 커피를 추출하고 우유를 준비해 정한 비율로 조합해요.']],
 bakery: [['소금빵','강력분,이스트,버터,소금','매장 배합표로 반죽하고 발효·성형한 뒤 승인한 오븐 기준으로 구워요.'],['스콘','박력분,버터,우유,설탕,베이킹파우더','재료를 배합표대로 혼합하고 성형해 매장 오븐 기준으로 구워요.']],
 pub: [['어묵탕','어묵,무,대파,육수','손질한 재료와 매장 육수·양념 배합으로 끓여 제공해요.'],['감자튀김','감자,식용유,소금','감자를 매장 전처리·튀김 기준으로 준비하고 익힘을 확인해 간해요.']],
 other: [],
};
export const bundleVersion = 'starter-2026-10-08-v1';
export const storeBundles = Object.fromEntries(Object.entries(recipes).map(([type, rows]) => [type, rows.map(([name, ingredients, method], i) => ({id:`${type}-${i+1}`, name, ingredients:ingredients.split(','), method, status:'매장 기준 확인 필요'}))]));

export function applyStoreBundle(state, setup, type, now) {
  if (setup.menuIds == null) return; // Old clients retain their existing contract.
  if (setup.bundleVersion !== bundleVersion) throw new StoreError('기본 메뉴가 변경됐어요. 다시 확인해 주세요.',409);
  const available = storeBundles[type.id];
  if (!Array.isArray(setup.menuIds) || new Set(setup.menuIds).size !== setup.menuIds.length || setup.menuIds.some(id=>!available.some(row=>row.id===id))) throw new StoreError('기본 메뉴 선택을 확인해 주세요.');
  const selected = available.filter(row=>setup.menuIds.includes(row.id));
  if (!selected.length) return;
  state.checklistFolders.push({id:'store-recipes',name:'메뉴·레시피'});
  state.bigTapOrder = [...(state.bigTapOrder ?? []),'store-recipes'];
  for (const row of selected) {
    const ingredientIds = row.ingredients.map(name=> {
      let item = state.items.find(item=>item.name===name);
      if (!item) {
        item = {id:`starter-item-${state.items.length+1}`,name,unit:['우유','정수','식용유','우동육수','육수'].includes(name)?'L':name==='달걀'?'개':name==='김'?'장':'kg',supplier:'공급처 미설정',emoji:'📦',zone:null,minimum:0,orderQuantity:1,price:0,reviewDays:3,quantity:0,lastOrderedAt:null,lastCheckedAt:null,setupNeedsReview:true};
        state.items.push(item);
      }
      return item.id;
    });
    const menu = {id:`starter-menu-${row.id}`,name:row.name,category:type.name,price:0,ingredientIds,setupNeedsReview:true};
    state.sales.menus.push(menu);
    const knowledgeIds=state.taskTemplates.filter(t=>t.knowledge?.menuNames?.includes(row.name)||t.knowledge?.ingredientNames?.some(name=>row.ingredients.includes(name))).map(t=>t.id);
    state.taskTemplates.push({knowledge:{scope:'menu',topics:['recipe'],safetyReviewRequired:true},id:`menu-manual-${menu.id}`,menuManualId:menu.id,title:menu.name,emoji:'🍽️',folderId:'store-recipes',slot:'피크',requiredRole:'cook',zone:null,assignmentScopeVersion:2,version:1,sourceIds:[],settings:{usage:'reference',knowledgeIds,type:'order',enabled:false,recurrence:{mode:'daily',weekdays:[]},allowBulkComplete:false,enforceSequence:false},steps:[{id:'menu',title:menu.name,manual:`기본 초안 · 매장 기준 확인 필요\n주요 재료: ${row.ingredients.join(', ')}\n${row.method}\n분량·온도·시간·알레르기·제공 기준은 매장에서 확인해 수정하세요.`,tip:'메뉴 가격과 재료 단위·공급처·발주 기준도 매장에 맞게 수정하세요.',contentRevision:1}]});
  }
  state.store.starterBundle={version:bundleVersion,businessTypeId:type.id,menuIds:setup.menuIds,createdAt:now.toISOString()};
}
