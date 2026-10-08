export const businessTypes = [
  ['chicken', '치킨', 'restaurant', 'chicken'],
  ['korean', '한식', 'restaurant', 'korean'],
  ['donkatsu', '돈까스', 'restaurant', 'chicken'],
  ['snack', '분식', 'restaurant', 'snack'],
  ['bbq', '고기·구이', 'restaurant', 'bbq'],
  ['sushi', '일식·초밥', 'restaurant', 'sushi'],
  ['chinese', '중식', 'restaurant', 'chinese'],
  ['pizza', '피자', 'restaurant', 'pizza'],
  ['bonejjim', '감자탕·뼈찜', 'restaurant', 'bonejjim'],
  ['banchan', '반찬·도시락', 'restaurant', 'banchan'],
  ['cafe', '카페', 'cafe', 'cafe'],
  ['bakery', '베이커리', 'bakery', 'bakery'],
  ['pub', '주점', 'bar', 'pub'],
  ['other', '기타 식음료', 'other', 'common'],
].map(([id, name, industryId, collectionId]) => ({id, name, industryId, collectionId}));

