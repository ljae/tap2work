// Language preferences and actual translation availability are independent.
// Keep BCP-47 strings, never translated labels, in persisted configuration.
export const supportedLocales = ['ko'];
export function canonicalLocale(value) {
  if (typeof value !== 'string' || value.length > 35) return null;
  try { return Intl.getCanonicalLocales(value)[0] ?? null; } catch { return null; }
}
export function languageContext(state, person, invitation = null) {
  const storeLocale = canonicalLocale(state.store?.locale) ?? 'ko';
  const preferredLocale = canonicalLocale(person?.preferences?.locale) ?? storeLocale;
  const invitationLocale = canonicalLocale(invitation?.locale) ?? preferredLocale;
  const effective = locale => supportedLocales.includes(locale) ? locale : supportedLocales.includes(locale.split('-')[0]) ? locale.split('-')[0] : 'ko';
  return { storeLocale, preferredLocale, effectiveLocale: effective(preferredLocale), invitationLocale, effectiveInvitationLocale: effective(invitationLocale), timeZone: state.store?.timeZone ?? 'Asia/Seoul' };
}
