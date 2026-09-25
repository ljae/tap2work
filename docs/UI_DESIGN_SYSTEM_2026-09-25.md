# tap2work UI design system · 2026-09-25

## Reference and fit

The [UI UX Pro Max skill](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill) was installed from the repository's `.claude/skills/ui-ux-pro-max` path and used for product, UX and Flutter guidance (upstream main `dcc40ff5133ef78276117db0cc34e7b83cc8aeba`). Its generated restaurant landing page and dark operations dashboard palettes were not adopted: tap2work already has a confirmed warm paper, deep green and coral direction. The applicable principles are clear task hierarchy, large touch targets, readable status in text as well as color, and phone-first responsive layout.

## Shared language

| Element | Rule |
| --- | --- |
| Background | Warm paper `#F7F5F0`; white card surfaces with a fine border |
| Navigation and headings | Deep green; selected navigation has a visible Korean label |
| Primary action | Coral `#B8422C` with white text; its contrast is approximately 5.45:1 |
| Attention state | Soft coral surface plus text and icon; color alone never carries meaning |
| Spacing | 8 px rhythm, with 16–24 px content gaps and a 20 px phone gutter |
| Headings | One page title, then section headings; short kicker and supporting sentence where helpful |
| Cards | 20 px shared surface radius, quiet borders, restrained shadow or no shadow |
| Controls | Labeled pickers, equal-width choices, visible focus border, touch areas targeting at least 48 dp |

The code tokens live in `app/lib/ui/components.dart` and the theme in `app/lib/main.dart`. Screen-specific exceptions should use those tokens before introducing another color or spacing value.

## Screen hierarchy

1. **현황:** current work and shortages first; operations shortcuts second; reports and historical views below. Prepared inventory details remain available in a collapsed summary.
2. **할 일:** search has an explicit label; Tap cards lead with progress and show readable count, state and action text.
3. **근무:** seven-day selection above one selected-day R&R timeline. Its fixed time axis and horizontally scrollable role columns are intentional. Half-hour rows use 48 dp height. Empty required slots use a text and icon state.
4. **매장:** configured table, seat and equipment counts appear as separate summary cards; map and material locations follow.
5. **로그인 and first-shift guide:** shared type, cards and button hierarchy; password visibility and loading feedback are explicit. The existing practice/buddy separation remains.

The four operations destinations retain the same 1240 px maximum content width and 20 px phone gutters. The schedule and floor map may scroll within their own bounded work areas. The public preview remains read-only and explicitly labeled as sample data. These visual changes do not create authenticated employee actions, real supplier orders, live occupancy or payroll.

## Verification boundary

Flutter analysis and all 84 widget tests passed, including existing 320 px screen cases. The public Flutter build passed. No native build, physical-device interaction, dark-theme implementation or visual screenshot comparison was performed for this revision.
