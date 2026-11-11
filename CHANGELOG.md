# Changelog

All notable changes to WhiskrKit for iOS are listed here. Versions follow
[Semantic Versioning](https://semver.org); every release is a git tag.

Add a line under **Unreleased** in each pull request. When releasing, rename
**Unreleased** to the new version and date, and start a new empty section.

## Unreleased

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
