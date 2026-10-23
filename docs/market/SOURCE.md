# 매뉴얼 마켓 공용 원본

기존 64 TAP의 콘텐츠와 ID를 보존하고 전체 업종 탐색 메타데이터 및 공통·법적 기준 확인 항목을 추가했습니다. 법적 기준 카드는 적용 대상과 출처 범위가 있는 확인용 초안이며 법 준수 판정이 아닙니다.

## 외식 공통 · 첫 매장 · 오늘의 공석과 인수인계 읽기

```tap2work-tap
{
  "sourceId": "common/opening",
  "collectionId": "common",
  "collectionName": "외식 공통 · 첫 매장",
  "title": "오늘의 공석과 인수인계 읽기",
  "slot": "오픈",
  "reviewedAt": "2026-09-20",
  "basis": "공개 자료를 참고한 편집 제안 · 현장 검토 필요",
  "steps": [
    {
      "id": "step-1",
      "title": "인수인계에서 바뀐 일 찾기",
      "manual": "오늘 품절·예약·미완료 업무를 읽고 본인 업무에 영향을 주는 항목을 하나씩 짚어요.",
      "tip": "어제 메모를 오늘 공지로 착각하지 않도록 날짜부터 봐요.",
      "tags": [],
      "sourceUrl": "https://www.gov.uk/government/publications/safer-food-better-business-for-caterers"
    },
    {
      "id": "step-2",
      "title": "담당과 도움받을 사람 확인",
      "manual": "빈 근무 시간과 오늘 버디를 확인하고 모르는 업무를 누구에게 물을지 정해요.",
      "tip": "혼자 할 수 없는 장비 업무는 시작 전에 담당을 맞춰요.",
      "tags": [],
      "sourceUrl": "https://www.gov.uk/government/publications/safer-food-better-business-for-caterers"
    },
    {
      "id": "step-3",
      "title": "오픈 전 빠진 준비 전달",
      "manual": "내 구역을 한 바퀴 돌고 부족한 준비를 담당자에게 직접 알려요. 인수인계가 끝났는지 확인해요.",
      "tip": "메모를 읽은 것과 준비를 마친 것은 달라요.",
      "tags": [],
      "sourceUrl": "https://www.gov.uk/government/publications/safer-food-better-business-for-caterers"
    }
  ],
  "industryIds": [
    "food"
  ],
  "purposeId": "people",
  "kind": "operation",
  "summary": "인수인계에서 바뀐 일 찾기 · 담당과 도움받을 사람 확인",
  "applicability": "외식 공통 · 첫 매장의 해당 작업을 하는 사업장. 현장 절차와 장비 지침에 맞게 조정하세요.",
  "jurisdiction": "출처별 관할 · 운영 참고",
  "keywords": [],
  "references": [
    {
      "title": "기존 체크리스트 원문 1",
      "url": "https://www.gov.uk/government/publications/safer-food-better-business-for-caterers",
      "checkedAt": "2026-09-20",
      "scope": "기존 위키 조사 자료 · 업무 구조 참고, 국내 법적 기준으로 단정하지 않음"
    }
  ],
  "knowledge": {
    "scope": "food",
    "topics": [
      "people"
    ],
    "suggestedUse": "routine"
  }
}
```

## 외식 공통 · 첫 매장 · 전처리 도구와 작업대 준비

```tap2work-tap
{
  "sourceId": "common/prep",
  "collectionId": "common",
  "collectionName": "외식 공통 · 첫 매장",
  "title": "전처리 도구와 작업대 준비",
  "slot": "준비",
  "reviewedAt": "2026-09-20",
  "basis": "공개 자료를 참고한 편집 제안 · 현장 검토 필요",
  "steps": [
    {
      "id": "step-1",
      "title": "원물과 완성식품 구역 나누기",
      "manual": "생재료와 바로 먹는 재료를 다른 용기·도구로 준비하고 라벨을 확인해요.",
      "tip": "색상만 외우지 말고 도구의 용도를 확인해요.",
      "tags": [],
      "sourceUrl": "https://www.gov.uk/government/publications/safer-food-better-business-for-caterers"
    },
    {
      "id": "step-2",
      "title": "작업대 세척 후 준비",
      "manual": "찌꺼기와 오염을 먼저 제거하고 매장 제품 지침대로 세척·소독해요. 필요한 접촉시간과 헹굼을 확인해요.",
      "tip": "먼지가 남은 표면에 소독제만 뿌려 끝내지 않아요.",
      "tags": [],
      "sourceUrl": "https://www.gov.uk/government/publications/safer-food-better-business-for-caterers"
    },
    {
      "id": "step-3",
      "title": "오늘 사용할 양만 소분",
      "manual": "예상 주문과 레시피에 맞춰 소분하고 재료명·준비 시각·사용 기준을 표시해요.",
      "tip": "추가 준비량은 잔량을 본 뒤 결정하면 중복 손질을 줄여요.",
      "tags": [],
      "sourceUrl": "https://www.gov.uk/government/publications/safer-food-better-business-for-caterers"
    }
  ],
  "industryIds": [
    "food"
  ],
  "purposeId": "production",
  "kind": "operation",
  "summary": "원물과 완성식품 구역 나누기 · 작업대 세척 후 준비",
  "applicability": "외식 공통 · 첫 매장의 해당 작업을 하는 사업장. 현장 절차와 장비 지침에 맞게 조정하세요.",
  "jurisdiction": "출처별 관할 · 운영 참고",
  "keywords": [],
  "references": [
    {
      "title": "기존 체크리스트 원문 1",
      "url": "https://www.gov.uk/government/publications/safer-food-better-business-for-caterers",
      "checkedAt": "2026-09-20",
      "scope": "기존 위키 조사 자료 · 업무 구조 참고, 국내 법적 기준으로 단정하지 않음"
    }
  ],
  "knowledge": {
    "scope": "food",
    "topics": [
      "production"
    ],
    "suggestedUse": "routine"
  }
}
```

## 외식 공통 · 첫 매장 · 설거지 구역 정리 확인

```tap2work-tap
{
  "sourceId": "common/close",
  "collectionId": "common",
  "collectionName": "외식 공통 · 첫 매장",
  "title": "설거지 구역 정리 확인",
  "slot": "마감",
  "reviewedAt": "2026-09-20",
  "basis": "공개 자료를 참고한 편집 제안 · 현장 검토 필요",
  "steps": [
    {
      "id": "step-1",
      "title": "사용 식기와 깨끗한 식기 분리",
      "manual": "잔반을 비우고 세척 전후 식기의 이동 방향이 섞이지 않게 놓아요.",
      "tip": "깨끗한 식기를 오염된 바구니로 되돌리지 않아요.",
      "tags": [],
      "sourceUrl": "https://www.gov.uk/government/publications/safer-food-better-business-for-caterers"
    },
    {
      "id": "step-2",
      "title": "세척 결과와 건조 확인",
      "manual": "매장 세척기·세제 지침대로 처리한 뒤 음식물과 세제 잔여를 확인하고 지정 건조대에 놓아요.",
      "tip": "겹쳐 쌓은 식기 사이에 물기가 남지 않는지 봐요.",
      "tags": [],
      "sourceUrl": "https://www.gov.uk/government/publications/safer-food-better-business-for-caterers"
    },
    {
      "id": "step-3",
      "title": "배수망과 바닥 정리",
      "manual": "배수망 찌꺼기를 수거하고 도구를 제자리에 둬요. 물기를 정리한 뒤 통로를 열어요.",
      "tip": "젖은 바닥에 표지만 세우고 마감하지 않아요.",
      "tags": [],
      "sourceUrl": "https://www.gov.uk/government/publications/safer-food-better-business-for-caterers"
    }
  ],
  "industryIds": [
    "food"
  ],
  "purposeId": "hygiene",
  "kind": "operation",
  "summary": "사용 식기와 깨끗한 식기 분리 · 세척 결과와 건조 확인",
  "applicability": "외식 공통 · 첫 매장의 해당 작업을 하는 사업장. 현장 절차와 장비 지침에 맞게 조정하세요.",
  "jurisdiction": "출처별 관할 · 운영 참고",
  "keywords": [],
  "references": [
    {
      "title": "기존 체크리스트 원문 1",
      "url": "https://www.gov.uk/government/publications/safer-food-better-business-for-caterers",
      "checkedAt": "2026-09-20",
      "scope": "기존 위키 조사 자료 · 업무 구조 참고, 국내 법적 기준으로 단정하지 않음"
    }
  ],
  "knowledge": {
    "scope": "food",
    "topics": [
      "hygiene"
    ],
    "suggestedUse": "routine"
  }
}
```

## 뼈찜·감자탕 전문점 · 출근 · 개인 위생과 인수인계

```tap2work-tap
{
  "sourceId": "bonejjim/staff-open",
  "collectionId": "bonejjim",
  "collectionName": "뼈찜·감자탕 전문점",
  "title": "출근 · 개인 위생과 인수인계",
  "emoji": "🧑‍🍳",
  "slot": "오픈",
  "reviewedAt": "2026-09-20",
  "basis": "방문 후기 S19·S25~S29의 제공 사례 비교와 공개 위생 자료를 참고한 편집 제안. 매장 레시피·현재 메뉴·제공 방식은 책임자 검수 필요.",
  "steps": [
    {
      "id": "step-1",
      "title": "손 씻기와 위생복·위생모 착용",
      "manual": "탈의 후 비누로 30초 이상 손을 씻고 매장 위생복·위생모(주방은 마스크)를 착용해요. 손에 상처가 있으면 방수 밴드와 장갑을 쓰고 책임자에게 알려요.",
      "tip": "앞치마를 화장실까지 입고 가지 않아요. 휴대폰을 만졌으면 다시 손을 씻어요.",
      "tags": [],
      "sourceUrl": "https://www.foodsafetykorea.go.kr/portal/board/boardDetail.do?menu_no=3504&menu_grp=MENU_NEW04&bbs_no=bbs1021"
    },
    {
      "id": "step-2",
      "title": "몸 상태 말하기",
      "manual": "설사·구토·발열·인후통이 있으면 조리·배식 전에 사장님이나 매니저에게 먼저 알려요. 연 1회 건강진단(장티푸스·파라티푸스·폐결핵) 기록은 사장님이 관리해요.",
      "tip": "아파도 참고 일하는 게 아니라, 알리는 것이 매장 규칙이에요.",
      "tags": [],
      "sourceUrl": "https://www.foodsafetykorea.go.kr/portal/board/boardDetail.do?menu_no=3504&menu_grp=MENU_NEW04&bbs_no=bbs1021"
    },
    {
      "id": "step-3",
      "title": "어제 인수인계 메모 읽기",
      "manual": "마감 메모에서 품절 재료, 남은 육수·초벌 등뼈 양, 예약, 고장 난 장비를 확인하고 내 업무에 영향을 주는 항목을 짚어요.",
      "tip": "날짜를 먼저 봐요. 어제 메모를 오늘 상황으로 착각하기 쉬워요.",
      "tags": [],
      "sourceUrl": "https://www.foodsafetykorea.go.kr/portal/board/boardDetail.do?menu_no=3504&menu_grp=MENU_NEW04&bbs_no=bbs1021"
    },
    {
      "id": "step-4",
      "title": "오늘 담당과 버디 확인",
      "manual": "오픈·피크·마감 담당과 오늘 버디를 확인해요. 혼자 하기 어려운 육수 솥·화구 업무는 시작 전에 담당을 정해요.",
      "tip": "처음 하는 일은 시작 전에 물어보는 게 가장 빨라요.",
      "tags": [],
      "sourceUrl": "https://www.foodsafetykorea.go.kr/portal/board/boardDetail.do?menu_no=3504&menu_grp=MENU_NEW04&bbs_no=bbs1021"
    }
  ],
  "industryIds": [
    "food"
  ],
  "purposeId": "people",
  "kind": "operation",
  "summary": "손 씻기와 위생복·위생모 착용 · 몸 상태 말하기",
  "applicability": "뼈찜·감자탕 전문점의 해당 작업을 하는 사업장. 현장 절차와 장비 지침에 맞게 조정하세요.",
  "jurisdiction": "출처별 관할 · 운영 참고",
  "keywords": [],
  "references": [
    {
      "title": "기존 체크리스트 원문 1",
      "url": "https://www.foodsafetykorea.go.kr/portal/board/boardDetail.do?menu_no=3504&menu_grp=MENU_NEW04&bbs_no=bbs1021",
      "checkedAt": "2026-09-20",
      "scope": "기존 위키 조사 자료 · 업무 구조 참고, 국내 법적 기준으로 단정하지 않음"
    }
  ],
  "knowledge": {
    "scope": "menu",
    "topics": [
      "people"
    ],
    "suggestedUse": "routine",
    "supersededBy": [
      "food/shift"
    ]
  }
}
```

## 뼈찜·감자탕 전문점 · 오픈 · 홀과 셀프바 준비

```tap2work-tap
{
  "sourceId": "bonejjim/hall-open",
  "collectionId": "bonejjim",
  "collectionName": "뼈찜·감자탕 전문점",
  "title": "오픈 · 홀과 셀프바 준비",
  "emoji": "🪑",
  "slot": "오픈",
  "reviewedAt": "2026-09-20",
  "basis": "방문 후기 S19·S25~S29의 제공 사례 비교와 공개 위생 자료를 참고한 편집 제안. 매장 레시피·현재 메뉴·제공 방식은 책임자 검수 필요.",
  "steps": [
    {
      "id": "step-1",
      "title": "간판·조명·냉난방 켜고 안내문 확인",
      "manual": "간판과 홀 조명, 냉난방을 켜요. 출입문의 영업시간(11:30~22:00), 브레이크타임(14:00~16:00, 주말 제외), 라스트오더 21:30 안내가 잘 보이는지 확인해요.",
      "tip": "안내문이 떨어져 있으면 손님 안내가 두 배로 늘어요.",
      "tags": [],
      "sourceUrl": "https://blog.naver.com/yjh97423/224347712759"
    },
    {
      "id": "step-2",
      "title": "테이블 세팅",
      "manual": "테이블마다 휴지·물티슈·앞접시 받침·뼈 버리는 통을 놓고 의자를 정렬해요. 뜨거운 냄비가 올라갈 자리에 받침이 있는지 봐요.",
      "tip": "테이블 위 끈적임은 마감 때보다 오픈 직후 밝은 조명에서 잘 보여요.",
      "tags": [],
      "sourceUrl": "https://blog.naver.com/yjh97423/224347712759"
    },
    {
      "id": "step-3",
      "title": "셀프바 채우기",
      "manual": "앞접시·국그릇·수저·집게를 채우고 밑반찬(매장 구성)을 반찬통에 담아 뚜껑을 덮어요. 반찬마다 전용 집게를 두고 담은 시각을 표시해요.",
      "tip": "손님이 집는 반찬은 조금씩 자주 채워야 버리는 양이 줄어요.",
      "tags": [],
      "sourceUrl": "https://blog.naver.com/yjh97423/224347712759"
    },
    {
      "id": "step-4",
      "title": "소금·후추·양념통과 물 준비",
      "manual": "셀프바 옆 소금·후추·다대기 통을 채우고 정수기·물병·컵을 확인해요. 뼈곰탕 국물에 곁들이는 양념이라 손님 손이 많이 가요.",
      "tip": "뚜껑 구멍이 막힌 소금통은 채우기 전에 씻어 말려요.",
      "tags": [],
      "sourceUrl": "https://blog.naver.com/yjh97423/224347712759"
    },
    {
      "id": "step-5",
      "title": "주차장·입구 정리",
      "manual": "매장 주차 공간의 장애물과 입구 바닥·유리를 정리해요. 우천 시 우산 꽂이와 미끄럼 표시를 놔요.",
      "tip": "입구 정리는 첫 손님이 오기 전 마지막 5분에 해요.",
      "tags": [],
      "sourceUrl": "https://blog.naver.com/yjh97423/224347712759"
    }
  ],
  "industryIds": [
    "food"
  ],
  "purposeId": "opening",
  "kind": "operation",
  "summary": "간판·조명·냉난방 켜고 안내문 확인 · 테이블 세팅",
  "applicability": "뼈찜·감자탕 전문점의 해당 작업을 하는 사업장. 현장 절차와 장비 지침에 맞게 조정하세요.",
  "jurisdiction": "출처별 관할 · 운영 참고",
  "keywords": [],
  "references": [
    {
      "title": "기존 체크리스트 원문 1",
      "url": "https://blog.naver.com/yjh97423/224347712759",
      "checkedAt": "2026-09-20",
      "scope": "기존 위키 조사 자료 · 업무 구조 참고, 국내 법적 기준으로 단정하지 않음"
    }
  ],
  "knowledge": {
    "scope": "menu",
    "topics": [
      "opening"
    ],
    "suggestedUse": "routine",
    "supersededBy": [
      "food/hall-open"
    ]
  }
}
```

## 뼈찜·감자탕 전문점 · 준비 · 등뼈 전처리

```tap2work-tap
{
  "sourceId": "bonejjim/bone-prep",
  "collectionId": "bonejjim",
  "collectionName": "뼈찜·감자탕 전문점",
  "title": "준비 · 등뼈 전처리",
  "emoji": "🍖",
  "slot": "준비",
  "reviewedAt": "2026-09-20",
  "basis": "방문 후기 S19·S25~S29의 제공 사례 비교와 공개 위생 자료를 참고한 편집 제안. 매장 레시피·현재 메뉴·제공 방식은 책임자 검수 필요.",
  "steps": [
    {
      "id": "step-1",
      "title": "입고 등뼈 확인",
      "manual": "라벨의 부위·중량·입고일을 확인하고 색과 냄새가 정상인지 봐요. 이상하면 사용하지 말고 사장님에게 사진과 함께 알려요.",
      "tip": "냉동 등뼈는 해동 시작 시각을 적어두면 핏물 시간을 계산하기 쉬워요.",
      "tags": [],
      "sourceUrl": "https://m.kin.naver.com/qna/dirs/8020103/docs/491088119"
    },
    {
      "id": "step-2",
      "title": "핏물 빼기",
      "manual": "찬물(매장 레시피의 설탕물 여부)에 등뼈를 담가 매장 기준 시간 동안 핏물을 빼고 중간에 물을 갈아요. 시작 시각을 용기에 표시해요.",
      "tip": "핏물이 덜 빠지면 육수가 탁하고 잡내가 나요. 시간을 눈대중으로 줄이지 않아요.",
      "tags": [],
      "sourceUrl": "https://m.kin.naver.com/qna/dirs/8020103/docs/491088119"
    },
    {
      "id": "step-3",
      "title": "초벌 삶기",
      "manual": "끓는 물에 매장 향신채(월계수잎·통후추·생강·소주 등 레시피 기준)를 넣고 등뼈를 매장 기준 시간만큼 데친 뒤 물을 버려요.",
      "tip": "초벌 물은 절대 육수에 쓰지 않아요.",
      "tags": [],
      "sourceUrl": "https://m.kin.naver.com/qna/dirs/8020103/docs/491088119"
    },
    {
      "id": "step-4",
      "title": "뼈 하나씩 헹구기",
      "manual": "흐르는 찬물에 뼈를 하나씩 헹궈 핏덩이·뼈가루·불순물을 제거해요. 씻은 뼈는 깨끗한 전용 바트에 담아요.",
      "tip": "생뼈를 만진 도구와 씻은 뼈를 담는 바트를 섞지 않아요.",
      "tags": [],
      "sourceUrl": "https://m.kin.naver.com/qna/dirs/8020103/docs/491088119"
    },
    {
      "id": "step-5",
      "title": "사이즈별 소분과 표시",
      "manual": "소·중·대 기준 무게(매장 레시피)로 나눠 용기에 담고 재료명·소분 시각·사용 기준을 붙여 냉장 보관해요.",
      "tip": "저녁 예약과 어제 판매량을 보고 소분량을 정하면 남는 뼈가 줄어요.",
      "tags": [],
      "sourceUrl": "https://m.kin.naver.com/qna/dirs/8020103/docs/491088119"
    }
  ],
  "industryIds": [
    "food"
  ],
  "purposeId": "production",
  "kind": "operation",
  "summary": "입고 등뼈 확인 · 핏물 빼기",
  "applicability": "뼈찜·감자탕 전문점의 해당 작업을 하는 사업장. 현장 절차와 장비 지침에 맞게 조정하세요.",
  "jurisdiction": "출처별 관할 · 운영 참고",
  "keywords": [],
  "references": [
    {
      "title": "기존 체크리스트 원문 1",
      "url": "https://m.kin.naver.com/qna/dirs/8020103/docs/491088119",
      "checkedAt": "2026-09-20",
      "scope": "기존 위키 조사 자료 · 업무 구조 참고, 국내 법적 기준으로 단정하지 않음"
    }
  ],
  "knowledge": {
    "scope": "menu",
    "topics": [
      "production"
    ],
    "suggestedUse": "reference",
    "useCase": "recipe"
  }
}
```

## 뼈찜·감자탕 전문점 · 준비 · 육수와 기본 뼈곰탕 국물

```tap2work-tap
{
  "sourceId": "bonejjim/broth",
  "collectionId": "bonejjim",
  "collectionName": "뼈찜·감자탕 전문점",
  "title": "준비 · 육수와 기본 뼈곰탕 국물",
  "emoji": "🍲",
  "slot": "준비",
  "reviewedAt": "2026-09-20",
  "basis": "방문 후기 S19·S25~S29의 제공 사례 비교와 공개 위생 자료를 참고한 편집 제안. 매장 레시피·현재 메뉴·제공 방식은 책임자 검수 필요.",
  "steps": [
    {
      "id": "step-1",
      "title": "육수 솥 올리기",
      "manual": "솥의 물량과 초벌 등뼈·대파·마늘·생강 등 매장 레시피 재료를 확인하고 불을 올려요. 시작 시각을 적어요.",
      "tip": "가스 밸브를 연 뒤 점화 확인까지 자리를 떠나지 않아요.",
      "tags": [],
      "sourceUrl": "https://blog.naver.com/yjh97423/224347712759"
    },
    {
      "id": "step-2",
      "title": "거품·기름 걷기와 불 조절",
      "manual": "끓기 시작하면 거품과 기름을 걷고 매장 기준 화력으로 낮춰요. 물이 줄면 뜨거운 물로만 보충해요.",
      "tip": "찬물을 부으면 국물이 탁해지고 시간이 늘어요.",
      "tags": [],
      "sourceUrl": "https://blog.naver.com/yjh97423/224347712759"
    },
    {
      "id": "step-3",
      "title": "기본 제공 국물 준비",
      "manual": "오늘 주문에 제공할 식전 국물 종류와 품절 대체 기준을 담당자에게 확인해요. 여러 방문 후기에 뼈 국물·콩나물국·미제공 사례가 있어 모든 주문의 기본 제공으로 표시하지 않아요.",
      "tip": "보온통 바닥에 남은 어제 국물을 새 국물에 섞지 않아요.",
      "tags": [],
      "sourceUrl": "https://blog.naver.com/yjh97423/224347712759"
    },
    {
      "id": "step-4",
      "title": "어제 육수 잔량 처리",
      "manual": "어제 보관한 육수가 있으면 사장님·매니저에게 사용 여부를 확인받고, 승인된 것만 재가열해 사용해요.",
      "tip": "냄새가 괜찮다는 이유만으로 사용을 결정하지 않아요.",
      "tags": [],
      "sourceUrl": "https://blog.naver.com/yjh97423/224347712759"
    }
  ],
  "industryIds": [
    "food"
  ],
  "purposeId": "production",
  "kind": "operation",
  "summary": "육수 솥 올리기 · 거품·기름 걷기와 불 조절",
  "applicability": "뼈찜·감자탕 전문점의 해당 작업을 하는 사업장. 현장 절차와 장비 지침에 맞게 조정하세요.",
  "jurisdiction": "출처별 관할 · 운영 참고",
  "keywords": [],
  "references": [
    {
      "title": "기존 체크리스트 원문 1",
      "url": "https://blog.naver.com/yjh97423/224347712759",
      "checkedAt": "2026-09-20",
      "scope": "기존 위키 조사 자료 · 업무 구조 참고, 국내 법적 기준으로 단정하지 않음"
    }
  ],
  "knowledge": {
    "scope": "menu",
    "topics": [
      "production"
    ],
    "suggestedUse": "reference",
    "useCase": "recipe"
  }
}
```

## 뼈찜·감자탕 전문점 · 준비 · 양념·사리·사이드

```tap2work-tap
{
  "sourceId": "bonejjim/sauce-side",
  "collectionId": "bonejjim",
  "collectionName": "뼈찜·감자탕 전문점",
  "title": "준비 · 양념·사리·사이드",
  "emoji": "🌶️",
  "slot": "준비",
  "reviewedAt": "2026-09-20",
  "basis": "방문 후기 S19·S25~S29의 제공 사례 비교와 공개 위생 자료를 참고한 편집 제안. 매장 레시피·현재 메뉴·제공 방식은 책임자 검수 필요.",
  "steps": [
    {
      "id": "step-1",
      "title": "뼈찜 양념장 소분",
      "manual": "산뼈찜과 화산뼈찜의 오늘 판매 옵션·매운 단계와 매장 승인 양념 준비 기준을 확인하고 용기별 이름을 표시해요. 배합·정량은 매장 레시피가 확정된 뒤 입력해요.",
      "tip": "비슷한 색의 양념장은 위치가 아니라 라벨로 구분해요.",
      "tags": [],
      "sourceUrl": "https://blog.naver.com/yjh97423/224347712759"
    },
    {
      "id": "step-2",
      "title": "특제소스 준비",
      "manual": "오늘 메뉴별 소스 제공 기준을 담당자에게 확인하고 종류별 준비분을 식별해요. 후기에는 산뼈찜 간장 겨자 소스와 화산뼈찜 마요소스 등 다른 사례가 있어 고정하지 않아요.",
      "tip": "소스 종류와 제공 여부를 주문별로 확인해요. 화산뼈찜에 마요소스가 제공된 후기 사례도 있어요.",
      "tags": [],
      "sourceUrl": "https://blog.naver.com/yjh97423/224347712759"
    },
    {
      "id": "step-3",
      "title": "사리·볶음밥 재료 확인",
      "manual": "오늘 판매하는 우동·칼국수사리와 계란볶음밥·식후 볶음밥을 구분해 준비분을 확인해요. 사리의 별도/함께 제공과 시점은 주문표 및 매장 기준을 확인해요.",
      "tip": "피크에 사리가 떨어지면 주문을 못 받아요. 준비 시간에 세는 것이 가장 쉬워요.",
      "tags": [],
      "sourceUrl": "https://blog.naver.com/yjh97423/224347712759"
    },
    {
      "id": "step-4",
      "title": "감자·우거지·채소 손질",
      "manual": "감자·우거지(시래기)·콩나물·대파를 매장 레시피 크기로 손질해 용기에 담고 손질 시각을 표시해요.",
      "tip": "생뼈를 다룬 도마와 채소 도마를 구분해요.",
      "tags": [],
      "sourceUrl": "https://blog.naver.com/yjh97423/224347712759"
    },
    {
      "id": "step-5",
      "title": "시그니처 소품 확인",
      "manual": "뼈찜 위에 꽂는 깃발 등 데코 소품과 집게·가위·앞접시 예비분을 배식대에 채워요.",
      "tip": "소품이 젖거나 찢어졌으면 바로 교체해요.",
      "tags": [],
      "sourceUrl": "https://blog.naver.com/yjh97423/224347712759"
    }
  ],
  "industryIds": [
    "food"
  ],
  "purposeId": "production",
  "kind": "operation",
  "summary": "뼈찜 양념장 소분 · 특제소스 준비",
  "applicability": "뼈찜·감자탕 전문점의 해당 작업을 하는 사업장. 현장 절차와 장비 지침에 맞게 조정하세요.",
  "jurisdiction": "출처별 관할 · 운영 참고",
  "keywords": [],
  "references": [
    {
      "title": "기존 체크리스트 원문 1",
      "url": "https://blog.naver.com/yjh97423/224347712759",
      "checkedAt": "2026-09-20",
      "scope": "기존 위키 조사 자료 · 업무 구조 참고, 국내 법적 기준으로 단정하지 않음"
    }
  ],
  "knowledge": {
    "scope": "menu",
    "topics": [
      "production"
    ],
    "suggestedUse": "reference",
    "useCase": "recipe"
  }
}
```

## 뼈찜·감자탕 전문점 · 피크 · 주방 라인

```tap2work-tap
{
  "sourceId": "bonejjim/kitchen-peak",
  "collectionId": "bonejjim",
  "collectionName": "뼈찜·감자탕 전문점",
  "title": "피크 · 주방 라인",
  "emoji": "🔥",
  "slot": "피크",
  "reviewedAt": "2026-09-20",
  "basis": "방문 후기 S19·S25~S29의 제공 사례 비교와 공개 위생 자료를 참고한 편집 제안. 매장 레시피·현재 메뉴·제공 방식은 책임자 검수 필요.",
  "steps": [
    {
      "id": "step-1",
      "title": "주문표 읽기",
      "manual": "주문번호·테이블과 메뉴(산뼈찜·화산뼈찜·뼈곰탕·뼈짬뽕), 수량·사이즈·맵기·면/밥 선택·사리·볶음밥 구분·제외 요청을 주문표에서 확인해요.",
      "tip": "사이즈와 인원수를 헷갈리지 않게 주문표의 표기 방식을 통일해요.",
      "tags": [],
      "sourceUrl": "https://blog.naver.com/yjh97423/224347712759"
    },
    {
      "id": "step-2",
      "title": "뼈찜 조리",
      "manual": "주문 메뉴와 사이즈·맵기·제외 요청을 준비분에 대조하고 매장 책임자가 승인한 조리 절차와 완료 기준을 확인해요. 후기만으로 시간·화력·원재료를 정하지 않아요.",
      "tip": "조리 시간·화력·완료 판정은 매장 책임자가 승인한 매뉴얼에서 확인해요.",
      "tags": [],
      "sourceUrl": "https://blog.naver.com/yjh97423/224347712759"
    },
    {
      "id": "step-3",
      "title": "완성 확인과 마무리",
      "manual": "본품과 주문표를 대조한 뒤 오늘 매장 기준에 맞는 동반 소스·국물·사리의 종류와 별도/함께 제공 방식을 확인해요. 후기에 서로 다른 제공 사례가 있어 한 방식으로 고정하지 않아요.",
      "tip": "우동사리가 별도로 나온 후기와 본품에 함께 나온 후기가 있어요. 오늘 기준을 확인해요.",
      "tags": [],
      "sourceUrl": "https://blog.naver.com/yjh97423/224347712759"
    },
    {
      "id": "step-4",
      "title": "볶음밥 타이밍 맞추기",
      "manual": "계란볶음밥 추가 주문과 식후 볶음밥 요청을 별개 항목으로 확인해요. 실제 상품 관계와 조리·제공 시점은 매장 기준을 따르고 주문 변경 시 홀과 다시 맞춰요.",
      "tip": "식후 요청이 실제로 들어온 뒤 주문번호와 테이블을 대조해요.",
      "tags": [],
      "sourceUrl": "https://blog.naver.com/yjh97423/224347712759"
    },
    {
      "id": "step-5",
      "title": "뜨거운 냄비 전달",
      "manual": "완성된 냄비는 받침 위에 올려 배식대에 두고 홀에 콜해요. 냄비 손잡이와 국물 넘침을 확인해요.",
      "tip": "배식대에 오래 둔 냄비는 온도와 모양이 함께 떨어져요.",
      "tags": [],
      "sourceUrl": "https://blog.naver.com/yjh97423/224347712759"
    }
  ],
  "industryIds": [
    "food"
  ],
  "purposeId": "service",
  "kind": "operation",
  "summary": "주문표 읽기 · 뼈찜 조리",
  "applicability": "뼈찜·감자탕 전문점의 해당 작업을 하는 사업장. 현장 절차와 장비 지침에 맞게 조정하세요.",
  "jurisdiction": "출처별 관할 · 운영 참고",
  "keywords": [],
  "references": [
    {
      "title": "기존 체크리스트 원문 1",
      "url": "https://blog.naver.com/yjh97423/224347712759",
      "checkedAt": "2026-09-20",
      "scope": "기존 위키 조사 자료 · 업무 구조 참고, 국내 법적 기준으로 단정하지 않음"
    }
  ],
  "knowledge": {
    "scope": "menu",
    "topics": [
      "service"
    ],
    "suggestedUse": "reference",
    "useCase": "recipe"
  }
}
```

## 뼈찜·감자탕 전문점 · 피크 · 홀 서비스

```tap2work-tap
{
  "sourceId": "bonejjim/hall-peak",
  "collectionId": "bonejjim",
  "collectionName": "뼈찜·감자탕 전문점",
  "title": "피크 · 홀 서비스",
  "emoji": "🙋",
  "slot": "피크",
  "reviewedAt": "2026-09-20",
  "basis": "방문 후기 S19·S25~S29의 제공 사례 비교와 공개 위생 자료를 참고한 편집 제안. 매장 레시피·현재 메뉴·제공 방식은 책임자 검수 필요.",
  "steps": [
    {
      "id": "step-1",
      "title": "자리 안내와 주문 받기",
      "manual": "주문에서 메뉴·사이즈·맵기·사리·면/밥 선택·볶음밥·제외 요청을 확인해요. 소스와 식전 국물 제공은 오늘 매장 기준을 확인해 안내해요.",
      "tip": "방문 후기에서 확인된 옵션만 오늘 판매 메뉴라고 단정하지 않아요.",
      "tags": [],
      "sourceUrl": "https://blog.naver.com/yjh97423/224347712759"
    },
    {
      "id": "step-2",
      "title": "기본 국물과 셀프바 안내",
      "manual": "오늘 매장 기준에 따라 식전 국물 제공 여부와 셀프바 이용 방법을 안내해요. 국물 종류·품절 대체·미제공 사례가 방문 후기에 달라 임의로 기본 제공이라고 말하지 않아요.",
      "tip": "국물 품절 시 승인된 대체 제공품과 안내 문구를 확인해요.",
      "tags": [],
      "sourceUrl": "https://blog.naver.com/yjh97423/224347712759"
    },
    {
      "id": "step-3",
      "title": "뼈찜 세팅",
      "manual": "뜨거운 본품과 주문표의 사리·소스·추가품을 대조해요. 사리의 제공 시점과 별도/함께 여부는 매장 기준과 주문 요청을 확인해요.",
      "tip": "냄비를 내려놓기 전에 테이블 위 물컵을 먼저 치워요.",
      "tags": [],
      "sourceUrl": "https://blog.naver.com/yjh97423/224347712759"
    },
    {
      "id": "step-4",
      "title": "중간 수거와 반찬 보충",
      "manual": "뼈 통과 빈 그릇을 중간에 수거하고 셀프바 반찬이 바닥나기 전에 채워요. 채운 시각을 표시해요.",
      "tip": "새 반찬을 남은 반찬 위에 덧붓지 말고 통을 교체해요.",
      "tags": [],
      "sourceUrl": "https://blog.naver.com/yjh97423/224347712759"
    },
    {
      "id": "step-5",
      "title": "결제와 라스트오더 안내",
      "manual": "결제 시 주문 내역을 확인하고 21:00 이후 입장 손님에게는 라스트오더 21:30을 안내해요.",
      "tip": "브레이크 직전 손님에게는 종료 시각을 자리 안내 때 말해요.",
      "tags": [],
      "sourceUrl": "https://blog.naver.com/yjh97423/224347712759"
    }
  ],
  "industryIds": [
    "food"
  ],
  "purposeId": "service",
  "kind": "operation",
  "summary": "자리 안내와 주문 받기 · 기본 국물과 셀프바 안내",
  "applicability": "뼈찜·감자탕 전문점의 해당 작업을 하는 사업장. 현장 절차와 장비 지침에 맞게 조정하세요.",
  "jurisdiction": "출처별 관할 · 운영 참고",
  "keywords": [],
  "references": [
    {
      "title": "기존 체크리스트 원문 1",
      "url": "https://blog.naver.com/yjh97423/224347712759",
      "checkedAt": "2026-09-20",
      "scope": "기존 위키 조사 자료 · 업무 구조 참고, 국내 법적 기준으로 단정하지 않음"
    }
  ],
  "knowledge": {
    "scope": "menu",
    "topics": [
      "service"
    ],
    "suggestedUse": "reference",
    "useCase": "recipe"
  }
}
```

## 뼈찜·감자탕 전문점 · 피크 · 포장·배달 주문

```tap2work-tap
{
  "sourceId": "bonejjim/packing",
  "collectionId": "bonejjim",
  "collectionName": "뼈찜·감자탕 전문점",
  "title": "피크 · 포장·배달 주문",
  "emoji": "📦",
  "slot": "피크",
  "reviewedAt": "2026-09-20",
  "basis": "방문 후기 S19·S25~S29의 제공 사례 비교와 공개 위생 자료를 참고한 편집 제안. 매장 레시피·현재 메뉴·제공 방식은 책임자 검수 필요.",
  "steps": [
    {
      "id": "step-1",
      "title": "포장 준비 위생",
      "manual": "지정된 포장 구역에서 손을 30초 이상 씻고 위생장갑·위생모·마스크를 착용해요. 다른 작업을 했으면 장갑을 교체해요.",
      "tip": "배달 기사님은 조리실·포장 구역에 들어오지 않도록 안내해요.",
      "tags": [],
      "sourceUrl": "https://ceo.baemin.com/qna/3582"
    },
    {
      "id": "step-2",
      "title": "용기 담기",
      "manual": "식품용 표시가 있는 깨끗한 용기에 집게·국자로 담아요. 뼈찜 본체, 사리, 특제소스, 밑반찬, 볶음밥은 각각 분리 포장하고 뜨거운 것과 차가운 것이 닿지 않게 해요.",
      "tip": "국물이 많은 뼈찜은 용기 용량의 매장 기준선까지만 담아요.",
      "tags": [],
      "sourceUrl": "https://ceo.baemin.com/qna/3582"
    },
    {
      "id": "step-3",
      "title": "밀폐와 주문 대조",
      "manual": "뚜껑을 닫고 기울여 국물이 새지 않는지 확인한 뒤 주문표와 메뉴·사이즈·사리·소스·수저 개수를 대조해요.",
      "tip": "봉투를 닫기 전에 대조하면 다시 여는 일이 없어요.",
      "tags": [],
      "sourceUrl": "https://ceo.baemin.com/qna/3582"
    },
    {
      "id": "step-4",
      "title": "즉시 출고",
      "manual": "포장을 마치면 바로 출고 선반에 두고 주문 번호를 표시해요. 외부에 오래 방치하지 않아요.",
      "tip": "배달앱 예상 시간이 밀리면 홀 담당에게 바로 알려요.",
      "tags": [],
      "sourceUrl": "https://ceo.baemin.com/qna/3582"
    }
  ],
  "industryIds": [
    "food"
  ],
  "purposeId": "service",
  "kind": "operation",
  "summary": "포장 준비 위생 · 용기 담기",
  "applicability": "뼈찜·감자탕 전문점의 해당 작업을 하는 사업장. 현장 절차와 장비 지침에 맞게 조정하세요.",
  "jurisdiction": "출처별 관할 · 운영 참고",
  "keywords": [],
  "references": [
    {
      "title": "기존 체크리스트 원문 1",
      "url": "https://ceo.baemin.com/qna/3582",
      "checkedAt": "2026-09-20",
      "scope": "기존 위키 조사 자료 · 업무 구조 참고, 국내 법적 기준으로 단정하지 않음"
    }
  ],
  "knowledge": {
    "scope": "menu",
    "topics": [
      "service"
    ],
    "suggestedUse": "routine",
    "supersededBy": [
      "food/packing"
    ]
  }
}
```

## 뼈찜·감자탕 전문점 · 브레이크타임 · 정리와 저녁 준비

```tap2work-tap
{
  "sourceId": "bonejjim/break",
  "collectionId": "bonejjim",
  "collectionName": "뼈찜·감자탕 전문점",
  "title": "브레이크타임 · 정리와 저녁 준비",
  "emoji": "☕",
  "slot": "브레이크",
  "reviewedAt": "2026-09-20",
  "basis": "방문 후기 S19·S25~S29의 제공 사례 비교와 공개 위생 자료를 참고한 편집 제안. 매장 레시피·현재 메뉴·제공 방식은 책임자 검수 필요.",
  "steps": [
    {
      "id": "step-1",
      "title": "브레이크 안내",
      "manual": "14:00에 출입문 안내를 브레이크(16:00 재오픈)로 바꾸고 식사 중인 손님은 편히 마무리하도록 안내해요. 주말은 브레이크가 없어요.",
      "tip": "전화 문의에는 재오픈 시각을 함께 말해요.",
      "tags": [],
      "sourceUrl": "https://blog.naver.com/yjh97423/224347712759"
    },
    {
      "id": "step-2",
      "title": "홀·셀프바 정리",
      "manual": "테이블과 바닥을 정리하고 셀프바 반찬은 뚜껑을 덮어 냉장 보관하거나 매장 폐기 기준에 따라 처리해요. 반찬통·집게를 교체해요.",
      "tip": "점심에 오래 나와 있던 반찬을 저녁에 그대로 쓰지 않아요.",
      "tags": [],
      "sourceUrl": "https://blog.naver.com/yjh97423/224347712759"
    },
    {
      "id": "step-3",
      "title": "육수·초벌 등뼈 점검",
      "manual": "육수 잔량과 상태를 보고 저녁용을 보충해요. 저녁 예약과 점심 판매량으로 초벌 등뼈 소분량을 정해요.",
      "tip": "점심 피크에 부족했던 사이즈를 메모해 두면 저녁 준비가 빨라요.",
      "tags": [],
      "sourceUrl": "https://blog.naver.com/yjh97423/224347712759"
    },
    {
      "id": "step-4",
      "title": "재고 확인과 보충 요청",
      "manual": "우동사리·계란·밥·포장 용기·앞접시 예비분을 세고 부족한 것은 앱의 보충 요청으로 남겨요.",
      "tip": "저녁 발주는 브레이크 중에 결정해야 늦지 않아요.",
      "tags": [],
      "sourceUrl": "https://blog.naver.com/yjh97423/224347712759"
    },
    {
      "id": "step-5",
      "title": "식사와 휴식 교대",
      "manual": "직원 식사와 휴식을 교대로 하고 16:00 재오픈 5분 전 각자 자리로 돌아와요.",
      "tip": "쉬는 시간도 근무의 일부예요. 급한 일이 아니면 부르지 않아요.",
      "tags": [],
      "sourceUrl": "https://blog.naver.com/yjh97423/224347712759"
    }
  ],
  "industryIds": [
    "food"
  ],
  "purposeId": "hygiene",
  "kind": "operation",
  "summary": "브레이크 안내 · 홀·셀프바 정리",
  "applicability": "뼈찜·감자탕 전문점의 해당 작업을 하는 사업장. 현장 절차와 장비 지침에 맞게 조정하세요.",
  "jurisdiction": "출처별 관할 · 운영 참고",
  "keywords": [],
  "references": [
    {
      "title": "기존 체크리스트 원문 1",
      "url": "https://blog.naver.com/yjh97423/224347712759",
      "checkedAt": "2026-09-20",
      "scope": "기존 위키 조사 자료 · 업무 구조 참고, 국내 법적 기준으로 단정하지 않음"
    }
  ],
  "knowledge": {
    "scope": "menu",
    "topics": [
      "break",
      "preparation"
    ],
    "suggestedUse": "reference",
    "supersededBy": [
      "common/break-service",
      "food/service-reset",
      "bonejjim/evening-prep"
    ]
  }
}
```

## 뼈찜·감자탕 전문점 · 마감 · 주방

```tap2work-tap
{
  "sourceId": "bonejjim/kitchen-close",
  "collectionId": "bonejjim",
  "collectionName": "뼈찜·감자탕 전문점",
  "title": "마감 · 주방",
  "emoji": "🧽",
  "slot": "마감",
  "reviewedAt": "2026-09-20",
  "basis": "방문 후기 S19·S25~S29의 제공 사례 비교와 공개 위생 자료를 참고한 편집 제안. 매장 레시피·현재 메뉴·제공 방식은 책임자 검수 필요.",
  "steps": [
    {
      "id": "step-1",
      "title": "육수와 초벌 등뼈 처리",
      "manual": "남은 육수·초벌 등뼈·양념장은 사장님·매니저 기준에 따라 보관 또는 폐기하고, 보관분은 작은 용기에 나눠 날짜·시각을 표시해요.",
      "tip": "큰 솥째 두면 중심부가 천천히 식어요.",
      "tags": [],
      "sourceUrl": "https://blog.naver.com/yjh97423/224347712759"
    },
    {
      "id": "step-2",
      "title": "손질 재료 정리",
      "manual": "감자·우거지·사리·볶음밥 재료를 뚜껑 덮어 냉장 보관하고 소비 기준을 표시해요. 생뼈와 손질 채소를 다른 칸에 둬요.",
      "tip": "내일 준비 담당이 찾기 쉽게 같은 자리에 둬요.",
      "tags": [],
      "sourceUrl": "https://blog.naver.com/yjh97423/224347712759"
    },
    {
      "id": "step-3",
      "title": "화구·후드·솥 세척과 가스 차단",
      "manual": "화구와 후드 필터, 육수 솥을 매장 세제 지침대로 세척하고 가스 밸브를 닫아요.",
      "tip": "가스 밸브 확인은 마지막 사람이 한 번 더 해요.",
      "tags": [],
      "sourceUrl": "https://blog.naver.com/yjh97423/224347712759"
    },
    {
      "id": "step-4",
      "title": "식기 세척과 배수망 정리",
      "manual": "냄비·앞접시·뼈 통을 세척해 건조대에 놓고 배수망 찌꺼기를 비워요. 바닥 물기를 정리해요.",
      "tip": "뼈 통은 냄새가 남기 쉬워 뜨거운 물로 한 번 더 헹궈요.",
      "tags": [],
      "sourceUrl": "https://blog.naver.com/yjh97423/224347712759"
    },
    {
      "id": "step-5",
      "title": "냉장고 정리와 인수인계 메모",
      "manual": "냉장고 온도(매장 기준)와 라벨을 확인하고 남은 재료·품절·고장을 마감 메모에 남겨요.",
      "tip": "메모는 내일 오픈 담당이 읽는다는 생각으로 짧게 써요.",
      "tags": [],
      "sourceUrl": "https://blog.naver.com/yjh97423/224347712759"
    }
  ],
  "industryIds": [
    "food"
  ],
  "purposeId": "closing",
  "kind": "operation",
  "summary": "육수와 초벌 등뼈 처리 · 손질 재료 정리",
  "applicability": "뼈찜·감자탕 전문점의 해당 작업을 하는 사업장. 현장 절차와 장비 지침에 맞게 조정하세요.",
  "jurisdiction": "출처별 관할 · 운영 참고",
  "keywords": [],
  "references": [
    {
      "title": "기존 체크리스트 원문 1",
      "url": "https://blog.naver.com/yjh97423/224347712759",
      "checkedAt": "2026-09-20",
      "scope": "기존 위키 조사 자료 · 업무 구조 참고, 국내 법적 기준으로 단정하지 않음"
    }
  ],
  "knowledge": {
    "scope": "menu",
    "topics": [
      "closing"
    ],
    "suggestedUse": "reference",
    "supersededBy": [
      "food/kitchen-close",
      "bonejjim/evening-prep"
    ],
    "useCase": "recipe"
  }
}
```

## 뼈찜·감자탕 전문점 · 마감 · 홀과 셀프바

```tap2work-tap
{
  "sourceId": "bonejjim/hall-close",
  "collectionId": "bonejjim",
  "collectionName": "뼈찜·감자탕 전문점",
  "title": "마감 · 홀과 셀프바",
  "emoji": "🧹",
  "slot": "마감",
  "reviewedAt": "2026-09-20",
  "basis": "방문 후기 S19·S25~S29의 제공 사례 비교와 공개 위생 자료를 참고한 편집 제안. 매장 레시피·현재 메뉴·제공 방식은 책임자 검수 필요.",
  "steps": [
    {
      "id": "step-1",
      "title": "셀프바 정리",
      "manual": "반찬은 폐기 기준에 따라 처리하고 반찬통·집게·소금통을 세척해요. 앞접시·수저를 내일 첫 손님 분량만큼 채워요.",
      "tip": "젖은 반찬통 뚜껑을 닫아 두면 냄새가 나요. 말린 뒤 닫아요.",
      "tags": [],
      "sourceUrl": "https://blog.naver.com/yjh97423/224347712759"
    },
    {
      "id": "step-2",
      "title": "테이블·의자·바닥 청소",
      "manual": "테이블 받침의 국물 자국을 닦고 의자를 정렬해요. 뼈 조각이 떨어진 바닥은 쓸고 닦아요.",
      "tip": "의자 다리 사이의 뼈 조각을 놓치기 쉬워요.",
      "tags": [],
      "sourceUrl": "https://blog.naver.com/yjh97423/224347712759"
    },
    {
      "id": "step-3",
      "title": "쓰레기와 음식물 분리",
      "manual": "일반·재활용·음식물 쓰레기를 분리해 지정 장소에 내놓고 배출 규칙(요일·시간)을 확인해요.",
      "tip": "뼈는 지역에 따라 음식물이 아닌 일반 쓰레기예요. 매장 규칙을 확인해요.",
      "tags": [],
      "sourceUrl": "https://blog.naver.com/yjh97423/224347712759"
    },
    {
      "id": "step-4",
      "title": "내일 준비물 채우기",
      "manual": "휴지·물티슈·정수기 물·포장 봉투를 채우고 셀프바 안내판을 바로 세워요.",
      "tip": "오픈 담당이 빈 통을 발견하면 첫 손님 응대가 늦어요.",
      "tags": [],
      "sourceUrl": "https://blog.naver.com/yjh97423/224347712759"
    },
    {
      "id": "step-5",
      "title": "소등과 문단속",
      "manual": "에어컨·조명·간판을 끄고 출입문을 잠근 뒤 마감 메모에 이름과 시각을 남겨요.",
      "tip": "마지막으로 가스 밸브와 콘센트를 한 번 더 봐요.",
      "tags": [],
      "sourceUrl": "https://blog.naver.com/yjh97423/224347712759"
    }
  ],
  "industryIds": [
    "food"
  ],
  "purposeId": "closing",
  "kind": "operation",
  "summary": "셀프바 정리 · 테이블·의자·바닥 청소",
  "applicability": "뼈찜·감자탕 전문점의 해당 작업을 하는 사업장. 현장 절차와 장비 지침에 맞게 조정하세요.",
  "jurisdiction": "출처별 관할 · 운영 참고",
  "keywords": [],
  "references": [
    {
      "title": "기존 체크리스트 원문 1",
      "url": "https://blog.naver.com/yjh97423/224347712759",
      "checkedAt": "2026-09-20",
      "scope": "기존 위키 조사 자료 · 업무 구조 참고, 국내 법적 기준으로 단정하지 않음"
    }
  ],
  "knowledge": {
    "scope": "menu",
    "topics": [
      "closing"
    ],
    "suggestedUse": "routine",
    "supersededBy": [
      "food/hall-close"
    ]
  }
}
```

## 한식·백반 · 반찬 소분과 배식 준비

```tap2work-tap
{
  "sourceId": "korean/prep",
  "collectionId": "korean",
  "collectionName": "한식·백반",
  "title": "반찬 소분과 배식 준비",
  "slot": "준비",
  "reviewedAt": "2026-09-20",
  "basis": "공개 자료를 참고한 편집 제안 · 현장 검토 필요",
  "steps": [
    {
      "id": "step-1",
      "title": "반찬별 준비량 정하기",
      "manual": "전날 잔량과 오늘 예약을 보고 첫 배식분과 추가분을 나눠 적어요.",
      "tip": "잘 팔리지 않은 반찬까지 같은 양으로 만들지 않아요.",
      "tags": [],
      "sourceUrl": "https://assets.publishing.service.gov.uk/media/69c52a4993cc6e8b87a6f744/sfbb-caterers-separating-foods_2.pdf"
    },
    {
      "id": "step-2",
      "title": "재료 용기 구분하기",
      "manual": "생재료와 배식용 반찬을 분리하고 각 용기에 이름과 준비 시각을 붙여요.",
      "tip": "집게를 다른 반찬에 번갈아 쓰지 않아요.",
      "tags": [],
      "sourceUrl": "https://assets.publishing.service.gov.uk/media/69c52a4993cc6e8b87a6f744/sfbb-caterers-separating-foods_2.pdf"
    },
    {
      "id": "step-3",
      "title": "보충 위치 정하기",
      "manual": "예비분을 지정 보관하고 배식대에는 매장 기준량만 내요. 바닥난 반찬을 바로 찾을 수 있는지 봐요.",
      "tip": "새 반찬을 오래된 잔량 위에 계속 덧붓지 않아요.",
      "tags": [],
      "sourceUrl": "https://assets.publishing.service.gov.uk/media/69c52a4993cc6e8b87a6f744/sfbb-caterers-separating-foods_2.pdf"
    }
  ],
  "industryIds": [
    "food"
  ],
  "purposeId": "production",
  "kind": "operation",
  "summary": "반찬별 준비량 정하기 · 재료 용기 구분하기",
  "applicability": "한식·백반의 해당 작업을 하는 사업장. 현장 절차와 장비 지침에 맞게 조정하세요.",
  "jurisdiction": "출처별 관할 · 운영 참고",
  "keywords": [],
  "references": [
    {
      "title": "기존 체크리스트 원문 1",
      "url": "https://assets.publishing.service.gov.uk/media/69c52a4993cc6e8b87a6f744/sfbb-caterers-separating-foods_2.pdf",
      "checkedAt": "2026-09-20",
      "scope": "기존 위키 조사 자료 · 업무 구조 참고, 국내 법적 기준으로 단정하지 않음"
    }
  ],
  "knowledge": {
    "scope": "menu",
    "topics": [
      "production"
    ],
    "suggestedUse": "reference",
    "useCase": "recipe"
  }
}
```

## 한식·백반 · 국·찌개 잔량 정리

```tap2work-tap
{
  "sourceId": "korean/close",
  "collectionId": "korean",
  "collectionName": "한식·백반",
  "title": "국·찌개 잔량 정리",
  "slot": "마감",
  "reviewedAt": "2026-09-20",
  "basis": "공개 자료를 참고한 편집 제안 · 현장 검토 필요",
  "steps": [
    {
      "id": "step-1",
      "title": "판매 잔량 구분",
      "manual": "냄비별 남은 양과 조리 시각을 적고 보관 가능 여부를 책임자에게 확인해요.",
      "tip": "냄새가 괜찮다는 이유로 보관을 결정하지 않아요.",
      "tags": [],
      "sourceUrl": "https://assets.publishing.service.gov.uk/media/69c52a4993cc6e8b87a6f744/sfbb-caterers-separating-foods_2.pdf"
    },
    {
      "id": "step-2",
      "title": "승인된 냉각 진행",
      "manual": "매장 기준에 맞춰 작은 용기로 나누고 냉각 시작·종료를 기록해요.",
      "tip": "큰 냄비째 두면 중심부가 천천히 식어요.",
      "tags": [],
      "sourceUrl": "https://assets.publishing.service.gov.uk/media/69c52a4993cc6e8b87a6f744/sfbb-caterers-separating-foods_2.pdf"
    },
    {
      "id": "step-3",
      "title": "다음 사용 표시",
      "manual": "품명·조리 시각·사용 기준을 표시해 지정 장소로 옮겨요.",
      "tip": "새로 만든 국과 이전 국의 기록을 섞지 않아요.",
      "tags": [],
      "sourceUrl": "https://assets.publishing.service.gov.uk/media/69c52a4993cc6e8b87a6f744/sfbb-caterers-separating-foods_2.pdf"
    }
  ],
  "industryIds": [
    "food"
  ],
  "purposeId": "closing",
  "kind": "operation",
  "summary": "판매 잔량 구분 · 승인된 냉각 진행",
  "applicability": "한식·백반의 해당 작업을 하는 사업장. 현장 절차와 장비 지침에 맞게 조정하세요.",
  "jurisdiction": "출처별 관할 · 운영 참고",
  "keywords": [],
  "references": [
    {
      "title": "기존 체크리스트 원문 1",
      "url": "https://assets.publishing.service.gov.uk/media/69c52a4993cc6e8b87a6f744/sfbb-caterers-separating-foods_2.pdf",
      "checkedAt": "2026-09-20",
      "scope": "기존 위키 조사 자료 · 업무 구조 참고, 국내 법적 기준으로 단정하지 않음"
    }
  ],
  "knowledge": {
    "scope": "menu",
    "topics": [
      "closing"
    ],
    "suggestedUse": "reference",
    "useCase": "recipe"
  }
}
```

## 분식·김밥 · 김밥 재료 라인 준비

```tap2work-tap
{
  "sourceId": "snack/prep",
  "collectionId": "snack",
  "collectionName": "분식·김밥",
  "title": "김밥 재료 라인 준비",
  "slot": "준비",
  "reviewedAt": "2026-09-20",
  "basis": "공개 자료를 참고한 편집 제안 · 현장 검토 필요",
  "steps": [
    {
      "id": "step-1",
      "title": "속재료 순서 배치",
      "manual": "레시피 순서대로 속재료를 놓고 한 줄 분량을 기준으로 양을 맞춰요.",
      "tip": "손이 교차하지 않도록 많이 쓰는 재료를 가까이 둬요.",
      "tags": [],
      "sourceUrl": "https://assets.publishing.service.gov.uk/media/69c52a4993cc6e8b87a6f744/sfbb-caterers-separating-foods_2.pdf"
    },
    {
      "id": "step-2",
      "title": "조리·비조리 도구 구분",
      "manual": "달걀 등 조리 전 재료와 완성 속재료의 집게·용기를 나눠요.",
      "tip": "같은 도마를 닦지 않고 연속 사용하지 않아요.",
      "tags": [],
      "sourceUrl": "https://assets.publishing.service.gov.uk/media/69c52a4993cc6e8b87a6f744/sfbb-caterers-separating-foods_2.pdf"
    },
    {
      "id": "step-3",
      "title": "소량 생산 기록",
      "manual": "완성 시각과 수량을 남기고 매장이 정한 보관·판매 기준으로 진열해요.",
      "tip": "바쁘기 전에 많이 말아두는 양부터 조절해요.",
      "tags": [],
      "sourceUrl": "https://assets.publishing.service.gov.uk/media/69c52a4993cc6e8b87a6f744/sfbb-caterers-separating-foods_2.pdf"
    }
  ],
  "industryIds": [
    "food"
  ],
  "purposeId": "production",
  "kind": "operation",
  "summary": "속재료 순서 배치 · 조리·비조리 도구 구분",
  "applicability": "분식·김밥의 해당 작업을 하는 사업장. 현장 절차와 장비 지침에 맞게 조정하세요.",
  "jurisdiction": "출처별 관할 · 운영 참고",
  "keywords": [],
  "references": [
    {
      "title": "기존 체크리스트 원문 1",
      "url": "https://assets.publishing.service.gov.uk/media/69c52a4993cc6e8b87a6f744/sfbb-caterers-separating-foods_2.pdf",
      "checkedAt": "2026-09-20",
      "scope": "기존 위키 조사 자료 · 업무 구조 참고, 국내 법적 기준으로 단정하지 않음"
    }
  ],
  "knowledge": {
    "scope": "menu",
    "topics": [
      "production"
    ],
    "suggestedUse": "reference",
    "useCase": "recipe"
  }
}
```

## 분식·김밥 · 떡볶이·튀김 주문 맞추기

```tap2work-tap
{
  "sourceId": "snack/peak",
  "collectionId": "snack",
  "collectionName": "분식·김밥",
  "title": "떡볶이·튀김 주문 맞추기",
  "slot": "피크",
  "reviewedAt": "2026-09-20",
  "basis": "공개 자료를 참고한 편집 제안 · 현장 검토 필요",
  "steps": [
    {
      "id": "step-1",
      "title": "주문 묶음 읽기",
      "manual": "주문 번호별 떡볶이·튀김·음료를 한 줄로 확인해요.",
      "tip": "개수와 인분 표기가 다른 메뉴를 구분해요.",
      "tags": [],
      "sourceUrl": "https://assets.publishing.service.gov.uk/media/69c52a4993cc6e8b87a6f744/sfbb-caterers-separating-foods_2.pdf"
    },
    {
      "id": "step-2",
      "title": "포장 조합 맞추기",
      "manual": "소스·튀김을 매장 포장 기준에 따라 나누고 추가 요청을 표시해요.",
      "tip": "눅눅해지기 쉬운 품목은 출고 직전에 조합해요.",
      "tags": [],
      "sourceUrl": "https://assets.publishing.service.gov.uk/media/69c52a4993cc6e8b87a6f744/sfbb-caterers-separating-foods_2.pdf"
    },
    {
      "id": "step-3",
      "title": "누락 대조",
      "manual": "주문표와 실물을 나란히 놓고 수량·소스·수저를 대조해요.",
      "tip": "봉투를 닫기 전 확인하면 다시 여는 일을 줄여요.",
      "tags": [],
      "sourceUrl": "https://assets.publishing.service.gov.uk/media/69c52a4993cc6e8b87a6f744/sfbb-caterers-separating-foods_2.pdf"
    }
  ],
  "industryIds": [
    "food"
  ],
  "purposeId": "service",
  "kind": "operation",
  "summary": "주문 묶음 읽기 · 포장 조합 맞추기",
  "applicability": "분식·김밥의 해당 작업을 하는 사업장. 현장 절차와 장비 지침에 맞게 조정하세요.",
  "jurisdiction": "출처별 관할 · 운영 참고",
  "keywords": [],
  "references": [
    {
      "title": "기존 체크리스트 원문 1",
      "url": "https://assets.publishing.service.gov.uk/media/69c52a4993cc6e8b87a6f744/sfbb-caterers-separating-foods_2.pdf",
      "checkedAt": "2026-09-20",
      "scope": "기존 위키 조사 자료 · 업무 구조 참고, 국내 법적 기준으로 단정하지 않음"
    }
  ],
  "knowledge": {
    "scope": "menu",
    "topics": [
      "service"
    ],
    "suggestedUse": "reference",
    "useCase": "recipe"
  }
}
```

## 고깃집·구이 · 테이블 구이 준비

```tap2work-tap
{
  "sourceId": "bbq/open",
  "collectionId": "bbq",
  "collectionName": "고깃집·구이",
  "title": "테이블 구이 준비",
  "slot": "오픈",
  "reviewedAt": "2026-09-20",
  "basis": "공개 자료를 참고한 편집 제안 · 현장 검토 필요",
  "steps": [
    {
      "id": "step-1",
      "title": "테이블별 집기 맞추기",
      "manual": "테이블 번호와 예약 인원을 보고 접시·집게·가위 수량을 맞춰요.",
      "tip": "원육용과 먹는 음식용 도구를 구분해 놓아요.",
      "tags": [],
      "sourceUrl": "https://assets.publishing.service.gov.uk/media/69c52a4993cc6e8b87a6f744/sfbb-caterers-separating-foods_2.pdf"
    },
    {
      "id": "step-2",
      "title": "장비 상태 확인",
      "manual": "버디에게 배운 범위에서 후드와 구이 장비의 외관·작동 상태를 확인해요.",
      "tip": "이상 냄새나 손상이 있으면 사용하지 말고 책임자에게 알려요.",
      "tags": [],
      "sourceUrl": "https://assets.publishing.service.gov.uk/media/69c52a4993cc6e8b87a6f744/sfbb-caterers-separating-foods_2.pdf"
    },
    {
      "id": "step-3",
      "title": "원육 보관 점검",
      "manual": "부위·준비 시각을 표시하고 주문에 필요한 분량만 꺼내요.",
      "tip": "테이블 회전 예상만 보고 장시간 상온에 내놓지 않아요.",
      "tags": [],
      "sourceUrl": "https://assets.publishing.service.gov.uk/media/69c52a4993cc6e8b87a6f744/sfbb-caterers-separating-foods_2.pdf"
    }
  ],
  "industryIds": [
    "food"
  ],
  "purposeId": "opening",
  "kind": "operation",
  "summary": "테이블별 집기 맞추기 · 장비 상태 확인",
  "applicability": "고깃집·구이의 해당 작업을 하는 사업장. 현장 절차와 장비 지침에 맞게 조정하세요.",
  "jurisdiction": "출처별 관할 · 운영 참고",
  "keywords": [],
  "references": [
    {
      "title": "기존 체크리스트 원문 1",
      "url": "https://assets.publishing.service.gov.uk/media/69c52a4993cc6e8b87a6f744/sfbb-caterers-separating-foods_2.pdf",
      "checkedAt": "2026-09-20",
      "scope": "기존 위키 조사 자료 · 업무 구조 참고, 국내 법적 기준으로 단정하지 않음"
    }
  ],
  "knowledge": {
    "scope": "menu",
    "topics": [
      "opening"
    ],
    "suggestedUse": "reference",
    "useCase": "recipe"
  }
}
```

## 고깃집·구이 · 구이 주문 인계

```tap2work-tap
{
  "sourceId": "bbq/peak",
  "collectionId": "bbq",
  "collectionName": "고깃집·구이",
  "title": "구이 주문 인계",
  "slot": "피크",
  "reviewedAt": "2026-09-20",
  "basis": "공개 자료를 참고한 편집 제안 · 현장 검토 필요",
  "steps": [
    {
      "id": "step-1",
      "title": "부위·중량 대조",
      "manual": "주문 부위와 레시피 중량을 확인하고 접시별 라벨을 맞춰요.",
      "tip": "비슷한 모양의 부위는 위치로만 구별하지 않아요.",
      "tags": [],
      "sourceUrl": "https://assets.publishing.service.gov.uk/media/69c52a4993cc6e8b87a6f744/sfbb-caterers-separating-foods_2.pdf"
    },
    {
      "id": "step-2",
      "title": "조리 전후 분리",
      "manual": "원육을 올리는 도구와 익은 음식을 옮기는 도구를 분리해요.",
      "tip": "원육 접시를 익은 고기 받침으로 다시 쓰지 않아요.",
      "tags": [],
      "sourceUrl": "https://assets.publishing.service.gov.uk/media/69c52a4993cc6e8b87a6f744/sfbb-caterers-separating-foods_2.pdf"
    },
    {
      "id": "step-3",
      "title": "테이블 확인 후 전달",
      "manual": "테이블 번호와 추가 주문 여부를 확인한 뒤 담당자에게 넘겨요.",
      "tip": "추가분을 첫 주문과 혼동하지 않게 주문 번호도 봐요.",
      "tags": [],
      "sourceUrl": "https://assets.publishing.service.gov.uk/media/69c52a4993cc6e8b87a6f744/sfbb-caterers-separating-foods_2.pdf"
    }
  ],
  "industryIds": [
    "food"
  ],
  "purposeId": "service",
  "kind": "operation",
  "summary": "부위·중량 대조 · 조리 전후 분리",
  "applicability": "고깃집·구이의 해당 작업을 하는 사업장. 현장 절차와 장비 지침에 맞게 조정하세요.",
  "jurisdiction": "출처별 관할 · 운영 참고",
  "keywords": [],
  "references": [
    {
      "title": "기존 체크리스트 원문 1",
      "url": "https://assets.publishing.service.gov.uk/media/69c52a4993cc6e8b87a6f744/sfbb-caterers-separating-foods_2.pdf",
      "checkedAt": "2026-09-20",
      "scope": "기존 위키 조사 자료 · 업무 구조 참고, 국내 법적 기준으로 단정하지 않음"
    }
  ],
  "knowledge": {
    "scope": "menu",
    "topics": [
      "service"
    ],
    "suggestedUse": "reference",
    "useCase": "recipe"
  }
}
```

## 횟집·초밥 · 생식재료 입고 확인

```tap2work-tap
{
  "sourceId": "sushi/prep",
  "collectionId": "sushi",
  "collectionName": "횟집·초밥",
  "title": "생식재료 입고 확인",
  "slot": "준비",
  "reviewedAt": "2026-09-20",
  "basis": "공개 자료를 참고한 편집 제안 · 현장 검토 필요",
  "steps": [
    {
      "id": "step-1",
      "title": "거래 정보 대조",
      "manual": "품목·수량·공급처·입고 시각을 거래 기록과 맞춰요.",
      "tip": "생식용 적합성은 외관만 보고 판단하지 말고 책임자에게 확인해요.",
      "tags": [],
      "sourceUrl": "https://assets.publishing.service.gov.uk/media/69c52a4993cc6e8b87a6f744/sfbb-caterers-separating-foods_2.pdf"
    },
    {
      "id": "step-2",
      "title": "이상 제품 분리",
      "manual": "포장 파손과 보관 상태를 확인하고 의심 제품은 판매 준비와 분리해요.",
      "tip": "반품 예정 제품을 정상 재고와 같은 칸에 두지 않아요.",
      "tags": [],
      "sourceUrl": "https://assets.publishing.service.gov.uk/media/69c52a4993cc6e8b87a6f744/sfbb-caterers-separating-foods_2.pdf"
    },
    {
      "id": "step-3",
      "title": "용도별 보관",
      "manual": "생식용과 가열용을 표시해 지정 보관하고 사용 순서를 정해요.",
      "tip": "먼저 쓰는 제품이 뒤쪽에 가려지지 않게 놓아요.",
      "tags": [],
      "sourceUrl": "https://assets.publishing.service.gov.uk/media/69c52a4993cc6e8b87a6f744/sfbb-caterers-separating-foods_2.pdf"
    }
  ],
  "industryIds": [
    "food"
  ],
  "purposeId": "inventory",
  "kind": "operation",
  "summary": "거래 정보 대조 · 이상 제품 분리",
  "applicability": "횟집·초밥의 해당 작업을 하는 사업장. 현장 절차와 장비 지침에 맞게 조정하세요.",
  "jurisdiction": "출처별 관할 · 운영 참고",
  "keywords": [],
  "references": [
    {
      "title": "기존 체크리스트 원문 1",
      "url": "https://assets.publishing.service.gov.uk/media/69c52a4993cc6e8b87a6f744/sfbb-caterers-separating-foods_2.pdf",
      "checkedAt": "2026-09-20",
      "scope": "기존 위키 조사 자료 · 업무 구조 참고, 국내 법적 기준으로 단정하지 않음"
    }
  ],
  "knowledge": {
    "scope": "menu",
    "topics": [
      "inventory"
    ],
    "suggestedUse": "reference",
    "useCase": "recipe"
  }
}
```

## 횟집·초밥 · 초밥 주문 마무리

```tap2work-tap
{
  "sourceId": "sushi/peak",
  "collectionId": "sushi",
  "collectionName": "횟집·초밥",
  "title": "초밥 주문 마무리",
  "slot": "피크",
  "reviewedAt": "2026-09-20",
  "basis": "공개 자료를 참고한 편집 제안 · 현장 검토 필요",
  "steps": [
    {
      "id": "step-1",
      "title": "주문 구성 대조",
      "manual": "세트별 생선 종류·수량·제외 요청을 확인해요.",
      "tip": "세트 이름이 같아도 옵션이 다를 수 있어요.",
      "tags": [],
      "sourceUrl": "https://assets.publishing.service.gov.uk/media/69c52a4993cc6e8b87a6f744/sfbb-caterers-separating-foods_2.pdf"
    },
    {
      "id": "step-2",
      "title": "전용 작업대 준비",
      "manual": "생식 작업 도구와 다른 재료 도구를 구분하고 사용 전 청결을 확인해요.",
      "tip": "이전 주문의 재료 조각이 남아 있지 않은지 봐요.",
      "tags": [],
      "sourceUrl": "https://assets.publishing.service.gov.uk/media/69c52a4993cc6e8b87a6f744/sfbb-caterers-separating-foods_2.pdf"
    },
    {
      "id": "step-3",
      "title": "완성품 바로 인계",
      "manual": "주문 번호를 붙이고 와사비·소스 포함 여부를 확인해요.",
      "tip": "완성품 대기 시간을 줄이도록 인계할 사람부터 확인해요.",
      "tags": [],
      "sourceUrl": "https://assets.publishing.service.gov.uk/media/69c52a4993cc6e8b87a6f744/sfbb-caterers-separating-foods_2.pdf"
    }
  ],
  "industryIds": [
    "food"
  ],
  "purposeId": "service",
  "kind": "operation",
  "summary": "주문 구성 대조 · 전용 작업대 준비",
  "applicability": "횟집·초밥의 해당 작업을 하는 사업장. 현장 절차와 장비 지침에 맞게 조정하세요.",
  "jurisdiction": "출처별 관할 · 운영 참고",
  "keywords": [],
  "references": [
    {
      "title": "기존 체크리스트 원문 1",
      "url": "https://assets.publishing.service.gov.uk/media/69c52a4993cc6e8b87a6f744/sfbb-caterers-separating-foods_2.pdf",
      "checkedAt": "2026-09-20",
      "scope": "기존 위키 조사 자료 · 업무 구조 참고, 국내 법적 기준으로 단정하지 않음"
    }
  ],
  "knowledge": {
    "scope": "menu",
    "topics": [
      "service"
    ],
    "suggestedUse": "reference",
    "useCase": "recipe"
  }
}
```

## 치킨·튀김 · 튀김 작업 준비

```tap2work-tap
{
  "sourceId": "chicken/prep",
  "collectionId": "chicken",
  "collectionName": "치킨·튀김",
  "title": "튀김 작업 준비",
  "slot": "준비",
  "reviewedAt": "2026-09-20",
  "basis": "공개 자료를 참고한 편집 제안 · 현장 검토 필요",
  "steps": [
    {
      "id": "step-1",
      "title": "작업량과 기기 확인",
      "manual": "주문 예상량을 보고 배치 크기를 정하고 장비 예열 완료를 확인해요.",
      "tip": "한 번에 많이 넣으면 매장 조리 기준을 맞추기 어려워요.",
      "tags": [],
      "sourceUrl": "https://assets.publishing.service.gov.uk/media/69c53918471d520038d0f6d8/sfbb-caterer-cooking-01-cooking-safely_0.pdf"
    },
    {
      "id": "step-2",
      "title": "생재료 도구 분리",
      "manual": "생닭용 집게와 완성품용 집게를 다른 받침에 놓아요.",
      "tip": "손잡이까지 오염되지 않았는지 확인해요.",
      "tags": [],
      "sourceUrl": "https://assets.publishing.service.gov.uk/media/69c53918471d520038d0f6d8/sfbb-caterer-cooking-01-cooking-safely_0.pdf"
    },
    {
      "id": "step-3",
      "title": "기름 주변 통로 정리",
      "manual": "미끄러운 자국과 장애물을 제거하고 안전한 통로를 확보해요.",
      "tip": "기름 처리와 장비 분해는 교육받은 담당자가 해요.",
      "tags": [],
      "sourceUrl": "https://assets.publishing.service.gov.uk/media/69c53918471d520038d0f6d8/sfbb-caterer-cooking-01-cooking-safely_0.pdf"
    }
  ],
  "industryIds": [
    "food"
  ],
  "purposeId": "production",
  "kind": "operation",
  "summary": "작업량과 기기 확인 · 생재료 도구 분리",
  "applicability": "치킨·튀김의 해당 작업을 하는 사업장. 현장 절차와 장비 지침에 맞게 조정하세요.",
  "jurisdiction": "출처별 관할 · 운영 참고",
  "keywords": [],
  "references": [
    {
      "title": "기존 체크리스트 원문 1",
      "url": "https://assets.publishing.service.gov.uk/media/69c53918471d520038d0f6d8/sfbb-caterer-cooking-01-cooking-safely_0.pdf",
      "checkedAt": "2026-09-20",
      "scope": "기존 위키 조사 자료 · 업무 구조 참고, 국내 법적 기준으로 단정하지 않음"
    }
  ],
  "knowledge": {
    "scope": "menu",
    "topics": [
      "production"
    ],
    "suggestedUse": "reference",
    "useCase": "recipe"
  }
}
```

## 치킨·튀김 · 튀김 완성 검수

```tap2work-tap
{
  "sourceId": "chicken/peak",
  "collectionId": "chicken",
  "collectionName": "치킨·튀김",
  "title": "튀김 완성 검수",
  "slot": "피크",
  "reviewedAt": "2026-09-20",
  "basis": "공개 자료를 참고한 편집 제안 · 현장 검토 필요",
  "steps": [
    {
      "id": "step-1",
      "title": "배치 기록 맞추기",
      "manual": "조리 시작 시각과 제품 종류를 배치별로 구분해요.",
      "tip": "서로 다른 배치를 한 타이머로 기억하지 않아요.",
      "tags": [],
      "sourceUrl": "https://assets.publishing.service.gov.uk/media/69c53918471d520038d0f6d8/sfbb-caterer-cooking-01-cooking-safely_0.pdf"
    },
    {
      "id": "step-2",
      "title": "익힘 기준 확인",
      "manual": "매장의 검증된 중심부 확인 방법으로 익힘을 확인하고 미달품은 내보내지 않아요.",
      "tip": "겉색만으로 완성을 결정하지 않아요.",
      "tags": [],
      "sourceUrl": "https://assets.publishing.service.gov.uk/media/69c53918471d520038d0f6d8/sfbb-caterer-cooking-01-cooking-safely_0.pdf"
    },
    {
      "id": "step-3",
      "title": "소스와 주문 대조",
      "manual": "맛·수량·사이드·소스를 주문표와 맞추고 출고해요.",
      "tip": "반반 메뉴는 두 맛의 수량을 각각 봐요.",
      "tags": [],
      "sourceUrl": "https://assets.publishing.service.gov.uk/media/69c53918471d520038d0f6d8/sfbb-caterer-cooking-01-cooking-safely_0.pdf"
    }
  ],
  "industryIds": [
    "food"
  ],
  "purposeId": "service",
  "kind": "operation",
  "summary": "배치 기록 맞추기 · 익힘 기준 확인",
  "applicability": "치킨·튀김의 해당 작업을 하는 사업장. 현장 절차와 장비 지침에 맞게 조정하세요.",
  "jurisdiction": "출처별 관할 · 운영 참고",
  "keywords": [],
  "references": [
    {
      "title": "기존 체크리스트 원문 1",
      "url": "https://assets.publishing.service.gov.uk/media/69c53918471d520038d0f6d8/sfbb-caterer-cooking-01-cooking-safely_0.pdf",
      "checkedAt": "2026-09-20",
      "scope": "기존 위키 조사 자료 · 업무 구조 참고, 국내 법적 기준으로 단정하지 않음"
    }
  ],
  "knowledge": {
    "scope": "menu",
    "topics": [
      "service"
    ],
    "suggestedUse": "reference",
    "useCase": "recipe"
  }
}
```

## 피자·양식 · 토핑·소스 준비

```tap2work-tap
{
  "sourceId": "pizza/prep",
  "collectionId": "pizza",
  "collectionName": "피자·양식",
  "title": "토핑·소스 준비",
  "slot": "준비",
  "reviewedAt": "2026-09-20",
  "basis": "공개 자료를 참고한 편집 제안 · 현장 검토 필요",
  "steps": [
    {
      "id": "step-1",
      "title": "레시피 양 맞추기",
      "manual": "메뉴별 한 판 분량을 저울로 확인하고 계량 도구를 준비해요.",
      "tip": "눈대중 추가 토핑은 원가와 익힘을 함께 바꿔요.",
      "tags": [],
      "sourceUrl": "https://assets.publishing.service.gov.uk/media/69c53918471d520038d0f6d8/sfbb-caterer-cooking-01-cooking-safely_0.pdf"
    },
    {
      "id": "step-2",
      "title": "재료 칸 나누기",
      "manual": "토핑별 집게와 보관 칸을 정하고 품명·사용 기준을 붙여요.",
      "tip": "제외 요청 재료가 다른 칸으로 넘어가지 않게 해요.",
      "tags": [],
      "sourceUrl": "https://assets.publishing.service.gov.uk/media/69c53918471d520038d0f6d8/sfbb-caterer-cooking-01-cooking-safely_0.pdf"
    },
    {
      "id": "step-3",
      "title": "오븐 준비 확인",
      "manual": "모델별 예열과 사용할 도구 상태를 담당자와 확인해요.",
      "tip": "설정 온도와 실제 준비 완료를 같은 것으로 보지 않아요.",
      "tags": [],
      "sourceUrl": "https://assets.publishing.service.gov.uk/media/69c53918471d520038d0f6d8/sfbb-caterer-cooking-01-cooking-safely_0.pdf"
    }
  ],
  "industryIds": [
    "food"
  ],
  "purposeId": "production",
  "kind": "operation",
  "summary": "레시피 양 맞추기 · 재료 칸 나누기",
  "applicability": "피자·양식의 해당 작업을 하는 사업장. 현장 절차와 장비 지침에 맞게 조정하세요.",
  "jurisdiction": "출처별 관할 · 운영 참고",
  "keywords": [],
  "references": [
    {
      "title": "기존 체크리스트 원문 1",
      "url": "https://assets.publishing.service.gov.uk/media/69c53918471d520038d0f6d8/sfbb-caterer-cooking-01-cooking-safely_0.pdf",
      "checkedAt": "2026-09-20",
      "scope": "기존 위키 조사 자료 · 업무 구조 참고, 국내 법적 기준으로 단정하지 않음"
    }
  ],
  "knowledge": {
    "scope": "menu",
    "topics": [
      "production"
    ],
    "suggestedUse": "reference",
    "useCase": "recipe"
  }
}
```

## 피자·양식 · 피자 포장 검수

```tap2work-tap
{
  "sourceId": "pizza/peak",
  "collectionId": "pizza",
  "collectionName": "피자·양식",
  "title": "피자 포장 검수",
  "slot": "피크",
  "reviewedAt": "2026-09-20",
  "basis": "공개 자료를 참고한 편집 제안 · 현장 검토 필요",
  "steps": [
    {
      "id": "step-1",
      "title": "사이즈·옵션 확인",
      "manual": "주문 번호별 크기와 도우·추가·제외 토핑을 대조해요.",
      "tip": "같은 메뉴라도 도우가 다른 주문을 나란히 구분해요.",
      "tags": [],
      "sourceUrl": "https://assets.publishing.service.gov.uk/media/69c53918471d520038d0f6d8/sfbb-caterer-cooking-01-cooking-safely_0.pdf"
    },
    {
      "id": "step-2",
      "title": "완성 기준 확인",
      "manual": "매장 레시피의 익힘과 커팅 기준을 확인하고 조각 수를 맞춰요.",
      "tip": "박스를 닫기 전에 빠진 토핑을 봐요.",
      "tags": [],
      "sourceUrl": "https://assets.publishing.service.gov.uk/media/69c53918471d520038d0f6d8/sfbb-caterer-cooking-01-cooking-safely_0.pdf"
    },
    {
      "id": "step-3",
      "title": "구성품 넣기",
      "manual": "소스·피클·음료를 주문표와 맞추고 운반 중 흐르지 않게 담아요.",
      "tip": "뜨거운 음식과 차가운 음료는 포장 기준에 따라 분리해요.",
      "tags": [],
      "sourceUrl": "https://assets.publishing.service.gov.uk/media/69c53918471d520038d0f6d8/sfbb-caterer-cooking-01-cooking-safely_0.pdf"
    }
  ],
  "industryIds": [
    "food"
  ],
  "purposeId": "service",
  "kind": "operation",
  "summary": "사이즈·옵션 확인 · 완성 기준 확인",
  "applicability": "피자·양식의 해당 작업을 하는 사업장. 현장 절차와 장비 지침에 맞게 조정하세요.",
  "jurisdiction": "출처별 관할 · 운영 참고",
  "keywords": [],
  "references": [
    {
      "title": "기존 체크리스트 원문 1",
      "url": "https://assets.publishing.service.gov.uk/media/69c53918471d520038d0f6d8/sfbb-caterer-cooking-01-cooking-safely_0.pdf",
      "checkedAt": "2026-09-20",
      "scope": "기존 위키 조사 자료 · 업무 구조 참고, 국내 법적 기준으로 단정하지 않음"
    }
  ],
  "knowledge": {
    "scope": "menu",
    "topics": [
      "service"
    ],
    "suggestedUse": "reference",
    "useCase": "recipe"
  }
}
```

## 중식·면요리 · 면·소스 준비량 맞추기

```tap2work-tap
{
  "sourceId": "chinese/prep",
  "collectionId": "chinese",
  "collectionName": "중식·면요리",
  "title": "면·소스 준비량 맞추기",
  "slot": "준비",
  "reviewedAt": "2026-09-20",
  "basis": "공개 자료를 참고한 편집 제안 · 현장 검토 필요",
  "steps": [
    {
      "id": "step-1",
      "title": "메뉴별 소분",
      "manual": "면과 소스를 매장 레시피 분량으로 나누고 품명·준비 시각을 적어요.",
      "tip": "예상 주문이 적은 메뉴는 처음부터 많이 만들지 않아요.",
      "tags": [],
      "sourceUrl": "https://assets.publishing.service.gov.uk/media/69c52a4993cc6e8b87a6f744/sfbb-caterers-separating-foods_2.pdf"
    },
    {
      "id": "step-2",
      "title": "전용 도구 배치",
      "manual": "생육·해산물·완성 소스의 도구를 구분해 놓아요.",
      "tip": "작업대가 좁으면 시간대를 나누고 사이에 세척해요.",
      "tags": [],
      "sourceUrl": "https://assets.publishing.service.gov.uk/media/69c52a4993cc6e8b87a6f744/sfbb-caterers-separating-foods_2.pdf"
    },
    {
      "id": "step-3",
      "title": "예비분 보관",
      "manual": "바로 쓸 양과 냉장 보관할 양을 나누고 사용 순서를 맞춰요.",
      "tip": "오래된 소스 위에 새 소스를 덧채우지 않아요.",
      "tags": [],
      "sourceUrl": "https://assets.publishing.service.gov.uk/media/69c52a4993cc6e8b87a6f744/sfbb-caterers-separating-foods_2.pdf"
    }
  ],
  "industryIds": [
    "food"
  ],
  "purposeId": "production",
  "kind": "operation",
  "summary": "메뉴별 소분 · 전용 도구 배치",
  "applicability": "중식·면요리의 해당 작업을 하는 사업장. 현장 절차와 장비 지침에 맞게 조정하세요.",
  "jurisdiction": "출처별 관할 · 운영 참고",
  "keywords": [],
  "references": [
    {
      "title": "기존 체크리스트 원문 1",
      "url": "https://assets.publishing.service.gov.uk/media/69c52a4993cc6e8b87a6f744/sfbb-caterers-separating-foods_2.pdf",
      "checkedAt": "2026-09-20",
      "scope": "기존 위키 조사 자료 · 업무 구조 참고, 국내 법적 기준으로 단정하지 않음"
    }
  ],
  "knowledge": {
    "scope": "menu",
    "topics": [
      "production"
    ],
    "suggestedUse": "reference",
    "useCase": "recipe"
  }
}
```

## 중식·면요리 · 배달 면요리 조합

```tap2work-tap
{
  "sourceId": "chinese/peak",
  "collectionId": "chinese",
  "collectionName": "중식·면요리",
  "title": "배달 면요리 조합",
  "slot": "피크",
  "reviewedAt": "2026-09-20",
  "basis": "공개 자료를 참고한 편집 제안 · 현장 검토 필요",
  "steps": [
    {
      "id": "step-1",
      "title": "동시 출고 묶기",
      "manual": "주문 번호별 면·요리·밥의 완성 순서를 담당자와 맞춰요.",
      "tip": "면이 먼저 완성되어 오래 기다리지 않게 해요.",
      "tags": [],
      "sourceUrl": "https://assets.publishing.service.gov.uk/media/69c52a4993cc6e8b87a6f744/sfbb-caterers-separating-foods_2.pdf"
    },
    {
      "id": "step-2",
      "title": "국물·면 포장 확인",
      "manual": "메뉴별 분리 포장 기준과 뚜껑 밀착 상태를 확인해요.",
      "tip": "뜨거운 용기를 잡는 방법도 먼저 익혀요.",
      "tags": [],
      "sourceUrl": "https://assets.publishing.service.gov.uk/media/69c52a4993cc6e8b87a6f744/sfbb-caterers-separating-foods_2.pdf"
    },
    {
      "id": "step-3",
      "title": "묶음 대조",
      "manual": "메뉴 수·단무지·소스·추가 요청을 확인하고 한 주문으로 묶어요.",
      "tip": "두 주문의 비슷한 용기를 바꿔 담지 않도록 번호를 붙여요.",
      "tags": [],
      "sourceUrl": "https://assets.publishing.service.gov.uk/media/69c52a4993cc6e8b87a6f744/sfbb-caterers-separating-foods_2.pdf"
    }
  ],
  "industryIds": [
    "food"
  ],
  "purposeId": "service",
  "kind": "operation",
  "summary": "동시 출고 묶기 · 국물·면 포장 확인",
  "applicability": "중식·면요리의 해당 작업을 하는 사업장. 현장 절차와 장비 지침에 맞게 조정하세요.",
  "jurisdiction": "출처별 관할 · 운영 참고",
  "keywords": [],
  "references": [
    {
      "title": "기존 체크리스트 원문 1",
      "url": "https://assets.publishing.service.gov.uk/media/69c52a4993cc6e8b87a6f744/sfbb-caterers-separating-foods_2.pdf",
      "checkedAt": "2026-09-20",
      "scope": "기존 위키 조사 자료 · 업무 구조 참고, 국내 법적 기준으로 단정하지 않음"
    }
  ],
  "knowledge": {
    "scope": "menu",
    "topics": [
      "service"
    ],
    "suggestedUse": "reference",
    "useCase": "recipe"
  }
}
```

## 카페·커피 · 음료 레시피 맞추기

```tap2work-tap
{
  "sourceId": "cafe/open",
  "collectionId": "cafe",
  "collectionName": "카페·커피",
  "title": "음료 레시피 맞추기",
  "slot": "오픈",
  "reviewedAt": "2026-09-20",
  "basis": "공개 자료를 참고한 편집 제안 · 현장 검토 필요",
  "steps": [
    {
      "id": "step-1",
      "title": "오늘의 기준 준비",
      "manual": "원두·우유·시럽 재고와 메뉴별 레시피를 확인해요.",
      "tip": "새 봉지를 열면 이전 재료와 섞기 전에 표시를 확인해요.",
      "tags": [],
      "sourceUrl": "https://us.jura.com/en/customer-advice/optimum-maintenance/faq"
    },
    {
      "id": "step-2",
      "title": "테스트 음료 확인",
      "manual": "매장 기준량과 추출 결과를 담당자와 확인하고 변경 설정을 기록해요.",
      "tip": "추출 설정을 여러 개 동시에 바꾸지 말고 원인을 확인해요.",
      "tags": [],
      "sourceUrl": "https://us.jura.com/en/customer-advice/optimum-maintenance/faq"
    },
    {
      "id": "step-3",
      "title": "우유별 도구 구분",
      "manual": "우유와 대체 음료의 용기를 표시하고 요청 대응 방법을 맞춰요.",
      "tip": "대체 우유 사용만으로 알레르기 대응을 보장하지 않아요.",
      "tags": [],
      "sourceUrl": "https://us.jura.com/en/customer-advice/optimum-maintenance/faq"
    }
  ],
  "industryIds": [
    "food"
  ],
  "purposeId": "opening",
  "kind": "operation",
  "summary": "오늘의 기준 준비 · 테스트 음료 확인",
  "applicability": "카페·커피의 해당 작업을 하는 사업장. 현장 절차와 장비 지침에 맞게 조정하세요.",
  "jurisdiction": "출처별 관할 · 운영 참고",
  "keywords": [],
  "references": [
    {
      "title": "기존 체크리스트 원문 1",
      "url": "https://us.jura.com/en/customer-advice/optimum-maintenance/faq",
      "checkedAt": "2026-09-20",
      "scope": "기존 위키 조사 자료 · 업무 구조 참고, 국내 법적 기준으로 단정하지 않음"
    }
  ],
  "knowledge": {
    "scope": "menu",
    "topics": [
      "opening"
    ],
    "suggestedUse": "reference",
    "useCase": "recipe"
  }
}
```

## 카페·커피 · 우유 회로와 음료대 마감

```tap2work-tap
{
  "sourceId": "cafe/close",
  "collectionId": "cafe",
  "collectionName": "카페·커피",
  "title": "우유 회로와 음료대 마감",
  "slot": "마감",
  "reviewedAt": "2026-09-20",
  "basis": "공개 자료를 참고한 편집 제안 · 현장 검토 필요",
  "steps": [
    {
      "id": "step-1",
      "title": "모델별 관리 절차 열기",
      "manual": "설치된 머신의 설명서에서 우유 회로 관리와 사용할 제품을 확인해요.",
      "tip": "JURA 자료의 절차를 다른 모델에 그대로 쓰지 않아요.",
      "tags": [],
      "sourceUrl": "https://us.jura.com/en/customer-advice/optimum-maintenance/faq"
    },
    {
      "id": "step-2",
      "title": "세척 프로그램 완료",
      "manual": "해당 기기 지침에 따라 세척·헹굼을 끝내고 완료 표시를 확인해요.",
      "tip": "자동 헹굼만으로 모든 우유 잔여가 제거됐다고 보지 않아요.",
      "tags": [],
      "sourceUrl": "https://us.jura.com/en/customer-advice/optimum-maintenance/faq"
    },
    {
      "id": "step-3",
      "title": "다음 오픈 인계",
      "manual": "관리 완료 시각과 이상 증상·소모품 부족을 남기고 바를 정리해요.",
      "tip": "추출 불량을 다음 사람이 처음부터 다시 찾지 않도록 기록해요.",
      "tags": [],
      "sourceUrl": "https://us.jura.com/en/customer-advice/optimum-maintenance/faq"
    }
  ],
  "industryIds": [
    "food"
  ],
  "purposeId": "closing",
  "kind": "operation",
  "summary": "모델별 관리 절차 열기 · 세척 프로그램 완료",
  "applicability": "카페·커피의 해당 작업을 하는 사업장. 현장 절차와 장비 지침에 맞게 조정하세요.",
  "jurisdiction": "출처별 관할 · 운영 참고",
  "keywords": [],
  "references": [
    {
      "title": "기존 체크리스트 원문 1",
      "url": "https://us.jura.com/en/customer-advice/optimum-maintenance/faq",
      "checkedAt": "2026-09-20",
      "scope": "기존 위키 조사 자료 · 업무 구조 참고, 국내 법적 기준으로 단정하지 않음"
    }
  ],
  "knowledge": {
    "scope": "menu",
    "topics": [
      "closing"
    ],
    "suggestedUse": "reference",
    "useCase": "recipe"
  }
}
```

## 베이커리·제과 · 반죽 계량과 배치 준비

```tap2work-tap
{
  "sourceId": "bakery/prep",
  "collectionId": "bakery",
  "collectionName": "베이커리·제과",
  "title": "반죽 계량과 배치 준비",
  "slot": "준비",
  "reviewedAt": "2026-09-20",
  "basis": "공개 자료를 참고한 편집 제안 · 현장 검토 필요",
  "steps": [
    {
      "id": "step-1",
      "title": "배치별 재료 계량",
      "manual": "레시피 배수와 재료 중량을 확인하고 계량 완료 표시를 해요.",
      "tip": "소금·이스트처럼 적은 재료도 생략하지 않아요.",
      "tags": [],
      "sourceUrl": "https://www.hse.gov.uk/coshh/industry/baking.htm"
    },
    {
      "id": "step-2",
      "title": "가루 날림 줄이기",
      "manual": "가루를 낮은 위치에서 조심히 붓고 매장 집진·청소 절차를 따라요.",
      "tip": "분진을 날리는 마른 쓸기보다 적합한 청소 방법을 써요.",
      "tags": [],
      "sourceUrl": "https://www.hse.gov.uk/coshh/industry/baking.htm"
    },
    {
      "id": "step-3",
      "title": "배치 표기",
      "manual": "반죽 이름·시작 시각·담당을 표시하고 발효 상태를 매장 기준과 대조해요.",
      "tip": "시간만 맞고 상태가 다른 배치는 책임자에게 확인해요.",
      "tags": [],
      "sourceUrl": "https://www.hse.gov.uk/coshh/industry/baking.htm"
    }
  ],
  "industryIds": [
    "food"
  ],
  "purposeId": "production",
  "kind": "operation",
  "summary": "배치별 재료 계량 · 가루 날림 줄이기",
  "applicability": "베이커리·제과의 해당 작업을 하는 사업장. 현장 절차와 장비 지침에 맞게 조정하세요.",
  "jurisdiction": "출처별 관할 · 운영 참고",
  "keywords": [],
  "references": [
    {
      "title": "기존 체크리스트 원문 1",
      "url": "https://www.hse.gov.uk/coshh/industry/baking.htm",
      "checkedAt": "2026-09-20",
      "scope": "기존 위키 조사 자료 · 업무 구조 참고, 국내 법적 기준으로 단정하지 않음"
    }
  ],
  "knowledge": {
    "scope": "menu",
    "topics": [
      "production"
    ],
    "suggestedUse": "reference",
    "useCase": "recipe"
  }
}
```

## 베이커리·제과 · 굽기와 판매 진열

```tap2work-tap
{
  "sourceId": "bakery/peak",
  "collectionId": "bakery",
  "collectionName": "베이커리·제과",
  "title": "굽기와 판매 진열",
  "slot": "피크",
  "reviewedAt": "2026-09-20",
  "basis": "공개 자료를 참고한 편집 제안 · 현장 검토 필요",
  "steps": [
    {
      "id": "step-1",
      "title": "오븐·트레이 대조",
      "manual": "메뉴별 예열과 트레이 수량을 확인하고 배치가 섞이지 않게 해요.",
      "tip": "크기와 수량이 바뀌면 같은 굽기 시간이 맞는지 확인해요.",
      "tags": [],
      "sourceUrl": "https://www.hse.gov.uk/coshh/industry/baking.htm"
    },
    {
      "id": "step-2",
      "title": "완제품 검수",
      "manual": "매장 기준 색·형태·익힘을 확인하고 불량품을 분리해요.",
      "tip": "불량 이유를 남기면 다음 배치를 조절하기 쉬워요.",
      "tags": [],
      "sourceUrl": "https://www.hse.gov.uk/coshh/industry/baking.htm"
    },
    {
      "id": "step-3",
      "title": "진열 카드 맞추기",
      "manual": "품명·가격·원재료 안내를 제품 위치와 맞추고 생산 순서로 놓아요.",
      "tip": "비슷한 빵의 집게와 제품 카드가 바뀌지 않게 해요.",
      "tags": [],
      "sourceUrl": "https://www.hse.gov.uk/coshh/industry/baking.htm"
    }
  ],
  "industryIds": [
    "food"
  ],
  "purposeId": "service",
  "kind": "operation",
  "summary": "오븐·트레이 대조 · 완제품 검수",
  "applicability": "베이커리·제과의 해당 작업을 하는 사업장. 현장 절차와 장비 지침에 맞게 조정하세요.",
  "jurisdiction": "출처별 관할 · 운영 참고",
  "keywords": [],
  "references": [
    {
      "title": "기존 체크리스트 원문 1",
      "url": "https://www.hse.gov.uk/coshh/industry/baking.htm",
      "checkedAt": "2026-09-20",
      "scope": "기존 위키 조사 자료 · 업무 구조 참고, 국내 법적 기준으로 단정하지 않음"
    }
  ],
  "knowledge": {
    "scope": "menu",
    "topics": [
      "service"
    ],
    "suggestedUse": "reference",
    "useCase": "recipe"
  }
}
```

## 배달·포장 전문점 · 주문 접수 준비

```tap2work-tap
{
  "sourceId": "delivery/open",
  "collectionId": "delivery",
  "collectionName": "배달·포장 전문점",
  "title": "주문 접수 준비",
  "slot": "오픈",
  "reviewedAt": "2026-09-20",
  "basis": "공개 자료를 참고한 편집 제안 · 현장 검토 필요",
  "steps": [
    {
      "id": "step-1",
      "title": "판매 가능 메뉴 확인",
      "manual": "재료 잔량과 준비 상태를 보고 품절 메뉴를 판매 채널 담당자에게 알려요.",
      "tip": "앱에 판매중인 메뉴와 주방 준비 상태가 같은지 봐요.",
      "tags": [],
      "sourceUrl": "https://www.gov.uk/government/publications/food-safety-for-food-delivery/food-safety-for-food-delivery"
    },
    {
      "id": "step-2",
      "title": "옵션 표준 확인",
      "manual": "맵기·제외·추가 옵션의 표시 위치를 팀과 맞춰요.",
      "tip": "요청사항을 구두 전달만 하지 않아요.",
      "tags": [],
      "sourceUrl": "https://www.gov.uk/government/publications/food-safety-for-food-delivery/food-safety-for-food-delivery"
    },
    {
      "id": "step-3",
      "title": "포장재 준비",
      "manual": "메뉴별 용기·봉투·라벨을 주문 동선에 맞춰 준비해요.",
      "tip": "용기 크기가 맞지 않으면 피크에 재포장하게 돼요.",
      "tags": [],
      "sourceUrl": "https://www.gov.uk/government/publications/food-safety-for-food-delivery/food-safety-for-food-delivery"
    }
  ],
  "industryIds": [
    "food"
  ],
  "purposeId": "opening",
  "kind": "operation",
  "summary": "판매 가능 메뉴 확인 · 옵션 표준 확인",
  "applicability": "배달·포장 전문점의 해당 작업을 하는 사업장. 현장 절차와 장비 지침에 맞게 조정하세요.",
  "jurisdiction": "출처별 관할 · 운영 참고",
  "keywords": [],
  "references": [
    {
      "title": "기존 체크리스트 원문 1",
      "url": "https://www.gov.uk/government/publications/food-safety-for-food-delivery/food-safety-for-food-delivery",
      "checkedAt": "2026-09-20",
      "scope": "기존 위키 조사 자료 · 업무 구조 참고, 국내 법적 기준으로 단정하지 않음"
    }
  ],
  "knowledge": {
    "scope": "menu",
    "topics": [
      "opening"
    ],
    "suggestedUse": "routine"
  }
}
```

## 배달·포장 전문점 · 기사 인계 전 검수

```tap2work-tap
{
  "sourceId": "delivery/peak",
  "collectionId": "delivery",
  "collectionName": "배달·포장 전문점",
  "title": "기사 인계 전 검수",
  "slot": "피크",
  "reviewedAt": "2026-09-20",
  "basis": "공개 자료를 참고한 편집 제안 · 현장 검토 필요",
  "steps": [
    {
      "id": "step-1",
      "title": "주문 번호 대조",
      "manual": "음식과 주문표의 메뉴·수량·옵션을 확인해요.",
      "tip": "같은 이름의 두 주문도 번호로 구분해요.",
      "tags": [],
      "sourceUrl": "https://www.gov.uk/government/publications/food-safety-for-food-delivery/food-safety-for-food-delivery"
    },
    {
      "id": "step-2",
      "title": "밀봉과 온도 구분",
      "manual": "새지 않게 밀봉하고 냉장·보온 필요 음식을 매장 운반 기준으로 포장해요.",
      "tip": "알레르기 관련 요청은 내용과 포장을 따로 확인해요.",
      "tags": [],
      "sourceUrl": "https://www.gov.uk/government/publications/food-safety-for-food-delivery/food-safety-for-food-delivery"
    },
    {
      "id": "step-3",
      "title": "인계 확인",
      "manual": "기사에게 전달할 주문 번호를 대조하고 인계 시각을 기록해요.",
      "tip": "조리 완료와 실제 인계는 다른 단계예요.",
      "tags": [],
      "sourceUrl": "https://www.gov.uk/government/publications/food-safety-for-food-delivery/food-safety-for-food-delivery"
    }
  ],
  "industryIds": [
    "food"
  ],
  "purposeId": "service",
  "kind": "operation",
  "summary": "주문 번호 대조 · 밀봉과 온도 구분",
  "applicability": "배달·포장 전문점의 해당 작업을 하는 사업장. 현장 절차와 장비 지침에 맞게 조정하세요.",
  "jurisdiction": "출처별 관할 · 운영 참고",
  "keywords": [],
  "references": [
    {
      "title": "기존 체크리스트 원문 1",
      "url": "https://www.gov.uk/government/publications/food-safety-for-food-delivery/food-safety-for-food-delivery",
      "checkedAt": "2026-09-20",
      "scope": "기존 위키 조사 자료 · 업무 구조 참고, 국내 법적 기준으로 단정하지 않음"
    }
  ],
  "knowledge": {
    "scope": "menu",
    "topics": [
      "service"
    ],
    "suggestedUse": "routine"
  }
}
```

## 반찬·도시락 · 도시락 배치 준비

```tap2work-tap
{
  "sourceId": "banchan/prep",
  "collectionId": "banchan",
  "collectionName": "반찬·도시락",
  "title": "도시락 배치 준비",
  "slot": "준비",
  "reviewedAt": "2026-09-20",
  "basis": "공개 자료를 참고한 편집 제안 · 현장 검토 필요",
  "steps": [
    {
      "id": "step-1",
      "title": "수량표 만들기",
      "manual": "예약 수량과 추가 여유분을 구분하고 용기 수를 먼저 맞춰요.",
      "tip": "반찬별 양이 달라지지 않게 계량 도구를 준비해요.",
      "tags": [],
      "sourceUrl": "https://assets.publishing.service.gov.uk/media/69c52a4993cc6e8b87a6f744/sfbb-caterers-separating-foods_2.pdf"
    },
    {
      "id": "step-2",
      "title": "구성표대로 담기",
      "manual": "반찬별 전용 도구를 쓰고 메뉴 구성표와 각 칸을 대조해요.",
      "tip": "빠진 칸을 찾기 쉬우려면 담는 순서를 고정해요.",
      "tags": [],
      "sourceUrl": "https://assets.publishing.service.gov.uk/media/69c52a4993cc6e8b87a6f744/sfbb-caterers-separating-foods_2.pdf"
    },
    {
      "id": "step-3",
      "title": "생산 정보 붙이기",
      "manual": "제품명·준비 시각·보관과 사용 안내를 매장 기준으로 표시해요.",
      "tip": "스티커를 미리 많이 인쇄하면 다른 배치에 잘못 붙이기 쉬워요.",
      "tags": [],
      "sourceUrl": "https://assets.publishing.service.gov.uk/media/69c52a4993cc6e8b87a6f744/sfbb-caterers-separating-foods_2.pdf"
    }
  ],
  "industryIds": [
    "food"
  ],
  "purposeId": "production",
  "kind": "operation",
  "summary": "수량표 만들기 · 구성표대로 담기",
  "applicability": "반찬·도시락의 해당 작업을 하는 사업장. 현장 절차와 장비 지침에 맞게 조정하세요.",
  "jurisdiction": "출처별 관할 · 운영 참고",
  "keywords": [],
  "references": [
    {
      "title": "기존 체크리스트 원문 1",
      "url": "https://assets.publishing.service.gov.uk/media/69c52a4993cc6e8b87a6f744/sfbb-caterers-separating-foods_2.pdf",
      "checkedAt": "2026-09-20",
      "scope": "기존 위키 조사 자료 · 업무 구조 참고, 국내 법적 기준으로 단정하지 않음"
    }
  ],
  "knowledge": {
    "scope": "menu",
    "topics": [
      "production"
    ],
    "suggestedUse": "reference",
    "useCase": "recipe"
  }
}
```

## 반찬·도시락 · 남은 반찬 정리

```tap2work-tap
{
  "sourceId": "banchan/close",
  "collectionId": "banchan",
  "collectionName": "반찬·도시락",
  "title": "남은 반찬 정리",
  "slot": "마감",
  "reviewedAt": "2026-09-20",
  "basis": "공개 자료를 참고한 편집 제안 · 현장 검토 필요",
  "steps": [
    {
      "id": "step-1",
      "title": "잔량과 이유 기록",
      "manual": "제품별 판매·잔량·폐기 이유를 구분해 적어요.",
      "tip": "잔량이 많으면 가격보다 먼저 준비량과 진열 시간을 봐요.",
      "tags": [],
      "sourceUrl": "https://assets.publishing.service.gov.uk/media/69c52a4993cc6e8b87a6f744/sfbb-caterers-separating-foods_2.pdf"
    },
    {
      "id": "step-2",
      "title": "보관 가능분 확인",
      "manual": "책임자가 승인한 것만 정해진 냉각·보관 절차로 옮겨요.",
      "tip": "진열했던 식품을 새 제품과 합치지 않아요.",
      "tags": [],
      "sourceUrl": "https://assets.publishing.service.gov.uk/media/69c52a4993cc6e8b87a6f744/sfbb-caterers-separating-foods_2.pdf"
    },
    {
      "id": "step-3",
      "title": "다음 준비량 조정",
      "manual": "요일·예약과 잔량 기록을 보고 내일 첫 생산량을 적어요.",
      "tip": "오늘 한 번의 과부족으로 모든 메뉴 양을 바꾸지 않아요.",
      "tags": [],
      "sourceUrl": "https://assets.publishing.service.gov.uk/media/69c52a4993cc6e8b87a6f744/sfbb-caterers-separating-foods_2.pdf"
    }
  ],
  "industryIds": [
    "food"
  ],
  "purposeId": "closing",
  "kind": "operation",
  "summary": "잔량과 이유 기록 · 보관 가능분 확인",
  "applicability": "반찬·도시락의 해당 작업을 하는 사업장. 현장 절차와 장비 지침에 맞게 조정하세요.",
  "jurisdiction": "출처별 관할 · 운영 참고",
  "keywords": [],
  "references": [
    {
      "title": "기존 체크리스트 원문 1",
      "url": "https://assets.publishing.service.gov.uk/media/69c52a4993cc6e8b87a6f744/sfbb-caterers-separating-foods_2.pdf",
      "checkedAt": "2026-09-20",
      "scope": "기존 위키 조사 자료 · 업무 구조 참고, 국내 법적 기준으로 단정하지 않음"
    }
  ],
  "knowledge": {
    "scope": "menu",
    "topics": [
      "closing"
    ],
    "suggestedUse": "reference",
    "useCase": "recipe"
  }
}
```

## 주점·바 · 바·홀 오픈 준비

```tap2work-tap
{
  "sourceId": "pub/open",
  "collectionId": "pub",
  "collectionName": "주점·바",
  "title": "바·홀 오픈 준비",
  "slot": "오픈",
  "reviewedAt": "2026-09-20",
  "basis": "공개 자료를 참고한 편집 제안 · 현장 검토 필요",
  "steps": [
    {
      "id": "step-1",
      "title": "잔과 도구 점검",
      "manual": "메뉴에 필요한 잔·오프너·계량 도구를 세고 깨짐과 오염을 봐요.",
      "tip": "금이 간 잔은 세척해 다시 쓰지 말고 분리해요.",
      "tags": [],
      "sourceUrl": "https://assets.publishing.service.gov.uk/media/69c52c9f93cc6e8b87a6f747/sfbb-chinese-cleaning-02-cleaning-effectively.pdf"
    },
    {
      "id": "step-2",
      "title": "음료 레시피 확인",
      "manual": "메뉴별 계량량과 가니시 준비량을 확인해요.",
      "tip": "계량 없이 따르는 습관은 맛과 재고를 동시에 흔들어요.",
      "tags": [],
      "sourceUrl": "https://assets.publishing.service.gov.uk/media/69c52c9f93cc6e8b87a6f747/sfbb-chinese-cleaning-02-cleaning-effectively.pdf"
    },
    {
      "id": "step-3",
      "title": "통로 확보",
      "manual": "테이블 사이 장애물과 바닥 물기를 없애고 서빙 동선을 확인해요.",
      "tip": "박스를 임시로 놓은 자리가 계속 통로를 막지 않게 해요.",
      "tags": [],
      "sourceUrl": "https://assets.publishing.service.gov.uk/media/69c52c9f93cc6e8b87a6f747/sfbb-chinese-cleaning-02-cleaning-effectively.pdf"
    }
  ],
  "industryIds": [
    "food"
  ],
  "purposeId": "opening",
  "kind": "operation",
  "summary": "잔과 도구 점검 · 음료 레시피 확인",
  "applicability": "주점·바의 해당 작업을 하는 사업장. 현장 절차와 장비 지침에 맞게 조정하세요.",
  "jurisdiction": "출처별 관할 · 운영 참고",
  "keywords": [],
  "references": [
    {
      "title": "기존 체크리스트 원문 1",
      "url": "https://assets.publishing.service.gov.uk/media/69c52c9f93cc6e8b87a6f747/sfbb-chinese-cleaning-02-cleaning-effectively.pdf",
      "checkedAt": "2026-09-20",
      "scope": "기존 위키 조사 자료 · 업무 구조 참고, 국내 법적 기준으로 단정하지 않음"
    }
  ],
  "knowledge": {
    "scope": "menu",
    "topics": [
      "opening"
    ],
    "suggestedUse": "routine"
  }
}
```

## 주점·바 · 잔·재고 인수인계

```tap2work-tap
{
  "sourceId": "pub/close",
  "collectionId": "pub",
  "collectionName": "주점·바",
  "title": "잔·재고 인수인계",
  "slot": "마감",
  "reviewedAt": "2026-09-20",
  "basis": "공개 자료를 참고한 편집 제안 · 현장 검토 필요",
  "steps": [
    {
      "id": "step-1",
      "title": "파손 잔 분리",
      "manual": "파손 여부를 밝은 곳에서 확인하고 지정 용기에 처리해요.",
      "tip": "깨진 유리가 있는 구역은 맨손으로 쓸지 않아요.",
      "tags": [],
      "sourceUrl": "https://assets.publishing.service.gov.uk/media/69c52c9f93cc6e8b87a6f747/sfbb-chinese-cleaning-02-cleaning-effectively.pdf"
    },
    {
      "id": "step-2",
      "title": "음료 잔량 확인",
      "manual": "주요 병의 남은 양을 매장 단위로 기록하고 미개봉 재고와 구분해요.",
      "tip": "대략 한 병이라는 표현 대신 같은 단위를 써요.",
      "tags": [],
      "sourceUrl": "https://assets.publishing.service.gov.uk/media/69c52c9f93cc6e8b87a6f747/sfbb-chinese-cleaning-02-cleaning-effectively.pdf"
    },
    {
      "id": "step-3",
      "title": "마감 이상 기록",
      "manual": "누락 주문·파손·소모품 부족을 다음 담당에게 남겨요.",
      "tip": "정산 자료에 실제 고객 정보를 넣어 공유하지 않아요.",
      "tags": [],
      "sourceUrl": "https://assets.publishing.service.gov.uk/media/69c52c9f93cc6e8b87a6f747/sfbb-chinese-cleaning-02-cleaning-effectively.pdf"
    }
  ],
  "industryIds": [
    "food"
  ],
  "purposeId": "inventory",
  "kind": "operation",
  "summary": "파손 잔 분리 · 음료 잔량 확인",
  "applicability": "주점·바의 해당 작업을 하는 사업장. 현장 절차와 장비 지침에 맞게 조정하세요.",
  "jurisdiction": "출처별 관할 · 운영 참고",
  "keywords": [],
  "references": [
    {
      "title": "기존 체크리스트 원문 1",
      "url": "https://assets.publishing.service.gov.uk/media/69c52c9f93cc6e8b87a6f747/sfbb-chinese-cleaning-02-cleaning-effectively.pdf",
      "checkedAt": "2026-09-20",
      "scope": "기존 위키 조사 자료 · 업무 구조 참고, 국내 법적 기준으로 단정하지 않음"
    }
  ],
  "knowledge": {
    "scope": "menu",
    "topics": [
      "inventory"
    ],
    "suggestedUse": "routine"
  }
}
```

## 편의점·식품 소매 · 입고와 진열 회전

```tap2work-tap
{
  "sourceId": "convenience/open",
  "collectionId": "convenience",
  "collectionName": "편의점·식품 소매",
  "title": "입고와 진열 회전",
  "slot": "오픈",
  "reviewedAt": "2026-09-20",
  "basis": "공개 자료를 참고한 편집 제안 · 현장 검토 필요",
  "steps": [
    {
      "id": "step-1",
      "title": "입고 품목 대조",
      "manual": "거래 내역과 실물 수량·포장 상태를 맞춰요.",
      "tip": "박스 수와 낱개 수를 혼동하지 않아요.",
      "tags": [],
      "sourceUrl": "https://www.gov.uk/government/publications/safer-food-better-business-for-retailers"
    },
    {
      "id": "step-2",
      "title": "날짜 순서 정렬",
      "manual": "판매 기준 날짜를 확인하고 먼저 나갈 상품이 앞에 오도록 진열해요.",
      "tip": "기존 상품 뒤에 새 상품만 쌓이면 오래된 재고가 가려져요.",
      "tags": [],
      "sourceUrl": "https://www.gov.uk/government/publications/safer-food-better-business-for-retailers"
    },
    {
      "id": "step-3",
      "title": "이상 재고 분리",
      "manual": "파손·판매 기준이 지난 제품을 판매 선반에서 빼고 사유를 적어요.",
      "tip": "회수·반품 예정품은 정상 재고로 세지 않아요.",
      "tags": [],
      "sourceUrl": "https://www.gov.uk/government/publications/safer-food-better-business-for-retailers"
    }
  ],
  "industryIds": [
    "retail"
  ],
  "purposeId": "inventory",
  "kind": "operation",
  "summary": "입고 품목 대조 · 날짜 순서 정렬",
  "applicability": "편의점·식품 소매의 해당 작업을 하는 사업장. 현장 절차와 장비 지침에 맞게 조정하세요.",
  "jurisdiction": "출처별 관할 · 운영 참고",
  "keywords": [],
  "references": [
    {
      "title": "기존 체크리스트 원문 1",
      "url": "https://www.gov.uk/government/publications/safer-food-better-business-for-retailers",
      "checkedAt": "2026-09-20",
      "scope": "기존 위키 조사 자료 · 업무 구조 참고, 국내 법적 기준으로 단정하지 않음"
    }
  ],
  "knowledge": {
    "scope": "menu",
    "topics": [
      "inventory"
    ],
    "suggestedUse": "routine"
  }
}
```

## 편의점·식품 소매 · 매대와 통로 순회

```tap2work-tap
{
  "sourceId": "convenience/peak",
  "collectionId": "convenience",
  "collectionName": "편의점·식품 소매",
  "title": "매대와 통로 순회",
  "slot": "피크",
  "reviewedAt": "2026-09-20",
  "basis": "공개 자료를 참고한 편집 제안 · 현장 검토 필요",
  "steps": [
    {
      "id": "step-1",
      "title": "빈칸 확인",
      "manual": "진열 빈칸과 실제 창고 재고를 대조해 보충해요.",
      "tip": "빈칸이 꼭 품절은 아니에요.",
      "tags": [],
      "sourceUrl": "https://www.gov.uk/government/publications/safer-food-better-business-for-retailers"
    },
    {
      "id": "step-2",
      "title": "가격표 대조",
      "manual": "행사 품목의 이름·용량·표시 가격을 실물과 맞춰요.",
      "tip": "행사 종료 후 이전 표시가 남아 있지 않은지 봐요.",
      "tags": [],
      "sourceUrl": "https://www.gov.uk/government/publications/safer-food-better-business-for-retailers"
    },
    {
      "id": "step-3",
      "title": "바닥 오염 제거",
      "manual": "흘린 음료나 포장물을 즉시 정리하고 마른 뒤 통행을 열어요.",
      "tip": "입구 매트가 말려 올라오지 않았는지 확인해요.",
      "tags": [],
      "sourceUrl": "https://www.gov.uk/government/publications/safer-food-better-business-for-retailers"
    }
  ],
  "industryIds": [
    "retail"
  ],
  "purposeId": "service",
  "kind": "operation",
  "summary": "빈칸 확인 · 가격표 대조",
  "applicability": "편의점·식품 소매의 해당 작업을 하는 사업장. 현장 절차와 장비 지침에 맞게 조정하세요.",
  "jurisdiction": "출처별 관할 · 운영 참고",
  "keywords": [],
  "references": [
    {
      "title": "기존 체크리스트 원문 1",
      "url": "https://www.gov.uk/government/publications/safer-food-better-business-for-retailers",
      "checkedAt": "2026-09-20",
      "scope": "기존 위키 조사 자료 · 업무 구조 참고, 국내 법적 기준으로 단정하지 않음"
    }
  ],
  "knowledge": {
    "scope": "menu",
    "topics": [
      "service"
    ],
    "suggestedUse": "routine"
  }
}
```

## 의류·잡화 소매 · 진열과 판매 준비

```tap2work-tap
{
  "sourceId": "retail/open",
  "collectionId": "retail",
  "collectionName": "의류·잡화 소매",
  "title": "진열과 판매 준비",
  "slot": "오픈",
  "reviewedAt": "2026-09-20",
  "basis": "공개 자료를 참고한 편집 제안 · 현장 검토 필요",
  "steps": [
    {
      "id": "step-1",
      "title": "신상품 수량 대조",
      "manual": "색상·사이즈별 실물을 입고표와 맞추고 불량을 분리해요.",
      "tip": "전체 개수만 맞아도 사이즈 구성은 틀릴 수 있어요.",
      "tags": [],
      "sourceUrl": "https://www.hse.gov.uk/retail/slips-and-trips.htm"
    },
    {
      "id": "step-2",
      "title": "상품 위치 정하기",
      "manual": "품번·색상별 위치를 정하고 직원이 같은 이름으로 찾을 수 있게 해요.",
      "tip": "창고 위치는 브랜드 이름만 적기보다 선반 번호까지 적어요.",
      "tags": [],
      "sourceUrl": "https://www.hse.gov.uk/retail/slips-and-trips.htm"
    },
    {
      "id": "step-3",
      "title": "가격·통로 확인",
      "manual": "가격표와 실제 상품을 맞추고 이동 통로를 비워요.",
      "tip": "촬영용 장식이 고객 동선을 막지 않게 해요.",
      "tags": [],
      "sourceUrl": "https://www.hse.gov.uk/retail/slips-and-trips.htm"
    }
  ],
  "industryIds": [
    "retail"
  ],
  "purposeId": "opening",
  "kind": "operation",
  "summary": "신상품 수량 대조 · 상품 위치 정하기",
  "applicability": "의류·잡화 소매의 해당 작업을 하는 사업장. 현장 절차와 장비 지침에 맞게 조정하세요.",
  "jurisdiction": "출처별 관할 · 운영 참고",
  "keywords": [],
  "references": [
    {
      "title": "기존 체크리스트 원문 1",
      "url": "https://www.hse.gov.uk/retail/slips-and-trips.htm",
      "checkedAt": "2026-09-20",
      "scope": "기존 위키 조사 자료 · 업무 구조 참고, 국내 법적 기준으로 단정하지 않음"
    }
  ],
  "knowledge": {
    "scope": "menu",
    "topics": [
      "opening"
    ],
    "suggestedUse": "routine"
  }
}
```

## 의류·잡화 소매 · 반품과 재진열

```tap2work-tap
{
  "sourceId": "retail/close",
  "collectionId": "retail",
  "collectionName": "의류·잡화 소매",
  "title": "반품과 재진열",
  "slot": "마감",
  "reviewedAt": "2026-09-20",
  "basis": "공개 자료를 참고한 편집 제안 · 현장 검토 필요",
  "steps": [
    {
      "id": "step-1",
      "title": "반품 상태 확인",
      "manual": "반품 사유와 구성품을 확인하고 재판매 가능 여부를 책임자에게 넘겨요.",
      "tip": "접수 즉시 정상 재고로 되돌리지 않아요.",
      "tags": [],
      "sourceUrl": "https://www.hse.gov.uk/retail/slips-and-trips.htm"
    },
    {
      "id": "step-2",
      "title": "피팅룸 정리",
      "manual": "남은 상품을 품번·사이즈별로 분류하고 제자리에 놓아요.",
      "tip": "주머니 속 물품은 매장 분실물 절차로 처리해요.",
      "tags": [],
      "sourceUrl": "https://www.hse.gov.uk/retail/slips-and-trips.htm"
    },
    {
      "id": "step-3",
      "title": "재고 차이 기록",
      "manual": "장부와 실물 차이를 품목별로 남기고 다음 확인 담당을 정해요.",
      "tip": "차이를 맞추려고 근거 없이 수량을 덮어쓰지 않아요.",
      "tags": [],
      "sourceUrl": "https://www.hse.gov.uk/retail/slips-and-trips.htm"
    }
  ],
  "industryIds": [
    "retail"
  ],
  "purposeId": "closing",
  "kind": "operation",
  "summary": "반품 상태 확인 · 피팅룸 정리",
  "applicability": "의류·잡화 소매의 해당 작업을 하는 사업장. 현장 절차와 장비 지침에 맞게 조정하세요.",
  "jurisdiction": "출처별 관할 · 운영 참고",
  "keywords": [],
  "references": [
    {
      "title": "기존 체크리스트 원문 1",
      "url": "https://www.hse.gov.uk/retail/slips-and-trips.htm",
      "checkedAt": "2026-09-20",
      "scope": "기존 위키 조사 자료 · 업무 구조 참고, 국내 법적 기준으로 단정하지 않음"
    }
  ],
  "knowledge": {
    "scope": "menu",
    "topics": [
      "closing"
    ],
    "suggestedUse": "routine"
  }
}
```

## 미용실·바버숍 · 예약과 시술대 준비

```tap2work-tap
{
  "sourceId": "hair/open",
  "collectionId": "hair",
  "collectionName": "미용실·바버숍",
  "title": "예약과 시술대 준비",
  "slot": "오픈",
  "reviewedAt": "2026-09-20",
  "basis": "공개 자료를 참고한 편집 제안 · 현장 검토 필요",
  "steps": [
    {
      "id": "step-1",
      "title": "예약 범위 확인",
      "manual": "시간·시술 종류·예상 소요를 확인하고 겹치는 장비 사용을 맞춰요.",
      "tip": "상담이 필요한 고객은 바로 시술 단계로 넘기지 않아요.",
      "tags": [],
      "sourceUrl": "https://www.hse.gov.uk/coshh/industry/hairdressing.htm"
    },
    {
      "id": "step-2",
      "title": "제품과 도구 확인",
      "manual": "제품 라벨·사용 지침과 도구 상태를 확인하고 용도별로 놓아요.",
      "tip": "새 제품은 이전 제품과 같은 배합이라고 추측하지 않아요.",
      "tags": [],
      "sourceUrl": "https://www.hse.gov.uk/coshh/industry/hairdressing.htm"
    },
    {
      "id": "step-3",
      "title": "작업 보호 준비",
      "manual": "제품 지침에 맞는 장갑과 환기 상태를 확인해요.",
      "tip": "젖은 손으로 오래 일하는 구간을 팀에서 나눠요.",
      "tags": [],
      "sourceUrl": "https://www.hse.gov.uk/coshh/industry/hairdressing.htm"
    }
  ],
  "industryIds": [
    "beauty"
  ],
  "purposeId": "opening",
  "kind": "operation",
  "summary": "예약 범위 확인 · 제품과 도구 확인",
  "applicability": "미용실·바버숍의 해당 작업을 하는 사업장. 현장 절차와 장비 지침에 맞게 조정하세요.",
  "jurisdiction": "출처별 관할 · 운영 참고",
  "keywords": [],
  "references": [
    {
      "title": "기존 체크리스트 원문 1",
      "url": "https://www.hse.gov.uk/coshh/industry/hairdressing.htm",
      "checkedAt": "2026-09-20",
      "scope": "기존 위키 조사 자료 · 업무 구조 참고, 국내 법적 기준으로 단정하지 않음"
    }
  ],
  "knowledge": {
    "scope": "menu",
    "topics": [
      "opening"
    ],
    "suggestedUse": "routine"
  }
}
```

## 미용실·바버숍 · 고객 교체 정리

```tap2work-tap
{
  "sourceId": "hair/peak",
  "collectionId": "hair",
  "collectionName": "미용실·바버숍",
  "title": "고객 교체 정리",
  "slot": "피크",
  "reviewedAt": "2026-09-20",
  "basis": "공개 자료를 참고한 편집 제안 · 현장 검토 필요",
  "steps": [
    {
      "id": "step-1",
      "title": "사용 도구 수거",
      "manual": "사용한 도구와 수건을 깨끗한 준비분과 분리해요.",
      "tip": "다음 고객용 트레이에 사용 도구를 잠깐 올려두지 않아요.",
      "tags": [],
      "sourceUrl": "https://www.hse.gov.uk/coshh/industry/hairdressing.htm"
    },
    {
      "id": "step-2",
      "title": "접촉면 정리",
      "manual": "의자·작업대를 재질과 제품 지침에 맞춰 닦고 필요한 처리를 해요.",
      "tip": "겉보기 깨끗함과 처리 완료를 구분해요.",
      "tags": [],
      "sourceUrl": "https://www.hse.gov.uk/coshh/industry/hairdressing.htm"
    },
    {
      "id": "step-3",
      "title": "다음 예약 인계",
      "manual": "추가 상담과 지연 여부를 다음 담당자에게 알려요.",
      "tip": "고객의 개인적인 상담 내용은 공개 체크리스트에 적지 않아요.",
      "tags": [],
      "sourceUrl": "https://www.hse.gov.uk/coshh/industry/hairdressing.htm"
    }
  ],
  "industryIds": [
    "beauty"
  ],
  "purposeId": "service",
  "kind": "operation",
  "summary": "사용 도구 수거 · 접촉면 정리",
  "applicability": "미용실·바버숍의 해당 작업을 하는 사업장. 현장 절차와 장비 지침에 맞게 조정하세요.",
  "jurisdiction": "출처별 관할 · 운영 참고",
  "keywords": [],
  "references": [
    {
      "title": "기존 체크리스트 원문 1",
      "url": "https://www.hse.gov.uk/coshh/industry/hairdressing.htm",
      "checkedAt": "2026-09-20",
      "scope": "기존 위키 조사 자료 · 업무 구조 참고, 국내 법적 기준으로 단정하지 않음"
    }
  ],
  "knowledge": {
    "scope": "menu",
    "topics": [
      "service"
    ],
    "suggestedUse": "routine"
  }
}
```

## 네일숍 · 네일 작업대 준비

```tap2work-tap
{
  "sourceId": "nail/open",
  "collectionId": "nail",
  "collectionName": "네일숍",
  "title": "네일 작업대 준비",
  "slot": "오픈",
  "reviewedAt": "2026-09-20",
  "basis": "공개 자료를 참고한 편집 제안 · 현장 검토 필요",
  "steps": [
    {
      "id": "step-1",
      "title": "예약 내용 대조",
      "manual": "제거·연장·디자인 상담 여부를 확인해 준비 시간을 맞춰요.",
      "tip": "디자인 확정 전 필요한 재료를 임의로 정하지 않아요.",
      "tags": [],
      "sourceUrl": "https://www.osha.gov/nail-salons"
    },
    {
      "id": "step-2",
      "title": "제품·환기 확인",
      "manual": "사용 제품의 지침과 환기 설비를 확인하고 뚜껑을 관리해요.",
      "tip": "다른 용기로 옮긴 제품은 이름이 보이게 표시해요.",
      "tags": [],
      "sourceUrl": "https://www.osha.gov/nail-salons"
    },
    {
      "id": "step-3",
      "title": "청결 도구 구분",
      "manual": "사용 전후 도구와 일회용품의 위치를 분리해요.",
      "tip": "외관이 깨끗해도 처리 상태를 모르면 바로 사용하지 않아요.",
      "tags": [],
      "sourceUrl": "https://www.osha.gov/nail-salons"
    }
  ],
  "industryIds": [
    "beauty"
  ],
  "purposeId": "opening",
  "kind": "operation",
  "summary": "예약 내용 대조 · 제품·환기 확인",
  "applicability": "네일숍의 해당 작업을 하는 사업장. 현장 절차와 장비 지침에 맞게 조정하세요.",
  "jurisdiction": "출처별 관할 · 운영 참고",
  "keywords": [],
  "references": [
    {
      "title": "기존 체크리스트 원문 1",
      "url": "https://www.osha.gov/nail-salons",
      "checkedAt": "2026-09-20",
      "scope": "기존 위키 조사 자료 · 업무 구조 참고, 국내 법적 기준으로 단정하지 않음"
    }
  ],
  "knowledge": {
    "scope": "menu",
    "topics": [
      "opening"
    ],
    "suggestedUse": "routine"
  }
}
```

## 네일숍 · 도구·소모품 마감

```tap2work-tap
{
  "sourceId": "nail/close",
  "collectionId": "nail",
  "collectionName": "네일숍",
  "title": "도구·소모품 마감",
  "slot": "마감",
  "reviewedAt": "2026-09-20",
  "basis": "공개 자료를 참고한 편집 제안 · 현장 검토 필요",
  "steps": [
    {
      "id": "step-1",
      "title": "재사용 여부 구분",
      "manual": "제품과 도구의 사용 지침대로 폐기분과 처리할 도구를 나눠요.",
      "tip": "일회용품을 닦아서 다음 고객에게 쓰지 않아요.",
      "tags": [],
      "sourceUrl": "https://www.osha.gov/nail-salons"
    },
    {
      "id": "step-2",
      "title": "작업면 처리",
      "manual": "분진과 오염을 먼저 제거하고 재질에 맞는 제품 지침을 따라요.",
      "tip": "소독제를 서로 섞어 쓰지 않아요.",
      "tags": [],
      "sourceUrl": "https://www.osha.gov/nail-salons"
    },
    {
      "id": "step-3",
      "title": "다음 예약 준비",
      "manual": "부족한 팁·장갑·파일을 적고 다음 예약 재료를 준비해요.",
      "tip": "품절 색상은 고객 도착 전에 상담 담당에게 알려요.",
      "tags": [],
      "sourceUrl": "https://www.osha.gov/nail-salons"
    }
  ],
  "industryIds": [
    "beauty"
  ],
  "purposeId": "closing",
  "kind": "operation",
  "summary": "재사용 여부 구분 · 작업면 처리",
  "applicability": "네일숍의 해당 작업을 하는 사업장. 현장 절차와 장비 지침에 맞게 조정하세요.",
  "jurisdiction": "출처별 관할 · 운영 참고",
  "keywords": [],
  "references": [
    {
      "title": "기존 체크리스트 원문 1",
      "url": "https://www.osha.gov/nail-salons",
      "checkedAt": "2026-09-20",
      "scope": "기존 위키 조사 자료 · 업무 구조 참고, 국내 법적 기준으로 단정하지 않음"
    }
  ],
  "knowledge": {
    "scope": "menu",
    "topics": [
      "closing"
    ],
    "suggestedUse": "routine"
  }
}
```

## 피부관리·스파 · 관리실 준비

```tap2work-tap
{
  "sourceId": "skin/open",
  "collectionId": "skin",
  "collectionName": "피부관리·스파",
  "title": "관리실 준비",
  "slot": "오픈",
  "reviewedAt": "2026-09-20",
  "basis": "공개 자료를 참고한 편집 제안 · 현장 검토 필요",
  "steps": [
    {
      "id": "step-1",
      "title": "예약·관리 범위 확인",
      "manual": "예약 종류와 상담 필요 여부를 담당자에게 확인해요.",
      "tip": "금기 판단이나 치료 결정을 체크리스트가 대신하지 않아요.",
      "tags": [],
      "sourceUrl": "https://www.cdc.gov/hygiene/about/when-and-how-to-clean-and-disinfect-a-facility.html"
    },
    {
      "id": "step-2",
      "title": "린넨과 제품 배치",
      "manual": "깨끗한 린넨과 사용할 제품을 관리 순서대로 준비해요.",
      "tip": "개봉일과 제품 사용 지침을 먼저 봐요.",
      "tags": [],
      "sourceUrl": "https://www.cdc.gov/hygiene/about/when-and-how-to-clean-and-disinfect-a-facility.html"
    },
    {
      "id": "step-3",
      "title": "장비 사용 범위 확인",
      "manual": "교육받은 장비의 점검 절차를 따르고 이상이 있으면 사용을 중단해요.",
      "tip": "다른 모델에서 익힌 설정을 그대로 옮기지 않아요.",
      "tags": [],
      "sourceUrl": "https://www.cdc.gov/hygiene/about/when-and-how-to-clean-and-disinfect-a-facility.html"
    }
  ],
  "industryIds": [
    "beauty"
  ],
  "purposeId": "opening",
  "kind": "operation",
  "summary": "예약·관리 범위 확인 · 린넨과 제품 배치",
  "applicability": "피부관리·스파의 해당 작업을 하는 사업장. 현장 절차와 장비 지침에 맞게 조정하세요.",
  "jurisdiction": "출처별 관할 · 운영 참고",
  "keywords": [],
  "references": [
    {
      "title": "기존 체크리스트 원문 1",
      "url": "https://www.cdc.gov/hygiene/about/when-and-how-to-clean-and-disinfect-a-facility.html",
      "checkedAt": "2026-09-20",
      "scope": "기존 위키 조사 자료 · 업무 구조 참고, 국내 법적 기준으로 단정하지 않음"
    }
  ],
  "knowledge": {
    "scope": "menu",
    "topics": [
      "opening"
    ],
    "suggestedUse": "routine"
  }
}
```

## 피부관리·스파 · 룸 회전 정리

```tap2work-tap
{
  "sourceId": "skin/peak",
  "collectionId": "skin",
  "collectionName": "피부관리·스파",
  "title": "룸 회전 정리",
  "slot": "피크",
  "reviewedAt": "2026-09-20",
  "basis": "공개 자료를 참고한 편집 제안 · 현장 검토 필요",
  "steps": [
    {
      "id": "step-1",
      "title": "사용 린넨 분리",
      "manual": "사용한 린넨을 회수함에 넣고 새 린넨과 교차하지 않게 해요.",
      "tip": "회수함 위에 새 수건을 잠시 올려두지 않아요.",
      "tags": [],
      "sourceUrl": "https://www.cdc.gov/hygiene/about/when-and-how-to-clean-and-disinfect-a-facility.html"
    },
    {
      "id": "step-2",
      "title": "접촉면 확인",
      "manual": "침대·손잡이·트레이의 오염을 제거하고 제품 지침대로 처리해요.",
      "tip": "처리 중인 룸을 준비 완료로 표시하지 않아요.",
      "tags": [],
      "sourceUrl": "https://www.cdc.gov/hygiene/about/when-and-how-to-clean-and-disinfect-a-facility.html"
    },
    {
      "id": "step-3",
      "title": "다음 준비 완료 전달",
      "manual": "소모품과 룸 상태를 확인한 뒤 다음 담당자에게 알려요.",
      "tip": "고객 상담 기록은 별도 보호된 절차로 관리해요.",
      "tags": [],
      "sourceUrl": "https://www.cdc.gov/hygiene/about/when-and-how-to-clean-and-disinfect-a-facility.html"
    }
  ],
  "industryIds": [
    "beauty"
  ],
  "purposeId": "service",
  "kind": "operation",
  "summary": "사용 린넨 분리 · 접촉면 확인",
  "applicability": "피부관리·스파의 해당 작업을 하는 사업장. 현장 절차와 장비 지침에 맞게 조정하세요.",
  "jurisdiction": "출처별 관할 · 운영 참고",
  "keywords": [],
  "references": [
    {
      "title": "기존 체크리스트 원문 1",
      "url": "https://www.cdc.gov/hygiene/about/when-and-how-to-clean-and-disinfect-a-facility.html",
      "checkedAt": "2026-09-20",
      "scope": "기존 위키 조사 자료 · 업무 구조 참고, 국내 법적 기준으로 단정하지 않음"
    }
  ],
  "knowledge": {
    "scope": "menu",
    "topics": [
      "service"
    ],
    "suggestedUse": "routine"
  }
}
```

## 숙박·게스트하우스 · 퇴실 객실 정비

```tap2work-tap
{
  "sourceId": "lodging/prep",
  "collectionId": "lodging",
  "collectionName": "숙박·게스트하우스",
  "title": "퇴실 객실 정비",
  "slot": "준비",
  "reviewedAt": "2026-09-20",
  "basis": "공개 자료를 참고한 편집 제안 · 현장 검토 필요",
  "steps": [
    {
      "id": "step-1",
      "title": "입실 상태 확인",
      "manual": "퇴실 완료와 정비할 객실 번호를 대조하고 분실물은 별도 기록해요.",
      "tip": "객실 번호를 기억에 의존하지 않아요.",
      "tags": [],
      "sourceUrl": "https://www.cdc.gov/hygiene/about/when-and-how-to-clean-and-disinfect-a-facility.html"
    },
    {
      "id": "step-2",
      "title": "린넨 회수·교체",
      "manual": "사용 린넨과 깨끗한 린넨을 분리하고 세탁 라벨에 맞는 제품을 준비해요.",
      "tip": "깨끗한 린넨을 바닥에 내려놓지 않아요.",
      "tags": [],
      "sourceUrl": "https://www.cdc.gov/hygiene/about/when-and-how-to-clean-and-disinfect-a-facility.html"
    },
    {
      "id": "step-3",
      "title": "접촉면 정비",
      "manual": "리모컨·손잡이·스위치를 재질별 지침에 맞춰 닦아요.",
      "tip": "눈에 띄는 침구만 정리하고 손이 닿는 곳을 빠뜨리지 않아요.",
      "tags": [],
      "sourceUrl": "https://www.cdc.gov/hygiene/about/when-and-how-to-clean-and-disinfect-a-facility.html"
    }
  ],
  "industryIds": [
    "lodging"
  ],
  "purposeId": "production",
  "kind": "operation",
  "summary": "입실 상태 확인 · 린넨 회수·교체",
  "applicability": "숙박·게스트하우스의 해당 작업을 하는 사업장. 현장 절차와 장비 지침에 맞게 조정하세요.",
  "jurisdiction": "출처별 관할 · 운영 참고",
  "keywords": [],
  "references": [
    {
      "title": "기존 체크리스트 원문 1",
      "url": "https://www.cdc.gov/hygiene/about/when-and-how-to-clean-and-disinfect-a-facility.html",
      "checkedAt": "2026-09-20",
      "scope": "기존 위키 조사 자료 · 업무 구조 참고, 국내 법적 기준으로 단정하지 않음"
    }
  ],
  "knowledge": {
    "scope": "menu",
    "topics": [
      "production"
    ],
    "suggestedUse": "routine"
  }
}
```

## 숙박·게스트하우스 · 객실 판매 준비 확인

```tap2work-tap
{
  "sourceId": "lodging/open",
  "collectionId": "lodging",
  "collectionName": "숙박·게스트하우스",
  "title": "객실 판매 준비 확인",
  "slot": "오픈",
  "reviewedAt": "2026-09-20",
  "basis": "공개 자료를 참고한 편집 제안 · 현장 검토 필요",
  "steps": [
    {
      "id": "step-1",
      "title": "객실 비품 대조",
      "manual": "타월·휴지·물 등 매장 기준 수량을 체크해요.",
      "tip": "투숙 인원과 기본 세트 수량을 같이 봐요.",
      "tags": [],
      "sourceUrl": "https://www.cdc.gov/hygiene/about/when-and-how-to-clean-and-disinfect-a-facility.html"
    },
    {
      "id": "step-2",
      "title": "설비 작동 확인",
      "manual": "조명·냉난방·잠금 상태를 매장 점검 절차로 확인해요.",
      "tip": "고장 객실은 정비 완료와 판매 가능 상태를 구분해요.",
      "tags": [],
      "sourceUrl": "https://www.cdc.gov/hygiene/about/when-and-how-to-clean-and-disinfect-a-facility.html"
    },
    {
      "id": "step-3",
      "title": "최종 검수 인계",
      "manual": "담당자 검수 후 준비 완료를 전달하고 보류 사유를 남겨요.",
      "tip": "청소를 시작했다는 표시를 완료 표시로 쓰지 않아요.",
      "tags": [],
      "sourceUrl": "https://www.cdc.gov/hygiene/about/when-and-how-to-clean-and-disinfect-a-facility.html"
    }
  ],
  "industryIds": [
    "lodging"
  ],
  "purposeId": "opening",
  "kind": "operation",
  "summary": "객실 비품 대조 · 설비 작동 확인",
  "applicability": "숙박·게스트하우스의 해당 작업을 하는 사업장. 현장 절차와 장비 지침에 맞게 조정하세요.",
  "jurisdiction": "출처별 관할 · 운영 참고",
  "keywords": [],
  "references": [
    {
      "title": "기존 체크리스트 원문 1",
      "url": "https://www.cdc.gov/hygiene/about/when-and-how-to-clean-and-disinfect-a-facility.html",
      "checkedAt": "2026-09-20",
      "scope": "기존 위키 조사 자료 · 업무 구조 참고, 국내 법적 기준으로 단정하지 않음"
    }
  ],
  "knowledge": {
    "scope": "menu",
    "topics": [
      "opening"
    ],
    "suggestedUse": "routine"
  }
}
```

## 청소·시설관리 · 현장별 청소 준비

```tap2work-tap
{
  "sourceId": "cleaning/prep",
  "collectionId": "cleaning",
  "collectionName": "청소·시설관리",
  "title": "현장별 청소 준비",
  "slot": "준비",
  "reviewedAt": "2026-09-20",
  "basis": "공개 자료를 참고한 편집 제안 · 현장 검토 필요",
  "steps": [
    {
      "id": "step-1",
      "title": "구역과 순서 합의",
      "manual": "오늘 청소 구역·출입 가능 시간·보류 공간을 담당자와 맞춰요.",
      "tip": "사용 중인 공간을 임의로 열지 않아요.",
      "tags": [],
      "sourceUrl": "https://www.cdc.gov/hygiene/about/when-and-how-to-clean-and-disinfect-a-facility.html"
    },
    {
      "id": "step-2",
      "title": "재질·제품 대조",
      "manual": "표면 재질과 제품 라벨을 확인하고 맞는 도구를 준비해요.",
      "tip": "강한 제품이 모든 재질에 적합한 것은 아니에요.",
      "tags": [],
      "sourceUrl": "https://www.cdc.gov/hygiene/about/when-and-how-to-clean-and-disinfect-a-facility.html"
    },
    {
      "id": "step-3",
      "title": "작업 구역 표시",
      "manual": "젖을 구역 접근을 제한하고 다른 이동 경로를 확보해요.",
      "tip": "표지만 두고 사람이 계속 지나가게 하지 않아요.",
      "tags": [],
      "sourceUrl": "https://www.cdc.gov/hygiene/about/when-and-how-to-clean-and-disinfect-a-facility.html"
    }
  ],
  "industryIds": [
    "services"
  ],
  "purposeId": "hygiene",
  "kind": "operation",
  "summary": "구역과 순서 합의 · 재질·제품 대조",
  "applicability": "청소·시설관리의 해당 작업을 하는 사업장. 현장 절차와 장비 지침에 맞게 조정하세요.",
  "jurisdiction": "출처별 관할 · 운영 참고",
  "keywords": [],
  "references": [
    {
      "title": "기존 체크리스트 원문 1",
      "url": "https://www.cdc.gov/hygiene/about/when-and-how-to-clean-and-disinfect-a-facility.html",
      "checkedAt": "2026-09-20",
      "scope": "기존 위키 조사 자료 · 업무 구조 참고, 국내 법적 기준으로 단정하지 않음"
    }
  ],
  "knowledge": {
    "scope": "menu",
    "topics": [
      "hygiene"
    ],
    "suggestedUse": "routine"
  }
}
```

## 청소·시설관리 · 청소 완료 검수

```tap2work-tap
{
  "sourceId": "cleaning/close",
  "collectionId": "cleaning",
  "collectionName": "청소·시설관리",
  "title": "청소 완료 검수",
  "slot": "마감",
  "reviewedAt": "2026-09-20",
  "basis": "공개 자료를 참고한 편집 제안 · 현장 검토 필요",
  "steps": [
    {
      "id": "step-1",
      "title": "구역별 결과 확인",
      "manual": "손잡이·모서리·가구 뒤 등 빠뜨리기 쉬운 곳을 구역표와 대조해요.",
      "tip": "넓은 면적을 끝냈다고 작은 접촉면을 생략하지 않아요.",
      "tags": [],
      "sourceUrl": "https://www.cdc.gov/hygiene/about/when-and-how-to-clean-and-disinfect-a-facility.html"
    },
    {
      "id": "step-2",
      "title": "도구 정리",
      "manual": "도구를 용도별로 처리하고 약품은 표시된 보관 장소로 옮겨요.",
      "tip": "소분병에 이름 없는 액체를 남기지 않아요.",
      "tags": [],
      "sourceUrl": "https://www.cdc.gov/hygiene/about/when-and-how-to-clean-and-disinfect-a-facility.html"
    },
    {
      "id": "step-3",
      "title": "건조 후 인계",
      "manual": "물기가 정리된 것을 확인하고 보류·파손 항목을 담당자에게 넘겨요.",
      "tip": "작업 완료와 시설 수리 완료는 따로 기록해요.",
      "tags": [],
      "sourceUrl": "https://www.cdc.gov/hygiene/about/when-and-how-to-clean-and-disinfect-a-facility.html"
    }
  ],
  "industryIds": [
    "services"
  ],
  "purposeId": "hygiene",
  "kind": "operation",
  "summary": "구역별 결과 확인 · 도구 정리",
  "applicability": "청소·시설관리의 해당 작업을 하는 사업장. 현장 절차와 장비 지침에 맞게 조정하세요.",
  "jurisdiction": "출처별 관할 · 운영 참고",
  "keywords": [],
  "references": [
    {
      "title": "기존 체크리스트 원문 1",
      "url": "https://www.cdc.gov/hygiene/about/when-and-how-to-clean-and-disinfect-a-facility.html",
      "checkedAt": "2026-09-20",
      "scope": "기존 위키 조사 자료 · 업무 구조 참고, 국내 법적 기준으로 단정하지 않음"
    }
  ],
  "knowledge": {
    "scope": "menu",
    "topics": [
      "hygiene"
    ],
    "suggestedUse": "routine"
  }
}
```

## 세탁소·셀프 빨래방 · 세탁 접수·분류

```tap2work-tap
{
  "sourceId": "laundry/open",
  "collectionId": "laundry",
  "collectionName": "세탁소·셀프 빨래방",
  "title": "세탁 접수·분류",
  "slot": "오픈",
  "reviewedAt": "2026-09-20",
  "basis": "공개 자료를 참고한 편집 제안 · 현장 검토 필요",
  "steps": [
    {
      "id": "step-1",
      "title": "품목과 상태 기록",
      "manual": "의류 개수·기존 손상·주머니 확인 결과를 접수표에 남겨요.",
      "tip": "처음부터 있던 얼룩과 세탁 중 발생한 문제를 구분해요.",
      "tags": [],
      "sourceUrl": "https://www.nfpa.org/-/media/project/storefront/catalog/files/safety-tip-sheets/dryersafetytips.pdf?rev=8af04b5662ec41ebaed95e6064888f71"
    },
    {
      "id": "step-2",
      "title": "케어라벨 확인",
      "manual": "소재·세탁·건조 표시를 보고 처리 가능한 담당에게 분류해요.",
      "tip": "모르는 기호는 임의로 해석하지 않아요.",
      "tags": [],
      "sourceUrl": "https://www.nfpa.org/-/media/project/storefront/catalog/files/safety-tip-sheets/dryersafetytips.pdf?rev=8af04b5662ec41ebaed95e6064888f71"
    },
    {
      "id": "step-3",
      "title": "주문별 묶음 관리",
      "manual": "접수 번호로 품목을 연결하고 분리 세탁 항목도 같은 주문으로 추적해요.",
      "tip": "색이 같은 옷이라도 다른 고객 물품을 섞지 않아요.",
      "tags": [],
      "sourceUrl": "https://www.nfpa.org/-/media/project/storefront/catalog/files/safety-tip-sheets/dryersafetytips.pdf?rev=8af04b5662ec41ebaed95e6064888f71"
    }
  ],
  "industryIds": [
    "services"
  ],
  "purposeId": "opening",
  "kind": "operation",
  "summary": "품목과 상태 기록 · 케어라벨 확인",
  "applicability": "세탁소·셀프 빨래방의 해당 작업을 하는 사업장. 현장 절차와 장비 지침에 맞게 조정하세요.",
  "jurisdiction": "출처별 관할 · 운영 참고",
  "keywords": [],
  "references": [
    {
      "title": "기존 체크리스트 원문 1",
      "url": "https://www.nfpa.org/-/media/project/storefront/catalog/files/safety-tip-sheets/dryersafetytips.pdf?rev=8af04b5662ec41ebaed95e6064888f71",
      "checkedAt": "2026-09-20",
      "scope": "기존 위키 조사 자료 · 업무 구조 참고, 국내 법적 기준으로 단정하지 않음"
    }
  ],
  "knowledge": {
    "scope": "menu",
    "topics": [
      "opening"
    ],
    "suggestedUse": "routine"
  }
}
```

## 세탁소·셀프 빨래방 · 건조기와 출고 점검

```tap2work-tap
{
  "sourceId": "laundry/close",
  "collectionId": "laundry",
  "collectionName": "세탁소·셀프 빨래방",
  "title": "건조기와 출고 점검",
  "slot": "마감",
  "reviewedAt": "2026-09-20",
  "basis": "공개 자료를 참고한 편집 제안 · 현장 검토 필요",
  "steps": [
    {
      "id": "step-1",
      "title": "필터·주변 확인",
      "manual": "기기 설명서에 따라 보풀 필터를 관리하고 주변 적재물을 치워요.",
      "tip": "필터 없이 돌리지 않아요.",
      "tags": [],
      "sourceUrl": "https://www.nfpa.org/-/media/project/storefront/catalog/files/safety-tip-sheets/dryersafetytips.pdf?rev=8af04b5662ec41ebaed95e6064888f71"
    },
    {
      "id": "step-2",
      "title": "건조 이상 기록",
      "manual": "평소보다 오래 걸리거나 이상 냄새가 있으면 사용을 멈추고 점검을 요청해요.",
      "tip": "내부 수리는 교육받은 서비스 담당에게 맡겨요.",
      "tags": [],
      "sourceUrl": "https://www.nfpa.org/-/media/project/storefront/catalog/files/safety-tip-sheets/dryersafetytips.pdf?rev=8af04b5662ec41ebaed95e6064888f71"
    },
    {
      "id": "step-3",
      "title": "출고 수량 대조",
      "manual": "완전 건조와 의류 상태를 확인하고 접수 품목·수량을 맞춰 포장해요.",
      "tip": "여러 벌 중 한 벌만 다른 장소에 남지 않았는지 확인해요.",
      "tags": [],
      "sourceUrl": "https://www.nfpa.org/-/media/project/storefront/catalog/files/safety-tip-sheets/dryersafetytips.pdf?rev=8af04b5662ec41ebaed95e6064888f71"
    }
  ],
  "industryIds": [
    "services"
  ],
  "purposeId": "closing",
  "kind": "operation",
  "summary": "필터·주변 확인 · 건조 이상 기록",
  "applicability": "세탁소·셀프 빨래방의 해당 작업을 하는 사업장. 현장 절차와 장비 지침에 맞게 조정하세요.",
  "jurisdiction": "출처별 관할 · 운영 참고",
  "keywords": [],
  "references": [
    {
      "title": "기존 체크리스트 원문 1",
      "url": "https://www.nfpa.org/-/media/project/storefront/catalog/files/safety-tip-sheets/dryersafetytips.pdf?rev=8af04b5662ec41ebaed95e6064888f71",
      "checkedAt": "2026-09-20",
      "scope": "기존 위키 조사 자료 · 업무 구조 참고, 국내 법적 기준으로 단정하지 않음"
    }
  ],
  "knowledge": {
    "scope": "menu",
    "topics": [
      "closing"
    ],
    "suggestedUse": "routine"
  }
}
```

## 꽃집·플라워숍 · 입고 꽃과 주문 준비

```tap2work-tap
{
  "sourceId": "florist/prep",
  "collectionId": "florist",
  "collectionName": "꽃집·플라워숍",
  "title": "입고 꽃과 주문 준비",
  "slot": "준비",
  "reviewedAt": "2026-09-20",
  "basis": "공개 자료를 참고한 편집 제안 · 현장 검토 필요",
  "steps": [
    {
      "id": "step-1",
      "title": "주문별 품종 확인",
      "manual": "납기·색감·용도와 입고 품종·수량을 맞춰요.",
      "tip": "대체 꽃이 필요하면 제작 전에 확인해요.",
      "tags": [],
      "sourceUrl": "https://extension.umn.edu/about/our-stories/news/yard-and-garden-news/fresh-flowers-and-blue-ribbons"
    },
    {
      "id": "step-2",
      "title": "꽃 상태 분류",
      "manual": "꽃잎·줄기·잎의 상태를 보고 손상분과 먼저 사용할 것을 나눠요.",
      "tip": "좋은 꽃 사이에 손상분을 숨겨 넣지 않아요.",
      "tags": [],
      "sourceUrl": "https://extension.umn.edu/about/our-stories/news/yard-and-garden-news/fresh-flowers-and-blue-ribbons"
    },
    {
      "id": "step-3",
      "title": "제작 순서 정하기",
      "manual": "픽업·배송 시간별 작업 순서를 정하고 메시지 문구를 대조해요.",
      "tip": "비슷한 축하 문구도 주문별로 다시 읽어요.",
      "tags": [],
      "sourceUrl": "https://extension.umn.edu/about/our-stories/news/yard-and-garden-news/fresh-flowers-and-blue-ribbons"
    }
  ],
  "industryIds": [
    "retail"
  ],
  "purposeId": "inventory",
  "kind": "operation",
  "summary": "주문별 품종 확인 · 꽃 상태 분류",
  "applicability": "꽃집·플라워숍의 해당 작업을 하는 사업장. 현장 절차와 장비 지침에 맞게 조정하세요.",
  "jurisdiction": "출처별 관할 · 운영 참고",
  "keywords": [],
  "references": [
    {
      "title": "기존 체크리스트 원문 1",
      "url": "https://extension.umn.edu/about/our-stories/news/yard-and-garden-news/fresh-flowers-and-blue-ribbons",
      "checkedAt": "2026-09-20",
      "scope": "기존 위키 조사 자료 · 업무 구조 참고, 국내 법적 기준으로 단정하지 않음"
    }
  ],
  "knowledge": {
    "scope": "menu",
    "topics": [
      "inventory"
    ],
    "suggestedUse": "routine"
  }
}
```

## 꽃집·플라워숍 · 꽃다발·화병 전달

```tap2work-tap
{
  "sourceId": "florist/peak",
  "collectionId": "florist",
  "collectionName": "꽃집·플라워숍",
  "title": "꽃다발·화병 전달",
  "slot": "피크",
  "reviewedAt": "2026-09-20",
  "basis": "공개 자료를 참고한 편집 제안 · 현장 검토 필요",
  "steps": [
    {
      "id": "step-1",
      "title": "완성품 대조",
      "manual": "주문 색감·수량·메시지를 확인하고 사진 등 매장 검수 방식을 따라요.",
      "tip": "사진을 남길 때 고객 연락처가 보이지 않게 해요.",
      "tags": [],
      "sourceUrl": "https://extension.umn.edu/about/our-stories/news/yard-and-garden-news/fresh-flowers-and-blue-ribbons"
    },
    {
      "id": "step-2",
      "title": "직립·완충 포장",
      "manual": "화병은 세워 고정하고 흔들림과 물 쏟아짐을 줄이도록 포장해요.",
      "tip": "줄기뿐 아니라 꽃머리가 박스에 눌리지 않는지도 봐요.",
      "tags": [],
      "sourceUrl": "https://extension.umn.edu/about/our-stories/news/yard-and-garden-news/fresh-flowers-and-blue-ribbons"
    },
    {
      "id": "step-3",
      "title": "관리 안내 전달",
      "manual": "품종에 맞는 관리 안내와 수령 시각을 전달해요.",
      "tip": "모든 꽃에 같은 보관법을 단정하지 않아요.",
      "tags": [],
      "sourceUrl": "https://extension.umn.edu/about/our-stories/news/yard-and-garden-news/fresh-flowers-and-blue-ribbons"
    }
  ],
  "industryIds": [
    "retail"
  ],
  "purposeId": "service",
  "kind": "operation",
  "summary": "완성품 대조 · 직립·완충 포장",
  "applicability": "꽃집·플라워숍의 해당 작업을 하는 사업장. 현장 절차와 장비 지침에 맞게 조정하세요.",
  "jurisdiction": "출처별 관할 · 운영 참고",
  "keywords": [],
  "references": [
    {
      "title": "기존 체크리스트 원문 1",
      "url": "https://extension.umn.edu/about/our-stories/news/yard-and-garden-news/fresh-flowers-and-blue-ribbons",
      "checkedAt": "2026-09-20",
      "scope": "기존 위키 조사 자료 · 업무 구조 참고, 국내 법적 기준으로 단정하지 않음"
    }
  ],
  "knowledge": {
    "scope": "menu",
    "topics": [
      "service"
    ],
    "suggestedUse": "routine"
  }
}
```

## 헬스장·피트니스 · 운동 공간 오픈 점검

```tap2work-tap
{
  "sourceId": "fitness/open",
  "collectionId": "fitness",
  "collectionName": "헬스장·피트니스",
  "title": "운동 공간 오픈 점검",
  "slot": "오픈",
  "reviewedAt": "2026-09-20",
  "basis": "공개 자료를 참고한 편집 제안 · 현장 검토 필요",
  "steps": [
    {
      "id": "step-1",
      "title": "기구 외관 확인",
      "manual": "케이블·핀·손잡이·패드 상태를 정해진 점검표로 확인해요.",
      "tip": "손상 장비는 사용 가능 표시를 남기지 않아요.",
      "tags": [],
      "sourceUrl": "https://www.cdc.gov/mrsa/prevention/coaches-athletic-directors.html"
    },
    {
      "id": "step-2",
      "title": "동선과 도구 정리",
      "manual": "덤벨·매트·밴드를 지정 위치로 돌리고 이동 공간을 비워요.",
      "tip": "바닥에 잠깐 둔 작은 원판도 장애물이 돼요.",
      "tags": [],
      "sourceUrl": "https://www.cdc.gov/mrsa/prevention/coaches-athletic-directors.html"
    },
    {
      "id": "step-3",
      "title": "청결 준비 확인",
      "manual": "공유 장비의 청소 상태와 필요한 물품을 확인해요.",
      "tip": "패드가 찢어져 제대로 닦이지 않으면 담당자에게 알려요.",
      "tags": [],
      "sourceUrl": "https://www.cdc.gov/mrsa/prevention/coaches-athletic-directors.html"
    }
  ],
  "industryIds": [
    "education"
  ],
  "purposeId": "opening",
  "kind": "operation",
  "summary": "기구 외관 확인 · 동선과 도구 정리",
  "applicability": "헬스장·피트니스의 해당 작업을 하는 사업장. 현장 절차와 장비 지침에 맞게 조정하세요.",
  "jurisdiction": "출처별 관할 · 운영 참고",
  "keywords": [],
  "references": [
    {
      "title": "기존 체크리스트 원문 1",
      "url": "https://www.cdc.gov/mrsa/prevention/coaches-athletic-directors.html",
      "checkedAt": "2026-09-20",
      "scope": "기존 위키 조사 자료 · 업무 구조 참고, 국내 법적 기준으로 단정하지 않음"
    }
  ],
  "knowledge": {
    "scope": "menu",
    "topics": [
      "opening"
    ],
    "suggestedUse": "routine"
  }
}
```

## 헬스장·피트니스 · 사용 후 기구 정리

```tap2work-tap
{
  "sourceId": "fitness/peak",
  "collectionId": "fitness",
  "collectionName": "헬스장·피트니스",
  "title": "사용 후 기구 정리",
  "slot": "피크",
  "reviewedAt": "2026-09-20",
  "basis": "공개 자료를 참고한 편집 제안 · 현장 검토 필요",
  "steps": [
    {
      "id": "step-1",
      "title": "공유 접촉면 청소",
      "manual": "기구 재질과 제품 지침에 따라 손잡이·패드를 처리해요.",
      "tip": "젖은 채로 다음 사용자를 받지 않도록 건조를 확인해요.",
      "tags": [],
      "sourceUrl": "https://www.cdc.gov/mrsa/prevention/coaches-athletic-directors.html"
    },
    {
      "id": "step-2",
      "title": "기본 상태 복귀",
      "manual": "추가 중량·밴드·소도구를 지정 위치에 되돌려요.",
      "tip": "다음 사람이 이전 사용자의 설정을 그대로 쓸 거라고 가정하지 않아요.",
      "tags": [],
      "sourceUrl": "https://www.cdc.gov/mrsa/prevention/coaches-athletic-directors.html"
    },
    {
      "id": "step-3",
      "title": "이상·문의 인계",
      "manual": "소음·헐거움·사용 문의를 담당 트레이너에게 넘겨요.",
      "tip": "체크리스트 완료가 기구 수리나 운동 처방을 뜻하지 않아요.",
      "tags": [],
      "sourceUrl": "https://www.cdc.gov/mrsa/prevention/coaches-athletic-directors.html"
    }
  ],
  "industryIds": [
    "education"
  ],
  "purposeId": "service",
  "kind": "operation",
  "summary": "공유 접촉면 청소 · 기본 상태 복귀",
  "applicability": "헬스장·피트니스의 해당 작업을 하는 사업장. 현장 절차와 장비 지침에 맞게 조정하세요.",
  "jurisdiction": "출처별 관할 · 운영 참고",
  "keywords": [],
  "references": [
    {
      "title": "기존 체크리스트 원문 1",
      "url": "https://www.cdc.gov/mrsa/prevention/coaches-athletic-directors.html",
      "checkedAt": "2026-09-20",
      "scope": "기존 위키 조사 자료 · 업무 구조 참고, 국내 법적 기준으로 단정하지 않음"
    }
  ],
  "knowledge": {
    "scope": "menu",
    "topics": [
      "service"
    ],
    "suggestedUse": "routine"
  }
}
```

## 필라테스·요가 · 수업 도구 준비

```tap2work-tap
{
  "sourceId": "pilates/open",
  "collectionId": "pilates",
  "collectionName": "필라테스·요가",
  "title": "수업 도구 준비",
  "slot": "오픈",
  "reviewedAt": "2026-09-20",
  "basis": "공개 자료를 참고한 편집 제안 · 현장 검토 필요",
  "steps": [
    {
      "id": "step-1",
      "title": "수업 구성 확인",
      "manual": "정원·수업 종류·필요 소도구를 강사와 맞춰요.",
      "tip": "수업 이름이 같아도 준비물이 달라질 수 있어요.",
      "tags": [],
      "sourceUrl": "https://www.cdc.gov/mrsa/prevention/coaches-athletic-directors.html"
    },
    {
      "id": "step-2",
      "title": "도구 상태 점검",
      "manual": "매트·스트랩·스프링 등 외관을 확인하고 이상품을 분리해요.",
      "tip": "장비 설정은 자격과 교육 범위 내 담당자가 해요.",
      "tags": [],
      "sourceUrl": "https://www.cdc.gov/mrsa/prevention/coaches-athletic-directors.html"
    },
    {
      "id": "step-3",
      "title": "공간 배치",
      "manual": "강사 시야와 이동 공간을 확보하고 도구 수량을 맞춰요.",
      "tip": "남는 도구를 통로에 놓지 않아요.",
      "tags": [],
      "sourceUrl": "https://www.cdc.gov/mrsa/prevention/coaches-athletic-directors.html"
    }
  ],
  "industryIds": [
    "education"
  ],
  "purposeId": "opening",
  "kind": "operation",
  "summary": "수업 구성 확인 · 도구 상태 점검",
  "applicability": "필라테스·요가의 해당 작업을 하는 사업장. 현장 절차와 장비 지침에 맞게 조정하세요.",
  "jurisdiction": "출처별 관할 · 운영 참고",
  "keywords": [],
  "references": [
    {
      "title": "기존 체크리스트 원문 1",
      "url": "https://www.cdc.gov/mrsa/prevention/coaches-athletic-directors.html",
      "checkedAt": "2026-09-20",
      "scope": "기존 위키 조사 자료 · 업무 구조 참고, 국내 법적 기준으로 단정하지 않음"
    }
  ],
  "knowledge": {
    "scope": "menu",
    "topics": [
      "opening"
    ],
    "suggestedUse": "routine"
  }
}
```

## 필라테스·요가 · 수업 사이 정리

```tap2work-tap
{
  "sourceId": "pilates/peak",
  "collectionId": "pilates",
  "collectionName": "필라테스·요가",
  "title": "수업 사이 정리",
  "slot": "피크",
  "reviewedAt": "2026-09-20",
  "basis": "공개 자료를 참고한 편집 제안 · 현장 검토 필요",
  "steps": [
    {
      "id": "step-1",
      "title": "사용품 회수",
      "manual": "사용한 소도구를 모아 처리 전후 위치를 나눠요.",
      "tip": "사용 여부를 모르는 물품은 준비 완료로 놓지 않아요.",
      "tags": [],
      "sourceUrl": "https://www.cdc.gov/mrsa/prevention/coaches-athletic-directors.html"
    },
    {
      "id": "step-2",
      "title": "접촉면 관리",
      "manual": "재질별 지침대로 닦고 건조된 상태를 확인해요.",
      "tip": "다공성 소재는 임의로 흠뻑 적시지 않아요.",
      "tags": [],
      "sourceUrl": "https://www.cdc.gov/mrsa/prevention/coaches-athletic-directors.html"
    },
    {
      "id": "step-3",
      "title": "다음 수업 인계",
      "manual": "부족한 도구와 지연 사항을 강사에게 알려요.",
      "tip": "수강생의 개인 건강 정보를 공용 메모에 적지 않아요.",
      "tags": [],
      "sourceUrl": "https://www.cdc.gov/mrsa/prevention/coaches-athletic-directors.html"
    }
  ],
  "industryIds": [
    "education"
  ],
  "purposeId": "service",
  "kind": "operation",
  "summary": "사용품 회수 · 접촉면 관리",
  "applicability": "필라테스·요가의 해당 작업을 하는 사업장. 현장 절차와 장비 지침에 맞게 조정하세요.",
  "jurisdiction": "출처별 관할 · 운영 참고",
  "keywords": [],
  "references": [
    {
      "title": "기존 체크리스트 원문 1",
      "url": "https://www.cdc.gov/mrsa/prevention/coaches-athletic-directors.html",
      "checkedAt": "2026-09-20",
      "scope": "기존 위키 조사 자료 · 업무 구조 참고, 국내 법적 기준으로 단정하지 않음"
    }
  ],
  "knowledge": {
    "scope": "menu",
    "topics": [
      "service"
    ],
    "suggestedUse": "routine"
  }
}
```

## 반려견 미용 · 미용 전 인수인계

```tap2work-tap
{
  "sourceId": "pet/open",
  "collectionId": "pet",
  "collectionName": "반려견 미용",
  "title": "미용 전 인수인계",
  "slot": "오픈",
  "reviewedAt": "2026-09-20",
  "basis": "공개 자료를 참고한 편집 제안 · 현장 검토 필요",
  "steps": [
    {
      "id": "step-1",
      "title": "보호자 요청 확인",
      "manual": "원하는 범위와 특이사항·긴급 연락 방법을 매장 접수 절차로 확인해요.",
      "tip": "민감한 개인정보는 공개 체크리스트에 기록하지 않아요.",
      "tags": [],
      "sourceUrl": "https://www.akc.org/groomer-hub/education-standards/"
    },
    {
      "id": "step-2",
      "title": "상태와 행동 관찰",
      "manual": "피부·털·움직임과 불안 반응을 교육받은 담당자가 확인해요.",
      "tip": "이상 반응을 미용으로 해결하려 하지 말고 책임자에게 알려요.",
      "tags": [],
      "sourceUrl": "https://www.akc.org/groomer-hub/education-standards/"
    },
    {
      "id": "step-3",
      "title": "작업 공간 준비",
      "manual": "테이블·욕조·문·도구가 안전하게 준비됐는지 확인해요.",
      "tip": "테이블이나 욕조 위 동물을 혼자 두지 않아요.",
      "tags": [],
      "sourceUrl": "https://www.akc.org/groomer-hub/education-standards/"
    }
  ],
  "industryIds": [
    "pet"
  ],
  "purposeId": "people",
  "kind": "operation",
  "summary": "보호자 요청 확인 · 상태와 행동 관찰",
  "applicability": "반려견 미용의 해당 작업을 하는 사업장. 현장 절차와 장비 지침에 맞게 조정하세요.",
  "jurisdiction": "출처별 관할 · 운영 참고",
  "keywords": [],
  "references": [
    {
      "title": "기존 체크리스트 원문 1",
      "url": "https://www.akc.org/groomer-hub/education-standards/",
      "checkedAt": "2026-09-20",
      "scope": "기존 위키 조사 자료 · 업무 구조 참고, 국내 법적 기준으로 단정하지 않음"
    }
  ],
  "knowledge": {
    "scope": "menu",
    "topics": [
      "people"
    ],
    "suggestedUse": "routine"
  }
}
```

## 반려견 미용 · 미용 후 정리·인계

```tap2work-tap
{
  "sourceId": "pet/close",
  "collectionId": "pet",
  "collectionName": "반려견 미용",
  "title": "미용 후 정리·인계",
  "slot": "마감",
  "reviewedAt": "2026-09-20",
  "basis": "공개 자료를 참고한 편집 제안 · 현장 검토 필요",
  "steps": [
    {
      "id": "step-1",
      "title": "결과와 상태 확인",
      "manual": "담당자가 마무리 상태와 이상 반응을 확인하고 보호자에게 전달할 내용을 정리해요.",
      "tip": "강한 스트레스 반응이 있으면 완료를 서두르지 않아요.",
      "tags": [],
      "sourceUrl": "https://www.akc.org/groomer-hub/education-standards/"
    },
    {
      "id": "step-2",
      "title": "사용 도구 처리",
      "manual": "동물별 사용 도구와 작업면을 매장 위생 절차대로 처리해요.",
      "tip": "다음 동물이 오기 전 처리 완료를 확인해요.",
      "tags": [],
      "sourceUrl": "https://www.akc.org/groomer-hub/education-standards/"
    },
    {
      "id": "step-3",
      "title": "보호자 인계 대조",
      "manual": "동물과 보호자·소지품을 접수 기록과 대조해 인계해요.",
      "tip": "외형이 비슷한 동물도 이름만 부르며 넘기지 않아요.",
      "tags": [],
      "sourceUrl": "https://www.akc.org/groomer-hub/education-standards/"
    }
  ],
  "industryIds": [
    "pet"
  ],
  "purposeId": "closing",
  "kind": "operation",
  "summary": "결과와 상태 확인 · 사용 도구 처리",
  "applicability": "반려견 미용의 해당 작업을 하는 사업장. 현장 절차와 장비 지침에 맞게 조정하세요.",
  "jurisdiction": "출처별 관할 · 운영 참고",
  "keywords": [],
  "references": [
    {
      "title": "기존 체크리스트 원문 1",
      "url": "https://www.akc.org/groomer-hub/education-standards/",
      "checkedAt": "2026-09-20",
      "scope": "기존 위키 조사 자료 · 업무 구조 참고, 국내 법적 기준으로 단정하지 않음"
    }
  ],
  "knowledge": {
    "scope": "menu",
    "topics": [
      "closing"
    ],
    "suggestedUse": "routine"
  }
}
```

## 스터디카페·공유오피스 · 좌석과 공용 공간 준비

```tap2work-tap
{
  "sourceId": "study/open",
  "collectionId": "study",
  "collectionName": "스터디카페·공유오피스",
  "title": "좌석과 공용 공간 준비",
  "slot": "오픈",
  "reviewedAt": "2026-09-20",
  "basis": "공개 자료를 참고한 편집 제안 · 현장 검토 필요",
  "steps": [
    {
      "id": "step-1",
      "title": "예약·좌석 대조",
      "manual": "예약 구역과 이용 제한 좌석을 확인하고 안내를 맞춰요.",
      "tip": "정비 중인 좌석을 예약 가능 상태로 두지 않아요.",
      "tags": [],
      "sourceUrl": "https://www.cdc.gov/hygiene/about/when-and-how-to-clean-and-disinfect-a-facility.html"
    },
    {
      "id": "step-2",
      "title": "책상·기기 확인",
      "manual": "책상·손잡이를 정리하고 전자기기는 제조사 지침대로 닦아요.",
      "tip": "키보드 틈에 액체를 직접 붓지 않아요.",
      "tags": [],
      "sourceUrl": "https://www.cdc.gov/hygiene/about/when-and-how-to-clean-and-disinfect-a-facility.html"
    },
    {
      "id": "step-3",
      "title": "통로·소모품 확인",
      "manual": "통로와 출입구를 비우고 공용 물품의 잔량을 확인해요.",
      "tip": "가방이나 전원선이 이동을 막지 않게 해요.",
      "tags": [],
      "sourceUrl": "https://www.cdc.gov/hygiene/about/when-and-how-to-clean-and-disinfect-a-facility.html"
    }
  ],
  "industryIds": [
    "education"
  ],
  "purposeId": "opening",
  "kind": "operation",
  "summary": "예약·좌석 대조 · 책상·기기 확인",
  "applicability": "스터디카페·공유오피스의 해당 작업을 하는 사업장. 현장 절차와 장비 지침에 맞게 조정하세요.",
  "jurisdiction": "출처별 관할 · 운영 참고",
  "keywords": [],
  "references": [
    {
      "title": "기존 체크리스트 원문 1",
      "url": "https://www.cdc.gov/hygiene/about/when-and-how-to-clean-and-disinfect-a-facility.html",
      "checkedAt": "2026-09-20",
      "scope": "기존 위키 조사 자료 · 업무 구조 참고, 국내 법적 기준으로 단정하지 않음"
    }
  ],
  "knowledge": {
    "scope": "menu",
    "topics": [
      "opening"
    ],
    "suggestedUse": "routine"
  }
}
```

## 스터디카페·공유오피스 · 이용 종료 점검

```tap2work-tap
{
  "sourceId": "study/close",
  "collectionId": "study",
  "collectionName": "스터디카페·공유오피스",
  "title": "이용 종료 점검",
  "slot": "마감",
  "reviewedAt": "2026-09-20",
  "basis": "공개 자료를 참고한 편집 제안 · 현장 검토 필요",
  "steps": [
    {
      "id": "step-1",
      "title": "잔여 이용 확인",
      "manual": "예약 종료와 실제 이용 상태를 매장 절차로 확인해요.",
      "tip": "예약 시간이 지났다는 이유만으로 개인 물품을 버리지 않아요.",
      "tags": [],
      "sourceUrl": "https://www.cdc.gov/hygiene/about/when-and-how-to-clean-and-disinfect-a-facility.html"
    },
    {
      "id": "step-2",
      "title": "분실물 분리",
      "manual": "좌석별 남은 물건을 위치·시각과 함께 지정 절차로 보관해요.",
      "tip": "고객 정보가 적힌 종이를 공개 사진으로 공유하지 않아요.",
      "tags": [],
      "sourceUrl": "https://www.cdc.gov/hygiene/about/when-and-how-to-clean-and-disinfect-a-facility.html"
    },
    {
      "id": "step-3",
      "title": "다음 운영 인계",
      "manual": "고장·소음·소모품 부족을 구역별로 남기고 담당을 정해요.",
      "tip": "문제 기록에 해결 여부를 같이 남겨 중복 점검을 줄여요.",
      "tags": [],
      "sourceUrl": "https://www.cdc.gov/hygiene/about/when-and-how-to-clean-and-disinfect-a-facility.html"
    }
  ],
  "industryIds": [
    "education"
  ],
  "purposeId": "closing",
  "kind": "operation",
  "summary": "잔여 이용 확인 · 분실물 분리",
  "applicability": "스터디카페·공유오피스의 해당 작업을 하는 사업장. 현장 절차와 장비 지침에 맞게 조정하세요.",
  "jurisdiction": "출처별 관할 · 운영 참고",
  "keywords": [],
  "references": [
    {
      "title": "기존 체크리스트 원문 1",
      "url": "https://www.cdc.gov/hygiene/about/when-and-how-to-clean-and-disinfect-a-facility.html",
      "checkedAt": "2026-09-20",
      "scope": "기존 위키 조사 자료 · 업무 구조 참고, 국내 법적 기준으로 단정하지 않음"
    }
  ],
  "knowledge": {
    "scope": "menu",
    "topics": [
      "closing"
    ],
    "suggestedUse": "routine"
  }
}
```

## 업종 공통 · 근로계약·임금 서류 확인

```tap2work-tap
{
  "sourceId": "legal/employment",
  "collectionId": "legal",
  "collectionName": "업종 공통",
  "title": "근로계약·임금 서류 확인",
  "slot": "준비",
  "reviewedAt": "2026-10-05",
  "basis": "공식 안내를 바탕으로 편집한 확인 항목 · 적용 여부와 최신 기준 확인",
  "industryIds": [
    "all"
  ],
  "purposeId": "compliance",
  "kind": "legal",
  "summary": "직원을 고용할 때 먼저 확인할 근로조건과 지급 기록",
  "applicability": "근로자를 고용하는 사업장. 인원·고용형태별 적용 범위를 구분하세요.",
  "jurisdiction": "대한민국",
  "keywords": [
    "노무",
    "근로계약서",
    "급여"
  ],
  "references": [
    {
      "title": "고용노동부 · 소규모 사업장 필수 규정",
      "url": "https://www.moel.go.kr/news/cardinfo/view.do?bbs_seq=20220500493",
      "checkedAt": "2026-10-05",
      "scope": "2022년 안내 본문 확인 · 개별 고용조건 및 최신 법령 추가 확인"
    }
  ],
  "steps": [
    {
      "id": "step-1",
      "title": "근로조건 확인·교부",
      "manual": "계약서에 임금, 근로시간 등 필수 근로조건이 작성되고 근로자에게 교부됐는지 확인해요.",
      "tip": "",
      "tags": [],
      "sourceUrl": "https://www.moel.go.kr/news/cardinfo/view.do?bbs_seq=20220500493"
    },
    {
      "id": "step-2",
      "title": "임금명세서 확인",
      "manual": "지급 때 구성항목·계산방법·공제내역을 확인하고 임금명세서 교부 기록을 남겨요.",
      "tip": "",
      "tags": [],
      "sourceUrl": "https://www.moel.go.kr/news/cardinfo/view.do?bbs_seq=20220500493"
    },
    {
      "id": "step-3",
      "title": "적용 규정 확인",
      "manual": "상시 인원과 근무형태에 따른 휴게·휴일 등 적용 규정을 공식 안내와 대조하고 누락을 담당자에게 전달해요.",
      "tip": "",
      "tags": [],
      "sourceUrl": "https://www.moel.go.kr/news/cardinfo/view.do?bbs_seq=20220500493"
    }
  ],
  "knowledge": {
    "scope": "universal",
    "topics": [
      "compliance"
    ],
    "suggestedUse": "reference"
  }
}
```

## 업종 공통 · 고객 개인정보 처리 기준 확인

```tap2work-tap
{
  "sourceId": "legal/privacy",
  "collectionId": "legal",
  "collectionName": "업종 공통",
  "title": "고객 개인정보 처리 기준 확인",
  "slot": "준비",
  "reviewedAt": "2026-10-05",
  "basis": "공식 안내를 바탕으로 편집한 확인 항목 · 적용 여부와 최신 기준 확인",
  "industryIds": [
    "all"
  ],
  "purposeId": "compliance",
  "kind": "legal",
  "summary": "예약·회원·고객정보 수집부터 보관·파기까지",
  "applicability": "고객 개인정보를 처리하는 사업장. 수집 근거와 처리 목적에 따라 확인하세요.",
  "jurisdiction": "대한민국",
  "keywords": [
    "개인정보",
    "예약",
    "회원"
  ],
  "references": [
    {
      "title": "개인정보보호위원회 · 소상공인 개인정보 보호 핸드북",
      "url": "https://pipc.go.kr/np/cop/bbs/selectBoardArticle.do?bbsId=BS217&mCode=G010030020&nttId=10897",
      "checkedAt": "2026-10-05",
      "scope": "현재 안내서 게시 페이지 확인 · 구체적인 동의·파기 기준은 연결된 핸드북 확인"
    }
  ],
  "steps": [
    {
      "id": "step-1",
      "title": "처리하는 정보 파악",
      "manual": "예약·회원·주문에서 어떤 정보를 왜 처리하는지 목록을 만들고 공식 핸드북의 해당 항목을 대조해요.",
      "tip": "",
      "tags": [],
      "sourceUrl": "https://pipc.go.kr/np/cop/bbs/selectBoardArticle.do?bbsId=BS217&mCode=G010030020&nttId=10897"
    },
    {
      "id": "step-2",
      "title": "수집·이용 절차 점검",
      "manual": "수집·이용 근거와 고객에게 알릴 내용을 확인해요. 불필요한 정보는 양식에서 제외해요.",
      "tip": "",
      "tags": [],
      "sourceUrl": "https://pipc.go.kr/np/cop/bbs/selectBoardArticle.do?bbsId=BS217&mCode=G010030020&nttId=10897"
    },
    {
      "id": "step-3",
      "title": "보관·파기 담당 정하기",
      "manual": "정보 접근 담당과 보유기간을 확인하고 기간 종료 후 처리 절차를 정해요. 실제 고객정보를 공개 체크리스트에 적지 않아요.",
      "tip": "",
      "tags": [],
      "sourceUrl": "https://pipc.go.kr/np/cop/bbs/selectBoardArticle.do?bbsId=BS217&mCode=G010030020&nttId=10897"
    }
  ],
  "knowledge": {
    "scope": "universal",
    "topics": [
      "compliance"
    ],
    "suggestedUse": "reference"
  }
}
```

## 음식·음료 · 음식점 위생교육 대상·이수 확인

```tap2work-tap
{
  "sourceId": "legal/food-training",
  "collectionId": "legal",
  "collectionName": "음식·음료",
  "title": "음식점 위생교육 대상·이수 확인",
  "slot": "준비",
  "reviewedAt": "2026-10-05",
  "basis": "공식 안내를 바탕으로 편집한 확인 항목 · 적용 여부와 최신 기준 확인",
  "industryIds": [
    "food"
  ],
  "purposeId": "compliance",
  "kind": "legal",
  "summary": "영업 유형과 신규·기존 영업자에 맞는 교육 확인",
  "applicability": "식품접객업 등 위생교육 적용 영업자. 영업 유형과 예외 여부를 관할 기관에 확인하세요.",
  "jurisdiction": "대한민국",
  "keywords": [
    "식당",
    "카페",
    "식품위생"
  ],
  "references": [
    {
      "title": "법제처 생활법령정보 · 식품위생교육",
      "url": "https://easylaw.go.kr/CSP/CnpClsMain.laf?ccfNo=4&cciNo=1&cnpClsNo=2&csmSeq=839&popMenu=ov",
      "checkedAt": "2026-10-05",
      "scope": "식품위생교육 대상·기관·예외 안내 본문 확인"
    }
  ],
  "steps": [
    {
      "id": "step-1",
      "title": "교육 대상 구분",
      "manual": "영업신고 유형과 신규·기존 영업 여부를 확인하고 해당 교육기관과 교육 기준을 찾아요.",
      "tip": "",
      "tags": [],
      "sourceUrl": "https://easylaw.go.kr/CSP/CnpClsMain.laf?ccfNo=4&cciNo=1&cnpClsNo=2&csmSeq=839&popMenu=ov"
    },
    {
      "id": "step-2",
      "title": "이수 기록·다음 일정 확인",
      "manual": "교육 이수 자료를 보관하고 다음 교육 일정을 확인해요. 사전교육 예외는 관할 인정 여부를 확인해요.",
      "tip": "",
      "tags": [],
      "sourceUrl": "https://easylaw.go.kr/CSP/CnpClsMain.laf?ccfNo=4&cciNo=1&cnpClsNo=2&csmSeq=839&popMenu=ov"
    }
  ],
  "knowledge": {
    "scope": "universal",
    "topics": [
      "compliance"
    ],
    "suggestedUse": "reference"
  }
}
```

## 업종 공통 · 소방훈련·교육 적용 여부 확인

```tap2work-tap
{
  "sourceId": "legal/fire-training",
  "collectionId": "legal",
  "collectionName": "업종 공통",
  "title": "소방훈련·교육 적용 여부 확인",
  "slot": "준비",
  "reviewedAt": "2026-10-05",
  "basis": "공식 안내를 바탕으로 편집한 확인 항목 · 적용 여부와 최신 기준 확인",
  "industryIds": [
    "all"
  ],
  "purposeId": "compliance",
  "kind": "legal",
  "summary": "건물의 소방안전관리 대상부터 확인",
  "applicability": "소방안전관리대상물 관계인 등 해당 대상. 모든 사업장에 같은 기준이 적용되는 것은 아니에요.",
  "jurisdiction": "대한민국",
  "keywords": [
    "소방",
    "화재",
    "교육"
  ],
  "references": [
    {
      "title": "법제처 생활법령정보 · 소방훈련과 교육",
      "url": "https://easylaw.go.kr/CSP/CnpClsMain.laf?ccfNo=4&cciNo=3&cnpClsNo=1&csmSeq=1574&menuType=cnpcls&popMenu=ov",
      "checkedAt": "2026-10-05",
      "scope": "대상 구분·실시 및 기록 요건 본문 확인"
    }
  ],
  "steps": [
    {
      "id": "step-1",
      "title": "건물 대상 확인",
      "manual": "건물 관리 담당자와 소방안전관리대상물 여부 및 교육 책임자를 확인해요.",
      "tip": "",
      "tags": [],
      "sourceUrl": "https://easylaw.go.kr/CSP/CnpClsMain.laf?ccfNo=4&cciNo=3&cnpClsNo=1&csmSeq=1574&menuType=cnpcls&popMenu=ov"
    },
    {
      "id": "step-2",
      "title": "훈련·교육 기록 확인",
      "manual": "해당되는 훈련·교육의 일정, 결과 기록과 보관·제출 요건을 공식 안내에서 확인해요.",
      "tip": "",
      "tags": [],
      "sourceUrl": "https://easylaw.go.kr/CSP/CnpClsMain.laf?ccfNo=4&cciNo=3&cnpClsNo=1&csmSeq=1574&menuType=cnpcls&popMenu=ov"
    }
  ],
  "knowledge": {
    "scope": "universal",
    "topics": [
      "compliance"
    ],
    "suggestedUse": "reference"
  }
}
```

## 미용·뷰티 · 미용업 위생·게시 기준 확인

```tap2work-tap
{
  "sourceId": "legal/beauty",
  "collectionId": "legal",
  "collectionName": "미용·뷰티",
  "title": "미용업 위생·게시 기준 확인",
  "slot": "준비",
  "reviewedAt": "2026-10-05",
  "basis": "공식 안내를 바탕으로 편집한 확인 항목 · 적용 여부와 최신 기준 확인",
  "industryIds": [
    "beauty"
  ],
  "purposeId": "compliance",
  "kind": "legal",
  "summary": "영업 유형에 맞는 공중위생 점검 항목",
  "applicability": "미용업 세부 유형별 적용 확인. 서울 서대문구 자율점검표를 참고하며 관할 보건소 기준을 확인하세요.",
  "jurisdiction": "대한민국 · 서울 서대문구 참고 양식",
  "keywords": [],
  "references": [
    {
      "title": "서대문구 보건소 · 영업주 자율점검표",
      "url": "https://www.sdm.go.kr/health/static/upload/editor-images/20260205/3m-j.pdf",
      "checkedAt": "2026-10-05",
      "scope": "2026 지역 자율점검표 본문 확인 · 전국 공통 완료 인증 아님"
    }
  ],
  "steps": [
    {
      "id": "step-1",
      "title": "기구 보관·소독 확인",
      "manual": "소독 전후 기구의 분리 보관과 소독 장비 상태를 확인해요.",
      "tip": "",
      "tags": [],
      "sourceUrl": "https://www.sdm.go.kr/health/static/upload/editor-images/20260205/3m-j.pdf"
    },
    {
      "id": "step-2",
      "title": "신고·면허·요금 게시 확인",
      "manual": "내 영업 유형에 필요한 신고증·면허·요금 게시 여부를 점검해요.",
      "tip": "",
      "tags": [],
      "sourceUrl": "https://www.sdm.go.kr/health/static/upload/editor-images/20260205/3m-j.pdf"
    },
    {
      "id": "step-3",
      "title": "위생교육 기록 확인",
      "manual": "영업주 교육 이수 기록과 다음 일정을 확인하고 누락을 담당자에게 알려요.",
      "tip": "",
      "tags": [],
      "sourceUrl": "https://www.sdm.go.kr/health/static/upload/editor-images/20260205/3m-j.pdf"
    }
  ],
  "knowledge": {
    "scope": "universal",
    "topics": [
      "compliance"
    ],
    "suggestedUse": "reference"
  }
}
```

## 숙박·관광 · 숙박업 위생·시설 기준 확인

```tap2work-tap
{
  "sourceId": "legal/lodging",
  "collectionId": "legal",
  "collectionName": "숙박·관광",
  "title": "숙박업 위생·시설 기준 확인",
  "slot": "준비",
  "reviewedAt": "2026-10-05",
  "basis": "공식 안내를 바탕으로 편집한 확인 항목 · 적용 여부와 최신 기준 확인",
  "industryIds": [
    "lodging"
  ],
  "purposeId": "compliance",
  "kind": "legal",
  "summary": "영업 유형에 맞는 공중위생 점검 항목",
  "applicability": "신고된 숙박업 대상. 민박 등 다른 영업 유형에 그대로 적용하지 말고 관할 기준을 확인하세요.",
  "jurisdiction": "대한민국 · 서울 서대문구 참고 양식",
  "keywords": [],
  "references": [
    {
      "title": "서대문구 보건소 · 영업주 자율점검표",
      "url": "https://www.sdm.go.kr/health/static/upload/editor-images/20260205/5s-j.pdf",
      "checkedAt": "2026-10-05",
      "scope": "2026 지역 자율점검표 본문 확인 · 전국 공통 완료 인증 아님"
    }
  ],
  "steps": [
    {
      "id": "step-1",
      "title": "린넨·객실 위생 확인",
      "manual": "고객 교체 시 침구와 수건 처리, 욕실 상태와 환기를 확인해요.",
      "tip": "",
      "tags": [],
      "sourceUrl": "https://www.sdm.go.kr/health/static/upload/editor-images/20260205/5s-j.pdf"
    },
    {
      "id": "step-2",
      "title": "신고·요금·안전시설 확인",
      "manual": "신고증과 요금표 게시를 확인하고 난방 유형에 따른 안전시설 적용 여부를 점검해요.",
      "tip": "",
      "tags": [],
      "sourceUrl": "https://www.sdm.go.kr/health/static/upload/editor-images/20260205/5s-j.pdf"
    },
    {
      "id": "step-3",
      "title": "교육·정기관리 확인",
      "manual": "위생교육과 방제 등 적용 일정을 공식 점검표 및 관할 안내와 대조해요.",
      "tip": "",
      "tags": [],
      "sourceUrl": "https://www.sdm.go.kr/health/static/upload/editor-images/20260205/5s-j.pdf"
    }
  ],
  "knowledge": {
    "scope": "universal",
    "topics": [
      "compliance"
    ],
    "suggestedUse": "reference"
  }
}
```

## 생활·전문 서비스 · 세탁업 장비·약품 기준 확인

```tap2work-tap
{
  "sourceId": "legal/laundry",
  "collectionId": "legal",
  "collectionName": "생활·전문 서비스",
  "title": "세탁업 장비·약품 기준 확인",
  "slot": "준비",
  "reviewedAt": "2026-10-05",
  "basis": "공식 안내를 바탕으로 편집한 확인 항목 · 적용 여부와 최신 기준 확인",
  "industryIds": [
    "services"
  ],
  "purposeId": "compliance",
  "kind": "legal",
  "summary": "영업 유형에 맞는 공중위생 점검 항목",
  "applicability": "세탁업 중 해당 장비·용제를 사용하는 사업장. 셀프 빨래방에 드라이클리닝 기준을 일괄 적용하지 않아요.",
  "jurisdiction": "대한민국 · 서울 서대문구 참고 양식",
  "keywords": [],
  "references": [
    {
      "title": "서대문구 보건소 · 영업주 자율점검표",
      "url": "https://www.sdm.go.kr/health/static/upload/editor-images/20260205/4s-j.pdf",
      "checkedAt": "2026-10-05",
      "scope": "2026 지역 자율점검표 본문 확인 · 전국 공통 완료 인증 아님"
    }
  ],
  "steps": [
    {
      "id": "step-1",
      "title": "장비·약품 목록 확인",
      "manual": "사용하는 장비와 약품을 정리하고 내 영업 유형에 해당하는 점검 항목을 골라요.",
      "tip": "",
      "tags": [],
      "sourceUrl": "https://www.sdm.go.kr/health/static/upload/editor-images/20260205/4s-j.pdf"
    },
    {
      "id": "step-2",
      "title": "누출·보관 상태 확인",
      "manual": "용제 관련 설비와 보관 상태의 이상을 확인해요. 이상 시 사용을 중단하고 담당자에게 점검을 요청해요.",
      "tip": "",
      "tags": [],
      "sourceUrl": "https://www.sdm.go.kr/health/static/upload/editor-images/20260205/4s-j.pdf"
    }
  ],
  "knowledge": {
    "scope": "universal",
    "topics": [
      "compliance"
    ],
    "suggestedUse": "reference"
  }
}
```

## 교육·운동 · 학원·교습소 등록 기준 확인

```tap2work-tap
{
  "sourceId": "legal/academy",
  "collectionId": "legal",
  "collectionName": "교육·운동",
  "title": "학원·교습소 등록 기준 확인",
  "slot": "준비",
  "reviewedAt": "2026-10-05",
  "basis": "공식 안내를 바탕으로 편집한 확인 항목 · 적용 여부와 최신 기준 확인",
  "industryIds": [
    "education"
  ],
  "purposeId": "compliance",
  "kind": "legal",
  "summary": "교습 과정·시설·관할 기준 확인",
  "applicability": "학원 또는 교습소 설립·변경 시. 스터디카페나 일반 사무실에 자동 적용하지 않아요.",
  "jurisdiction": "대한민국",
  "keywords": [
    "학원",
    "교습소"
  ],
  "references": [
    {
      "title": "법제처 생활법령정보 · 학원의 등록",
      "url": "https://easylaw.go.kr/CSP/CnpClsMainBtr.laf?ccfNo=2&cciNo=2&cnpClsNo=1&csmSeq=1140&popMenu=ov",
      "checkedAt": "2026-10-05",
      "scope": "학원 등록 및 시설 기준 안내 본문 확인"
    }
  ],
  "steps": [
    {
      "id": "step-1",
      "title": "영업 형태 구분",
      "manual": "학원과 교습소 등 운영 형태를 구분하고 관할 교육청의 등록·신고 절차를 확인해요.",
      "tip": "",
      "tags": [],
      "sourceUrl": "https://easylaw.go.kr/CSP/CnpClsMainBtr.laf?ccfNo=2&cciNo=2&cnpClsNo=1&csmSeq=1140&popMenu=ov"
    },
    {
      "id": "step-2",
      "title": "시설·변경 사항 확인",
      "manual": "교습 과정과 시설 기준을 관할 조례·안내와 대조하고 변경등록이 필요한 사항을 확인해요.",
      "tip": "",
      "tags": [],
      "sourceUrl": "https://easylaw.go.kr/CSP/CnpClsMainBtr.laf?ccfNo=2&cciNo=2&cnpClsNo=1&csmSeq=1140&popMenu=ov"
    }
  ],
  "knowledge": {
    "scope": "universal",
    "topics": [
      "compliance"
    ],
    "suggestedUse": "reference"
  }
}
```

## 업종 공통 · 하루 업무 시작 준비

```tap2work-tap
{
  "sourceId": "business/opening",
  "collectionId": "business",
  "collectionName": "업종 공통",
  "title": "하루 업무 시작 준비",
  "slot": "준비",
  "reviewedAt": "2026-10-05",
  "basis": "업무 운영 편집 제안 · 현장 적용 전 검토",
  "industryIds": [
    "all"
  ],
  "purposeId": "opening",
  "kind": "operation",
  "summary": "오늘 일정·공간·필요 물품을 한 번에 확인",
  "applicability": "해당 업무가 있는 모든 업종. 사업장의 승인 절차에 맞게 사용하세요.",
  "jurisdiction": "매장별 운영 기준",
  "keywords": [],
  "references": [],
  "steps": [
    {
      "id": "step-1",
      "title": "오늘 일정 확인",
      "manual": "예약·납기·방문·작업 일정을 읽고 담당과 우선순위를 확인해요.",
      "tip": "",
      "tags": [],
      "sourceUrl": ""
    },
    {
      "id": "step-2",
      "title": "공간·도구 준비",
      "manual": "오늘 사용할 공간과 도구 상태를 확인하고 이상이 있으면 담당자에게 알려요.",
      "tip": "",
      "tags": [],
      "sourceUrl": ""
    },
    {
      "id": "step-3",
      "title": "미완료 인계 확인",
      "manual": "이전 근무의 미완료 항목과 변경사항을 읽고 오늘 처리할 담당을 정해요.",
      "tip": "",
      "tags": [],
      "sourceUrl": ""
    }
  ],
  "knowledge": {
    "scope": "universal",
    "topics": [
      "opening"
    ],
    "suggestedUse": "routine"
  }
}
```

## 업종 공통 · 예약·고객 요청 인계

```tap2work-tap
{
  "sourceId": "business/service",
  "collectionId": "business",
  "collectionName": "업종 공통",
  "title": "예약·고객 요청 인계",
  "slot": "준비",
  "reviewedAt": "2026-10-05",
  "basis": "업무 운영 편집 제안 · 현장 적용 전 검토",
  "industryIds": [
    "all"
  ],
  "purposeId": "service",
  "kind": "operation",
  "summary": "접수부터 완료까지 요청 누락 줄이기",
  "applicability": "해당 업무가 있는 모든 업종. 사업장의 승인 절차에 맞게 사용하세요.",
  "jurisdiction": "매장별 운영 기준",
  "keywords": [],
  "references": [],
  "steps": [
    {
      "id": "step-1",
      "title": "요청·약속 확인",
      "manual": "제공할 서비스, 일정과 합의한 범위를 대조해요.",
      "tip": "",
      "tags": [],
      "sourceUrl": ""
    },
    {
      "id": "step-2",
      "title": "변경·지연 안내",
      "manual": "변경사항을 담당자와 고객에게 전달하고 합의한 내용을 필요한 범위로 기록해요.",
      "tip": "",
      "tags": [],
      "sourceUrl": ""
    },
    {
      "id": "step-3",
      "title": "완료·다음 조치 확인",
      "manual": "완료한 서비스와 남은 요청을 확인하고 후속 담당에게 전달해요.",
      "tip": "",
      "tags": [],
      "sourceUrl": ""
    }
  ],
  "knowledge": {
    "scope": "universal",
    "topics": [
      "service"
    ],
    "suggestedUse": "routine"
  }
}
```

## 업종 공통 · 입고·재고·구매 확인

```tap2work-tap
{
  "sourceId": "business/inventory",
  "collectionId": "business",
  "collectionName": "업종 공통",
  "title": "입고·재고·구매 확인",
  "slot": "준비",
  "reviewedAt": "2026-10-05",
  "basis": "업무 운영 편집 제안 · 현장 적용 전 검토",
  "industryIds": [
    "all"
  ],
  "purposeId": "inventory",
  "kind": "operation",
  "summary": "필요 수량 확인부터 입고 이상 처리까지",
  "applicability": "해당 업무가 있는 모든 업종. 사업장의 승인 절차에 맞게 사용하세요.",
  "jurisdiction": "매장별 운영 기준",
  "keywords": [],
  "references": [],
  "steps": [
    {
      "id": "step-1",
      "title": "실물 수량 확인",
      "manual": "보관 장소별 수량과 사용 가능한 상태를 확인한 뒤 필요한 구매량을 정해요.",
      "tip": "",
      "tags": [],
      "sourceUrl": ""
    },
    {
      "id": "step-2",
      "title": "주문·납품 대조",
      "manual": "품목·수량·납기와 실제 입고를 대조하고 파손이나 누락은 분리해 담당자에게 알려요.",
      "tip": "",
      "tags": [],
      "sourceUrl": ""
    },
    {
      "id": "step-3",
      "title": "위치·인계 기록",
      "manual": "입고 위치와 처리 결과를 기록해 다음 담당자가 찾을 수 있게 해요.",
      "tip": "",
      "tags": [],
      "sourceUrl": ""
    }
  ],
  "knowledge": {
    "scope": "universal",
    "topics": [
      "inventory"
    ],
    "suggestedUse": "routine"
  }
}
```

## 업종 공통 · 공용 공간 청소·정리

```tap2work-tap
{
  "sourceId": "business/cleaning",
  "collectionId": "business",
  "collectionName": "업종 공통",
  "title": "공용 공간 청소·정리",
  "slot": "준비",
  "reviewedAt": "2026-10-05",
  "basis": "업무 운영 편집 제안 · 현장 적용 전 검토",
  "industryIds": [
    "all"
  ],
  "purposeId": "hygiene",
  "kind": "operation",
  "summary": "구역·도구·완료 확인을 하나의 흐름으로",
  "applicability": "해당 업무가 있는 모든 업종. 사업장의 승인 절차에 맞게 사용하세요.",
  "jurisdiction": "매장별 운영 기준",
  "keywords": [],
  "references": [],
  "steps": [
    {
      "id": "step-1",
      "title": "구역과 도구 확인",
      "manual": "청소할 구역과 출입 제한이 필요한 곳을 확인해요. 제품 표시와 현장 지침에 맞는 도구를 준비해요.",
      "tip": "",
      "tags": [],
      "sourceUrl": ""
    },
    {
      "id": "step-2",
      "title": "청소·정리 수행",
      "manual": "사용자 동선을 확보하고 구역별 승인된 순서로 청소해요. 서로 다른 약품을 임의로 섞지 않아요.",
      "tip": "",
      "tags": [],
      "sourceUrl": ""
    },
    {
      "id": "step-3",
      "title": "완료·이상 인계",
      "manual": "젖은 바닥과 남은 물품을 확인하고 미완료나 시설 이상을 인계해요.",
      "tip": "",
      "tags": [],
      "sourceUrl": ""
    }
  ],
  "knowledge": {
    "scope": "universal",
    "topics": [
      "hygiene"
    ],
    "suggestedUse": "routine"
  }
}
```

## 업종 공통 · 시설 이상 발견·조치 인계

```tap2work-tap
{
  "sourceId": "business/safety",
  "collectionId": "business",
  "collectionName": "업종 공통",
  "title": "시설 이상 발견·조치 인계",
  "slot": "준비",
  "reviewedAt": "2026-10-05",
  "basis": "업무 운영 편집 제안 · 현장 적용 전 검토",
  "industryIds": [
    "all"
  ],
  "purposeId": "safety",
  "kind": "operation",
  "summary": "위험 발견을 체크 표시로 끝내지 않기",
  "applicability": "해당 업무가 있는 모든 업종. 사업장의 승인 절차에 맞게 사용하세요.",
  "jurisdiction": "매장별 운영 기준",
  "keywords": [],
  "references": [],
  "steps": [
    {
      "id": "step-1",
      "title": "통로·설비 상태 확인",
      "manual": "출입 동선과 사용 설비의 눈에 보이는 이상을 확인해요. 장비를 임의로 분해하지 않아요.",
      "tip": "",
      "tags": [],
      "sourceUrl": ""
    },
    {
      "id": "step-2",
      "title": "이상 사용 중지·보고",
      "manual": "위험한 상태는 접근과 사용을 멈추고 현장 책임자에게 위치와 상태를 알려요.",
      "tip": "",
      "tags": [],
      "sourceUrl": ""
    },
    {
      "id": "step-3",
      "title": "조치 담당·결과 확인",
      "manual": "조치 담당과 미해결 사항을 기록해 다음 근무자에게 전달해요.",
      "tip": "",
      "tags": [],
      "sourceUrl": ""
    }
  ],
  "knowledge": {
    "scope": "universal",
    "topics": [
      "safety"
    ],
    "suggestedUse": "routine"
  }
}
```

## 업종 공통 · 근무·담당·신규 크루 인계

```tap2work-tap
{
  "sourceId": "business/people",
  "collectionId": "business",
  "collectionName": "업종 공통",
  "title": "근무·담당·신규 크루 인계",
  "slot": "준비",
  "reviewedAt": "2026-10-05",
  "basis": "업무 운영 편집 제안 · 현장 적용 전 검토",
  "industryIds": [
    "all"
  ],
  "purposeId": "people",
  "kind": "operation",
  "summary": "공석·담당·교육을 짧게 확인",
  "applicability": "해당 업무가 있는 모든 업종. 사업장의 승인 절차에 맞게 사용하세요.",
  "jurisdiction": "매장별 운영 기준",
  "keywords": [],
  "references": [],
  "steps": [
    {
      "id": "step-1",
      "title": "근무와 담당 확인",
      "manual": "오늘 근무 인원과 공석, 각 업무의 담당을 확인해요.",
      "tip": "",
      "tags": [],
      "sourceUrl": ""
    },
    {
      "id": "step-2",
      "title": "신규 크루 도움 연결",
      "manual": "새 크루의 버디와 교육 범위를 확인하고 혼자 하면 안 되는 작업을 안내해요.",
      "tip": "",
      "tags": [],
      "sourceUrl": ""
    },
    {
      "id": "step-3",
      "title": "교대 인계",
      "manual": "완료·미완료·이상 사항을 구분해 다음 담당자와 확인해요.",
      "tip": "",
      "tags": [],
      "sourceUrl": ""
    }
  ],
  "knowledge": {
    "scope": "universal",
    "topics": [
      "people"
    ],
    "suggestedUse": "routine"
  }
}
```

## 업종 공통 · 하루 마감·정산 인계

```tap2work-tap
{
  "sourceId": "business/closing",
  "collectionId": "business",
  "collectionName": "업종 공통",
  "title": "하루 마감·정산 인계",
  "slot": "준비",
  "reviewedAt": "2026-10-05",
  "basis": "업무 운영 편집 제안 · 현장 적용 전 검토",
  "industryIds": [
    "all"
  ],
  "purposeId": "closing",
  "kind": "operation",
  "summary": "미완료 업무와 결제 차이를 다음 날로 전달",
  "applicability": "해당 업무가 있는 모든 업종. 사업장의 승인 절차에 맞게 사용하세요.",
  "jurisdiction": "매장별 운영 기준",
  "keywords": [],
  "references": [],
  "steps": [
    {
      "id": "step-1",
      "title": "남은 업무 정리",
      "manual": "진행 중 고객 요청·물품·작업을 확인하고 보관 위치와 다음 담당을 정해요.",
      "tip": "",
      "tags": [],
      "sourceUrl": ""
    },
    {
      "id": "step-2",
      "title": "결제·기록 대조",
      "manual": "담당 권한 안에서 결제·취소·환불 기록을 대조하고 차이는 승인 없이 임의 수정하지 않아요.",
      "tip": "",
      "tags": [],
      "sourceUrl": ""
    },
    {
      "id": "step-3",
      "title": "시설 종료·다음 날 인계",
      "manual": "현장 종료 지침에 따라 설비와 잠금 상태를 확인하고 다음 날 필요한 일을 전달해요.",
      "tip": "",
      "tags": [],
      "sourceUrl": ""
    }
  ],
  "knowledge": {
    "scope": "universal",
    "topics": [
      "closing"
    ],
    "suggestedUse": "routine"
  }
}
```

## IT·사무·창작 · 요청·납기·결과물 인계

```tap2work-tap
{
  "sourceId": "business/office",
  "collectionId": "business",
  "collectionName": "IT·사무·창작",
  "title": "요청·납기·결과물 인계",
  "slot": "준비",
  "reviewedAt": "2026-10-05",
  "basis": "업무 운영 편집 제안 · 현장 적용 전 검토",
  "industryIds": [
    "office"
  ],
  "purposeId": "service",
  "kind": "operation",
  "summary": "IT·디자인·사무 업무의 요청과 검수 정리",
  "applicability": "해당 업종의 일반 인계·행정 업무용. 전문 작업 절차나 법정 점검을 대체하지 않아요.",
  "jurisdiction": "매장별 운영 기준",
  "keywords": [],
  "references": [],
  "steps": [
    {
      "id": "step-1",
      "title": "작업 범위 확인",
      "manual": "요청한 결과물과 납기, 검수 담당을 확인해요.",
      "tip": "",
      "tags": [],
      "sourceUrl": ""
    },
    {
      "id": "step-2",
      "title": "진행·변경 기록",
      "manual": "변경 요청과 합의 사항을 기록하고 관련 담당에게 전달해요.",
      "tip": "",
      "tags": [],
      "sourceUrl": ""
    },
    {
      "id": "step-3",
      "title": "전달·접근 확인",
      "manual": "최종 결과물의 버전과 전달 대상을 대조하고 접근 권한을 확인해요.",
      "tip": "",
      "tags": [],
      "sourceUrl": ""
    }
  ],
  "knowledge": {
    "scope": "universal",
    "topics": [
      "service"
    ],
    "suggestedUse": "routine"
  }
}
```

## 제조·생산 · 생산 작업 전후 인계

```tap2work-tap
{
  "sourceId": "business/manufacturing",
  "collectionId": "business",
  "collectionName": "제조·생산",
  "title": "생산 작업 전후 인계",
  "slot": "준비",
  "reviewedAt": "2026-10-05",
  "basis": "업무 운영 편집 제안 · 현장 적용 전 검토",
  "industryIds": [
    "manufacturing"
  ],
  "purposeId": "production",
  "kind": "operation",
  "summary": "작업지시·자재·이상품을 구분",
  "applicability": "해당 업종의 일반 인계·행정 업무용. 전문 작업 절차나 법정 점검을 대체하지 않아요.",
  "jurisdiction": "매장별 운영 기준",
  "keywords": [],
  "references": [],
  "steps": [
    {
      "id": "step-1",
      "title": "승인 작업지시 확인",
      "manual": "작업 품목과 승인된 작업지시·담당자·필요 교육을 확인해요.",
      "tip": "",
      "tags": [],
      "sourceUrl": ""
    },
    {
      "id": "step-2",
      "title": "자재·이상 확인",
      "manual": "자재와 도구의 식별을 대조하고 손상·이상품은 정상품과 구분해 책임자에게 알려요.",
      "tip": "",
      "tags": [],
      "sourceUrl": ""
    },
    {
      "id": "step-3",
      "title": "결과·미완료 인계",
      "manual": "완료 수량과 미완료·이상 내용을 현장 기록 방식으로 인계해요.",
      "tip": "",
      "tags": [],
      "sourceUrl": ""
    }
  ],
  "knowledge": {
    "scope": "universal",
    "topics": [
      "production"
    ],
    "suggestedUse": "routine"
  }
}
```

## 건설·현장 · 현장 작업 범위·인계 확인

```tap2work-tap
{
  "sourceId": "business/construction",
  "collectionId": "business",
  "collectionName": "건설·현장",
  "title": "현장 작업 범위·인계 확인",
  "slot": "준비",
  "reviewedAt": "2026-10-05",
  "basis": "업무 운영 편집 제안 · 현장 적용 전 검토",
  "industryIds": [
    "construction"
  ],
  "purposeId": "safety",
  "kind": "operation",
  "summary": "시작 전 담당 확인과 이상 시 중단",
  "applicability": "해당 업종의 일반 인계·행정 업무용. 전문 작업 절차나 법정 점검을 대체하지 않아요.",
  "jurisdiction": "매장별 운영 기준",
  "keywords": [],
  "references": [],
  "steps": [
    {
      "id": "step-1",
      "title": "작업 범위·담당 확인",
      "manual": "승인된 작업 범위와 현장 책임자, 출입·작업 허가 필요 여부를 확인해요.",
      "tip": "",
      "tags": [],
      "sourceUrl": ""
    },
    {
      "id": "step-2",
      "title": "위험·변경 전달",
      "manual": "현장 조건이 작업계획과 다르면 시작하지 말고 책임자에게 확인해요.",
      "tip": "",
      "tags": [],
      "sourceUrl": ""
    },
    {
      "id": "step-3",
      "title": "종료·미해결 인계",
      "manual": "작업 구역 상태와 남은 조치, 다음 담당을 인계해요.",
      "tip": "",
      "tags": [],
      "sourceUrl": ""
    }
  ],
  "knowledge": {
    "scope": "universal",
    "topics": [
      "safety"
    ],
    "suggestedUse": "routine"
  }
}
```

## 농림·어업 · 작업·출하 기록 인계

```tap2work-tap
{
  "sourceId": "business/agriculture",
  "collectionId": "business",
  "collectionName": "농림·어업",
  "title": "작업·출하 기록 인계",
  "slot": "준비",
  "reviewedAt": "2026-10-05",
  "basis": "업무 운영 편집 제안 · 현장 적용 전 검토",
  "industryIds": [
    "agriculture"
  ],
  "purposeId": "inventory",
  "kind": "operation",
  "summary": "작업 계획과 출하 물품 식별",
  "applicability": "해당 업종의 일반 인계·행정 업무용. 전문 작업 절차나 법정 점검을 대체하지 않아요.",
  "jurisdiction": "매장별 운영 기준",
  "keywords": [],
  "references": [],
  "steps": [
    {
      "id": "step-1",
      "title": "작업 계획 확인",
      "manual": "오늘 작업·출하 일정과 담당을 확인해요. 장비·약품은 승인된 지침과 교육 범위 안에서 사용해요.",
      "tip": "",
      "tags": [],
      "sourceUrl": ""
    },
    {
      "id": "step-2",
      "title": "물품 식별 대조",
      "manual": "출하 품목·수량·표시와 전달처를 대조하고 이상 물품은 분리해 보고해요.",
      "tip": "",
      "tags": [],
      "sourceUrl": ""
    },
    {
      "id": "step-3",
      "title": "미완료·보관 인계",
      "manual": "남은 물품 위치와 미완료 작업을 다음 담당에게 전달해요.",
      "tip": "",
      "tags": [],
      "sourceUrl": ""
    }
  ],
  "knowledge": {
    "scope": "universal",
    "topics": [
      "inventory"
    ],
    "suggestedUse": "routine"
  }
}
```

## 보건·돌봄 · 접수·비진료 행정 인계

```tap2work-tap
{
  "sourceId": "business/health",
  "collectionId": "business",
  "collectionName": "보건·돌봄",
  "title": "접수·비진료 행정 인계",
  "slot": "준비",
  "reviewedAt": "2026-10-05",
  "basis": "업무 운영 편집 제안 · 현장 적용 전 검토",
  "industryIds": [
    "health"
  ],
  "purposeId": "service",
  "kind": "operation",
  "summary": "진료·투약을 제외한 예약·행정 업무 정리",
  "applicability": "해당 업종의 일반 인계·행정 업무용. 전문 작업 절차나 법정 점검을 대체하지 않아요.",
  "jurisdiction": "매장별 운영 기준",
  "keywords": [],
  "references": [],
  "steps": [
    {
      "id": "step-1",
      "title": "예약·행정 담당 확인",
      "manual": "승인된 시스템에서 예약 일정과 행정 담당을 확인해요.",
      "tip": "",
      "tags": [],
      "sourceUrl": ""
    },
    {
      "id": "step-2",
      "title": "접근·공개 범위 확인",
      "manual": "민감한 정보가 공개된 화면이나 공용 기록에 노출되지 않도록 확인해요.",
      "tip": "",
      "tags": [],
      "sourceUrl": ""
    },
    {
      "id": "step-3",
      "title": "요청을 담당자에게 인계",
      "manual": "진료·투약·처치 판단이 필요한 요청은 해당 전문인력에게 연결해요.",
      "tip": "",
      "tags": [],
      "sourceUrl": ""
    }
  ],
  "knowledge": {
    "scope": "universal",
    "topics": [
      "service"
    ],
    "suggestedUse": "routine"
  }
}
```

## 업종 공통 · CCTV 설치·안내·접근 기준 확인

```tap2work-tap
{
  "sourceId": "legal/cctv",
  "collectionId": "legal",
  "collectionName": "업종 공통",
  "title": "CCTV 설치·안내·접근 기준 확인",
  "slot": "준비",
  "reviewedAt": "2026-10-05",
  "basis": "공식 안내를 바탕으로 편집한 확인 항목 · 적용 여부와 최신 기준 확인",
  "industryIds": [
    "all"
  ],
  "purposeId": "compliance",
  "kind": "legal",
  "summary": "설치 목적과 안내판·영상 접근 기준",
  "applicability": "공개된 장소에 고정형 CCTV를 설치·운영하는 사업장. 장소와 목적에 따라 허용 여부를 확인하세요.",
  "jurisdiction": "대한민국",
  "keywords": [
    "CCTV",
    "영상정보"
  ],
  "references": [
    {
      "title": "법제처 생활법령정보 · 영상정보처리기기",
      "url": "https://easylaw.go.kr/CSP/CnpClsMain.laf?ccfNo=2&cciNo=3&cnpClsNo=3&csmSeq=1257&popMenu=ov",
      "checkedAt": "2026-10-05",
      "scope": "공식 안내의 적용 대상·확인 항목 참고 · 사업 형태별 관할 기준 추가 확인"
    }
  ],
  "steps": [
    {
      "id": "step-1",
      "title": "설치 목적·장소 확인",
      "manual": "설치 목적과 장소가 허용 범위에 해당하는지 공식 안내를 확인해요.",
      "tip": "",
      "tags": [],
      "sourceUrl": "https://easylaw.go.kr/CSP/CnpClsMain.laf?ccfNo=2&cciNo=3&cnpClsNo=3&csmSeq=1257&popMenu=ov"
    },
    {
      "id": "step-2",
      "title": "안내판 항목 대조",
      "manual": "설치 목적·장소, 촬영 범위·시간, 관리책임자 연락처 등 필요한 내용을 안내판과 대조해요.",
      "tip": "",
      "tags": [],
      "sourceUrl": "https://easylaw.go.kr/CSP/CnpClsMain.laf?ccfNo=2&cciNo=3&cnpClsNo=3&csmSeq=1257&popMenu=ov"
    },
    {
      "id": "step-3",
      "title": "영상 접근·처리 확인",
      "manual": "접근 권한과 보관·처리 기준을 정하고 목적 외 이용이나 제공 요청은 담당자에게 확인해요.",
      "tip": "",
      "tags": [],
      "sourceUrl": "https://easylaw.go.kr/CSP/CnpClsMain.laf?ccfNo=2&cciNo=3&cnpClsNo=3&csmSeq=1257&popMenu=ov"
    }
  ],
  "knowledge": {
    "scope": "universal",
    "topics": [
      "compliance"
    ],
    "suggestedUse": "reference"
  }
}
```

## 업종 공통 · 영업 인허가·등록 대상 확인

```tap2work-tap
{
  "sourceId": "legal/permits",
  "collectionId": "legal",
  "collectionName": "업종 공통",
  "title": "영업 인허가·등록 대상 확인",
  "slot": "준비",
  "reviewedAt": "2026-10-05",
  "basis": "공식 안내를 바탕으로 편집한 확인 항목 · 적용 여부와 최신 기준 확인",
  "industryIds": [
    "all"
  ],
  "purposeId": "compliance",
  "kind": "legal",
  "summary": "사업 개시 전 업종별 신고·등록·허가 확인",
  "applicability": "신규 사업 개시 또는 영업 내용 변경 시. 사업자등록과 업종별 인허가는 구분해 확인하세요.",
  "jurisdiction": "대한민국",
  "keywords": [
    "사업자등록",
    "허가",
    "신고"
  ],
  "references": [
    {
      "title": "법제처 생활법령정보 · 법인사업자 등록과 인허가",
      "url": "https://m.easylaw.go.kr/MOB/CsmInfoRetrieve.laf?ccfNo=3&cciNo=2&cnpClsNo=2&csmSeq=632",
      "checkedAt": "2026-10-05",
      "scope": "공식 안내의 적용 대상·확인 항목 참고 · 사업 형태별 관할 기준 추가 확인"
    }
  ],
  "steps": [
    {
      "id": "step-1",
      "title": "실제 영업과 대상 대조",
      "manual": "제공할 서비스와 품목을 정리하고 관계 법령상 허가·등록·신고 대상인지 확인해요.",
      "tip": "",
      "tags": [],
      "sourceUrl": "https://m.easylaw.go.kr/MOB/CsmInfoRetrieve.laf?ccfNo=3&cciNo=2&cnpClsNo=2&csmSeq=632"
    },
    {
      "id": "step-2",
      "title": "관할 절차·증빙 확인",
      "manual": "대상 업종의 관할 기관과 개시 전 절차를 확인하고 필요한 증빙과 변경 사항을 정리해요.",
      "tip": "",
      "tags": [],
      "sourceUrl": "https://m.easylaw.go.kr/MOB/CsmInfoRetrieve.laf?ccfNo=3&cciNo=2&cnpClsNo=2&csmSeq=632"
    }
  ],
  "knowledge": {
    "scope": "universal",
    "topics": [
      "compliance"
    ],
    "suggestedUse": "reference"
  }
}
```


## 브레이크 · 영업 안내와 재개

```tap2work-tap
{
  "sourceId": "common/break-service",
  "collectionId": "common",
  "collectionName": "업종 공통",
  "title": "브레이크 · 영업 안내와 재개",
  "emoji": "📖",
  "slot": "브레이크",
  "reviewedAt": "2026-10-08",
  "basis": "공개 근거에 따른 편집 초안. 제품·장비별 조건과 매장 기준 확인 필요.",
  "steps": [
    {
      "id": "step-1",
      "title": "중단·재개 시간 안내",
      "manual": "우리매장 영업시간에 설정된 오늘의 브레이크 시작·종료 시각을 확인해 안내를 바꿔요. 특정 시각이나 주말 제외를 임의로 적용하지 않아요.",
      "tip": "",
      "tags": [
        "break"
      ],
      "sourceUrl": "https://www.mfds.go.kr/brd/m_827/view.do?seq=3607"
    },
    {
      "id": "step-2",
      "title": "고객·인계 확인",
      "manual": "진행 중인 응대와 전달할 사항을 담당 파트에 남겨요. 영업 브레이크와 크루 개인 휴게는 별개이므로 개인 휴게에 업무를 배정하지 않아요.",
      "tip": "",
      "tags": [
        "break"
      ],
      "sourceUrl": "https://www.mfds.go.kr/brd/m_827/view.do?seq=3607"
    },
    {
      "id": "step-3",
      "title": "영업 재개 확인",
      "manual": "설정된 재개 시각에 안내와 담당 파트의 준비 상태를 확인해요.",
      "tip": "",
      "tags": [
        "break"
      ],
      "sourceUrl": "https://www.mfds.go.kr/brd/m_827/view.do?seq=3607"
    }
  ],
  "industryIds": [
    "all"
  ],
  "purposeId": "service",
  "kind": "operation",
  "summary": "중단·재개 시간 안내 · 고객·인계 확인 · 영업 재개 확인",
  "applicability": "매장의 해당 공정·메뉴를 취급할 때만 사용. 제품 표시와 승인한 매장 기준을 함께 확인하세요.",
  "jurisdiction": "대한민국 · 운영 참고",
  "keywords": [
    "break"
  ],
  "references": [
    {
      "title": "식약처 대량조리 음식 주의요령",
      "url": "https://www.mfds.go.kr/brd/m_827/view.do?seq=3607",
      "checkedAt": "2026-10-08",
      "scope": "공정 관리 원칙 참고. 개별 제품의 보관기간 검증이 아님."
    }
  ],
  "knowledge": {
    "scope": "universal",
    "topics": [
      "break"
    ],
    "suggestedUse": "routine",
    "requiresBreak": true
  }
}
```


## 영업 사이 · 위생 정리

```tap2work-tap
{
  "sourceId": "food/service-reset",
  "collectionId": "food",
  "collectionName": "외식 공통",
  "title": "영업 사이 · 위생 정리",
  "emoji": "📖",
  "slot": "준비",
  "reviewedAt": "2026-10-08",
  "basis": "공개 근거에 따른 편집 초안. 제품·장비별 조건과 매장 기준 확인 필요.",
  "steps": [
    {
      "id": "step-1",
      "title": "작업 구역 정리",
      "manual": "작업대와 사용 도구를 정리하고 매장 세척·소독 방법에 따라 처리해요.",
      "tip": "",
      "tags": [
        "reset"
      ],
      "sourceUrl": "https://www.mfds.go.kr/brd/m_827/view.do?seq=3607"
    },
    {
      "id": "step-2",
      "title": "보관 대상 확인",
      "manual": "남은 식품은 제품·공정별 보관 기준으로 처리해요. 시간·상태가 불명확한 식품은 제공하지 말고 책임자에게 알려요.",
      "tip": "",
      "tags": [
        "reset"
      ],
      "sourceUrl": "https://www.mfds.go.kr/brd/m_827/view.do?seq=3607"
    },
    {
      "id": "step-3",
      "title": "필요한 것만 보충",
      "manual": "다음 영업에 부족한 재료와 도구만 기존 재고·보충 요청에 남겨요. 같은 수량을 다시 기록하지 않아요.",
      "tip": "",
      "tags": [
        "reset"
      ],
      "sourceUrl": "https://www.mfds.go.kr/brd/m_827/view.do?seq=3607"
    }
  ],
  "industryIds": [
    "food"
  ],
  "purposeId": "hygiene",
  "kind": "operation",
  "summary": "작업 구역 정리 · 보관 대상 확인 · 필요한 것만 보충",
  "applicability": "매장의 해당 공정·메뉴를 취급할 때만 사용. 제품 표시와 승인한 매장 기준을 함께 확인하세요.",
  "jurisdiction": "대한민국 · 운영 참고",
  "keywords": [
    "reset"
  ],
  "references": [
    {
      "title": "식약처 대량조리 음식 주의요령",
      "url": "https://www.mfds.go.kr/brd/m_827/view.do?seq=3607",
      "checkedAt": "2026-10-08",
      "scope": "공정 관리 원칙 참고. 개별 제품의 보관기간 검증이 아님."
    }
  ],
  "knowledge": {
    "scope": "food",
    "topics": [
      "reset"
    ],
    "suggestedUse": "routine"
  }
}
```


## 등뼈·육수 다음 영업 준비

```tap2work-tap
{
  "sourceId": "bonejjim/evening-prep",
  "collectionId": "bonejjim",
  "collectionName": "뼈찜·감자탕 전문점",
  "title": "등뼈·육수 다음 영업 준비",
  "emoji": "📖",
  "slot": "준비",
  "reviewedAt": "2026-10-08",
  "basis": "공개 근거에 따른 편집 초안. 제품·장비별 조건과 매장 기준 확인 필요.",
  "steps": [
    {
      "id": "step-1",
      "title": "준비량 확인",
      "manual": "예정 판매량과 남은 준비분을 확인해 초벌 등뼈·육수의 필요한 수량을 정해요.",
      "tip": "",
      "tags": [
        "preparation"
      ],
      "sourceUrl": "https://www.mfds.go.kr/brd/m_827/view.do?seq=3607"
    },
    {
      "id": "step-2",
      "title": "메뉴 기준으로 준비",
      "manual": "매장에서 승인한 등뼈 전처리·육수 레시피와 보관 기준을 확인해 준비해요. 조리된 식품의 불명확한 보관 이력을 재가열로 대신하지 않아요.",
      "tip": "",
      "tags": [
        "preparation"
      ],
      "sourceUrl": "https://www.mfds.go.kr/brd/m_827/view.do?seq=3607"
    }
  ],
  "industryIds": [
    "food"
  ],
  "purposeId": "production",
  "kind": "operation",
  "summary": "준비량 확인 · 메뉴 기준으로 준비",
  "applicability": "매장의 해당 공정·메뉴를 취급할 때만 사용. 제품 표시와 승인한 매장 기준을 함께 확인하세요.",
  "jurisdiction": "대한민국 · 운영 참고",
  "keywords": [
    "preparation"
  ],
  "references": [
    {
      "title": "식약처 대량조리 음식 주의요령",
      "url": "https://www.mfds.go.kr/brd/m_827/view.do?seq=3607",
      "checkedAt": "2026-10-08",
      "scope": "공정 관리 원칙 참고. 개별 제품의 보관기간 검증이 아님."
    }
  ],
  "knowledge": {
    "scope": "menu",
    "topics": [
      "preparation"
    ],
    "suggestedUse": "reference",
    "eventKind": "batch",
    "menuNames": [
      "감자탕",
      "뼈해장국"
    ],
    "safetyReviewRequired": true,
    "useCase": "recipe"
  }
}
```


## 국물 배치 · 냉각과 보관

```tap2work-tap
{
  "sourceId": "process/broth-storage",
  "collectionId": "process",
  "collectionName": "보관·조리 공정",
  "title": "국물 배치 · 냉각과 보관",
  "emoji": "📖",
  "slot": "준비",
  "reviewedAt": "2026-10-08",
  "basis": "공개 근거에 따른 편집 초안. 제품·장비별 조건과 매장 기준 확인 필요.",
  "steps": [
    {
      "id": "step-1",
      "title": "배치와 냉각 시작 확인",
      "manual": "육수인지 해산물 등이 들어간 완성 국물인지 구분해요. 실제 제조량·용기·냉각 장비와 시작 시각을 기록해요. 큰 솥을 실온에 방치해 천천히 식히지 않아요.",
      "tip": "",
      "tags": [
        "storage"
      ],
      "sourceUrl": "https://www.mfds.go.kr/brd/m_827/view.do?seq=3607"
    },
    {
      "id": "step-2",
      "title": "냉각 기준 확인",
      "manual": "매장에 검증된 용기 분할·냉각 방법을 사용하고 정해진 시점의 실제 시간·온도를 기록해요. 기준을 벗어나면 정상 완료하지 말고 사용을 보류한 뒤 책임자에게 알려요.",
      "tip": "",
      "tags": [
        "storage"
      ],
      "sourceUrl": "https://www.mfds.go.kr/brd/m_827/view.do?seq=3607"
    },
    {
      "id": "step-3",
      "title": "표시와 보관 확인",
      "manual": "배치명·제조/냉각 시각·보관 위치와 매장에 확인된 사용기한을 표시해요. 다음 사용 때 이력을 확인해요. 짬뽕 국물에 통일된 보관 일수를 임의로 적용하지 않아요.",
      "tip": "",
      "tags": [
        "storage"
      ],
      "sourceUrl": "https://www.mfds.go.kr/brd/m_827/view.do?seq=3607"
    }
  ],
  "industryIds": [
    "food"
  ],
  "purposeId": "hygiene",
  "kind": "operation",
  "summary": "배치와 냉각 시작 확인 · 냉각 기준 확인 · 표시와 보관 확인",
  "applicability": "매장의 해당 공정·메뉴를 취급할 때만 사용. 제품 표시와 승인한 매장 기준을 함께 확인하세요.",
  "jurisdiction": "대한민국 · 운영 참고",
  "keywords": [
    "storage"
  ],
  "references": [
    {
      "title": "식약처 대량조리 음식 주의요령",
      "url": "https://www.mfds.go.kr/brd/m_827/view.do?seq=3607",
      "checkedAt": "2026-10-08",
      "scope": "공정 관리 원칙 참고. 개별 제품의 보관기간 검증이 아님."
    }
  ],
  "knowledge": {
    "scope": "process",
    "topics": [
      "storage"
    ],
    "suggestedUse": "reference",
    "eventKind": "batch",
    "ingredientNames": [
      "육수",
      "우동육수"
    ],
    "menuNames": [
      "짬뽕",
      "감자탕",
      "뼈해장국",
      "어묵탕"
    ],
    "safetyReviewRequired": true,
    "useCase": "recipe"
  }
}
```


## 떡 · 개봉과 보관

```tap2work-tap
{
  "sourceId": "process/rice-cake-storage",
  "collectionId": "process",
  "collectionName": "보관·조리 공정",
  "title": "떡 · 개봉과 보관",
  "emoji": "📖",
  "slot": "준비",
  "reviewedAt": "2026-10-08",
  "basis": "공개 근거에 따른 편집 초안. 제품·장비별 조건과 매장 기준 확인 필요.",
  "steps": [
    {
      "id": "step-1",
      "title": "제품·상태 확인",
      "manual": "제품 표시의 보관방법과 소비기한을 확인해요. 실온 유통 밀봉 제품, 냉장·냉동 제품, 개봉·해동·불림·조리 상태를 구분해요.",
      "tip": "",
      "tags": [
        "storage"
      ],
      "sourceUrl": "https://www.foodsafetykorea.go.kr/portal/board/boardDetail.do?menu_no=3120&bbs_no=bbs001&ntctxt_no=1101604&menu_grp=MENU_NEW01"
    },
    {
      "id": "step-2",
      "title": "개봉·보관 기록",
      "manual": "제품과 로트, 실제 개봉 시각, 매장에 확인된 개봉 후 보관조건·기한과 위치를 기록해요. 밀봉 제품의 소비기한을 개봉 후에도 그대로 적용하지 않아요.",
      "tip": "",
      "tags": [
        "storage"
      ],
      "sourceUrl": "https://www.foodsafetykorea.go.kr/portal/board/boardDetail.do?menu_no=3120&bbs_no=bbs001&ntctxt_no=1101604&menu_grp=MENU_NEW01"
    },
    {
      "id": "step-3",
      "title": "사용 전 기준 확인",
      "manual": "표시와 실제 보관 이력을 대조해요. 불린 떡에 일반 제품의 기간을 적용하지 않아요. 곰팡이 등 이상이나 불명확한 이력이 있으면 사용을 보류하고 책임자에게 알려요.",
      "tip": "",
      "tags": [
        "storage"
      ],
      "sourceUrl": "https://www.foodsafetykorea.go.kr/portal/board/boardDetail.do?menu_no=3120&bbs_no=bbs001&ntctxt_no=1101604&menu_grp=MENU_NEW01"
    }
  ],
  "industryIds": [
    "food"
  ],
  "purposeId": "hygiene",
  "kind": "operation",
  "summary": "제품·상태 확인 · 개봉·보관 기록 · 사용 전 기준 확인",
  "applicability": "매장의 해당 공정·메뉴를 취급할 때만 사용. 제품 표시와 승인한 매장 기준을 함께 확인하세요.",
  "jurisdiction": "대한민국 · 운영 참고",
  "keywords": [
    "storage"
  ],
  "references": [
    {
      "title": "식품안전나라 떡 소비기한과 보관방법",
      "url": "https://www.foodsafetykorea.go.kr/portal/board/boardDetail.do?menu_no=3120&bbs_no=bbs001&ntctxt_no=1101604&menu_grp=MENU_NEW01",
      "checkedAt": "2026-10-08",
      "scope": "표시 보관조건과 소비기한 준수. 제품별 개봉·해동 후 기간 미확인."
    }
  ],
  "knowledge": {
    "scope": "process",
    "topics": [
      "storage"
    ],
    "suggestedUse": "reference",
    "eventKind": "opened",
    "ingredientNames": [
      "떡",
      "떡볶이떡"
    ],
    "menuNames": [
      "떡볶이"
    ],
    "safetyReviewRequired": true,
    "useCase": "recipe"
  }
}
```


## 2026-10-09 외식업 공통 구성 후보

업무 범위 조사 기반 원문. DB 공용 채널 발행은 별도 독립 검토 후 수행한다.

```tap2work-tap
{
  "knowledge": {
    "useCase": "routine",
    "scope": "food",
    "topics": [
      "people"
    ],
    "menuNames": [],
    "ingredientNames": [],
    "requiresBreak": false,
    "suggestedUse": "routine",
    "eventKind": null,
    "safetyReviewRequired": false,
    "supersededBy": []
  },
  "industryIds": [
    "food"
  ],
  "purposeId": "people",
  "kind": "operation",
  "summary": "근무 시작·교대 인수인계 · 매장 조건과 기준을 연결해 사용하는 기본 절차",
  "applicability": "해당 업무를 운영하는 음식점. 시설·서비스 방식·제품·제조사 지침에 맞게 확인 후 사용하세요.",
  "jurisdiction": "운영 참고 · 매장별 적용 기준 확인",
  "keywords": [
    "근무 시작·교대 인수인계",
    "사진",
    "영상",
    "모션그래픽",
    "편집 원본"
  ],
  "references": [
    {
      "title": "식약처 개방형주방 매뉴얼",
      "url": "https://www.mfds.go.kr/brd/m_218/view.do?seq=20196",
      "checkedAt": "2026-10-09",
      "scope": "2015 자료의 업무 분류·관리 구조 참고. 최신 법적·수치 기준으로 사용하지 않음"
    },
    {
      "title": "RestaurantOwner 운영 체크리스트",
      "url": "https://www.restaurantowner.com/public/DOWNLOAD-Restaurant-Checklists.cfm",
      "checkedAt": "2026-10-09",
      "scope": "공개 업무 범위 설명 참고. 회원 전용 양식 미열람"
    },
    {
      "title": "Basic Kitchen and Food Service Management — editable EPUB",
      "url": "https://opentextbc.ca/basickitchenandfoodservicemanagement/",
      "checkedAt": "2026-10-23",
      "scope": "BC Cook Articulation Committee, CC BY 4.0. Inventory and receiving principles; adapted into Korean store examples. Original EPUB and attribution are in the source pack. Not Korean legal or product-specific operating limits."
    },
    {
      "title": "Food Safety, Sanitation, and Personal Hygiene — editable EPUB",
      "url": "https://opentextbc.ca/foodsafety/",
      "checkedAt": "2026-10-23",
      "scope": "BC Cook Articulation Committee / go2HR, CC BY 4.0. Receiving and sanitation context; retain product labels and the store-approved procedure. The pack preserves the original publisher file and third-party credits."
    },
    {
      "title": "TAP Work — editable media, originals and licenses",
      "url": "https://tap2.work/manual-media/v1/",
      "checkedAt": "2026-10-23",
      "scope": "Original photos, CDC video, source EPUBs and editable motion scenes. Photos are illustrative. Each asset retains its own credit/license; no endorsement or completed field review is claimed."
    }
  ],
  "sourceId": "food/shift",
  "collectionId": "food",
  "collectionName": "외식업 공통",
  "title": "근무 시작·교대 인수인계",
  "emoji": "📋",
  "slot": "오픈",
  "reviewedAt": "2026-10-23",
  "basis": "공개 자료의 업무 범위를 참고하여 새로 작성한 운영 초안. 현장 방법·완료 기준은 책임자 확인 필요.",
  "steps": [
    {
      "id": "ready",
      "title": "손 씻기·복장과 몸 상태 확인",
      "manual": "개인 물품을 보관하고 손을 씻은 뒤 깨끗한 작업복과 머리 가림을 갖춰요. 구토·설사 등 몸 상태나 손의 상처는 식품을 만지기 전에 책임자에게 알려 업무를 조정해요.\n\n완료 기준: 식품 작업 전 위생 준비와 담당 확인을 마쳤어요.",
      "tip": "이상 시: 몸 상태가 좋지 않거나 상처 보호가 어려우면 임의로 조리·배식에 들어가지 않아요.",
      "tags": [
        "손 씻기"
      ],
      "imageUrl": "https://tap2.work/manual-media/v1/handwashing.jpg",
      "videoUrl": "https://tap2.work/manual-media/v1/handwashing.mp4",
      "sourceUrl": "https://tap2.work/manual-media/v1/?guide=shift"
    },
    {
      "id": "handover",
      "title": "미완료·품절·고장 인계 읽기",
      "manual": "오늘 날짜의 인계에서 미완료 주문, 품절 재료, 예약, 사용 중지 장비를 찾아요. 전 근무자에게 대상·위치·남은 행동·담당·마감 시각을 되짚어 물어요.\n\n완료 기준: 누가 언제 무엇을 마무리할지 서로 같은 내용으로 확인했어요.",
      "tip": "이상 시: 읽을 수 없거나 담당이 없으면 해당 업무를 책임자에게 다시 연결해요.",
      "tags": [
        "미완료"
      ],
      "imageUrl": "",
      "videoUrl": "https://tap2.work/manual-media/v1/shift.mp4",
      "sourceUrl": "https://tap2.work/manual-media/v1/?guide=shift"
    },
    {
      "id": "detail-step-3",
      "title": "내 구역과 교대 시간 확인",
      "manual": "근무표에서 오늘 파트·교대·휴게를 확인하고 함께 일할 크루와 도움받을 버디를 찾아요. 혼자 다루지 않는 무거운 용기·장비 작업을 구분해요.\n\n완료 기준: 본인 담당과 도움 요청 방법을 말할 수 있어요.",
      "tip": "이상 시: 공석이나 중복 배정은 책임자에게 알리고 임의로 다른 크루의 휴게를 없애지 않아요.",
      "tags": [
        "내 구역과 교대 시간 확인"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://tap2.work/manual-media/v1/?guide=shift"
    },
    {
      "id": "detail-step-4",
      "title": "시작 전 담당 구역 한 바퀴 확인",
      "manual": "작업대, 통로, 보관대 순서로 돌아 필요한 도구·재료와 장애물을 봐요. 부족분은 품목·수량·필요 시각으로 전달해요.\n\n완료 기준: 시작 가능한 일과 보류할 일이 구분돼요.",
      "tip": "이상 시: 누수·파손·위험한 장애물은 접근을 막고 먼저 알려요.",
      "tags": [
        "시작 전 담당 구역 한 바퀴 확인"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://tap2.work/manual-media/v1/?guide=shift"
    }
  ]
}
```

```tap2work-tap
{
  "sourceId": "food/hall-open",
  "collectionId": "food",
  "collectionName": "외식업 공통",
  "industryIds": [
    "food"
  ],
  "purposeId": "opening",
  "kind": "operation",
  "summary": "홀 오픈 · 매장 조건과 기준을 연결해 사용하는 기본 절차",
  "applicability": "해당 업무를 운영하는 음식점. 시설·서비스 방식·제품·제조사 지침에 맞게 확인 후 사용하세요.",
  "jurisdiction": "운영 참고 · 매장별 적용 기준 확인",
  "keywords": [
    "홀 오픈"
  ],
  "references": [
    {
      "title": "식약처 개방형주방 매뉴얼",
      "url": "https://www.mfds.go.kr/brd/m_218/view.do?seq=20196",
      "checkedAt": "2026-10-09",
      "scope": "2015 자료의 업무 분류·관리 구조 참고. 최신 법적·수치 기준으로 사용하지 않음"
    },
    {
      "title": "RestaurantOwner 운영 체크리스트",
      "url": "https://www.restaurantowner.com/public/DOWNLOAD-Restaurant-Checklists.cfm",
      "checkedAt": "2026-10-09",
      "scope": "공개 업무 범위 설명 참고. 회원 전용 양식 미열람"
    }
  ],
  "emoji": "📋",
  "slot": "오픈",
  "reviewedAt": "2026-10-13",
  "basis": "공개 자료의 업무 범위를 참고하여 새로 작성한 운영 초안. 현장 방법·완료 기준은 책임자 확인 필요.",
  "knowledge": {
    "scope": "food",
    "topics": [
      "opening",
      "hall"
    ],
    "suggestedUse": "routine",
    "safetyReviewRequired": false
  },
  "steps": [
    {
      "id": "entrance",
      "title": "입구·통로와 영업 안내 확인",
      "manual": "출입문에서 좌석까지 걸으며 장애물과 물기를 치워요. 오늘 영업·브레이크·마지막 주문 안내를 우리매장 설정과 대조해요.\n\n완료 기준: 출입·피난 통로가 열려 있고 오늘 안내가 맞아요.",
      "tip": "이상 시: 문 고장이나 미끄럼이 남으면 해당 구역을 막고 책임자에게 알려요.",
      "tags": [
        "입구"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.restaurantowner.com/public/DOWNLOAD-Restaurant-Checklists.cfm"
    },
    {
      "id": "tables",
      "title": "테이블 번호별 좌석·집기 세팅",
      "manual": "테이블을 번호 순서로 닦고 의자·받침·메뉴판을 놓아요. 인원별 앞접시·수저와 휴지·물티슈를 채우고 흔들림·파손을 살펴요.\n\n완료 기준: 예약 인원에 맞는 깨끗한 집기가 있고 통로를 침범하지 않아요.",
      "tip": "이상 시: 깨진 식기와 흔들리는 의자는 분리하고 대체품을 놓아요.",
      "tags": [
        "테이블 번호별 좌석"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.restaurantowner.com/public/DOWNLOAD-Restaurant-Checklists.cfm"
    },
    {
      "id": "selfbar",
      "title": "셀프바 용기·도구·표시 준비",
      "manual": "사용하는 매장만 진행해요. 깨끗한 용기에 첫 제공분만 담고 품명·준비 시각을 표시해요. 음식마다 전용 집게를 놓고 보관 조건을 확인해요.\n\n완료 기준: 음식·전용 도구·표시가 일치하고 보충분은 지정 보관돼요.",
      "tip": "이상 시: 시간·보관 이력이 불명확하거나 오염된 음식은 새 음식과 섞지 말고 사용을 보류해요.",
      "tags": [
        "셀프바 용기"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.restaurantowner.com/public/DOWNLOAD-Restaurant-Checklists.cfm"
    },
    {
      "id": "detail-step-4",
      "title": "음용수·컵과 소모품 채우기",
      "manual": "컵의 이물·파손을 보고 깨끗한 보관대에 놓아요. 정수기 출수부와 물받이를 확인하고 휴지·포장봉투를 지정 기준선까지 채워요.\n\n완료 기준: 첫 손님을 받을 수 있는 수량과 깨끗한 출수 구역을 확보했어요.",
      "tip": "이상 시: 물이 이상하거나 장비 누수가 있으면 사용을 멈추고 대체 음용수를 책임자와 정해요.",
      "tags": [
        "음용수"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.restaurantowner.com/public/DOWNLOAD-Restaurant-Checklists.cfm"
    },
    {
      "id": "detail-step-5",
      "title": "예약·품절·응대 변경 공유",
      "manual": "예약 인원과 좌석, 품절 메뉴, 대기 안내를 홀·주방 담당과 맞춰요. 현장에서 질문받기 쉬운 변경 한 가지를 서로 설명해요.\n\n완료 기준: 홀과 주방이 같은 판매 가능 메뉴와 안내를 알고 있어요.",
      "tip": "이상 시: 확인되지 않은 메뉴·가격·혜택은 손님에게 약속하지 말고 담당자에게 확인해요.",
      "tags": [
        "예약"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.restaurantowner.com/public/DOWNLOAD-Restaurant-Checklists.cfm"
    }
  ],
  "title": "홀 오픈"
}
```

```tap2work-tap
{
  "knowledge": {
    "useCase": "routine",
    "scope": "food",
    "topics": [
      "opening"
    ],
    "menuNames": [],
    "ingredientNames": [],
    "requiresBreak": false,
    "suggestedUse": "routine",
    "eventKind": null,
    "safetyReviewRequired": true,
    "supersededBy": []
  },
  "industryIds": [
    "food"
  ],
  "purposeId": "opening",
  "kind": "operation",
  "summary": "주방 오픈 · 매장 조건과 기준을 연결해 사용하는 기본 절차",
  "applicability": "해당 업무를 운영하는 음식점. 시설·서비스 방식·제품·제조사 지침에 맞게 확인 후 사용하세요.",
  "jurisdiction": "운영 참고 · 매장별 적용 기준 확인",
  "keywords": [
    "주방 오픈",
    "사진",
    "영상",
    "모션그래픽",
    "편집 원본"
  ],
  "references": [
    {
      "title": "식약처 개방형주방 매뉴얼",
      "url": "https://www.mfds.go.kr/brd/m_218/view.do?seq=20196",
      "checkedAt": "2026-10-09",
      "scope": "2015 자료의 업무 분류·관리 구조 참고. 최신 법적·수치 기준으로 사용하지 않음"
    },
    {
      "title": "RestaurantOwner 운영 체크리스트",
      "url": "https://www.restaurantowner.com/public/DOWNLOAD-Restaurant-Checklists.cfm",
      "checkedAt": "2026-10-09",
      "scope": "공개 업무 범위 설명 참고. 회원 전용 양식 미열람"
    },
    {
      "title": "Basic Kitchen and Food Service Management — editable EPUB",
      "url": "https://opentextbc.ca/basickitchenandfoodservicemanagement/",
      "checkedAt": "2026-10-23",
      "scope": "BC Cook Articulation Committee, CC BY 4.0. Inventory and receiving principles; adapted into Korean store examples. Original EPUB and attribution are in the source pack. Not Korean legal or product-specific operating limits."
    },
    {
      "title": "Food Safety, Sanitation, and Personal Hygiene — editable EPUB",
      "url": "https://opentextbc.ca/foodsafety/",
      "checkedAt": "2026-10-23",
      "scope": "BC Cook Articulation Committee / go2HR, CC BY 4.0. Receiving and sanitation context; retain product labels and the store-approved procedure. The pack preserves the original publisher file and third-party credits."
    },
    {
      "title": "TAP Work — editable media, originals and licenses",
      "url": "https://tap2.work/manual-media/v1/",
      "checkedAt": "2026-10-23",
      "scope": "Original photos, CDC video, source EPUBs and editable motion scenes. Photos are illustrative. Each asset retains its own credit/license; no endorsement or completed field review is claimed."
    }
  ],
  "sourceId": "food/kitchen-open",
  "collectionId": "food",
  "collectionName": "외식업 공통",
  "title": "주방 오픈",
  "emoji": "📋",
  "slot": "오픈",
  "reviewedAt": "2026-10-23",
  "basis": "공개 자료의 업무 범위를 참고하여 새로 작성한 운영 초안. 현장 방법·완료 기준은 책임자 확인 필요.",
  "steps": [
    {
      "id": "workbench",
      "title": "작업대·도구 청결 확인",
      "manual": "전날 마감 기록을 읽고 작업대·도마·칼·집게를 살펴요. 생재료와 바로 먹는 음식의 작업 구역·도구를 나누고 세척 후 건조된 도구를 배치해요.\n\n완료 기준: 오염된 도구가 없고 작업 흐름이 서로 교차하지 않아요.",
      "tip": "이상 시: 오염·균열이 있으면 도구를 빼고 재세척 또는 교체해요.",
      "tags": [
        "작업대"
      ],
      "imageUrl": "https://tap2.work/manual-media/v1/kitchen.jpg",
      "videoUrl": "https://tap2.work/manual-media/v1/opening.mp4",
      "sourceUrl": "https://tap2.work/manual-media/v1/?guide=opening"
    },
    {
      "id": "stock",
      "title": "당일 재료·준비량 대조",
      "manual": "예약·예상 주문과 사용 가능한 잔량을 비교해 첫 준비분과 추가 준비분을 나눠 적어요. 라벨의 품명·시각·사용 기준을 실제 재료와 맞춰요.\n\n완료 기준: 각 메뉴의 준비할 양과 부족 품목을 알 수 있어요.",
      "tip": "이상 시: 라벨·이력이 없는 재료는 먼저 쓰지 말고 분리해 확인해요.",
      "tags": [
        "당일 재료"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://tap2.work/manual-media/v1/?guide=opening"
    },
    {
      "id": "detail-step-3",
      "title": "보관 장비 표시·문 닫힘 확인",
      "manual": "냉장·냉동고별 표시값을 해당 매장 기준과 대조해 기록해요. 문 패킹, 닫힘, 통풍구 가림과 누수를 살펴요.\n\n완료 기준: 장비별 실제 표시값과 점검 시각이 남고 문이 닫혀요.",
      "tip": "이상 시: 기준 이탈 시 재료의 시간·온도 이력을 확인하도록 책임자에게 알리고 임의로 정상 처리하지 않아요.",
      "tags": [
        "보관 장비 표시"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://tap2.work/manual-media/v1/?guide=opening"
    },
    {
      "id": "detail-step-4",
      "title": "가열 장비 준비와 안전 동선 확인",
      "manual": "교육받은 장비만 제조사 절차로 가동해요. 손잡이·보호구·뜨거운 용기 받침을 준비하고 운반 통로를 비워요.\n\n완료 기준: 사용 가능한 장비와 사용 중지 장비가 구분돼요.",
      "tip": "이상 시: 가스 냄새·연기·이상 소음은 작업을 중단하고 매장 비상 절차를 따라요.",
      "tags": [
        "가열 장비 준비와 안전 동선 확인"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://tap2.work/manual-media/v1/?guide=opening"
    },
    {
      "id": "detail-step-5",
      "title": "조리·배식·설거지 동선 맞추기",
      "manual": "깨끗한 음식이 나가는 쪽과 사용 식기가 돌아오는 쪽을 분리해요. 주문표 위치와 완성 콜, 지원 요청 방식을 함께 확인해요.\n\n완료 기준: 주문·완성품·반납 식기가 섞이지 않고 각 위치를 찾을 수 있어요.",
      "tip": "이상 시: 공간이 부족하면 담당자와 작업 시간을 나누고 임의로 식품 옆에 오염 식기를 쌓지 않아요.",
      "tags": [
        "조리"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://tap2.work/manual-media/v1/?guide=opening"
    }
  ]
}
```

```tap2work-tap
{
  "sourceId": "food/purchasing",
  "collectionId": "food",
  "collectionName": "외식업 공통",
  "industryIds": [
    "food"
  ],
  "purposeId": "inventory",
  "kind": "operation",
  "summary": "구매·발주 준비 · 매장 조건과 기준을 연결해 사용하는 기본 절차",
  "applicability": "해당 업무를 운영하는 음식점. 시설·서비스 방식·제품·제조사 지침에 맞게 확인 후 사용하세요.",
  "jurisdiction": "운영 참고 · 매장별 적용 기준 확인",
  "keywords": [
    "구매·발주 준비"
  ],
  "references": [
    {
      "title": "식약처 개방형주방 매뉴얼",
      "url": "https://www.mfds.go.kr/brd/m_218/view.do?seq=20196",
      "checkedAt": "2026-10-09",
      "scope": "2015 자료의 업무 분류·관리 구조 참고. 최신 법적·수치 기준으로 사용하지 않음"
    },
    {
      "title": "RestaurantOwner 운영 체크리스트",
      "url": "https://www.restaurantowner.com/public/DOWNLOAD-Restaurant-Checklists.cfm",
      "checkedAt": "2026-10-09",
      "scope": "공개 업무 범위 설명 참고. 회원 전용 양식 미열람"
    }
  ],
  "emoji": "📋",
  "slot": "준비",
  "reviewedAt": "2026-10-13",
  "basis": "공개 자료의 업무 범위를 참고하여 새로 작성한 운영 초안. 현장 방법·완료 기준은 책임자 확인 필요.",
  "knowledge": {
    "scope": "food",
    "topics": [
      "inventory"
    ],
    "suggestedUse": "reference",
    "safetyReviewRequired": false
  },
  "steps": [
    {
      "id": "need",
      "title": "실재고·사용 가능량 확인",
      "manual": "품목별 단위와 보관 위치를 맞추고 실재고를 세요. 폐기 예정·격리분은 판매 가능한 수량에서 빼고 이미 주문한 미입고분은 별도로 적어요.\n\n완료 기준: 재고·사용 가능량·미입고가 구분돼 중복 주문을 피할 수 있어요.",
      "tip": "이상 시: 수량이나 단위가 맞지 않으면 재계수하고 확인 전 주문 수량을 확정하지 않아요.",
      "tags": [
        "실재고"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.restaurantowner.com/public/DOWNLOAD-Restaurant-Checklists.cfm"
    },
    {
      "id": "detail-step-2",
      "title": "다음 납품 전 필요한 양 계산",
      "manual": "다음 납품일까지의 예약·판매 예상량과 매장 안전재고를 합한 뒤 사용 가능 재고·미입고분을 빼요. 포장 단위에 맞춰 필요량을 정리해요.\n\n완료 기준: 필요량의 근거와 납품 희망일을 설명할 수 있어요.",
      "tip": "이상 시: 수요나 납품일이 불확실하면 가정과 부족 예상 시점을 책임자에게 알려요.",
      "tags": [
        "다음 납품 전 필요한 양 계산"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.restaurantowner.com/public/DOWNLOAD-Restaurant-Checklists.cfm"
    },
    {
      "id": "detail-step-3",
      "title": "품명·규격·대체품 조건 대조",
      "manual": "같은 이름의 다른 규격을 구분하고 중량·포장수·단가·최소 주문량을 대조해요. 원재료가 바뀌는 대체품은 메뉴·알레르기 안내 영향도 확인해요.\n\n완료 기준: 주문서에서 품목·규격·단위·납기·수량을 한 번에 확인할 수 있어요.",
      "tip": "이상 시: 대체품은 승인 없이 바꾸지 않아요.",
      "tags": [
        "품명"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.restaurantowner.com/public/DOWNLOAD-Restaurant-Checklists.cfm"
    },
    {
      "id": "approve",
      "title": "승인 요청과 주문 확인 인계",
      "manual": "담당자에게 발주 초안을 보여주고 승인된 경로로 주문했는지 확인해요. 주문 확인번호·예정 납품일·미확정 품목을 기록해 입고 담당에게 전해요.\n\n완료 기준: 승인·실제 주문 여부·예정 입고가 구분돼요.",
      "tip": "이상 시: 초안 작성이나 앱 체크를 실제 공급처 주문 완료로 기록하지 않아요.",
      "tags": [
        "승인 요청과 주문 확인 인계"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.restaurantowner.com/public/DOWNLOAD-Restaurant-Checklists.cfm"
    }
  ],
  "title": "구매·발주 준비"
}
```

```tap2work-tap
{
  "knowledge": {
    "useCase": "reference",
    "scope": "food",
    "topics": [
      "inventory"
    ],
    "menuNames": [],
    "ingredientNames": [],
    "requiresBreak": false,
    "suggestedUse": "reference",
    "eventKind": null,
    "safetyReviewRequired": true,
    "supersededBy": []
  },
  "industryIds": [
    "food"
  ],
  "purposeId": "inventory",
  "kind": "operation",
  "summary": "입고 확인 · 매장 조건과 기준을 연결해 사용하는 기본 절차",
  "applicability": "해당 업무를 운영하는 음식점. 시설·서비스 방식·제품·제조사 지침에 맞게 확인 후 사용하세요.",
  "jurisdiction": "운영 참고 · 매장별 적용 기준 확인",
  "keywords": [
    "입고 확인",
    "사진",
    "영상",
    "모션그래픽",
    "편집 원본"
  ],
  "references": [
    {
      "title": "식약처 개방형주방 매뉴얼",
      "url": "https://www.mfds.go.kr/brd/m_218/view.do?seq=20196",
      "checkedAt": "2026-10-09",
      "scope": "2015 자료의 업무 분류·관리 구조 참고. 최신 법적·수치 기준으로 사용하지 않음"
    },
    {
      "title": "RestaurantOwner 운영 체크리스트",
      "url": "https://www.restaurantowner.com/public/DOWNLOAD-Restaurant-Checklists.cfm",
      "checkedAt": "2026-10-09",
      "scope": "공개 업무 범위 설명 참고. 회원 전용 양식 미열람"
    },
    {
      "title": "Basic Kitchen and Food Service Management — editable EPUB",
      "url": "https://opentextbc.ca/basickitchenandfoodservicemanagement/",
      "checkedAt": "2026-10-23",
      "scope": "BC Cook Articulation Committee, CC BY 4.0. Inventory and receiving principles; adapted into Korean store examples. Original EPUB and attribution are in the source pack. Not Korean legal or product-specific operating limits."
    },
    {
      "title": "Food Safety, Sanitation, and Personal Hygiene — editable EPUB",
      "url": "https://opentextbc.ca/foodsafety/",
      "checkedAt": "2026-10-23",
      "scope": "BC Cook Articulation Committee / go2HR, CC BY 4.0. Receiving and sanitation context; retain product labels and the store-approved procedure. The pack preserves the original publisher file and third-party credits."
    },
    {
      "title": "TAP Work — editable media, originals and licenses",
      "url": "https://tap2.work/manual-media/v1/",
      "checkedAt": "2026-10-23",
      "scope": "Original photos, CDC video, source EPUBs and editable motion scenes. Photos are illustrative. Each asset retains its own credit/license; no endorsement or completed field review is claimed."
    }
  ],
  "sourceId": "food/receiving",
  "collectionId": "food",
  "collectionName": "외식업 공통",
  "title": "입고 확인",
  "emoji": "📋",
  "slot": "준비",
  "reviewedAt": "2026-10-23",
  "basis": "공개 자료의 업무 범위를 참고하여 새로 작성한 운영 초안. 현장 방법·완료 기준은 책임자 확인 필요.",
  "steps": [
    {
      "id": "match",
      "title": "주문서와 납품 실물 대조",
      "manual": "납품 차량에서 받은 품목을 주문서와 하나씩 맞춰요. 품명·규격·수량·단위·로트·기한을 보고 납품 시각과 공급처를 적어요.\n\n완료 기준: 실제 수량과 불일치 품목이 분리돼 기록돼요.",
      "tip": "이상 시: 미주문·대체·누락품은 정상 입고와 구분하고 책임자에게 확인해요.",
      "tags": [
        "주문서와 납품 실물 대조"
      ],
      "imageUrl": "",
      "videoUrl": "https://tap2.work/manual-media/v1/receiving.mp4",
      "sourceUrl": "https://tap2.work/manual-media/v1/?guide=receiving"
    },
    {
      "id": "condition",
      "title": "포장·상태와 보관 조건 확인",
      "manual": "포장 파손·누출·오염·해동 흔적을 보고 표시된 보관 조건을 확인해요. 매장 검수 기준에 따라 필요한 온도를 실제로 측정해 기록해요.\n\n완료 기준: 검수 대상과 실제 결과를 추적할 수 있어요.",
      "tip": "이상 시: 외관·냄새만으로 안전을 확정하지 말고 기준 미달품을 판매 재고와 분리해요.",
      "tags": [
        "포장"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://tap2.work/manual-media/v1/?guide=receiving"
    },
    {
      "id": "detail-step-3",
      "title": "반품·보류품 표시",
      "manual": "문제 품목에 사용 보류 표시를 붙이고 품명·수량·로트·사유·사진을 남겨요. 납품 담당과 책임자에게 사실을 전달해 반품 또는 후속 조치를 정해요.\n\n완료 기준: 보류품을 다른 크루가 실수로 사용할 수 없어요.",
      "tip": "이상 시: 공급처와 처리 합의가 안 되면 임의 사용·폐기하지 말고 책임자에게 맡겨요.",
      "tags": [
        "반품"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://tap2.work/manual-media/v1/?guide=receiving"
    },
    {
      "id": "detail-step-4",
      "title": "승인된 입고분 즉시 보관",
      "manual": "냉장·냉동 등 제품 표시와 매장 기준에 맞는 장소로 옮겨요. 기존 재고와 사용 순서를 맞추되 생재료와 바로 먹는 음식을 분리해요.\n\n완료 기준: 통로에 방치된 식재료 없이 라벨과 보관 위치가 연결돼요.",
      "tip": "이상 시: 공간이 부족하면 부적절한 장소에 두지 말고 대체 보관을 승인받아요.",
      "tags": [
        "승인된 입고분 즉시 보관"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://tap2.work/manual-media/v1/?guide=receiving"
    },
    {
      "id": "detail-step-5",
      "title": "실제 받은 수량으로 입고 기록",
      "manual": "확정된 정상 입고분만 재고에 반영하고 반품·보류·미입고는 따로 남겨요. 납품서와 기록을 다시 대조해 다음 담당에게 전달해요.\n\n완료 기준: 기록 수량이 실제 보관한 수량과 맞아요.",
      "tip": "이상 시: 주문 수량 전체를 받은 것으로 처리하지 않아요.",
      "tags": [
        "실제 받은 수량으로 입고 기록"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://tap2.work/manual-media/v1/?guide=receiving"
    }
  ]
}
```

```tap2work-tap
{
  "sourceId": "food/storage",
  "collectionId": "food",
  "collectionName": "외식업 공통",
  "industryIds": [
    "food"
  ],
  "purposeId": "inventory",
  "kind": "operation",
  "summary": "보관·재고 확인 · 매장 조건과 기준을 연결해 사용하는 기본 절차",
  "applicability": "해당 업무를 운영하는 음식점. 시설·서비스 방식·제품·제조사 지침에 맞게 확인 후 사용하세요.",
  "jurisdiction": "운영 참고 · 매장별 적용 기준 확인",
  "keywords": [
    "보관·재고 확인"
  ],
  "references": [
    {
      "title": "식약처 개방형주방 매뉴얼",
      "url": "https://www.mfds.go.kr/brd/m_218/view.do?seq=20196",
      "checkedAt": "2026-10-09",
      "scope": "2015 자료의 업무 분류·관리 구조 참고. 최신 법적·수치 기준으로 사용하지 않음"
    },
    {
      "title": "RestaurantOwner 운영 체크리스트",
      "url": "https://www.restaurantowner.com/public/DOWNLOAD-Restaurant-Checklists.cfm",
      "checkedAt": "2026-10-09",
      "scope": "공개 업무 범위 설명 참고. 회원 전용 양식 미열람"
    }
  ],
  "emoji": "📋",
  "slot": "준비",
  "reviewedAt": "2026-10-13",
  "basis": "공개 자료의 업무 범위를 참고하여 새로 작성한 운영 초안. 현장 방법·완료 기준은 책임자 확인 필요.",
  "knowledge": {
    "scope": "food",
    "topics": [
      "inventory"
    ],
    "suggestedUse": "routine",
    "safetyReviewRequired": true
  },
  "steps": [
    {
      "id": "locate",
      "title": "보관 위치·라벨·사용 순서 정리",
      "manual": "보관대별로 품명·개봉 또는 준비 시각·매장 사용기한을 읽어요. 먼저 사용할 승인 재고를 앞에 두고 원재료와 완성식품을 분리해요.\n\n완료 기준: 다른 크루가 재료와 사용 순서를 바로 찾을 수 있어요.",
      "tip": "이상 시: 라벨을 추정해 새로 붙이지 말고 불명확한 재료는 사용을 보류해요.",
      "tags": [
        "보관 위치"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.mfds.go.kr/brd/m_218/view.do?seq=20196"
    },
    {
      "id": "count",
      "title": "단위별 실재고 세기",
      "manual": "개·봉·중량 등 정한 단위로 세고 개봉분을 구분해 적어요. 두 사람이 세는 구역은 중복 범위를 먼저 나눠요.\n\n완료 기준: 품목·위치·단위·실수량·점검 시각이 남아요.",
      "tip": "이상 시: 장부 차이는 재계수하고 판매·입고·폐기 기록을 확인해 원인을 남겨요.",
      "tags": [
        "단위별 실재고 세기"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.mfds.go.kr/brd/m_218/view.do?seq=20196"
    },
    {
      "id": "detail-step-3",
      "title": "기한·손상·격리품 점검",
      "manual": "기한 임박, 포장 손상, 누출, 해동 흔적을 살펴요. 사용 가능한 임박품과 폐기 또는 판단 대기품을 구분해 담당자에게 전달해요.\n\n완료 기준: 사용 금지 재료가 판매 재고와 구분돼요.",
      "tip": "이상 시: 기한이나 이력을 알 수 없으면 맛보기로 판단하지 않아요.",
      "tags": [
        "기한"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.mfds.go.kr/brd/m_218/view.do?seq=20196"
    },
    {
      "id": "detail-step-4",
      "title": "보관 설비와 통풍 공간 확인",
      "manual": "문 닫힘·표시값·선반 오염을 보고 바닥 적치나 통풍구 가림을 정리해요. 식품 위에 세제나 개인 물품을 두지 않아요.\n\n완료 기준: 보관 조건과 청결을 유지하며 꺼낼 수 있어요.",
      "tip": "이상 시: 장비 이상은 영향을 받은 식품과 함께 보고해 이동 여부를 승인받아요.",
      "tags": [
        "보관 설비와 통풍 공간 확인"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.mfds.go.kr/brd/m_218/view.do?seq=20196"
    },
    {
      "id": "detail-step-5",
      "title": "재고 차이와 보충 필요 인계",
      "manual": "부족·과잉·임박·격리 품목을 수량·위치와 함께 남겨요. 주문 후 재고 확인 업무라면 해당 주문을 표시하고 결과만 기록해요.\n\n완료 기준: 담당자가 다음 구매·사용·폐기를 결정할 자료가 있어요.",
      "tip": "이상 시: 중간 점검이나 입고로 주문 기준 확인 기한을 임의로 미루지 않아요.",
      "tags": [
        "재고 차이와 보충 필요 인계"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.mfds.go.kr/brd/m_218/view.do?seq=20196"
    }
  ],
  "title": "보관·재고 확인"
}
```

```tap2work-tap
{
  "sourceId": "food/prep",
  "collectionId": "food",
  "collectionName": "외식업 공통",
  "industryIds": [
    "food"
  ],
  "purposeId": "production",
  "kind": "operation",
  "summary": "식재료 전처리·준비 · 매장 조건과 기준을 연결해 사용하는 기본 절차",
  "applicability": "해당 업무를 운영하는 음식점. 시설·서비스 방식·제품·제조사 지침에 맞게 확인 후 사용하세요.",
  "jurisdiction": "운영 참고 · 매장별 적용 기준 확인",
  "keywords": [
    "식재료 전처리·준비"
  ],
  "references": [
    {
      "title": "식약처 개방형주방 매뉴얼",
      "url": "https://www.mfds.go.kr/brd/m_218/view.do?seq=20196",
      "checkedAt": "2026-10-09",
      "scope": "2015 자료의 업무 분류·관리 구조 참고. 최신 법적·수치 기준으로 사용하지 않음"
    },
    {
      "title": "RestaurantOwner 운영 체크리스트",
      "url": "https://www.restaurantowner.com/public/DOWNLOAD-Restaurant-Checklists.cfm",
      "checkedAt": "2026-10-09",
      "scope": "공개 업무 범위 설명 참고. 회원 전용 양식 미열람"
    }
  ],
  "emoji": "📋",
  "slot": "준비",
  "reviewedAt": "2026-10-13",
  "basis": "공개 자료의 업무 범위를 참고하여 새로 작성한 운영 초안. 현장 방법·완료 기준은 책임자 확인 필요.",
  "knowledge": {
    "scope": "food",
    "topics": [
      "production"
    ],
    "suggestedUse": "routine",
    "safetyReviewRequired": true
  },
  "steps": [
    {
      "id": "plan",
      "title": "레시피·수량·사용 시점 확인",
      "manual": "메뉴별 승인 레시피에서 재료·배수·절단 크기를 확인해요. 첫 준비량과 추가 준비량, 사용할 시점을 작업표에 적어요.\n\n완료 기준: 어떤 재료를 얼마나 준비할지 정해져 있어요.",
      "tip": "이상 시: 배합·기준이 없거나 주문량이 바뀌면 임의로 늘리지 말고 담당자와 맞춰요.",
      "tags": [
        "레시피"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.mfds.go.kr/brd/m_218/view.do?seq=20196"
    },
    {
      "id": "detail-step-2",
      "title": "작업 구역과 도구 나누기",
      "manual": "생육·해산물과 바로 먹는 채소·완성식품의 도구·용기를 구분해요. 먼저 할 작업을 정하고 작업 전 손과 작업대를 정리해요.\n\n완료 기준: 준비된 도구가 재료별로 구분되고 깨끗해요.",
      "tip": "이상 시: 같은 도구를 써야 하면 작업 사이 세척·소독 절차를 마친 뒤 전환해요.",
      "tags": [
        "작업 구역과 도구 나누기"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.mfds.go.kr/brd/m_218/view.do?seq=20196"
    },
    {
      "id": "prepare",
      "title": "전처리·계량·소분 수행",
      "manual": "제품 표시와 승인 레시피 순서대로 세척·손질하고 저울의 용기 무게를 뺀 뒤 분량을 맞춰요. 한 용기의 수량을 먼저 버디와 대조한 뒤 같은 방식으로 소분해요.\n\n완료 기준: 절단 크기·중량·수량이 기준과 맞아요.",
      "tip": "이상 시: 변색·이물·기준 미달 재료는 섞지 말고 분리해 알려요.",
      "tags": [
        "전처리"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.mfds.go.kr/brd/m_218/view.do?seq=20196"
    },
    {
      "id": "detail-step-4",
      "title": "품명·시각·사용 기준 표시",
      "manual": "용기를 닫고 품명·준비 시각·확인된 사용기한·보관 위치를 표시해요. 기존 재고와 새 준비분을 구별하고 필요한 양만 작업대에 남겨요.\n\n완료 기준: 다른 크루가 표시를 읽고 올바른 순서로 사용할 수 있어요.",
      "tip": "이상 시: 표시가 지워졌거나 기준이 없으면 책임자가 확인할 때까지 사용을 보류해요.",
      "tags": [
        "품명"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.mfds.go.kr/brd/m_218/view.do?seq=20196"
    },
    {
      "id": "handover",
      "title": "준비 수량과 부족분 인계",
      "manual": "완료 수량·보관 위치·남은 원재료와 부족분을 담당자에게 전달해요. 도구를 세척하고 작업대·바닥의 오염을 제거해요.\n\n완료 기준: 다음 작업자가 준비분을 찾을 수 있고 구역이 정리돼요.",
      "tip": "이상 시: 미완료는 완료로 체크하지 말고 남은 수량과 예상 마무리 시각을 남겨요.",
      "tags": [
        "준비 수량과 부족분 인계"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.mfds.go.kr/brd/m_218/view.do?seq=20196"
    }
  ],
  "title": "식재료 전처리·준비"
}
```

```tap2work-tap
{
  "sourceId": "food/cooking",
  "collectionId": "food",
  "collectionName": "외식업 공통",
  "industryIds": [
    "food"
  ],
  "purposeId": "production",
  "kind": "operation",
  "summary": "조리·완성 확인 · 매장 조건과 기준을 연결해 사용하는 기본 절차",
  "applicability": "해당 업무를 운영하는 음식점. 시설·서비스 방식·제품·제조사 지침에 맞게 확인 후 사용하세요.",
  "jurisdiction": "운영 참고 · 매장별 적용 기준 확인",
  "keywords": [
    "조리·완성 확인"
  ],
  "references": [
    {
      "title": "식약처 개방형주방 매뉴얼",
      "url": "https://www.mfds.go.kr/brd/m_218/view.do?seq=20196",
      "checkedAt": "2026-10-09",
      "scope": "2015 자료의 업무 분류·관리 구조 참고. 최신 법적·수치 기준으로 사용하지 않음"
    },
    {
      "title": "RestaurantOwner 운영 체크리스트",
      "url": "https://www.restaurantowner.com/public/DOWNLOAD-Restaurant-Checklists.cfm",
      "checkedAt": "2026-10-09",
      "scope": "공개 업무 범위 설명 참고. 회원 전용 양식 미열람"
    }
  ],
  "emoji": "📋",
  "slot": "피크",
  "reviewedAt": "2026-10-13",
  "basis": "공개 자료의 업무 범위를 참고하여 새로 작성한 운영 초안. 현장 방법·완료 기준은 책임자 확인 필요.",
  "knowledge": {
    "scope": "food",
    "topics": [
      "production"
    ],
    "suggestedUse": "routine",
    "safetyReviewRequired": true
  },
  "steps": [
    {
      "id": "order",
      "title": "주문번호·메뉴·옵션 읽기",
      "manual": "주문번호와 테이블 또는 포장 채널, 수량·사이즈·맵기·제외·추가 요청을 소리 내어 되짚어요. 변경표는 이전 주문과 구분해요.\n\n완료 기준: 조리자와 전달자가 같은 주문을 알고 있어요.",
      "tip": "이상 시: 알레르기 요청은 재료·도구 교차접촉을 책임자에게 확인한 뒤 제공 가능 여부를 안내해요.",
      "tags": [
        "주문번호"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.mfds.go.kr/brd/m_218/view.do?seq=20196"
    },
    {
      "id": "detail-step-2",
      "title": "레시피와 준비분 대조",
      "manual": "승인 레시피의 배합·분량·장비·완료 기준을 열고 해당 배치의 라벨을 확인해요. 완성품용 접시·집게와 원재료 도구를 분리해요.\n\n완료 기준: 승인된 재료·도구·작업 기준을 갖췄어요.",
      "tip": "이상 시: 이력 불명 재료와 대체 재료를 임의로 쓰지 않아요.",
      "tags": [
        "레시피와 준비분 대조"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.mfds.go.kr/brd/m_218/view.do?seq=20196"
    },
    {
      "id": "process",
      "title": "메뉴별 조리 순서 수행",
      "manual": "레시피에 정한 투입 순서·분량·화력·시간을 따라요. 배치별 시작 시각을 구분하고 확인이 필요한 시간·온도는 실제 값으로 남겨요.\n\n완료 기준: 해당 메뉴의 검증된 조리 완료 기준을 충족했어요.",
      "tip": "이상 시: 익힘 미달이나 기록 누락은 정상 출고하지 말고 책임자가 정한 재처리·폐기 절차를 따라요.",
      "tags": [
        "메뉴별 조리 순서 수행"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.mfds.go.kr/brd/m_218/view.do?seq=20196"
    },
    {
      "id": "finish",
      "title": "완성품과 주문표 대조",
      "manual": "메뉴·수량·옵션·소스·사이드·접시 가장자리와 이물을 확인해요. 한 주문의 품목을 모아 제공 순서를 홀 또는 포장 담당과 맞춰요.\n\n완료 기준: 누락·다른 주문 혼입 없이 주문표와 실물이 맞아요.",
      "tip": "이상 시: 틀린 옵션·품목은 표시를 바꾸는 것만으로 처리하지 말고 재조리 여부를 확인해요.",
      "tags": [
        "완성품과 주문표 대조"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.mfds.go.kr/brd/m_218/view.do?seq=20196"
    },
    {
      "id": "detail-step-5",
      "title": "뜨거운 음식 안전하게 전달",
      "manual": "용기 손잡이와 받침을 확인하고 이동 경로를 비워요. 주문번호·뜨거움·남은 품목을 전달자에게 말하고 인수 여부를 확인해요.\n\n완료 기준: 수령 담당과 제공 순서가 확인돼요.",
      "tip": "이상 시: 넘침·용기 손상이 있으면 이동을 멈추고 안전하게 재포장해요.",
      "tags": [
        "뜨거운 음식 안전하게 전달"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.mfds.go.kr/brd/m_218/view.do?seq=20196"
    }
  ],
  "title": "조리·완성 확인"
}
```

```tap2work-tap
{
  "sourceId": "food/service",
  "collectionId": "food",
  "collectionName": "외식업 공통",
  "industryIds": [
    "food"
  ],
  "purposeId": "service",
  "kind": "operation",
  "summary": "홀 서비스·고객 요청 · 매장 조건과 기준을 연결해 사용하는 기본 절차",
  "applicability": "해당 업무를 운영하는 음식점. 시설·서비스 방식·제품·제조사 지침에 맞게 확인 후 사용하세요.",
  "jurisdiction": "운영 참고 · 매장별 적용 기준 확인",
  "keywords": [
    "홀 서비스·고객 요청"
  ],
  "references": [
    {
      "title": "식약처 개방형주방 매뉴얼",
      "url": "https://www.mfds.go.kr/brd/m_218/view.do?seq=20196",
      "checkedAt": "2026-10-09",
      "scope": "2015 자료의 업무 분류·관리 구조 참고. 최신 법적·수치 기준으로 사용하지 않음"
    },
    {
      "title": "RestaurantOwner 운영 체크리스트",
      "url": "https://www.restaurantowner.com/public/DOWNLOAD-Restaurant-Checklists.cfm",
      "checkedAt": "2026-10-09",
      "scope": "공개 업무 범위 설명 참고. 회원 전용 양식 미열람"
    }
  ],
  "emoji": "📋",
  "slot": "피크",
  "reviewedAt": "2026-10-13",
  "basis": "공개 자료의 업무 범위를 참고하여 새로 작성한 운영 초안. 현장 방법·완료 기준은 책임자 확인 필요.",
  "knowledge": {
    "scope": "food",
    "topics": [
      "service",
      "hall"
    ],
    "suggestedUse": "routine",
    "safetyReviewRequired": false
  },
  "steps": [
    {
      "id": "request",
      "title": "손님 요청을 되짚어 확인",
      "manual": "인원·테이블과 주문 메뉴·수량·옵션을 확인하고 주문 내용을 다시 읽어 드려요. 품절·대기 시간은 주방에서 확인한 내용으로 안내해요.\n\n완료 기준: 손님과 주문 내용이 일치하고 주문번호가 남아요.",
      "tip": "이상 시: 알레르기·제외 요청은 임의로 가능하다고 답하지 말고 조리 담당에게 확인해요.",
      "tags": [
        "손님 요청을 되짚어 확인"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.restaurantowner.com/public/DOWNLOAD-Restaurant-Checklists.cfm"
    },
    {
      "id": "detail-step-2",
      "title": "주방에 요청 전달·변경 확인",
      "manual": "테이블·주문번호·요청 내용을 정해진 주문 경로로 전하고 수신을 확인해요. 변경·취소 시 이미 조리 중인지 먼저 확인해요.\n\n완료 기준: 주방이 최신 요청을 알고 이전 요청과 구분해요.",
      "tip": "이상 시: 전달이 누락되면 손님에게 현재 상태를 설명하고 책임자에게 연결해요.",
      "tags": [
        "주방에 요청 전달"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.restaurantowner.com/public/DOWNLOAD-Restaurant-Checklists.cfm"
    },
    {
      "id": "serve",
      "title": "테이블·메뉴 대조 후 제공",
      "manual": "테이블 번호와 메뉴를 확인하고 뜨거운 그릇은 미리 알린 뒤 안정된 위치에 놓아요. 아이·가방·휴대품 위로 뜨거운 음식을 넘기지 않아요.\n\n완료 기준: 맞는 손님에게 안전하게 제공하고 남은 메뉴가 확인돼요.",
      "tip": "이상 시: 주문이 다르면 손님에게 확인하고 임의 교환·합류하지 않아요.",
      "tags": [
        "테이블"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.restaurantowner.com/public/DOWNLOAD-Restaurant-Checklists.cfm"
    },
    {
      "id": "detail-step-4",
      "title": "불편·지연·추가 요청 처리",
      "manual": "손님 말을 끊지 않고 사실을 확인해 주문번호·문제·요청을 책임자에게 전해요. 가능한 조치와 확인 후 안내할 시점을 분명히 말해요.\n\n완료 기준: 누가 후속 안내를 할지 정해져 있어요.",
      "tip": "이상 시: 환불·보상·안전 판단은 권한 밖에서 약속하지 않아요.",
      "tags": [
        "불편"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.restaurantowner.com/public/DOWNLOAD-Restaurant-Checklists.cfm"
    },
    {
      "id": "reset",
      "title": "퇴석 테이블 회전 정리",
      "manual": "분실물을 먼저 확인하고 식기·잔반을 수거해요. 테이블과 의자 접촉면을 정리한 뒤 깨끗한 집기를 새로 놓고 바닥을 봐요.\n\n완료 기준: 오염 식기와 잔반 없이 다음 손님을 받을 수 있어요.",
      "tip": "이상 시: 분실물은 임의 사용·공개하지 말고 발견 위치·시각과 함께 책임자에게 인계해요.",
      "tags": [
        "퇴석 테이블 회전 정리"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.restaurantowner.com/public/DOWNLOAD-Restaurant-Checklists.cfm"
    }
  ],
  "title": "홀 서비스·고객 요청"
}
```

```tap2work-tap
{
  "sourceId": "food/packing",
  "collectionId": "food",
  "collectionName": "외식업 공통",
  "industryIds": [
    "food"
  ],
  "purposeId": "service",
  "kind": "operation",
  "summary": "포장·배달 인계 · 매장 조건과 기준을 연결해 사용하는 기본 절차",
  "applicability": "해당 업무를 운영하는 음식점. 시설·서비스 방식·제품·제조사 지침에 맞게 확인 후 사용하세요.",
  "jurisdiction": "운영 참고 · 매장별 적용 기준 확인",
  "keywords": [
    "포장·배달 인계"
  ],
  "references": [
    {
      "title": "식약처 개방형주방 매뉴얼",
      "url": "https://www.mfds.go.kr/brd/m_218/view.do?seq=20196",
      "checkedAt": "2026-10-09",
      "scope": "2015 자료의 업무 분류·관리 구조 참고. 최신 법적·수치 기준으로 사용하지 않음"
    },
    {
      "title": "RestaurantOwner 운영 체크리스트",
      "url": "https://www.restaurantowner.com/public/DOWNLOAD-Restaurant-Checklists.cfm",
      "checkedAt": "2026-10-09",
      "scope": "공개 업무 범위 설명 참고. 회원 전용 양식 미열람"
    }
  ],
  "emoji": "📋",
  "slot": "피크",
  "reviewedAt": "2026-10-13",
  "basis": "공개 자료의 업무 범위를 참고하여 새로 작성한 운영 초안. 현장 방법·완료 기준은 책임자 확인 필요.",
  "knowledge": {
    "scope": "food",
    "topics": [
      "service",
      "takeout"
    ],
    "suggestedUse": "routine",
    "safetyReviewRequired": false
  },
  "steps": [
    {
      "id": "match",
      "title": "주문표 한 장씩 구성 확인",
      "manual": "한 주문의 본품·사이드·소스·음료·수저·제외 요청을 순서대로 읽어요. 여러 주문은 별도 칸에 놓고 주문번호를 표시해요.\n\n완료 기준: 한 주문의 준비 완료품과 대기품이 구분돼요.",
      "tip": "이상 시: 다른 주문이 섞이면 모두 다시 대조해요.",
      "tags": [
        "주문표 한 장씩 구성 확인"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.restaurantowner.com/public/DOWNLOAD-Restaurant-Checklists.cfm"
    },
    {
      "id": "detail-step-2",
      "title": "메뉴에 맞는 용기 준비",
      "manual": "식품용 용기를 확인하고 파손·오염·뚜껑 규격을 봐요. 뜨거운 것과 차가운 것, 국물과 마른 식품을 매장 포장 기준에 따라 구분해요.\n\n완료 기준: 해당 메뉴를 담을 수 있는 깨끗한 용기와 맞는 뚜껑이 있어요.",
      "tip": "이상 시: 규격이 없으면 임의 용기로 대체하지 말고 책임자에게 확인해요.",
      "tags": [
        "메뉴에 맞는 용기 준비"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.restaurantowner.com/public/DOWNLOAD-Restaurant-Checklists.cfm"
    },
    {
      "id": "pack",
      "title": "밀폐·누수·외부 오염 확인",
      "manual": "용기를 과하게 채우지 않고 뚜껑을 가장자리까지 닫아요. 안정된 상태에서 밀폐와 누출을 확인하고 용기 겉면을 정리해요.\n\n완료 기준: 뚜껑 들뜸·누출이 없고 운반 중 기울지 않아요.",
      "tip": "이상 시: 뜨거운 국물을 무리하게 기울이거나 눌러 확인하지 말고 용기를 교체해요.",
      "tags": [
        "밀폐"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.restaurantowner.com/public/DOWNLOAD-Restaurant-Checklists.cfm"
    },
    {
      "id": "detail-step-4",
      "title": "최종 대조와 봉투 표시",
      "manual": "실물과 주문표를 한 번 더 맞추고 무거운 용기는 아래에 놓아요. 봉투에 주문번호와 여러 봉투일 때 총 개수를 표시해요.\n\n완료 기준: 누락 없이 주문별 포장이 식별돼요.",
      "tip": "이상 시: 확인되지 않은 항목은 체크하지 말고 조리 담당에게 확인해요.",
      "tags": [
        "최종 대조와 봉투 표시"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.restaurantowner.com/public/DOWNLOAD-Restaurant-Checklists.cfm"
    },
    {
      "id": "handoff",
      "title": "수령자 주문번호와 인계 대조",
      "manual": "손님 또는 기사에게 주문번호를 확인하고 봉투 수·음료·취급 주의를 전해요. 실제 수령 뒤 인계 시각·상태를 기록해요.\n\n완료 기준: 맞는 수령자에게 모든 봉투가 전달됐어요.",
      "tip": "이상 시: 수령 지연품은 매장 보관·출고 기준으로 관리하고 기준을 넘으면 책임자에게 알려요.",
      "tags": [
        "수령자 주문번호와 인계 대조"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.restaurantowner.com/public/DOWNLOAD-Restaurant-Checklists.cfm"
    }
  ],
  "title": "포장·배달 인계"
}
```

```tap2work-tap
{
  "sourceId": "food/cleaning",
  "collectionId": "food",
  "collectionName": "외식업 공통",
  "industryIds": [
    "food"
  ],
  "purposeId": "hygiene",
  "kind": "operation",
  "summary": "세척·청소 · 매장 조건과 기준을 연결해 사용하는 기본 절차",
  "applicability": "해당 업무를 운영하는 음식점. 시설·서비스 방식·제품·제조사 지침에 맞게 확인 후 사용하세요.",
  "jurisdiction": "운영 참고 · 매장별 적용 기준 확인",
  "keywords": [
    "세척·청소"
  ],
  "references": [
    {
      "title": "식약처 개방형주방 매뉴얼",
      "url": "https://www.mfds.go.kr/brd/m_218/view.do?seq=20196",
      "checkedAt": "2026-10-09",
      "scope": "2015 자료의 업무 분류·관리 구조 참고. 최신 법적·수치 기준으로 사용하지 않음"
    },
    {
      "title": "RestaurantOwner 운영 체크리스트",
      "url": "https://www.restaurantowner.com/public/DOWNLOAD-Restaurant-Checklists.cfm",
      "checkedAt": "2026-10-09",
      "scope": "공개 업무 범위 설명 참고. 회원 전용 양식 미열람"
    }
  ],
  "emoji": "📋",
  "slot": "마감",
  "reviewedAt": "2026-10-13",
  "basis": "공개 자료의 업무 범위를 참고하여 새로 작성한 운영 초안. 현장 방법·완료 기준은 책임자 확인 필요.",
  "knowledge": {
    "scope": "food",
    "topics": [
      "hygiene"
    ],
    "suggestedUse": "routine",
    "safetyReviewRequired": true
  },
  "steps": [
    {
      "id": "prepare",
      "title": "대상·제품·도구 확인",
      "manual": "식품과 깨끗한 식기를 치우고 청소할 구역을 표시해요. 제품 라벨에서 적용 표면·희석·접촉시간·헹굼·보호구를 확인하고 구역 전용 도구를 준비해요.\n\n완료 기준: 식품이 노출되지 않고 맞는 제품·도구를 갖췄어요.",
      "tip": "이상 시: 라벨 없는 약품이나 용도가 다른 제품을 쓰거나 서로 섞지 않아요.",
      "tags": [
        "대상"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.mfds.go.kr/brd/m_218/view.do?seq=20196"
    },
    {
      "id": "detail-step-2",
      "title": "찌꺼기·기름 등 큰 오염 제거",
      "manual": "음식물과 이물을 먼저 수거하고 배수망·틈새의 찌꺼기를 제거해요. 칼날·깨진 조각은 손으로 쓸어 담지 않아요.\n\n완료 기준: 세척 전에 큰 오염과 위험물이 제거됐어요.",
      "tip": "이상 시: 날카로운 물건은 도구로 수거하고 파손 위치를 알려요.",
      "tags": [
        "찌꺼기"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.mfds.go.kr/brd/m_218/view.do?seq=20196"
    },
    {
      "id": "clean",
      "title": "세척·소독 순서 수행",
      "manual": "해당 표면과 제품 지침대로 세척하고 필요한 헹굼·소독을 진행해요. 소독이 필요한 표면은 정해진 농도·접촉시간을 확인해요.\n\n완료 기준: 오염 제거와 제품에 필요한 처리가 끝났어요.",
      "tip": "이상 시: 시간·희석을 모르거나 잘못 적용했으면 완료하지 말고 지침을 다시 확인해요.",
      "tags": [
        "세척"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.mfds.go.kr/brd/m_218/view.do?seq=20196"
    },
    {
      "id": "detail-step-4",
      "title": "자연 건조와 청결 보관",
      "manual": "세척한 식기는 물이 빠지는 깨끗한 건조대에 두고 마른 뒤 보관해요. 청소 도구를 세척·건조하고 식품·깨끗한 집기와 나눠 놓아요.\n\n완료 기준: 오염수·젖은 오염 행주와 다시 접촉하지 않아요.",
      "tip": "이상 시: 덜 마른 식기를 포개거나 더러운 행주로 닦아 마무리하지 않아요.",
      "tags": [
        "자연 건조와 청결 보관"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.mfds.go.kr/brd/m_218/view.do?seq=20196"
    },
    {
      "id": "inspect",
      "title": "빛 아래서 결과 확인·재개",
      "manual": "손잡이·모서리·배수구와 바닥을 다시 보고 찌꺼기·잔여 제품·물기를 확인해요. 물품을 복구하고 청소 시각·미완료 부분을 남겨요.\n\n완료 기준: 깨끗한 표면과 안전한 통로를 확인한 뒤 구역을 열어요.",
      "tip": "이상 시: 오염이 남으면 해당 부분을 다시 처리하고 재점검해요.",
      "tags": [
        "빛 아래서 결과 확인"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.mfds.go.kr/brd/m_218/view.do?seq=20196"
    }
  ],
  "title": "세척·청소"
}
```

```tap2work-tap
{
  "sourceId": "food/restrooms",
  "collectionId": "food",
  "collectionName": "외식업 공통",
  "industryIds": [
    "food"
  ],
  "purposeId": "hygiene",
  "kind": "operation",
  "summary": "화장실 점검·청소 · 매장 조건과 기준을 연결해 사용하는 기본 절차",
  "applicability": "해당 업무를 운영하는 음식점. 시설·서비스 방식·제품·제조사 지침에 맞게 확인 후 사용하세요.",
  "jurisdiction": "운영 참고 · 매장별 적용 기준 확인",
  "keywords": [
    "화장실 점검·청소"
  ],
  "references": [
    {
      "title": "식약처 개방형주방 매뉴얼",
      "url": "https://www.mfds.go.kr/brd/m_218/view.do?seq=20196",
      "checkedAt": "2026-10-09",
      "scope": "2015 자료의 업무 분류·관리 구조 참고. 최신 법적·수치 기준으로 사용하지 않음"
    },
    {
      "title": "RestaurantOwner 운영 체크리스트",
      "url": "https://www.restaurantowner.com/public/DOWNLOAD-Restaurant-Checklists.cfm",
      "checkedAt": "2026-10-09",
      "scope": "공개 업무 범위 설명 참고. 회원 전용 양식 미열람"
    }
  ],
  "emoji": "📋",
  "slot": "준비",
  "reviewedAt": "2026-10-13",
  "basis": "공개 자료의 업무 범위를 참고하여 새로 작성한 운영 초안. 현장 방법·완료 기준은 책임자 확인 필요.",
  "knowledge": {
    "scope": "food",
    "topics": [
      "hygiene"
    ],
    "suggestedUse": "routine",
    "safetyReviewRequired": true
  },
  "steps": [
    {
      "id": "check",
      "title": "사용 중 표시와 비품 확인",
      "manual": "손님 사용 여부를 보고 청소 중 안내를 세워요. 휴지·비누·건조 수단, 변기·세면대의 막힘·누수와 조명을 확인해요.\n\n완료 기준: 사용자 접근을 안내하고 보충·고장 항목을 알 수 있어요.",
      "tip": "이상 시: 오수 넘침이나 파손이 있으면 사용을 막고 책임자에게 알려요.",
      "tags": [
        "사용 중 표시와 비품 확인"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.mfds.go.kr/brd/m_218/view.do?seq=20196"
    },
    {
      "id": "clean",
      "title": "깨끗한 곳에서 오염된 곳 순서로 청소",
      "manual": "화장실 전용 장갑·도구로 손잡이·세면대·변기·바닥을 구분해 처리해요. 제품 지침을 따르고 변기용 도구를 세면대나 주방에 쓰지 않아요.\n\n완료 기준: 접촉면·변기·바닥에 눈에 보이는 오염과 잔여 제품이 없어요.",
      "tip": "이상 시: 체액·날카로운 물체는 일반 청소로 덮지 말고 정해진 별도 절차를 확인해요.",
      "tags": [
        "깨끗한 곳에서 오염된 곳 순서로 청소"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.mfds.go.kr/brd/m_218/view.do?seq=20196"
    },
    {
      "id": "detail-step-3",
      "title": "비품 채우고 작동 확인",
      "manual": "휴지·비누를 채우고 물 내림·수도·건조 수단을 확인해요. 물기를 없애고 쓰레기를 밀폐해 지정 경로로 옮겨요.\n\n완료 기준: 손님이 바로 사용할 수 있고 바닥이 미끄럽지 않아요.",
      "tip": "이상 시: 반복 막힘·누수는 임시 조치와 사용 제한을 인계해요.",
      "tags": [
        "비품 채우고 작동 확인"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.mfds.go.kr/brd/m_218/view.do?seq=20196"
    },
    {
      "id": "detail-step-4",
      "title": "도구 분리 보관·손 씻기",
      "manual": "화장실 도구를 씻고 말려 지정 위치에 놓아요. 장갑을 벗고 손을 씻은 뒤 다른 업무로 돌아가요. 점검 시각·미해결 문제를 남겨요.\n\n완료 기준: 화장실 오염을 홀·주방으로 옮기지 않고 재개했어요.",
      "tip": "이상 시: 청소 도구가 섞였으면 사용을 멈추고 분리·재처리해요.",
      "tags": [
        "도구 분리 보관"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.mfds.go.kr/brd/m_218/view.do?seq=20196"
    }
  ],
  "title": "화장실 점검·청소"
}
```

```tap2work-tap
{
  "sourceId": "food/waste",
  "collectionId": "food",
  "collectionName": "외식업 공통",
  "industryIds": [
    "food"
  ],
  "purposeId": "hygiene",
  "kind": "operation",
  "summary": "폐기물 정리 · 매장 조건과 기준을 연결해 사용하는 기본 절차",
  "applicability": "해당 업무를 운영하는 음식점. 시설·서비스 방식·제품·제조사 지침에 맞게 확인 후 사용하세요.",
  "jurisdiction": "운영 참고 · 매장별 적용 기준 확인",
  "keywords": [
    "폐기물 정리"
  ],
  "references": [
    {
      "title": "식약처 개방형주방 매뉴얼",
      "url": "https://www.mfds.go.kr/brd/m_218/view.do?seq=20196",
      "checkedAt": "2026-10-09",
      "scope": "2015 자료의 업무 분류·관리 구조 참고. 최신 법적·수치 기준으로 사용하지 않음"
    },
    {
      "title": "RestaurantOwner 운영 체크리스트",
      "url": "https://www.restaurantowner.com/public/DOWNLOAD-Restaurant-Checklists.cfm",
      "checkedAt": "2026-10-09",
      "scope": "공개 업무 범위 설명 참고. 회원 전용 양식 미열람"
    }
  ],
  "emoji": "📋",
  "slot": "마감",
  "reviewedAt": "2026-10-13",
  "basis": "공개 자료의 업무 범위를 참고하여 새로 작성한 운영 초안. 현장 방법·완료 기준은 책임자 확인 필요.",
  "knowledge": {
    "scope": "food",
    "topics": [
      "hygiene"
    ],
    "suggestedUse": "routine",
    "safetyReviewRequired": false
  },
  "steps": [
    {
      "id": "sort",
      "title": "일반·재활용·음식물 분리",
      "manual": "매장 배출 안내에 따라 내용물과 포장재를 나눠요. 깨진 유리·날카로운 물건은 지정 용기와 표시를 사용해요.\n\n완료 기준: 종류별 용기에 이물 혼입 없이 담겼어요.",
      "tip": "이상 시: 분류가 불명확하면 책임자에게 확인하고 음식물통에 약품·위험물을 버리지 않아요.",
      "tags": [
        "일반"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.restaurantowner.com/public/DOWNLOAD-Restaurant-Checklists.cfm"
    },
    {
      "id": "detail-step-2",
      "title": "넘치기 전 밀폐·무게 확인",
      "manual": "지정 채움선 전에 비우고 봉투를 묶어요. 새는 곳과 운반 무게를 보고 필요하면 두 사람이 옮겨요.\n\n완료 기준: 새지 않고 안전하게 들 수 있어요.",
      "tip": "이상 시: 압축하려고 손을 넣지 말고 누출 봉투는 적합한 외부 용기로 보강해요.",
      "tags": [
        "넘치기 전 밀폐"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.restaurantowner.com/public/DOWNLOAD-Restaurant-Checklists.cfm"
    },
    {
      "id": "move",
      "title": "지정 시각·장소로 배출",
      "manual": "우리매장의 배출 장소·시간을 확인하고 음식 준비 동선을 피해서 옮겨요. 배출 후 뚜껑·문을 닫고 통로를 정리해요.\n\n완료 기준: 배출 규칙을 지키고 출입·피난 통로를 막지 않아요.",
      "tip": "이상 시: 배출 장소가 잠겨 있으면 임의 장소에 두지 말고 임시 보관을 확인해요.",
      "tags": [
        "지정 시각"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.restaurantowner.com/public/DOWNLOAD-Restaurant-Checklists.cfm"
    },
    {
      "id": "pest",
      "title": "용기 세척과 해충 흔적 보고",
      "manual": "쓰레기통과 주변 누출을 전용 도구로 정리하고 손을 씻어요. 벌레·배설물·갉은 흔적은 위치와 시각을 기록해 책임자에게 알려요.\n\n완료 기준: 빈 용기와 주변이 깨끗하고 뚜껑이 닫혀요.",
      "tip": "이상 시: 식품 주변에 임의로 살충제를 뿌리지 말고 영향을 받은 식품을 구분해요.",
      "tags": [
        "용기 세척과 해충 흔적 보고"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.restaurantowner.com/public/DOWNLOAD-Restaurant-Checklists.cfm"
    }
  ],
  "title": "폐기물 정리"
}
```

```tap2work-tap
{
  "sourceId": "food/hall-close",
  "collectionId": "food",
  "collectionName": "외식업 공통",
  "industryIds": [
    "food"
  ],
  "purposeId": "closing",
  "kind": "operation",
  "summary": "홀 마감 · 매장 조건과 기준을 연결해 사용하는 기본 절차",
  "applicability": "해당 업무를 운영하는 음식점. 시설·서비스 방식·제품·제조사 지침에 맞게 확인 후 사용하세요.",
  "jurisdiction": "운영 참고 · 매장별 적용 기준 확인",
  "keywords": [
    "홀 마감"
  ],
  "references": [
    {
      "title": "식약처 개방형주방 매뉴얼",
      "url": "https://www.mfds.go.kr/brd/m_218/view.do?seq=20196",
      "checkedAt": "2026-10-09",
      "scope": "2015 자료의 업무 분류·관리 구조 참고. 최신 법적·수치 기준으로 사용하지 않음"
    },
    {
      "title": "RestaurantOwner 운영 체크리스트",
      "url": "https://www.restaurantowner.com/public/DOWNLOAD-Restaurant-Checklists.cfm",
      "checkedAt": "2026-10-09",
      "scope": "공개 업무 범위 설명 참고. 회원 전용 양식 미열람"
    }
  ],
  "emoji": "📋",
  "slot": "마감",
  "reviewedAt": "2026-10-13",
  "basis": "공개 자료의 업무 범위를 참고하여 새로 작성한 운영 초안. 현장 방법·완료 기준은 책임자 확인 필요.",
  "knowledge": {
    "scope": "food",
    "topics": [
      "closing",
      "hall"
    ],
    "suggestedUse": "routine",
    "safetyReviewRequired": false
  },
  "steps": [
    {
      "id": "tables",
      "title": "테이블·의자·바닥 순서로 정리",
      "manual": "마지막 손님 퇴석과 분실물을 확인한 뒤 식기·잔반을 수거해요. 테이블 번호 순서로 접촉면·의자·바닥을 정리하고 파손을 살펴요.\n\n완료 기준: 각 테이블이 빈 상태로 깨끗하고 통로에 집기가 없어요.",
      "tip": "이상 시: 손님이 남은 구역은 청소 범위를 나누고 분실물·파손을 인계해요.",
      "tags": [
        "테이블"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.restaurantowner.com/public/DOWNLOAD-Restaurant-Checklists.cfm"
    },
    {
      "id": "selfbar",
      "title": "셀프바 음식·용기·도구 마감",
      "manual": "사용하는 매장만 진행해요. 제공했던 음식과 미제공 보관분을 나누고 보관 이력·매장 기준에 따라 처리해요. 반찬통·집게·가림막을 세척하고 건조해요.\n\n완료 기준: 음식의 처리와 집기 청소가 끝나고 잔여물이 없어요.",
      "tip": "이상 시: 음식 이력이 불명확하면 새 재료와 섞거나 다음 날 사용으로 임의 지정하지 않아요.",
      "tags": [
        "셀프바 음식"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.restaurantowner.com/public/DOWNLOAD-Restaurant-Checklists.cfm"
    },
    {
      "id": "burner",
      "title": "테이블 화구 종료 확인",
      "manual": "화구가 있는 매장만 진행해요. 식은 상태와 제조사 절차를 확인하고 지정된 전원·밸브를 종료해요. 받침·주변 오염과 손상을 봐요.\n\n완료 기준: 테이블별 종료 상태를 직접 확인했어요.",
      "tip": "이상 시: 가스 냄새·파손·잔열 위험이 있으면 조작을 중단하고 책임자에게 즉시 알려요.",
      "tags": [
        "테이블 화구 종료 확인"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.restaurantowner.com/public/DOWNLOAD-Restaurant-Checklists.cfm"
    },
    {
      "id": "waste",
      "title": "폐기물 밀폐·배출",
      "manual": "구역별 쓰레기를 나누어 담고 지정 장소·시간에 배출해요. 용기와 주변 바닥을 정리하고 손을 씻어요.\n\n완료 기준: 홀에 잔반·누출·넘친 쓰레기통이 없어요.",
      "tip": "이상 시: 배출 불가 상황은 위치와 다음 처리 담당을 기록해요.",
      "tags": [
        "폐기물 밀폐"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.restaurantowner.com/public/DOWNLOAD-Restaurant-Checklists.cfm"
    },
    {
      "id": "supplies",
      "title": "다음 영업 비품 채우기",
      "manual": "휴지·물티슈·컵·포장재를 매장 기준선까지 채우고 예비품 위치를 맞춰요. 부족한 품목은 남은 양과 다음 영업 필요량을 적어요.\n\n완료 기준: 다음 담당자가 소모품을 바로 찾을 수 있어요.",
      "tip": "이상 시: 재고가 없으면 채웠다고 체크하지 말고 보충 요청을 남겨요.",
      "tags": [
        "다음 영업 비품 채우기"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.restaurantowner.com/public/DOWNLOAD-Restaurant-Checklists.cfm"
    },
    {
      "id": "secure",
      "title": "소등·문단속과 인계 완료",
      "manual": "상시 가동 장비 목록을 먼저 확인해요. 종료 대상 조명·간판·냉난방만 끄고 창문·출입문을 확인해요. 고장·예약·미완료를 다음 담당에게 남겨요.\n\n완료 기준: 상시 가동 장비를 유지하고 잠금·마감 시각·확인자가 기록돼요.",
      "tip": "이상 시: 사람이 남았는지 확인하기 전 잠그지 말고, 이상은 책임자에게 인계해요.",
      "tags": [
        "소등"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.restaurantowner.com/public/DOWNLOAD-Restaurant-Checklists.cfm"
    }
  ],
  "title": "홀 마감"
}
```

```tap2work-tap
{
  "knowledge": {
    "useCase": "routine",
    "scope": "food",
    "topics": [
      "closing"
    ],
    "menuNames": [],
    "ingredientNames": [],
    "requiresBreak": false,
    "suggestedUse": "routine",
    "eventKind": null,
    "safetyReviewRequired": true,
    "supersededBy": []
  },
  "industryIds": [
    "food"
  ],
  "purposeId": "closing",
  "kind": "operation",
  "summary": "주방 마감 · 매장 조건과 기준을 연결해 사용하는 기본 절차",
  "applicability": "해당 업무를 운영하는 음식점. 시설·서비스 방식·제품·제조사 지침에 맞게 확인 후 사용하세요.",
  "jurisdiction": "운영 참고 · 매장별 적용 기준 확인",
  "keywords": [
    "주방 마감",
    "사진",
    "영상",
    "모션그래픽",
    "편집 원본"
  ],
  "references": [
    {
      "title": "식약처 개방형주방 매뉴얼",
      "url": "https://www.mfds.go.kr/brd/m_218/view.do?seq=20196",
      "checkedAt": "2026-10-09",
      "scope": "2015 자료의 업무 분류·관리 구조 참고. 최신 법적·수치 기준으로 사용하지 않음"
    },
    {
      "title": "RestaurantOwner 운영 체크리스트",
      "url": "https://www.restaurantowner.com/public/DOWNLOAD-Restaurant-Checklists.cfm",
      "checkedAt": "2026-10-09",
      "scope": "공개 업무 범위 설명 참고. 회원 전용 양식 미열람"
    },
    {
      "title": "Basic Kitchen and Food Service Management — editable EPUB",
      "url": "https://opentextbc.ca/basickitchenandfoodservicemanagement/",
      "checkedAt": "2026-10-23",
      "scope": "BC Cook Articulation Committee, CC BY 4.0. Inventory and receiving principles; adapted into Korean store examples. Original EPUB and attribution are in the source pack. Not Korean legal or product-specific operating limits."
    },
    {
      "title": "Food Safety, Sanitation, and Personal Hygiene — editable EPUB",
      "url": "https://opentextbc.ca/foodsafety/",
      "checkedAt": "2026-10-23",
      "scope": "BC Cook Articulation Committee / go2HR, CC BY 4.0. Receiving and sanitation context; retain product labels and the store-approved procedure. The pack preserves the original publisher file and third-party credits."
    },
    {
      "title": "TAP Work — editable media, originals and licenses",
      "url": "https://tap2.work/manual-media/v1/",
      "checkedAt": "2026-10-23",
      "scope": "Original photos, CDC video, source EPUBs and editable motion scenes. Photos are illustrative. Each asset retains its own credit/license; no endorsement or completed field review is claimed."
    }
  ],
  "sourceId": "food/kitchen-close",
  "collectionId": "food",
  "collectionName": "외식업 공통",
  "title": "주방 마감",
  "emoji": "📋",
  "slot": "마감",
  "reviewedAt": "2026-10-23",
  "basis": "공개 자료의 업무 범위를 참고하여 새로 작성한 운영 초안. 현장 방법·완료 기준은 책임자 확인 필요.",
  "steps": [
    {
      "id": "remaining",
      "title": "남은 식재료 사용 이력 확인",
      "manual": "품목별 조리·개봉·보관 이력과 남은 양을 확인해요. 승인 기준에 따라 보관·폐기·판단 대기를 나누고 서로 섞지 않아요.\n\n완료 기준: 각 잔량의 처리와 책임자가 명확해요.",
      "tip": "이상 시: 이력을 모르는 식품은 재가열만으로 다음 영업 사용을 승인하지 않아요.",
      "tags": [
        "남은 식재료 사용 이력 확인"
      ],
      "imageUrl": "https://tap2.work/manual-media/v1/kitchen.jpg",
      "videoUrl": "https://tap2.work/manual-media/v1/closing.mp4",
      "sourceUrl": "https://tap2.work/manual-media/v1/?guide=closing"
    },
    {
      "id": "detail-step-2",
      "title": "보관할 조리식품 냉각·표시",
      "manual": "매장에서 검증한 용기 분할·냉각 절차에 따라 실제 시각·온도를 기록해요. 품명·배치·사용기한·보관 위치를 붙여요.\n\n완료 기준: 검증된 냉각 기준과 보관 조건을 충족한 분량만 저장돼요.",
      "tip": "이상 시: 큰 솥을 실온 방치하지 말고 기준 이탈분은 사용을 보류해 책임자에게 알려요.",
      "tags": [
        "보관할 조리식품 냉각"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://tap2.work/manual-media/v1/?guide=closing"
    },
    {
      "id": "clean",
      "title": "작업대·식기·설비 청소",
      "manual": "식품을 치우고 장비가 식고 안전하게 정지된 뒤 허용된 범위를 청소해요. 칼·도마·용기를 세척·건조하고 배수망 찌꺼기를 비워요.\n\n완료 기준: 음식물·기름·제품 잔여 없이 도구가 건조 보관돼요.",
      "tip": "이상 시: 전기부에 물을 뿌리거나 교육받지 않은 부품을 분해하지 않아요.",
      "tags": [
        "작업대"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://tap2.work/manual-media/v1/?guide=closing"
    },
    {
      "id": "detail-step-4",
      "title": "종료 장비와 상시 가동 장비 구분",
      "manual": "매장 종료 목록에 따라 화구·작업 장비의 전원·밸브 상태를 하나씩 확인해요. 냉장·냉동 등 상시 가동 설비는 유지해요.\n\n완료 기준: 끄는 장비와 계속 켜둘 장비가 목록과 일치해요.",
      "tip": "이상 시: 종료 방법을 모르면 임의 차단하지 말고 책임자에게 확인해요.",
      "tags": [
        "종료 장비와 상시 가동 장비 구분"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://tap2.work/manual-media/v1/?guide=closing"
    },
    {
      "id": "storage",
      "title": "냉장·냉동고와 바닥 최종 확인",
      "manual": "장비별 표시값·문 닫힘·라벨과 누수를 보고 통로의 물기·장애물을 제거해요. 부족·폐기·고장·미완료를 수량·위치와 함께 남겨요.\n\n완료 기준: 보관 상태와 안전한 통로를 확인하고 다음 담당이 인계를 읽을 수 있어요.",
      "tip": "이상 시: 온도 이상·문 고장은 식품 영향과 임시 조치를 함께 책임자에게 전달해요.",
      "tags": [
        "냉장"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://tap2.work/manual-media/v1/?guide=closing"
    }
  ]
}
```

```tap2work-tap
{
  "sourceId": "food/equipment",
  "collectionId": "food",
  "collectionName": "외식업 공통",
  "industryIds": [
    "food"
  ],
  "purposeId": "safety",
  "kind": "operation",
  "summary": "정기 시설·장비 관리 · 매장 조건과 기준을 연결해 사용하는 기본 절차",
  "applicability": "해당 업무를 운영하는 음식점. 시설·서비스 방식·제품·제조사 지침에 맞게 확인 후 사용하세요.",
  "jurisdiction": "운영 참고 · 매장별 적용 기준 확인",
  "keywords": [
    "정기 시설·장비 관리"
  ],
  "references": [
    {
      "title": "식약처 개방형주방 매뉴얼",
      "url": "https://www.mfds.go.kr/brd/m_218/view.do?seq=20196",
      "checkedAt": "2026-10-09",
      "scope": "2015 자료의 업무 분류·관리 구조 참고. 최신 법적·수치 기준으로 사용하지 않음"
    },
    {
      "title": "RestaurantOwner 운영 체크리스트",
      "url": "https://www.restaurantowner.com/public/DOWNLOAD-Restaurant-Checklists.cfm",
      "checkedAt": "2026-10-09",
      "scope": "공개 업무 범위 설명 참고. 회원 전용 양식 미열람"
    }
  ],
  "emoji": "📋",
  "slot": "준비",
  "reviewedAt": "2026-10-13",
  "basis": "공개 자료의 업무 범위를 참고하여 새로 작성한 운영 초안. 현장 방법·완료 기준은 책임자 확인 필요.",
  "knowledge": {
    "scope": "food",
    "topics": [
      "safety"
    ],
    "suggestedUse": "reference",
    "safetyReviewRequired": true
  },
  "steps": [
    {
      "id": "plan",
      "title": "이번 점검 대상·주기 확인",
      "manual": "장비대장에서 모델·위치·최근 점검일·다음 예정일을 보고 이번 대상을 골라요. 제조사 지침에서 크루가 할 수 있는 청소·육안 점검과 전문 정비를 구분해요.\n\n완료 기준: 담당·예정일·허용 작업 범위가 정해져 있어요.",
      "tip": "이상 시: 지침이나 교육이 없으면 분해·전기·가스 정비를 시작하지 않아요.",
      "tags": [
        "이번 점검 대상"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.mfds.go.kr/brd/m_218/view.do?seq=20196"
    },
    {
      "id": "detail-step-2",
      "title": "영업 영향과 안전 상태 확인",
      "manual": "영업 중지 구역·대체 장비를 책임자와 정해요. 뜨거움·회전부가 멈추고 제조사 절차에 따른 안전 상태인지 확인해요.\n\n완료 기준: 다른 크루가 작업 중인 장비를 켜지 않도록 표시돼요.",
      "tip": "이상 시: 안전하게 정지시킬 수 없으면 정비 담당에게 맡겨요.",
      "tags": [
        "영업 영향과 안전 상태 확인"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.mfds.go.kr/brd/m_218/view.do?seq=20196"
    },
    {
      "id": "detail-step-3",
      "title": "누수·패킹·소음·필터 외관 점검",
      "manual": "목록 순서대로 접근 가능한 부분을 보고 정상 사진·제조사 기준과 비교해요. 장비명·증상·발생 조건과 사진을 남겨요.\n\n완료 기준: 정상·조치 필요·사용 중지가 장비별로 구분돼요.",
      "tip": "이상 시: 보호덮개를 제거하거나 위험부에 손을 넣어 원인을 찾지 않아요.",
      "tags": [
        "누수"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.mfds.go.kr/brd/m_218/view.do?seq=20196"
    },
    {
      "id": "record",
      "title": "조치·복구·다음 점검 인계",
      "manual": "허용된 청소 후 부품 복구와 작동 확인을 담당자와 수행해요. 미해결 문제는 요청 번호·담당·기한으로 남기고 다음 점검일을 갱신해요.\n\n완료 기준: 복구 확인과 미해결 항목이 분리돼요.",
      "tip": "이상 시: 점검 체크만으로 수리 완료 처리하지 않아요.",
      "tags": [
        "조치"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.mfds.go.kr/brd/m_218/view.do?seq=20196"
    }
  ],
  "title": "정기 시설·장비 관리"
}
```

```tap2work-tap
{
  "sourceId": "food/incident",
  "collectionId": "food",
  "collectionName": "외식업 공통",
  "industryIds": [
    "food"
  ],
  "purposeId": "safety",
  "kind": "operation",
  "summary": "이상·회수·영업 중단 대응 · 매장 조건과 기준을 연결해 사용하는 기본 절차",
  "applicability": "해당 업무를 운영하는 음식점. 시설·서비스 방식·제품·제조사 지침에 맞게 확인 후 사용하세요.",
  "jurisdiction": "운영 참고 · 매장별 적용 기준 확인",
  "keywords": [
    "이상·회수·영업 중단 대응"
  ],
  "references": [
    {
      "title": "식약처 개방형주방 매뉴얼",
      "url": "https://www.mfds.go.kr/brd/m_218/view.do?seq=20196",
      "checkedAt": "2026-10-09",
      "scope": "2015 자료의 업무 분류·관리 구조 참고. 최신 법적·수치 기준으로 사용하지 않음"
    },
    {
      "title": "RestaurantOwner 운영 체크리스트",
      "url": "https://www.restaurantowner.com/public/DOWNLOAD-Restaurant-Checklists.cfm",
      "checkedAt": "2026-10-09",
      "scope": "공개 업무 범위 설명 참고. 회원 전용 양식 미열람"
    }
  ],
  "emoji": "📋",
  "slot": "준비",
  "reviewedAt": "2026-10-13",
  "basis": "공개 자료의 업무 범위를 참고하여 새로 작성한 운영 초안. 현장 방법·완료 기준은 책임자 확인 필요.",
  "knowledge": {
    "scope": "food",
    "topics": [
      "safety"
    ],
    "suggestedUse": "reference",
    "safetyReviewRequired": true
  },
  "steps": [
    {
      "id": "report",
      "title": "작업 중단·사람 보호·보고",
      "manual": "식품 이상·이물·파손·시설 위험을 발견하면 해당 작업과 제공을 멈춰요. 사람의 안전을 먼저 확보하고 책임자에게 장소·대상·발견 시각·상황을 알려요.\n\n완료 기준: 위험 구역과 영향을 받을 주문을 구분했어요.",
      "tip": "이상 시: 즉시 위험은 매장 비상 절차로 신고·대피하고 혼자 해결하려 하지 않아요.",
      "tags": [
        "작업 중단"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.mfds.go.kr/brd/m_218/view.do?seq=20196"
    },
    {
      "id": "isolate",
      "title": "관련 제품·로트·주문 구분",
      "manual": "사용 보류 표시를 붙이고 동일 재료·배치·주문의 범위를 확인해요. 제품과 포장·라벨·관련 기록을 책임자가 정한 방법으로 보존해요.\n\n완료 기준: 다른 크루가 보류 대상을 판매하거나 사용하지 않아요.",
      "tip": "이상 시: 증거가 될 물품을 임의 폐기하거나 정상 재료와 섞지 않아요.",
      "tags": [
        "관련 제품"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.mfds.go.kr/brd/m_218/view.do?seq=20196"
    },
    {
      "id": "detail-step-3",
      "title": "관찰한 사실과 임시 조치 기록",
      "manual": "누가 언제 무엇을 발견했는지, 관련 주문·수량·위치, 실제로 한 조치를 구분해 적어요. 손님 연락정보는 승인된 제한 접근 경로에만 남겨요.\n\n완료 기준: 추측과 사실이 섞이지 않고 후속 담당이 파악할 수 있어요.",
      "tip": "이상 시: 공용 메모에 민감정보를 올리거나 원인을 단정하지 않아요.",
      "tags": [
        "관찰한 사실과 임시 조치 기록"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.mfds.go.kr/brd/m_218/view.do?seq=20196"
    },
    {
      "id": "resume",
      "title": "재개 승인과 다음 근무자 인계",
      "manual": "책임자가 정한 처리·회수·폐기·수리 결과와 재개 허용 범위를 확인해요. 남은 점검·연락 담당·기한을 다음 근무자에게 전달해요.\n\n완료 기준: 재개 승인과 미해결 후속 업무가 구분돼요.",
      "tip": "이상 시: 조치가 끝나지 않았으면 완료 체크로 정상 영업을 대신하지 않아요.",
      "tags": [
        "재개 승인과 다음 근무자 인계"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.mfds.go.kr/brd/m_218/view.do?seq=20196"
    }
  ],
  "title": "이상·회수·영업 중단 대응"
}
```

```tap2work-tap
{
  "sourceId": "food/settlement",
  "collectionId": "food",
  "collectionName": "외식업 공통",
  "industryIds": [
    "food"
  ],
  "purposeId": "closing",
  "kind": "operation",
  "summary": "마감 정산·관리 인계 · 매장 조건과 기준을 연결해 사용하는 기본 절차",
  "applicability": "해당 업무를 운영하는 음식점. 시설·서비스 방식·제품·제조사 지침에 맞게 확인 후 사용하세요.",
  "jurisdiction": "운영 참고 · 매장별 적용 기준 확인",
  "keywords": [
    "마감 정산·관리 인계"
  ],
  "references": [
    {
      "title": "식약처 개방형주방 매뉴얼",
      "url": "https://www.mfds.go.kr/brd/m_218/view.do?seq=20196",
      "checkedAt": "2026-10-09",
      "scope": "2015 자료의 업무 분류·관리 구조 참고. 최신 법적·수치 기준으로 사용하지 않음"
    },
    {
      "title": "RestaurantOwner 운영 체크리스트",
      "url": "https://www.restaurantowner.com/public/DOWNLOAD-Restaurant-Checklists.cfm",
      "checkedAt": "2026-10-09",
      "scope": "공개 업무 범위 설명 참고. 회원 전용 양식 미열람"
    }
  ],
  "emoji": "📋",
  "slot": "마감",
  "reviewedAt": "2026-10-13",
  "basis": "공개 자료의 업무 범위를 참고하여 새로 작성한 운영 초안. 현장 방법·완료 기준은 책임자 확인 필요.",
  "knowledge": {
    "scope": "food",
    "topics": [
      "closing"
    ],
    "suggestedUse": "routine",
    "safetyReviewRequired": false
  },
  "steps": [
    {
      "id": "records",
      "title": "결제·취소·환불 자료 대조",
      "manual": "권한 있는 담당이 해당 영업일 POS 마감과 승인된 결제·취소·환불 기록을 대조해요. 교대 경계·자정 이후 귀속을 확인하고 현금은 지정 장소에서 세요.\n\n완료 기준: 결제 수단별 금액과 차이가 구분돼요.",
      "tip": "이상 시: 금액이 다르면 기록을 맞추려고 임의 수정하지 말고 거래번호와 차이를 남겨요.",
      "tags": [
        "결제"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.restaurantowner.com/public/DOWNLOAD-Restaurant-Checklists.cfm"
    },
    {
      "id": "detail-step-2",
      "title": "미결 주문·정산 차이 확인",
      "manual": "미결제·중복·부분 취소와 배달 채널별 정산 차이를 목록으로 만들어요. 주문번호·금액·현재 상태·후속 담당을 적어요.\n\n완료 기준: 정상 마감과 확인 대기 건이 나뉘어요.",
      "tip": "이상 시: 환불·보상은 담당 권한과 승인 절차를 따라요.",
      "tags": [
        "미결 주문"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.restaurantowner.com/public/DOWNLOAD-Restaurant-Checklists.cfm"
    },
    {
      "id": "detail-step-3",
      "title": "현금·자료·기기 보관",
      "manual": "정해진 보관 경로로 현금과 마감 자료를 인계하고 승인된 기기에서 로그아웃 또는 잠금해요. 개인정보가 보이는 출력물을 방치하지 않아요.\n\n완료 기준: 정산 자료와 현금의 인수 담당이 확인돼요.",
      "tip": "이상 시: 공용 비밀번호 공유나 개인 계좌 이체로 임의 처리하지 않아요.",
      "tags": [
        "현금"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.restaurantowner.com/public/DOWNLOAD-Restaurant-Checklists.cfm"
    },
    {
      "id": "handover",
      "title": "다음 영업 인계 작성",
      "manual": "품절·발주 미확정·예약·수리·미완료 업무를 대상·남은 행동·담당·기한으로 적어요. 다음 담당에게 전달 여부를 확인해요.\n\n완료 기준: 받는 사람이 다음 행동을 바로 알 수 있어요.",
      "tip": "이상 시: 책임자가 정해지지 않은 건을 단순 완료 처리하지 않아요.",
      "tags": [
        "다음 영업 인계 작성"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.restaurantowner.com/public/DOWNLOAD-Restaurant-Checklists.cfm"
    }
  ],
  "title": "마감 정산·관리 인계"
}
```


## 고객 맞이·대기·좌석 안내

```tap2work-tap
{
  "sourceId": "food/guest-welcome",
  "collectionId": "food",
  "collectionName": "외식업 공통",
  "industryIds": [
    "food"
  ],
  "purposeId": "service",
  "kind": "operation",
  "summary": "고객 맞이·대기·좌석 안내",
  "applicability": "해당 업무를 운영하는 음식점. 시설·서비스 방식·제품·제조사 지침에 맞게 확인 후 사용하세요.",
  "jurisdiction": "운영 참고 · 매장별 적용 기준 확인",
  "keywords": [
    "홀 서비스·고객 요청"
  ],
  "references": [
    {
      "title": "식약처 개방형주방 매뉴얼",
      "url": "https://www.mfds.go.kr/brd/m_218/view.do?seq=20196",
      "checkedAt": "2026-10-09",
      "scope": "2015 자료의 업무 분류·관리 구조 참고. 최신 법적·수치 기준으로 사용하지 않음"
    },
    {
      "title": "RestaurantOwner 운영 체크리스트",
      "url": "https://www.restaurantowner.com/public/DOWNLOAD-Restaurant-Checklists.cfm",
      "checkedAt": "2026-10-09",
      "scope": "공개 업무 범위 설명 참고. 회원 전용 양식 미열람"
    }
  ],
  "emoji": "📖",
  "slot": "준비",
  "reviewedAt": "2026-10-13",
  "basis": "공개 자료의 업무 범위를 참고하여 새로 작성한 운영 초안. 현장 방법·완료 기준은 책임자 확인 필요.",
  "knowledge": {
    "scope": "food",
    "topics": [
      "service"
    ],
    "suggestedUse": "reference",
    "safetyReviewRequired": false,
    "useCase": "reference"
  },
  "steps": [
    {
      "id": "step-1",
      "title": "눈을 맞추고 인사하기",
      "manual": "손님이 들어오면 하던 안전 작업을 마무리하고 “어서 오세요. 몇 분이세요?”라고 인사해요. 바로 안내하기 어려우면 “잠시만 기다려 주세요. 곧 안내해 드리겠습니다”라고 먼저 알려요.\n\n완료 기준: 방문 인원과 안내 담당을 확인했어요.",
      "tip": "이상 시: 뜨거운 용기를 든 채 급하게 뛰지 않고 가까운 크루에게 응대를 요청해요.",
      "tags": [
        "고객 맞이·대기·좌석 안내"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.restaurantowner.com/public/DOWNLOAD-Restaurant-Checklists.cfm"
    },
    {
      "id": "step-2",
      "title": "예약·이용 조건 확인하기",
      "manual": "예약 여부와 인원, 유아 의자·이동 편의가 필요한지 묻고 준비 가능한 좌석을 확인해요. 손님의 외모로 나이·장애·관계를 추측하지 않아요.\n\n완료 기준: 예약표와 이용 인원이 일치하고 필요한 도움을 확인했어요.",
      "tip": "이상 시: 안전한 좌석이 없으면 책임자에게 대안을 확인해요.",
      "tags": [
        "고객 맞이·대기·좌석 안내"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.restaurantowner.com/public/DOWNLOAD-Restaurant-Checklists.cfm"
    },
    {
      "id": "step-3",
      "title": "대기 시간과 순서 안내하기",
      "manual": "실제 빈자리와 정리 상황을 확인한 뒤 예상 대기 시간을 범위로 안내해요. 대기명과 인원만 필요한 곳에 기록하고 연락처는 매장 승인 방식으로 받아요.\n\n완료 기준: 손님이 대기 순서·예상 시간·호출 방법을 이해했어요.",
      "tip": "이상 시: 예상보다 지연되면 먼저 변경된 상황을 알려요. 근거 없는 확정 시간을 약속하지 않아요.",
      "tags": [
        "고객 맞이·대기·좌석 안내"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.restaurantowner.com/public/DOWNLOAD-Restaurant-Checklists.cfm"
    },
    {
      "id": "step-4",
      "title": "좌석까지 안내하고 첫 설명하기",
      "manual": "깨끗이 준비된 테이블 번호를 확인하고 메뉴·주문 방법·물 위치를 짧게 설명해요. “주문하실 때 알레르기나 피해야 할 재료가 있다면 꼭 말씀해 주세요”라고 안내해요.\n\n완료 기준: 테이블 번호가 맞고 메뉴와 주문 방법을 전달했어요.",
      "tip": "이상 시: 확인되지 않은 재료·가격·행사는 기억으로 답하지 않고 최신 매장 자료를 확인해요.",
      "tags": [
        "고객 맞이·대기·좌석 안내"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.restaurantowner.com/public/DOWNLOAD-Restaurant-Checklists.cfm"
    },
    {
      "id": "step-5",
      "title": "고객의 질문을 끝까지 듣기",
      "manual": "메뉴 설명은 구성·맵기·양처럼 확인된 정보로 답해요. 추천은 “어떤 맛을 선호하세요?”로 시작하고 추가 금액이 있으면 주문 전에 알려요.\n\n완료 기준: 손님이 선택한 메뉴와 추가 비용을 이해했어요.",
      "tip": "이상 시: 모르는 질문은 “정확히 확인하고 안내해 드리겠습니다”라고 말하고 담당자에게 확인해요.",
      "tags": [
        "고객 맞이·대기·좌석 안내"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.restaurantowner.com/public/DOWNLOAD-Restaurant-Checklists.cfm"
    }
  ],
  "title": "고객 맞이·대기·좌석 안내"
}
```


## 전화 응대·예약·포장 주문

```tap2work-tap
{
  "sourceId": "food/phone-service",
  "collectionId": "food",
  "collectionName": "외식업 공통",
  "industryIds": [
    "food"
  ],
  "purposeId": "service",
  "kind": "operation",
  "summary": "전화 응대·예약·포장 주문",
  "applicability": "해당 업무를 운영하는 음식점. 시설·서비스 방식·제품·제조사 지침에 맞게 확인 후 사용하세요.",
  "jurisdiction": "운영 참고 · 매장별 적용 기준 확인",
  "keywords": [
    "홀 서비스·고객 요청"
  ],
  "references": [
    {
      "title": "식약처 개방형주방 매뉴얼",
      "url": "https://www.mfds.go.kr/brd/m_218/view.do?seq=20196",
      "checkedAt": "2026-10-09",
      "scope": "2015 자료의 업무 분류·관리 구조 참고. 최신 법적·수치 기준으로 사용하지 않음"
    },
    {
      "title": "RestaurantOwner 운영 체크리스트",
      "url": "https://www.restaurantowner.com/public/DOWNLOAD-Restaurant-Checklists.cfm",
      "checkedAt": "2026-10-09",
      "scope": "공개 업무 범위 설명 참고. 회원 전용 양식 미열람"
    }
  ],
  "emoji": "📖",
  "slot": "준비",
  "reviewedAt": "2026-10-13",
  "basis": "공개 자료의 업무 범위를 참고하여 새로 작성한 운영 초안. 현장 방법·완료 기준은 책임자 확인 필요.",
  "knowledge": {
    "scope": "food",
    "topics": [
      "service"
    ],
    "suggestedUse": "reference",
    "safetyReviewRequired": false,
    "useCase": "reference"
  },
  "steps": [
    {
      "id": "step-1",
      "title": "매장명과 함께 전화 받기",
      "manual": "주변 소음을 줄이고 “안녕하세요, 우리 매장입니다. 무엇을 도와드릴까요?”라고 또렷하게 말해요. 통화 중 다른 손님께 짧게 양해를 구하고 기기 화면의 개인정보가 보이지 않게 해요.\n\n완료 기준: 고객의 문의 종류와 응대 담당이 확인됐어요.",
      "tip": "이상 시: 받기 어려우면 책임자에게 연결해요. 가능하지 않은 자동 콜백을 약속하지 않아요.",
      "tags": [
        "전화 응대·예약·포장 주문"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.restaurantowner.com/public/DOWNLOAD-Restaurant-Checklists.cfm"
    },
    {
      "id": "step-2",
      "title": "보류·연결에 먼저 동의 구하기",
      "manual": "“확인을 위해 잠시 기다려 주실 수 있을까요?”라고 묻고 보류해요. 오래 걸리면 중간 상황을 알리고, 다른 담당자에게 연결할 때 고객의 질문과 확인한 내용을 함께 전달해요.\n\n완료 기준: 고객이 누구에게 무엇을 기다리는지 알아요.",
      "tip": "이상 시: 연결이 안 되면 먼저 돌아와 가능한 회신 방법을 고객과 정해요.",
      "tags": [
        "전화 응대·예약·포장 주문"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.restaurantowner.com/public/DOWNLOAD-Restaurant-Checklists.cfm"
    },
    {
      "id": "step-3",
      "title": "예약 날짜·시간·인원 되읽기",
      "manual": "“10월 15일 목요일 저녁 7시, 네 분 예약이 맞으실까요?”처럼 날짜·요일·오전/오후·인원·예약명을 되읽어요. 좌석 가능 여부와 매장이 승인한 예약 변경·취소 기준을 설명해요.\n\n완료 기준: 예약표에 같은 정보가 기록되고 고객이 내용을 확인했어요.",
      "tip": "이상 시: 만석이면 확정이라고 말하지 않고 가능한 시간 또는 대기 방식을 제안해요.",
      "tags": [
        "전화 응대·예약·포장 주문"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.restaurantowner.com/public/DOWNLOAD-Restaurant-Checklists.cfm"
    },
    {
      "id": "step-4",
      "title": "포장 메뉴·옵션·수령 시간 확인하기",
      "manual": "메뉴명·수량·옵션·제외 재료·포장 여부를 한 항목씩 적고 주방에 실제 준비 시간을 확인해요. 알레르기 요청은 원재료와 교차 접촉 가능성을 책임자와 확인한 뒤 안내해요.\n\n완료 기준: 주방과 고객이 동일한 주문·준비 시간을 확인했어요.",
      "tip": "이상 시: 안전 여부가 불확실하면 가능하다고 약속하지 않고 대안 또는 제공 불가를 안내해요.",
      "tags": [
        "전화 응대·예약·포장 주문"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.restaurantowner.com/public/DOWNLOAD-Restaurant-Checklists.cfm"
    },
    {
      "id": "step-5",
      "title": "금액·수령 방법을 마지막으로 확인하기",
      "manual": "최신 가격표로 총액과 결제 방법을 안내하고 “주문은 …, 수령은 …시, 금액은 …원입니다. 맞으실까요?”라고 되읽어요. 찾아오는 길은 실제 주소와 출입구 안내를 사용해요.\n\n완료 기준: 주문표에 접수자·수령 시각·확인된 요청이 남았어요.",
      "tip": "이상 시: 주문 변경은 주방 접수 여부를 확인하고 변경 내용이 전달됐는지 다시 확인해요.",
      "tags": [
        "전화 응대·예약·포장 주문"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.restaurantowner.com/public/DOWNLOAD-Restaurant-Checklists.cfm"
    },
    {
      "id": "step-6",
      "title": "통화 종료와 개인정보 정리하기",
      "manual": "“문의 감사합니다. 방문 때 뵙겠습니다”라고 마무리한 뒤 예약 또는 주문 기록을 담당 크루에게 연결해요. 연락처를 개인 메신저나 개인 기기에 옮기지 않아요.\n\n완료 기준: 통화 내용이 업무 기록에 연결되고 불필요한 메모가 남지 않았어요.",
      "tip": "이상 시: 부재 문의는 확인할 담당과 회신 약속을 남기되 실제로 연결되지 않은 알림을 보냈다고 말하지 않아요.",
      "tags": [
        "전화 응대·예약·포장 주문"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.restaurantowner.com/public/DOWNLOAD-Restaurant-Checklists.cfm"
    }
  ],
  "title": "전화 응대·예약·포장 주문"
}
```


## 주문 접수·품절·변경 안내

```tap2work-tap
{
  "sourceId": "food/order-confirm",
  "collectionId": "food",
  "collectionName": "외식업 공통",
  "industryIds": [
    "food"
  ],
  "purposeId": "service",
  "kind": "operation",
  "summary": "주문 접수·품절·변경 안내",
  "applicability": "해당 업무를 운영하는 음식점. 시설·서비스 방식·제품·제조사 지침에 맞게 확인 후 사용하세요.",
  "jurisdiction": "운영 참고 · 매장별 적용 기준 확인",
  "keywords": [
    "홀 서비스·고객 요청"
  ],
  "references": [
    {
      "title": "식약처 개방형주방 매뉴얼",
      "url": "https://www.mfds.go.kr/brd/m_218/view.do?seq=20196",
      "checkedAt": "2026-10-09",
      "scope": "2015 자료의 업무 분류·관리 구조 참고. 최신 법적·수치 기준으로 사용하지 않음"
    },
    {
      "title": "RestaurantOwner 운영 체크리스트",
      "url": "https://www.restaurantowner.com/public/DOWNLOAD-Restaurant-Checklists.cfm",
      "checkedAt": "2026-10-09",
      "scope": "공개 업무 범위 설명 참고. 회원 전용 양식 미열람"
    }
  ],
  "emoji": "📖",
  "slot": "준비",
  "reviewedAt": "2026-10-13",
  "basis": "공개 자료의 업무 범위를 참고하여 새로 작성한 운영 초안. 현장 방법·완료 기준은 책임자 확인 필요.",
  "knowledge": {
    "scope": "food",
    "topics": [
      "service"
    ],
    "suggestedUse": "reference",
    "safetyReviewRequired": false,
    "useCase": "reference"
  },
  "steps": [
    {
      "id": "step-1",
      "title": "테이블과 메뉴를 한 번 더 확인",
      "manual": "테이블 번호를 먼저 확인하고 메뉴·수량·옵션·제외 요청을 주문 기기에 입력해요. 고객 말을 중간에 추정해 완성하지 말고 되읽은 뒤 전송해요.\n\n완료 기준: 손님의 확인을 받은 주문과 전송 내역이 같아요.",
      "tip": "이상 시: 주문표가 출력되지 않으면 중복 전송 전에 주방 수신 여부를 확인해요.",
      "tags": [
        "주문 접수·품절·변경 안내"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.restaurantowner.com/public/DOWNLOAD-Restaurant-Checklists.cfm"
    },
    {
      "id": "step-2",
      "title": "품절은 대안과 가격 차이까지 안내",
      "manual": "주방과 품절·재개 가능 시점을 확인하고 주문 전에 알려요. 대체 메뉴의 구성·추가 비용을 설명하고 고객이 동의한 항목만 변경해요.\n\n완료 기준: 품절 안내와 대체 선택이 주문표에 반영됐어요.",
      "tip": "이상 시: 매장 메뉴에 없는 조합이나 가격을 임의로 약속하지 않아요.",
      "tags": [
        "주문 접수·품절·변경 안내"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.restaurantowner.com/public/DOWNLOAD-Restaurant-Checklists.cfm"
    },
    {
      "id": "step-3",
      "title": "추가·취소는 조리 상태 먼저 확인",
      "manual": "고객 요청을 적고 주방에 현재 진행 단계를 확인해요. 변경 가능 여부와 금액 차이를 설명한 뒤 승인된 방식으로 수정하고 주방에 수정표가 전달됐는지 봐요.\n\n완료 기준: 기존·수정 주문이 구분되고 중복 조리가 없어요.",
      "tip": "이상 시: 이미 조리된 주문은 책임자의 변경·환불 기준으로 안내해요.",
      "tags": [
        "주문 접수·품절·변경 안내"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.restaurantowner.com/public/DOWNLOAD-Restaurant-Checklists.cfm"
    },
    {
      "id": "step-4",
      "title": "지연을 먼저 알리고 다시 약속",
      "manual": "현재 주문 순서와 주방의 예상 시간을 확인해 “준비가 늦어지고 있습니다. 약 …분 더 걸릴 예정입니다”라고 설명해요. 가능하면 고객이 선택할 수 있는 대안을 제시해요.\n\n완료 기준: 고객에게 확인된 예상 시간과 대안을 전달했어요.",
      "tip": "이상 시: 예상이 다시 바뀌면 기다리게 두지 말고 먼저 안내해요.",
      "tags": [
        "주문 접수·품절·변경 안내"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.restaurantowner.com/public/DOWNLOAD-Restaurant-Checklists.cfm"
    }
  ],
  "title": "주문 접수·품절·변경 안내"
}
```


## 불만·오주문·환불 요청 응대

```tap2work-tap
{
  "knowledge": {
    "useCase": "reference",
    "scope": "food",
    "topics": [
      "service"
    ],
    "menuNames": [],
    "ingredientNames": [],
    "requiresBreak": false,
    "suggestedUse": "reference",
    "eventKind": null,
    "safetyReviewRequired": false,
    "supersededBy": []
  },
  "industryIds": [
    "food"
  ],
  "purposeId": "service",
  "kind": "operation",
  "summary": "불만·오주문·환불 요청 응대",
  "applicability": "해당 업무를 운영하는 음식점. 시설·서비스 방식·제품·제조사 지침에 맞게 확인 후 사용하세요.",
  "jurisdiction": "운영 참고 · 매장별 적용 기준 확인",
  "keywords": [
    "홀 서비스·고객 요청",
    "사진",
    "영상",
    "모션그래픽",
    "편집 원본"
  ],
  "references": [
    {
      "title": "식약처 개방형주방 매뉴얼",
      "url": "https://www.mfds.go.kr/brd/m_218/view.do?seq=20196",
      "checkedAt": "2026-10-09",
      "scope": "2015 자료의 업무 분류·관리 구조 참고. 최신 법적·수치 기준으로 사용하지 않음"
    },
    {
      "title": "RestaurantOwner 운영 체크리스트",
      "url": "https://www.restaurantowner.com/public/DOWNLOAD-Restaurant-Checklists.cfm",
      "checkedAt": "2026-10-09",
      "scope": "공개 업무 범위 설명 참고. 회원 전용 양식 미열람"
    },
    {
      "title": "Basic Kitchen and Food Service Management — editable EPUB",
      "url": "https://opentextbc.ca/basickitchenandfoodservicemanagement/",
      "checkedAt": "2026-10-23",
      "scope": "BC Cook Articulation Committee, CC BY 4.0. Inventory and receiving principles; adapted into Korean store examples. Original EPUB and attribution are in the source pack. Not Korean legal or product-specific operating limits."
    },
    {
      "title": "Food Safety, Sanitation, and Personal Hygiene — editable EPUB",
      "url": "https://opentextbc.ca/foodsafety/",
      "checkedAt": "2026-10-23",
      "scope": "BC Cook Articulation Committee / go2HR, CC BY 4.0. Receiving and sanitation context; retain product labels and the store-approved procedure. The pack preserves the original publisher file and third-party credits."
    },
    {
      "title": "TAP Work — editable media, originals and licenses",
      "url": "https://tap2.work/manual-media/v1/",
      "checkedAt": "2026-10-23",
      "scope": "Original photos, CDC video, source EPUBs and editable motion scenes. Photos are illustrative. Each asset retains its own credit/license; no endorsement or completed field review is claimed."
    }
  ],
  "sourceId": "food/complaint-service",
  "collectionId": "food",
  "collectionName": "외식업 공통",
  "title": "불만·오주문·환불 요청 응대",
  "emoji": "📖",
  "slot": "준비",
  "reviewedAt": "2026-10-23",
  "basis": "공개 자료의 업무 범위를 참고하여 새로 작성한 운영 초안. 현장 방법·완료 기준은 책임자 확인 필요.",
  "steps": [
    {
      "id": "step-1",
      "title": "방어하지 않고 불편을 확인",
      "manual": "말을 끊지 않고 듣고 “불편을 드려 죄송합니다. 주문하신 내용과 제공된 내용을 확인하겠습니다”라고 말해요. 다른 손님 앞에서 언쟁하지 않아요.\n\n완료 기준: 고객이 요청한 해결과 실제 발생 사실이 구분됐어요.",
      "tip": "이상 시: 위협·폭력이 있으면 동료·책임자에게 도움을 요청하고 안전한 거리를 확보해요.",
      "tags": [
        "불만·오주문·환불 요청 응대"
      ],
      "imageUrl": "",
      "videoUrl": "https://tap2.work/manual-media/v1/service.mp4",
      "sourceUrl": "https://tap2.work/manual-media/v1/?guide=service"
    },
    {
      "id": "step-2",
      "title": "주문·제공·결제 사실 대조",
      "manual": "테이블·주문 시각·메뉴·결제 내역을 확인해요. 음식이나 물품은 고객 동의를 받고 구분해 보관하고, 원인을 확인하기 전에 누가 잘못했다고 단정하지 않아요.\n\n완료 기준: 확인한 사실과 아직 모르는 내용을 책임자에게 전달했어요.",
      "tip": "이상 시: 이물·신체 이상 등은 제공을 중지하고 책임자에게 즉시 연결해요.",
      "tags": [
        "불만·오주문·환불 요청 응대"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://tap2.work/manual-media/v1/?guide=service"
    },
    {
      "id": "step-3",
      "title": "권한 안에서 해결안 제시",
      "manual": "책임자에게 재제공·교환·환불 가능 여부를 확인하고 고객에게 가능한 선택과 예상 시간을 설명해요. 할인이나 무료 제공은 승인받은 범위에서만 약속해요.\n\n완료 기준: 고객과 승인 담당이 동일한 해결안을 확인했어요.",
      "tip": "이상 시: 거절 안내가 필요하면 이유를 짧게 설명하고 책임자 응대로 연결해요.",
      "tags": [
        "불만·오주문·환불 요청 응대"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://tap2.work/manual-media/v1/?guide=service"
    },
    {
      "id": "step-4",
      "title": "해결 결과와 다음 조치 남기기",
      "manual": "약속한 재제공·결제 취소가 실제로 처리됐는지 확인하고 고객에게 다시 알려요. 발생 내용·조치·담당·재발 방지 확인점을 인계에 적어요.\n\n완료 기준: 처리 결과와 미완료 후속 작업이 구분돼요.",
      "tip": "이상 시: 결제 취소 실패는 완료로 말하지 않고 실제 상태와 담당을 알려요.",
      "tags": [
        "불만·오주문·환불 요청 응대"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://tap2.work/manual-media/v1/?guide=service"
    }
  ]
}
```


## 알레르기 요청 확인과 주방 전달

```tap2work-tap
{
  "sourceId": "food/allergen-conversation",
  "collectionId": "food",
  "collectionName": "외식업 공통",
  "industryIds": [
    "food"
  ],
  "purposeId": "service",
  "kind": "operation",
  "summary": "알레르기 요청 확인과 주방 전달",
  "applicability": "해당 업무를 운영하는 음식점. 시설·서비스 방식·제품·제조사 지침에 맞게 확인 후 사용하세요.",
  "jurisdiction": "운영 참고 · 매장별 적용 기준 확인",
  "keywords": [
    "홀 서비스·고객 요청"
  ],
  "references": [
    {
      "title": "식약처 개방형주방 매뉴얼",
      "url": "https://www.mfds.go.kr/brd/m_218/view.do?seq=20196",
      "checkedAt": "2026-10-09",
      "scope": "2015 자료의 업무 분류·관리 구조 참고. 최신 법적·수치 기준으로 사용하지 않음"
    },
    {
      "title": "RestaurantOwner 운영 체크리스트",
      "url": "https://www.restaurantowner.com/public/DOWNLOAD-Restaurant-Checklists.cfm",
      "checkedAt": "2026-10-09",
      "scope": "공개 업무 범위 설명 참고. 회원 전용 양식 미열람"
    }
  ],
  "emoji": "📖",
  "slot": "준비",
  "reviewedAt": "2026-10-13",
  "basis": "공개 자료의 업무 범위를 참고하여 새로 작성한 운영 초안. 현장 방법·완료 기준은 책임자 확인 필요.",
  "knowledge": {
    "scope": "food",
    "topics": [
      "service"
    ],
    "suggestedUse": "reference",
    "safetyReviewRequired": false,
    "useCase": "reference"
  },
  "steps": [
    {
      "id": "step-1",
      "title": "피해야 하는 재료를 정확히 묻기",
      "manual": "알레르기 요청을 받으면 대상 재료와 주문 메뉴를 기록해요. “해당 재료와 조리 과정을 책임자에게 확인한 뒤 안내하겠습니다”라고 말해요.\n\n완료 기준: 고객 요청이 주문표에 명확히 기록됐어요.",
      "tip": "이상 시: 알레르기의 심각도를 크루가 판단하거나 조금은 괜찮다고 권하지 않아요.",
      "tags": [
        "알레르기 요청 확인과 주방 전달"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.restaurantowner.com/public/DOWNLOAD-Restaurant-Checklists.cfm"
    },
    {
      "id": "step-2",
      "title": "원재료 자료와 조리 환경 확인",
      "manual": "소스·토핑·대체 재료까지 최신 원재료 자료를 확인하고 주방 책임자에게 공용 도구·기름·작업대의 교차 접촉 가능성을 물어요.\n\n완료 기준: 확인한 재료와 조리 가능 여부를 책임자가 검토했어요.",
      "tip": "이상 시: 정보가 없거나 안전을 확인할 수 없으면 제공 가능하다고 말하지 않아요.",
      "tags": [
        "알레르기 요청 확인과 주방 전달"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.restaurantowner.com/public/DOWNLOAD-Restaurant-Checklists.cfm"
    },
    {
      "id": "step-3",
      "title": "고객 확인 후 주문을 구분해 전달",
      "manual": "확인 결과와 제한을 고객에게 설명하고 선택한 주문을 주방 담당에게 말과 주문표로 전달해요. 제공 직전 대상 테이블과 주문을 다시 대조해요.\n\n완료 기준: 주방 담당과 제공 크루가 동일한 요청을 확인했어요.",
      "tip": "이상 시: 실수나 혼입 가능성이 있으면 해당 접시 제공을 멈추고 책임자 판단을 받아요.",
      "tags": [
        "알레르기 요청 확인과 주방 전달"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.restaurantowner.com/public/DOWNLOAD-Restaurant-Checklists.cfm"
    }
  ],
  "title": "알레르기 요청 확인과 주방 전달"
}
```


## 월간 운영·매뉴얼 점검

```tap2work-tap
{
  "sourceId": "food/monthly-review",
  "collectionId": "food",
  "collectionName": "외식업 공통",
  "industryIds": [
    "food"
  ],
  "purposeId": "people",
  "kind": "operation",
  "summary": "월간 운영·매뉴얼 점검",
  "applicability": "해당 업무를 운영하는 음식점. 시설·서비스 방식·제품·제조사 지침에 맞게 확인 후 사용하세요.",
  "jurisdiction": "운영 참고 · 매장별 적용 기준 확인",
  "keywords": [
    "홀 서비스·고객 요청"
  ],
  "references": [
    {
      "title": "식약처 개방형주방 매뉴얼",
      "url": "https://www.mfds.go.kr/brd/m_218/view.do?seq=20196",
      "checkedAt": "2026-10-09",
      "scope": "2015 자료의 업무 분류·관리 구조 참고. 최신 법적·수치 기준으로 사용하지 않음"
    },
    {
      "title": "RestaurantOwner 운영 체크리스트",
      "url": "https://www.restaurantowner.com/public/DOWNLOAD-Restaurant-Checklists.cfm",
      "checkedAt": "2026-10-09",
      "scope": "공개 업무 범위 설명 참고. 회원 전용 양식 미열람"
    }
  ],
  "emoji": "🗓️",
  "slot": "준비",
  "reviewedAt": "2026-10-13",
  "basis": "공개 자료의 업무 범위를 참고하여 새로 작성한 운영 초안. 현장 방법·완료 기준은 책임자 확인 필요.",
  "knowledge": {
    "scope": "food",
    "topics": [
      "people"
    ],
    "suggestedUse": "reference",
    "safetyReviewRequired": false,
    "useCase": "periodic"
  },
  "steps": [
    {
      "id": "step-1",
      "title": "반복된 불편과 미완료 업무 찾기",
      "manual": "지난달 인계·불만·업무 이상 기록에서 반복된 주제를 추려요. 빈도뿐 아니라 안전·고객 영향·재작업이 컸던 항목을 우선해요.\n\n완료 기준: 이번에 바꿀 항목과 이유가 정리됐어요.",
      "tip": "이상 시: 기록이 없으면 발생했다고 가정하지 말고 크루에게 사례를 확인해요.",
      "tags": [
        "월간 운영·매뉴얼 점검"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.restaurantowner.com/public/DOWNLOAD-Restaurant-Checklists.cfm"
    },
    {
      "id": "step-2",
      "title": "메뉴·가격·전화 안내 대조",
      "manual": "현재 메뉴·가격·품절 안내·예약 방식·연락처를 실제 사용하는 자료와 대조해요. 사용하지 않는 안내는 수정하거나 보관해요.\n\n완료 기준: 고객에게 전달되는 안내가 현재 매장 운영과 같아요.",
      "tip": "이상 시: 가격이나 환불 권한 변경은 사장님 확인 후 안내해요.",
      "tags": [
        "월간 운영·매뉴얼 점검"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.restaurantowner.com/public/DOWNLOAD-Restaurant-Checklists.cfm"
    },
    {
      "id": "step-3",
      "title": "정기 점검·소모품·설비 일정 확인",
      "manual": "설비별 제조사 점검 권장 주기와 매장 기록을 대조해 다음 점검일·업체 연락·담당을 확인해요. 월간 점검이 필요한 일상 청소를 대체하지 않아요.\n\n완료 기준: 점검 예정과 담당, 필요한 준비가 정리됐어요.",
      "tip": "이상 시: 고장 징후는 정기일까지 미루지 말고 사용 중지와 책임자 보고를 먼저 해요.",
      "tags": [
        "월간 운영·매뉴얼 점검"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.restaurantowner.com/public/DOWNLOAD-Restaurant-Checklists.cfm"
    },
    {
      "id": "step-4",
      "title": "변경할 매뉴얼과 반복 업무 검토",
      "manual": "사장님이 매뉴얼의 행동·완료 기준·이상 대응을 수정하고 내일 미리보기에서 담당과 일정을 확인해요. 변경 이유와 적용일을 크루에게 설명해요.\n\n완료 기준: 수정 내용과 앞으로 적용될 범위를 확인했어요.",
      "tip": "이상 시: 이미 진행·완료한 업무의 기록을 새 기준으로 덮어쓰지 않아요.",
      "tags": [
        "월간 운영·매뉴얼 점검"
      ],
      "imageUrl": "",
      "videoUrl": "",
      "sourceUrl": "https://www.restaurantowner.com/public/DOWNLOAD-Restaurant-Checklists.cfm"
    }
  ],
  "title": "월간 운영·매뉴얼 점검"
}
```


## 개업 전 · 영업 조건과 준비 서류

```tap2work-tap
{
  "sourceId": "startup/permits",
  "collectionId": "food-startup",
  "collectionName": "개업 준비",
  "title": "개업 전 · 영업 조건과 준비 서류",
  "slot": "준비",
  "reviewedAt": "2026-10-13",
  "basis": "공개 자료를 참고한 편집 제안 · 현장 검토 필요",
  "steps": [
    {
      "id": "step-1",
      "title": "계약·공사 전에 영업 가능 조건 확인",
      "manual": "판매 방식과 취급 품목, 주소와 시설 계획을 적고 관할 기관에 해당 업종의 신고·허가·시설 요건을 확인해요. 이전 운영자의 허가가 그대로 적용된다고 가정하지 않아요.\n\n완료 기준: 확인한 기관·날짜·답변과 남은 조건, 확인 담당과 기한이 기록돼요.",
      "tip": "매장 기준과 담당자를 확인한 뒤 사용해 주세요.",
      "tags": [],
      "sourceUrl": "https://www.gov.uk/government/publications/safer-food-better-business-for-caterers"
    },
    {
      "id": "step-2",
      "title": "위생교육·건강진단 대상과 일정 확인",
      "manual": "영업자와 식품을 직접 취급할 크루의 업무를 나누고 적용되는 교육·건강진단과 개업 전 준비 시점을 공식 안내로 확인해요. 개인정보가 든 서류는 공용 매뉴얼에 올리지 않아요.\n\n완료 기준: 대상별 확인 담당·준비 상태·보관 장소와 재확인 일정이 정해져요.",
      "tip": "매장 기준과 담당자를 확인한 뒤 사용해 주세요.",
      "tags": [],
      "sourceUrl": "https://easylaw.go.kr/CSP/CnpClsMain.laf?ccfNo=4&cciNo=1&cnpClsNo=2&csmSeq=839&popMenu=ov"
    },
    {
      "id": "step-3",
      "title": "제출·발급·승인 상태를 구분",
      "manual": "신고·등록·검사·보험 등 우리 매장에 해당하는 절차를 목록으로 만들고 접수와 완료를 구분해요. 필요한 원본·사본·수수료·연락처를 담당자와 대조하고 개업일에서 역산해 일정을 잡아요.\n\n완료 기준: 영업 전 해결할 조건이 남았는지 책임자가 확인할 수 있어요.",
      "tip": "매장 기준과 담당자를 확인한 뒤 사용해 주세요.",
      "tags": [],
      "sourceUrl": "https://www.gov.uk/government/publications/safer-food-better-business-for-caterers"
    },
    {
      "id": "step-4",
      "title": "개업 준비 문서의 담당과 접근 범위 정리",
      "manual": "사업·임대·설비·거래처·비상 연락 자료의 원본 보관 장소와 수정 담당을 정해요. 크루에게는 업무에 필요한 위치·연락 경로만 공유하고 개인 서류와 비밀번호는 분리해요.\n\n완료 기준: 책임자가 없어도 필요한 연락처를 찾을 수 있고 민감한 문서는 제한돼요.",
      "tip": "매장 기준과 담당자를 확인한 뒤 사용해 주세요.",
      "tags": [],
      "sourceUrl": "https://www.gov.uk/government/publications/safer-food-better-business-for-caterers"
    }
  ],
  "industryIds": [
    "food"
  ],
  "purposeId": "compliance",
  "kind": "operation",
  "summary": "개업 전 · 영업 조건과 준비 서류",
  "applicability": "외식 공통 · 첫 매장의 해당 작업을 하는 사업장. 현장 절차와 장비 지침에 맞게 조정하세요.",
  "jurisdiction": "출처별 관할 · 운영 참고",
  "keywords": [],
  "references": [
    {
      "title": "기존 체크리스트 원문 1",
      "url": "https://www.gov.uk/government/publications/safer-food-better-business-for-caterers",
      "checkedAt": "2026-09-20",
      "scope": "기존 위키 조사 자료 · 업무 구조 참고, 국내 법적 기준으로 단정하지 않음"
    },
    {
      "title": "법제처 생활법령정보 · 식품위생교육",
      "url": "https://easylaw.go.kr/CSP/CnpClsMain.laf?ccfNo=4&cciNo=1&cnpClsNo=2&csmSeq=839&popMenu=ov",
      "checkedAt": "2026-10-13",
      "scope": "식품위생교육 대상·기관·예외 안내 본문 확인"
    }
  ],
  "knowledge": {
    "scope": "food",
    "topics": [
      "compliance"
    ],
    "suggestedUse": "reference",
    "useCase": "startup"
  },
  "emoji": "🏪"
}
```


## 개업 전 · 공간·설비와 작업 동선

```tap2work-tap
{
  "sourceId": "startup/facilities",
  "collectionId": "food-startup",
  "collectionName": "개업 준비",
  "title": "개업 전 · 공간·설비와 작업 동선",
  "slot": "준비",
  "reviewedAt": "2026-10-13",
  "basis": "공개 자료를 참고한 편집 제안 · 현장 검토 필요",
  "steps": [
    {
      "id": "step-1",
      "title": "입고부터 폐기까지 실제 동선 걸어보기",
      "manual": "입고·보관·전처리·조리·제공·반납·세척·건조·폐기 장소를 실제 바닥에서 확인해요. 깨끗한 식기와 사용한 식기, 식재료와 폐기물이 만나는 지점을 찾아 위치나 이동 시간을 조정해요.\n\n완료 기준: 각 장소에 이름과 사진이 있고 통로·출입구를 막는 임시 적치가 없어요.",
      "tip": "매장 기준과 담당자를 확인한 뒤 사용해 주세요.",
      "tags": [],
      "sourceUrl": "https://www.gov.uk/government/publications/safer-food-better-business-for-caterers"
    },
    {
      "id": "step-2",
      "title": "설비별 사용·종료·고장 대응 기준 등록",
      "manual": "모델명과 제조사 설명서, 설치·점검 업체 연락처를 모아요. 사용 가능한 담당, 정상 표시, 종료 방법과 계속 가동할 장비를 구분해요. 차단기나 밸브는 책임자와 위치를 확인하고 임의 시험하지 않아요.\n\n완료 기준: 새 크루가 사용 전 확인할 자료와 고장 시 연락 경로를 찾을 수 있어요.",
      "tip": "매장 기준과 담당자를 확인한 뒤 사용해 주세요.",
      "tags": [],
      "sourceUrl": "https://www.gov.uk/government/publications/safer-food-better-business-for-caterers"
    },
    {
      "id": "step-3",
      "title": "첫 영업 전 청소·급배수·보관 상태 검수",
      "manual": "공사 잔재와 먼지를 제거한 뒤 구역별 세척 도구와 제품 사용법을 정해요. 손 씻는 곳, 급배수, 폐기물 장소, 보관 설비의 작동과 청결을 확인해요. 누수·해충 흔적·보관 조건 미달은 먼저 해결해요.\n\n완료 기준: 책임자가 실제 작동을 확인했고 보류 구역에는 사용 금지 표시가 있어요.",
      "tip": "매장 기준과 담당자를 확인한 뒤 사용해 주세요.",
      "tags": [],
      "sourceUrl": "https://www.gov.uk/government/publications/safer-food-better-business-for-caterers"
    },
    {
      "id": "step-4",
      "title": "영업 종료와 비상 상황을 현장에서 연습",
      "manual": "상시 가동할 보관 장비와 종료할 조명·열원 목록을 구분해 마감 경로를 걸어요. 대피 경로와 비상 연락, 설비 이상 시 멈추고 보고하는 방법을 공유해요. 위험한 상황을 실제로 만들지는 않아요.\n\n완료 기준: 마지막 확인 담당과 부재 시 대체 담당이 같은 종료 기준을 설명할 수 있어요.",
      "tip": "매장 기준과 담당자를 확인한 뒤 사용해 주세요.",
      "tags": [],
      "sourceUrl": "https://www.gov.uk/government/publications/safer-food-better-business-for-caterers"
    }
  ],
  "industryIds": [
    "food"
  ],
  "purposeId": "safety",
  "kind": "operation",
  "summary": "개업 전 · 공간·설비와 작업 동선",
  "applicability": "외식 공통 · 첫 매장의 해당 작업을 하는 사업장. 현장 절차와 장비 지침에 맞게 조정하세요.",
  "jurisdiction": "출처별 관할 · 운영 참고",
  "keywords": [],
  "references": [
    {
      "title": "기존 체크리스트 원문 1",
      "url": "https://www.gov.uk/government/publications/safer-food-better-business-for-caterers",
      "checkedAt": "2026-09-20",
      "scope": "기존 위키 조사 자료 · 업무 구조 참고, 국내 법적 기준으로 단정하지 않음"
    }
  ],
  "knowledge": {
    "scope": "food",
    "topics": [
      "safety"
    ],
    "suggestedUse": "reference",
    "useCase": "startup"
  },
  "emoji": "🏪"
}
```


## 개업 전 · 판매 메뉴와 고객 안내 기준

```tap2work-tap
{
  "sourceId": "startup/offer",
  "collectionId": "food-startup",
  "collectionName": "개업 준비",
  "title": "개업 전 · 판매 메뉴와 고객 안내 기준",
  "slot": "준비",
  "reviewedAt": "2026-10-13",
  "basis": "공개 자료를 참고한 편집 제안 · 현장 검토 필요",
  "steps": [
    {
      "id": "step-1",
      "title": "판매할 메뉴의 레시피와 원가 기준 확정",
      "manual": "메뉴별 재료·규격·분량·공정·완성 사진·제공 구성을 레시피에 모아요. 실제 시험 조리의 수율과 손실, 포장재를 반영해 원가를 확인하고 판매 가격은 책임자가 정해요. 예시 수치로 바로 판매하지 않아요.\n\n완료 기준: 같은 메뉴를 다른 담당자가 만들어도 비교할 기준과 수정 담당이 있어요.",
      "tip": "매장 기준과 담당자를 확인한 뒤 사용해 주세요.",
      "tags": [],
      "sourceUrl": "https://www.gov.uk/government/publications/safer-food-better-business-for-caterers"
    },
    {
      "id": "step-2",
      "title": "메뉴판·주문 화면·포장 안내 대조",
      "manual": "판매 이름·가격·옵션·품절·포장비·주문 마감 안내를 사용하는 모든 주문 경로에서 비교해요. 고객이 보는 안내와 주방 주문표가 같은 뜻인지 읽어봐요. 운영하지 않는 채널은 제외해요.\n\n완료 기준: 가격 차이와 누락 옵션을 수정하고 변경할 때 함께 고칠 위치를 기록했어요.",
      "tip": "매장 기준과 담당자를 확인한 뒤 사용해 주세요.",
      "tags": [],
      "sourceUrl": "https://www.gov.uk/government/publications/safer-food-better-business-for-caterers"
    },
    {
      "id": "step-3",
      "title": "원재료·대체품과 알레르기 질문 경로 준비",
      "manual": "복합 원재료와 소스까지 제품 표시를 확인하고 메뉴별 자료를 연결해요. 대체품을 받으면 자료를 다시 확인하도록 정해요. 알레르기 질문에 크루가 추측해 답하지 않도록 책임자 확인 경로와 안내 문구를 연습해요.\n\n완료 기준: 확인 불가능한 요청은 제공 가능하다고 약속하지 않는 기준이 공유돼요.",
      "tip": "매장 기준과 담당자를 확인한 뒤 사용해 주세요.",
      "tags": [],
      "sourceUrl": "https://www.gov.uk/government/publications/safer-food-better-business-for-caterers"
    },
    {
      "id": "step-4",
      "title": "시험 주문·변경·취소·수령까지 왕복 확인",
      "manual": "시험임을 알리고 주문 접수부터 주방 전달, 제공·포장, 결제와 취소까지 확인해요. 실제 결제가 필요한 시험은 책임자 승인 후 진행하고 취소 결과도 확인해요. 주문번호가 끊기거나 중복되는 지점을 적어요.\n\n완료 기준: 시험 기록과 실제 매출·재고를 구분하고 미해결 오류의 담당을 정했어요.",
      "tip": "매장 기준과 담당자를 확인한 뒤 사용해 주세요.",
      "tags": [],
      "sourceUrl": "https://www.gov.uk/government/publications/safer-food-better-business-for-caterers"
    }
  ],
  "industryIds": [
    "food"
  ],
  "purposeId": "service",
  "kind": "operation",
  "summary": "개업 전 · 판매 메뉴와 고객 안내 기준",
  "applicability": "외식 공통 · 첫 매장의 해당 작업을 하는 사업장. 현장 절차와 장비 지침에 맞게 조정하세요.",
  "jurisdiction": "출처별 관할 · 운영 참고",
  "keywords": [],
  "references": [
    {
      "title": "기존 체크리스트 원문 1",
      "url": "https://www.gov.uk/government/publications/safer-food-better-business-for-caterers",
      "checkedAt": "2026-09-20",
      "scope": "기존 위키 조사 자료 · 업무 구조 참고, 국내 법적 기준으로 단정하지 않음"
    }
  ],
  "knowledge": {
    "scope": "food",
    "topics": [
      "service"
    ],
    "suggestedUse": "reference",
    "useCase": "startup"
  },
  "emoji": "🏪"
}
```


## 개업 전 · 거래처·첫 발주와 재고 기준

```tap2work-tap
{
  "sourceId": "startup/supply",
  "collectionId": "food-startup",
  "collectionName": "개업 준비",
  "title": "개업 전 · 거래처·첫 발주와 재고 기준",
  "slot": "준비",
  "reviewedAt": "2026-10-13",
  "basis": "공개 자료를 참고한 편집 제안 · 현장 검토 필요",
  "steps": [
    {
      "id": "step-1",
      "title": "거래처와 품목별 납품 조건 합의",
      "manual": "품명·규격·단위·포장·보관 조건·납품 요일·주문 마감·최소 수량을 확인해요. 휴무·품절 때 연락할 사람과 대체품 승인, 불량·누락·반품 처리 방법을 적어요. 구두 약속은 담당자와 다시 대조해요.\n\n완료 기준: 발주 담당이 달라도 같은 규격과 조건으로 요청할 수 있어요.",
      "tip": "매장 기준과 담당자를 확인한 뒤 사용해 주세요.",
      "tags": [],
      "sourceUrl": "https://www.gov.uk/government/publications/safer-food-better-business-for-caterers"
    },
    {
      "id": "step-2",
      "title": "첫 발주량을 보관 능력과 시험 결과로 계산",
      "manual": "예상 판매량을 확정 수요로 보지 말고 시험 조리 소모량, 납품 간격, 실제 보관 공간을 함께 확인해요. 품목별 필요량과 근거를 적고 책임자가 첫 주문 범위를 승인해요.\n\n완료 기준: 주문량을 둘 곳이 있고 남거나 부족할 때의 조정 담당이 정해져요.",
      "tip": "매장 기준과 담당자를 확인한 뒤 사용해 주세요.",
      "tags": [],
      "sourceUrl": "https://www.gov.uk/government/publications/safer-food-better-business-for-caterers"
    },
    {
      "id": "step-3",
      "title": "첫 입고를 검수하고 실제 시작 재고 기록",
      "manual": "주문과 실물을 대조해 정상 입고·보류·반품·미입고를 나눠요. 기한과 제품별 검수 기준을 확인하고 받은 정상 수량만 보관·기록해요. 발주했다는 이유로 재고를 늘리지 않아요.\n\n완료 기준: 품목별 수량·단위·위치와 공급처 자료를 실제 물품에서 확인할 수 있어요.",
      "tip": "매장 기준과 담당자를 확인한 뒤 사용해 주세요.",
      "tags": [],
      "sourceUrl": "https://www.gov.uk/government/publications/safer-food-better-business-for-caterers"
    },
    {
      "id": "step-4",
      "title": "보관 표시·사용 순서와 확인 주기 정하기",
      "manual": "제품 상태별 보관 위치, 개봉·소분 표시와 매장 사용 기준을 정해요. 사용 이력을 모르는 물품은 따로 보류해요. 발주 후 재고 확인일과 입고 처리를 구분하고 중간 확인으로 기존 기한을 미루지 않아요.\n\n완료 기준: 다음 담당자가 먼저 사용할 물품과 확인할 날짜를 구별할 수 있어요.",
      "tip": "매장 기준과 담당자를 확인한 뒤 사용해 주세요.",
      "tags": [],
      "sourceUrl": "https://www.gov.uk/government/publications/safer-food-better-business-for-caterers"
    }
  ],
  "industryIds": [
    "food"
  ],
  "purposeId": "inventory",
  "kind": "operation",
  "summary": "개업 전 · 거래처·첫 발주와 재고 기준",
  "applicability": "외식 공통 · 첫 매장의 해당 작업을 하는 사업장. 현장 절차와 장비 지침에 맞게 조정하세요.",
  "jurisdiction": "출처별 관할 · 운영 참고",
  "keywords": [],
  "references": [
    {
      "title": "기존 체크리스트 원문 1",
      "url": "https://www.gov.uk/government/publications/safer-food-better-business-for-caterers",
      "checkedAt": "2026-09-20",
      "scope": "기존 위키 조사 자료 · 업무 구조 참고, 국내 법적 기준으로 단정하지 않음"
    }
  ],
  "knowledge": {
    "scope": "food",
    "topics": [
      "inventory"
    ],
    "suggestedUse": "reference",
    "useCase": "startup"
  },
  "emoji": "🏪"
}
```


## 개업 전 · 파트 배분과 크루 첫 연습

```tap2work-tap
{
  "sourceId": "startup/crew",
  "collectionId": "food-startup",
  "collectionName": "개업 준비",
  "title": "개업 전 · 파트 배분과 크루 첫 연습",
  "slot": "준비",
  "reviewedAt": "2026-10-13",
  "basis": "공개 자료를 참고한 편집 제안 · 현장 검토 필요",
  "steps": [
    {
      "id": "step-1",
      "title": "파트·직책·대체 담당을 따로 정하기",
      "manual": "조리·준비·설거지·홀·포장·관리 역할별로 할 일과 넘겨받을 결과를 적어요. 파트는 업무 구분, 직책은 변경 권한으로 구별해요. 혼자 겸하는 역할과 자리를 비울 때 대신 받을 담당도 정해요.\n\n완료 기준: 바쁜 시간에 빠지는 일이 없고 누구에게 도움을 요청할지 보여요.",
      "tip": "매장 기준과 담당자를 확인한 뒤 사용해 주세요.",
      "tags": [],
      "sourceUrl": "https://www.gov.uk/government/publications/safer-food-better-business-for-caterers"
    },
    {
      "id": "step-2",
      "title": "영업시간과 준비·마감·교대 시간 맞추기",
      "manual": "고객 영업시간과 크루의 준비·마감 시간을 구별하고 파트별 필요 인원, 교대와 휴게를 실제 근무표에 맞춰요. 개업 전 준비를 매일 오픈 체크와 섞지 않아요.\n\n완료 기준: 시간대별 담당과 공석이 보이며 사장님이 부족한 구간의 대응을 정했어요.",
      "tip": "매장 기준과 담당자를 확인한 뒤 사용해 주세요.",
      "tags": [],
      "sourceUrl": "https://www.gov.uk/government/publications/safer-food-better-business-for-caterers"
    },
    {
      "id": "step-3",
      "title": "버디 시범·직접 연습·확인을 분리",
      "manual": "버디가 장소와 방법을 보여주고 새 크루가 직접 해본 뒤 완료 기준을 설명하게 해요. 모르는 내용은 질문해도 된다고 안내하고 혼자 맡기기 어려운 장비·작업을 표시해요. 읽었다는 이유로 실제 수행 완료를 만들지 않아요.\n\n완료 기준: 본인 연습과 버디 확인이 구분되고 다음 연습할 항목이 남아요.",
      "tip": "매장 기준과 담당자를 확인한 뒤 사용해 주세요.",
      "tags": [],
      "sourceUrl": "https://www.gov.uk/government/publications/safer-food-better-business-for-caterers"
    },
    {
      "id": "step-4",
      "title": "매장 기준을 수정한 뒤 실제 업무 연결",
      "manual": "사장님이 예제의 장소·도구·수량·표현을 실제 매장에 맞춰 고쳐요. 루틴은 담당과 시간, 정기 업무는 주기, 레시피는 참조 경로를 확인해 선택 등록해요. 중요한 변경과 필요한 언어의 번역도 확인해요.\n\n완료 기준: 신규 크루가 매뉴얼만 보고 시작할 수 있고 미확정 기준은 보류로 구분돼요.",
      "tip": "매장 기준과 담당자를 확인한 뒤 사용해 주세요.",
      "tags": [],
      "sourceUrl": "https://www.gov.uk/government/publications/safer-food-better-business-for-caterers"
    }
  ],
  "industryIds": [
    "food"
  ],
  "purposeId": "people",
  "kind": "operation",
  "summary": "개업 전 · 파트 배분과 크루 첫 연습",
  "applicability": "외식 공통 · 첫 매장의 해당 작업을 하는 사업장. 현장 절차와 장비 지침에 맞게 조정하세요.",
  "jurisdiction": "출처별 관할 · 운영 참고",
  "keywords": [],
  "references": [
    {
      "title": "기존 체크리스트 원문 1",
      "url": "https://www.gov.uk/government/publications/safer-food-better-business-for-caterers",
      "checkedAt": "2026-09-20",
      "scope": "기존 위키 조사 자료 · 업무 구조 참고, 국내 법적 기준으로 단정하지 않음"
    }
  ],
  "knowledge": {
    "scope": "food",
    "topics": [
      "people"
    ],
    "suggestedUse": "reference",
    "useCase": "startup"
  },
  "emoji": "🏪"
}
```


## 개업 전 · 가오픈과 최종 준비 확인

```tap2work-tap
{
  "sourceId": "startup/rehearsal",
  "collectionId": "food-startup",
  "collectionName": "개업 준비",
  "title": "개업 전 · 가오픈과 최종 준비 확인",
  "slot": "준비",
  "reviewedAt": "2026-10-13",
  "basis": "공개 자료를 참고한 편집 제안 · 현장 검토 필요",
  "steps": [
    {
      "id": "step-1",
      "title": "손님 입장부터 마감까지 시험 운영",
      "manual": "시험 손님 역할과 담당을 정하고 입장·대기·주문·조리·제공·결제·퇴석·정리 순서로 실제 동선을 따라가요. 각 구간의 기다림, 빠진 도구, 반복 질문을 기록하고 한 번에 바꿀 항목을 정해요.\n\n완료 기준: 현장에서 찾은 문제마다 위치·담당·수정 기한이 있어요.",
      "tip": "매장 기준과 담당자를 확인한 뒤 사용해 주세요.",
      "tags": [],
      "sourceUrl": "https://www.gov.uk/government/publications/safer-food-better-business-for-caterers"
    },
    {
      "id": "step-2",
      "title": "동시 주문·품절·교대를 함께 연습",
      "manual": "가능한 주문량 안에서 주문이 겹치는 상황과 품절·변경·포장 수령·교대를 시험해요. 주방과 홀의 되읽기, 다음 담당이 인계를 받았다는 확인까지 해봐요. 소화하지 못한 양을 정상 처리 능력으로 기록하지 않아요.\n\n완료 기준: 혼잡할 때 주문을 조절할 책임자와 고객 안내 기준이 정해져요.",
      "tip": "매장 기준과 담당자를 확인한 뒤 사용해 주세요.",
      "tags": [],
      "sourceUrl": "https://www.gov.uk/government/publications/safer-food-better-business-for-caterers"
    },
    {
      "id": "step-3",
      "title": "고장·미입고·결원 때의 대안 확인",
      "manual": "장비 고장, 주문 시스템 중단, 미입고, 크루 부재를 가정해 멈출 범위와 연락할 사람을 말로 연습해요. 안전을 확인하지 못한 장비·식재료를 대안으로 쓰지 않아요.\n\n완료 기준: 축소 운영·판매 중지·재개를 결정할 담당과 전달 경로가 있어요.",
      "tip": "매장 기준과 담당자를 확인한 뒤 사용해 주세요.",
      "tags": [],
      "sourceUrl": "https://www.gov.uk/government/publications/safer-food-better-business-for-caterers"
    },
    {
      "id": "step-4",
      "title": "개업 가능 여부와 미완료 항목 최종 검토",
      "manual": "사장님이 서류·설비·위생·판매·입고·인원·연습 결과를 직접 대조해요. 영업을 막는 미해결 사항과 개업 후 개선할 사항을 나누고 보류 구역·메뉴를 명시해요. 기준 변경은 담당과 적용일을 정해 공유해요.\n\n완료 기준: 누가 무엇을 확인했는지 남고, 확인하지 못한 항목을 완료로 표시하지 않아요.",
      "tip": "매장 기준과 담당자를 확인한 뒤 사용해 주세요.",
      "tags": [],
      "sourceUrl": "https://www.gov.uk/government/publications/safer-food-better-business-for-caterers"
    }
  ],
  "industryIds": [
    "food"
  ],
  "purposeId": "opening",
  "kind": "operation",
  "summary": "개업 전 · 가오픈과 최종 준비 확인",
  "applicability": "외식 공통 · 첫 매장의 해당 작업을 하는 사업장. 현장 절차와 장비 지침에 맞게 조정하세요.",
  "jurisdiction": "출처별 관할 · 운영 참고",
  "keywords": [],
  "references": [
    {
      "title": "기존 체크리스트 원문 1",
      "url": "https://www.gov.uk/government/publications/safer-food-better-business-for-caterers",
      "checkedAt": "2026-09-20",
      "scope": "기존 위키 조사 자료 · 업무 구조 참고, 국내 법적 기준으로 단정하지 않음"
    }
  ],
  "knowledge": {
    "scope": "food",
    "topics": [
      "opening"
    ],
    "suggestedUse": "reference",
    "useCase": "startup"
  },
  "emoji": "🏪"
}
```
