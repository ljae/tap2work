# Doodle logo

The user requested a newly generated logo inspired by the original's messy but charming blob characters, millennial humor and gentle hand-holding reassurance. Generated with the built-in `image_gen` tool; no CLI/API fallback was used.

- Current artwork: `../../tap2work.png` (copied unchanged to Flutter assets during builds).
- Earlier user-supplied artwork: `tap2work-original.png`.
- Format: horizontal 3:1 PNG on a white background, with the wordmark and existing “we all need a minute” tagline.
- First generation produced a baked-in checkerboard instead of alpha transparency. A second image-generation edit replaced it with white. The final is not transparent.
- Native launcher icons were not changed.

## Generation prompt

```text
Use case: logo-brand.
Create a NEW compact horizontal logo for "tap2.work", a friendly workplace companion for small restaurant teams.
Reference image role: the supplied image is a mood and character reference only. Redesign it for a much more legible small app header.
Subject: two endearingly imperfect soft blob characters drawn with slightly wobbly charcoal-black doodle outlines. A small tired sky-blue blob sits with gently drooping eyes, a tiny weary mouth and one comic sweat drop. A sunny butter-yellow blob leans toward it, smiling softly and gently holding its hand. Their joined hands should read clearly as comforting companionship, not a high five. Two small hand-drawn tap/tap motion ticks near their hands. Warm, understated millennial humor, "everything will be okay" feeling; charming and messy but deliberately simple.
Composition: one finished horizontal brand lockup, approximately 3:1 aspect ratio, isolated on a genuinely transparent background. The two-character symbol occupies the left third; the wordmark occupies the right two thirds. Tight useful framing with about 4% safe padding; no giant empty margins, enclosing circle, scene, floor line, props, mockup or presentation board.
Text verbatim: "tap2.work" in large, bold, rounded, casually hand-lettered lowercase charcoal text. Under it a much smaller handwritten line reading exactly "we all need a minute". These are the only words.
Flat pastel blue and butter yellow fills, strong charcoal lines, no gradients or shadows, no paper texture. Coherent original logo suitable for a friendly digital product, visibly hand-drawn, clear at small size. Output one actual logo image, not multiple variations.
```

## Final background correction prompt

```text
Change only the background of this generated logo. Replace ALL gray checkerboard and any paper texture with a perfectly uniform pure white (#FFFFFF) background, including spaces between letters and between the characters. Preserve the existing two characters, hand-holding pose, wordmark 'tap2.work', tagline 'we all need a minute', composition and colors. One clean finished horizontal logo on solid white, no checkerboard, no gray pattern, no shadows, no mockup. Preserve tight framing and 3:1 aspect ratio.
```
