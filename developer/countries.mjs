// ISO 3166-1 alpha-2 identifiers from IANA tzdata iso3166.tab (249 countries).
// Static identifiers only; display names follow the selected guide language.
export const nationalityCodes = 'AD AE AF AG AI AL AM AO AQ AR AS AT AU AW AX AZ BA BB BD BE BF BG BH BI BJ BL BM BN BO BQ BR BS BT BV BW BY BZ CA CC CD CF CG CH CI CK CL CM CN CO CR CU CV CW CX CY CZ DE DJ DK DM DO DZ EC EE EG EH ER ES ET FI FJ FK FM FO FR GA GB GD GE GF GG GH GI GL GM GN GP GQ GR GS GT GU GW GY HK HM HN HR HT HU ID IE IL IM IN IO IQ IR IS IT JE JM JO JP KE KG KH KI KM KN KP KR KW KY KZ LA LB LC LI LK LR LS LT LU LV LY MA MC MD ME MF MG MH MK ML MM MN MO MP MQ MR MS MT MU MV MW MX MY MZ NA NC NE NF NG NI NL NO NP NR NU NZ OM PA PE PF PG PH PK PL PM PN PR PS PT PW PY QA RE RO RS RU RW SA SB SC SD SE SG SH SI SJ SK SL SM SN SO SR SS ST SV SX SY SZ TC TD TF TG TH TJ TK TL TM TN TO TR TT TV TW TZ UA UG UM US UY UZ VA VC VE VG VI VN VU WF WS YE YT ZA ZM ZW'.split(' ');
const countries = new Set(nationalityCodes);
export const validNationality = value => typeof value === 'string' && countries.has(value);
export function nationalityOptions(locale = 'ko') {
  let names;
  try { names = new Intl.DisplayNames([locale], { type: 'region' }); } catch { names = new Intl.DisplayNames(['ko'], { type: 'region' }); }
  const preferred = ['KR','VN','CN','JP','TH','NP','ID','US'];
  return nationalityCodes.map(code => ({ code, name: names.of(code) ?? code })).sort((a,b) => {
    const ai = preferred.indexOf(a.code), bi = preferred.indexOf(b.code);
    if (ai >= 0 || bi >= 0) return (ai < 0 ? 999 : ai) - (bi < 0 ? 999 : bi);
    return a.name.localeCompare(b.name,locale);
  });
}
