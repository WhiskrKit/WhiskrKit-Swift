# Changelog

All notable changes to WhiskrKit for iOS are listed here. Versions follow
[Semantic Versioning](https://semver.org); every release is a git tag.

Add a line under **Unreleased** in each pull request. When releasing, rename
**Unreleased** to the new version and date, and start a new empty section.

## Unreleased

### Added
- Translations of all built-in strings and VoiceOver labels into Dutch, German,
  French, Spanish, Italian, Portuguese (Brazil), Japanese, Korean and
  Simplified Chinese.
- WhiskrKit's own strings follow the language a survey was served in when the
  survey response includes a `language` field. Without it, they follow the
  app's language as before.

### Changed
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
