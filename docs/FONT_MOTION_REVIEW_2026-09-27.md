# TAP motion and Korean font review · 2026-09-27

## Finding and repair

The public read-only preview changed task state without calling the completion animation trigger. On the TAP detail view, conditionally inserted controls replaced the unkeyed `AnimatedSwitcher`, so opening a TAP skipped the intended transition. A completed board card also moves to another lane; on a phone that lane can be off screen. The UI now triggers motion after a successful preview or live completion, keeps stable switcher identities, and briefly shows the falling title at its source card when a checked TAP changes lanes. Completion records and undo rules still come from the existing state and server policy. Reduced-motion settings show the result without the animation.

## Aside CLI font search

Using `aside` CLI, we compared the official sources for [Pretendard](https://github.com/orioncactus/pretendard/blob/main/packages/pretendard/README.md), [SUIT](https://github.com/sun-typeface/SUIT/blob/main/.github/README.md), and [LINE Seed](https://seed.line.me/index_kr.html). Pretendard was selected for Korean screen readability and broad Hangul coverage. Four static weights from the pinned [Pretendard v1.3.9 release](https://github.com/orioncactus/pretendard/releases/tag/v1.3.9) are bundled locally under [SIL Open Font License 1.1](https://github.com/orioncactus/pretendard/blob/main/LICENSE). The previous Noto Sans KR asset was removed. Web and native use the same bundled Flutter font declaration; native rendering was not verified.

## Verification

`flutter analyze` reported no issues. `flutter test` passed 98 tests, including successful preview TAP and Small TAP completion at intermediate animation frames, TAP opening before the transition settles, reduced-motion behavior, and existing 320 px checks. `npm run check` and 65 console tests passed; no backend API or persistence code changed. A desktop local preview screenshot was visually inspected after the font change. A phone-sized live browser screenshot and native-device motion check were not completed.
