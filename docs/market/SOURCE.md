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
    "suggestedUse": "routine"
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
    "suggestedUse": "routine"
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
    "suggestedUse": "routine"
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
    "suggestedUse": "routine"
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
    "suggestedUse": "routine"
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
    "suggestedUse": "routine"
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
    "suggestedUse": "routine"
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
    "suggestedUse": "routine"
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
    "suggestedUse": "routine"
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
    "suggestedUse": "routine"
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
    "suggestedUse": "routine"
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
    "suggestedUse": "routine"
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
    "suggestedUse": "routine"
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
    "suggestedUse": "routine"
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
    "suggestedUse": "routine"
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
    "suggestedUse": "routine"
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
    "suggestedUse": "routine"
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
    "suggestedUse": "routine"
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
    "suggestedUse": "routine"
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
    "suggestedUse": "routine"
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
    "suggestedUse": "routine"
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
    "suggestedUse": "routine"
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
    "suggestedUse": "routine"
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
    "suggestedUse": "routine"
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
    "suggestedUse": "routine"
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
    "suggestedUse": "routine"
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
    "suggestedUse": "routine"
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
    "suggestedUse": "routine"
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
    "suggestedUse": "routine"
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
    "suggestedUse": "routine"
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
    "suggestedUse": "event",
    "eventKind": "batch",
    "menuNames": [
      "감자탕",
      "뼈해장국"
    ],
    "safetyReviewRequired": true
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
    "suggestedUse": "event",
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
    "safetyReviewRequired": true
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
    "suggestedUse": "event",
    "eventKind": "opened",
    "ingredientNames": [
      "떡",
      "떡볶이떡"
    ],
    "menuNames": [
      "떡볶이"
    ],
    "safetyReviewRequired": true
  }
}
```
