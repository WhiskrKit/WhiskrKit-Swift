# Changelog

All notable changes to WhiskrKit for iOS are listed here. Versions follow
[Semantic Versioning](https://semver.org); every release is a git tag.

Add a line under **Unreleased** in each pull request. When releasing, rename
**Unreleased** to the new version and date, and start a new empty section.

## Unreleased

## 0.3.0 (not yet released)

### Added
- Rating metrics for scale questions. The server sends a `metric` (`nps`,
  `csat`, `ces` or `custom`), a `displayStyle` (`numbers` or `stars`) and, for
  `custom`, optional `minLabel` and `maxLabel`. The server calculates the
  metric; the SDK renders the question and sends the chosen number, under the
  same `npsRating` key as before. All fields are optional: a survey from an
  older server shows as `custom` with numbers. Values this version doesn't know
  fall back to `custom` and `numbers` instead of failing the survey.
- Selected scores are colored per metric: NPS 0–6 red, 7–8 dark gold, 9–10
  green; CSAT 4–5 green; CSAT 1–3, CES and custom a neutral blue. The colors are
  fixed (not themeable), meet WCAG contrast in light and dark mode, and carry
  dark text. A 2pt outline marks the selected score as well, so the selection
  never relies on color alone.
- End labels in one line under the scale: translated defaults for NPS ("Not at
  all likely" / "Extremely likely"), CSAT ("Very dissatisfied" / "Very
  satisfied") and CES ("Very difficult" / "Very easy") in all ten languages, and
  the server's labels for `custom`. VoiceOver hears them in each button's hint,
  for example "8 out of 10. 0 is Not at all likely, 10 is Extremely likely".
- Five stars for `displayStyle: stars` with a 1 to 5 range; other ranges show
  numbers. Tapping the chosen star again clears it.
- Every request sends `X-WhiskrKit-SDK: ios/<version>`, the same header Android
  sends, so the server can handle compatibility.
- The Playground has a "Rating metrics" section with an NPS, CSAT, CSAT stars,
  CES and custom rating survey.

### Changed
- Scale questions without a metric show the neutral blue for the selected score
  instead of the red to green gradient.
- Score buttons grow with Dynamic Type (never smaller than 44pt) and wrap to
  more rows at large text sizes. Whether 0 to 5 fits on one row now depends on
  the number of options, not on the highest value, and rows no longer run past
  the edge of the screen.
- A question's `A11yLabel` and `A11yHint` are only applied when the server sends
  them, instead of setting an empty label.

### Fixed
- Deselecting a scale rating (tapping the selected score again) cleared the
  selection on screen but still submitted the old score. It is now removed from
  the response.
- The `User-Agent` reported the host app's version instead of the SDK's, because
  a Swift package has no bundle of its own to read it from. The version is now a
  constant in the SDK.

## 0.2.0 - 2026-11-11

### Added
- `WhiskrKit.shared.onSurveyCompleted`: called on the main actor when the user
  submits a survey, with the survey id and the submitted answers (question id,
  question type and value). It fires whether or not the response reaches the
  server, and not when a survey is dismissed without submitting.
- Global survey attributes: `setAttribute`, `setAttributes`, `removeAttribute` and
  `clearAttributes` attach string, number or bool values to every survey
  response submitted afterwards. Personal data is dropped by the server.
- A small "Powered by WhiskrKit" badge below the submit button of toasts and
  sheets (including the iPad floating panel), shown only when the server enables
  it with `branding.visible`. The server decides; the SDK only renders. A missing
  or malformed `branding` hides the badge and never breaks the survey. The text is
  translated, the product name is not. The badge is one VoiceOver element, scales
  with Dynamic Type, and, when the theme's secondary text color would not reach a
  4.5:1 contrast on the survey background, is darkened or lightened just enough
  to get there.
- The Playground's mocked toasts and sheets always show the badge, so it can be
  previewed in every theme and appearance.
- Translations of all built-in strings and VoiceOver labels into Dutch, German,
  French, Spanish, Italian, Portuguese (Brazil), Japanese, Korean and
  Simplified Chinese.
- WhiskrKit's own strings follow the language a survey was served in when the
  survey response includes a `language` field. Without it, they follow the
  app's language as before.

### Changed
- Star questions no longer read the unused `opensStoreReview` field, so a survey
  without it decodes as well.
- The star rating is a single adjustable VoiceOver element: swipe up or down to
  change the rating.
- Multiple choice options announce their state with the standard "Selected"
  trait instead of a custom "checked/unchecked" value and hint.

### Fixed
- Strings that were hardcoded in English ("checked", "Double tap to select",
  "stars", and the "Survey" fallback title) are now localized.
- Every star in the star rating had the VoiceOver label "Star 1".
- Placeholders in the string catalog are numbered, so translations can reorder
  them.

## 0.1.11 and earlier

See the [releases on GitHub](https://github.com/WhiskrKit/WhiskrKit-Swift/releases).
