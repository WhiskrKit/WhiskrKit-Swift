# WhiskrKit Playground: cross-platform spec

This file describes the WhiskrKit Playground sample app so it can be rebuilt for the
Android, React Native and Flutter SDKs. The iOS version in
`Examples/WhiskrKitPlayground/` is the reference. Everything a session in another SDK
repo needs is in this file, together with that SDK's own code.

Where the spec says "must", keep it identical on every platform so the playgrounds
behave the same and snippets look alike. Where it says "should", adapt to the
platform's conventions.

## 1. Purpose and scope

A small sample app that lets a developer see how WhiskrKit looks and behaves before
integrating it. One screen, no backend, no API key.

On that screen a developer can:

1. Present any question type or presentation style immediately.
2. Change theme colors, through presets or per color, and see the result on the next
   survey.
3. Copy a code snippet that builds the same theme with the platform's public API.

Out of scope, on purpose: survey placement controls, fonts, corner radii, spacing,
and an in-app preview of survey components. The real survey is the preview.

## 2. Project setup

- The sample lives in the SDK repo under `Examples/<PlaygroundName>/`.
- It **must** depend on the SDK through a local path reference to the repo's own
  source, not a published version, so it always builds against the current code.
- It **must** initialize WhiskrKit with mocked surveys. See section 5.
- CI **should** build the sample so it can't drift from the SDK. iOS: not added yet;
  the planned job runs `xcodebuild build -project
  Examples/WhiskrKitPlayground/WhiskrKitPlayground.xcodeproj -scheme
  WhiskrKitPlayground -destination 'generic/platform=iOS Simulator'`.

iOS specifics, for reference:

- `Examples/WhiskrKitPlayground/WhiskrKitPlayground.xcodeproj`, a classic
  `project.pbxproj` (`objectVersion = 77`, opens in Xcode 16+), with the repo root as a
  local Swift package (`relativePath = ../..`) and a shared scheme.
- Sources are in a synchronized folder `Examples/WhiskrKitPlayground/WhiskrKitPlayground/`:

  | File | Role |
  |---|---|
  | `PlaygroundApp.swift` | Entry point: initialize with mocks, create settings, attach WhiskrKit to the root view |
  | `PlaygroundCatalog.swift` | All data: survey descriptors, color roles, presets |
  | `ThemeSettings.swift` | Observable settings: persistence, theme building, snippet generation |
  | `PlaygroundView.swift` | The single screen |
  | `Color+Hex.swift` | `#RRGGBB` ⇄ color conversion |

## 3. Screen

One scrollable settings-style list (iOS: `Form` in a `NavigationStack`), titled
**"WhiskrKit Playground"**, with these sections in this order.

### 3.1 "Question types" and "Presentation styles"

One tappable row per survey descriptor (section 4), grouped by the descriptor's
`group`. Each row shows an icon, the name and a one-line summary. Tapping a row
presents that mocked survey immediately (section 5). Below the last of these two
sections, a footer reads: *"Surveys are mocked: responses and events are never sent
to WhiskrKit."*

### 3.2 "Presets"

One row per preset (section 7) showing the name, a row of six small swatches (the
color each role would get under that preset, with system colors drawn as the
system color in the current mode), and a checkmark on the preset whose colors
exactly match the current custom colors. Tapping a row replaces all custom colors
with the preset's. No checkmark shows when the current colors match no preset.

### 3.3 "Colors"

- First row: a three-way segmented control **"Preview in": System / Light / Dark**.
  It forces the app's appearance, presented surveys included, so a theme can be
  checked in both modes. It is not persisted.
- Then one row per color role (section 6): the name, the role's description, and
  the current value on its own line (`#RRGGBB`, or `System` when not customized).
  On the trailing side there's a color picker without opacity, and, only when the
  role is customized, a reset button that returns the role to its system color.
- Footer: *"A picked color is fixed: it looks the same in light and dark mode. Reset a
  color to go back to its adaptive system color."*

### 3.4 "Code"

- The generated snippet (section 9) in a small monospaced font, horizontally
  scrollable (no wrapping) and selectable.
- A **"Copy code"** button that puts the snippet on the clipboard. Its label changes to
  "Copied" with a checkmark for 2 seconds.

### Behavior

- Every color change is saved and applied to the SDK at once
  (`WhiskrKit.shared.setTheme(...)` on iOS). The next survey presented uses it.
- On launch the saved colors are loaded and applied before any survey can be shown.

## 4. Surveys (descriptors)

Defined as data, one list. Fields: `id` (the mocked survey id), `name`, `summary`,
icon, `group`.

| Group | Name | Mock id | Presentation | Content |
|---|---|---|---|---|
| Question types | Scale rating | `onboarding-survey` | sheet | Title "Welcome aboard!", description "Help us understand your needs better", follow-up question "What could we do better?". Scale rating "How likely are you to recommend us?", range 1–8, required. |
| Question types | Symbol rating | `feature-feedback` | sheet | Title "New Feature Feedback", description "What do you think of our latest update?". Five-star rating "Rate your experience", optional. |
| Question types | Thumbs rating | `checkout-survey` | sheet | Title "How was your checkout?", description "We'd love to hear your thoughts". Thumbs up/down, optional. |
| Question types | Text feedback | `ask-survey` | sheet | Title "What would you ask us?". Free text "Tell us more", max 200 characters, required. |
| Question types | Multiple choice | `choice-survey` | sheet | Title "You recently visited the Avatar", follow-up question "What did you like most?". Multi-select "What element is your strength?" with Water, Fire, Earth, Air; required. |
| Presentation styles | Toast | `welcome-toast` | toast | Title "Welcome to our app!", description "How are you liking it so far?", inline thumbs rating. Its follow-up opens `onboarding-survey`. |
| Presentation styles | Full-screen form | `super-survey` | full-screen form | Title "Main Road Construction", subtitle "Residents satisfaction survey of Main Road Ave", with all five question types: scale, text, symbol, thumbs, multiple choice. |

The question types are the five the iOS SDK supports: `scaleRating`, `symbolRating`,
`thumbsRating`, `textualSurvey`, `multipleChoice`. The presentation styles are
`sheet`, `toast`, `fullScreenForm`. If another SDK supports more or fewer, add or
remove rows and note it in section 13.

The iOS mock defines a few more ids (`quick-feedback`, `simple-toast`,
`detailed-survey`, `onboarding-questionnaire`, `satisfaction-survey`, `inline-nps`).
The playground doesn't use them.

## 5. Triggering mocked surveys

1. At startup: `initialize(apiKey: "playground", withMockedSurveys: true)`. Any key
   works in mock mode.
2. Attach WhiskrKit once to the root of the UI (iOS: the `.whiskrKit()` modifier on the
   root view). Without it, presenting does nothing.
3. On row tap: `present(surveyId: <mock id>)`. This skips eligibility rules, so a
   survey can be shown again and again.

The iOS mock waits 0.5 s before returning a survey, to imitate a network request. So
there's a short delay between tap and presentation.

### What mock mode must never do

In mock mode the SDK must not contact the backend and must not write eligibility
state. On iOS (after the fixes in section 10) that means:

| Path | Mock behavior |
|---|---|
| Fetch survey by id | Returned from an in-memory dictionary |
| Eligibility check | Delegates to the mock fetch, no request |
| Submit response | Logged only |
| Impressions | Not sent (guard in `recordImpression`), and the mock logs only |
| Retry queued submissions | Not started (the real service is never configured) |
| "Seen" and "completed" survey storage | Not written |

## 6. Color roles

Six roles, defined as data in one list. The `id` is the persistence key and the
variable name in the snippet, so it **must** be the same on every platform.

| `id` | Name | Description | iOS theme properties it sets | System default (iOS) |
|---|---|---|---|---|
| `accent` | Accent | Primary button background | `button.primary.backgroundColor` | `Color(.label)` |
| `onAccent` | On accent | Primary button text | `button.primary.textColor` | `Color(.systemBackground)` |
| `background` | Background | Sheet, form and toast background | `container.toast.backgroundColor`; and `container.sheet` / `container.fullScreen` **only when customized** | `Color(.secondarySystemBackground)` |
| `text` | Text | Titles, body, secondary buttons | `title`, `headline`, `body` colors and `button.secondary.textColor` | `Color.primary` |
| `secondaryText` | Secondary text | Subtitles and subheadlines | `subtitle`, `subheadline` colors | `Color.secondary` |
| `selection` | Selection | Selected multiple-choice options | `selectionColor.tintColor` | `Color(.label)` |

Meaning of the defaults, for platforms without these exact names: `accent` is
high-contrast foreground (black in light mode, white in dark); `onAccent` is the page
background (the inverse); `background` is a slightly raised surface; `text` and
`secondaryText` are the platform's primary and secondary label colors; `selection`
matches `accent`.

Theme values the playground does not expose stay as in `systemStyle`: all fonts,
corner radii (primary 10, secondary 8, toast 8), toast shadow off, secondary button
background transparent, and selection background `Color(.tertiarySystemBackground)`.

iOS rendering detail: the SDK draws subtitle and subheadline with an extra
"secondary" opacity on top of the chosen color, so `secondaryText` always looks a bit
lighter than the picked value.

### Building the theme

- **No custom colors:** use the SDK's built-in preset as-is (iOS:
  `WhiskrKitTheme.systemStyle`). The "System" preset therefore reproduces the default
  look exactly.
- **One or more custom colors:** build a theme equal to `systemStyle` with each role's
  color (custom or system default) put into the properties listed above. When
  `background` is not customized, leave the sheet and full-screen backgrounds unset,
  as `systemStyle` does, so the platform's own sheet background stays.

## 7. Presets

Defined as data. Roles a preset leaves out stay on their system color.

| `id` | Name | Colors |
|---|---|---|
| `system` | System | *(none)*. This is also the reset. |
| `ocean` | Ocean | `accent` `#0066CC`, `onAccent` `#FFFFFF`, `selection` `#0066CC` |
| `sunset` | Sunset | `accent` `#E8590C`, `onAccent` `#FFFFFF`, `selection` `#E8590C` |
| `midnight` | Midnight | `accent` `#F5C542`, `onAccent` `#1B1B2F`, `background` `#1B1B2F`, `text` `#F2F2F7`, `secondaryText` `#A5A5C0`, `selection` `#F5C542` |

Ocean and Sunset only set brand colors, so surfaces and text keep adapting to light
and dark mode. Midnight sets everything, which makes it a fixed dark theme in both
modes. That is the trade-off section 8 describes.

The iOS SDK has only one built-in preset (`systemStyle`). Ocean, Sunset and Midnight
exist only in the playground. If another SDK has more built-in presets, it may add
them as extra rows. Don't drop these four.

## 8. Light and dark mode

Decision: each role is either **System** (adaptive) or **one fixed custom color**.

- System uses the SDK's adaptive default, so it is correct in both modes.
- A picked color is static and looks the same in light and dark mode. The UI says so
  in the Colors footer, and the Preview toggle lets you check both modes.
- There are no separate light and dark colors per role. That would double the UI and
  the snippet. It could come later, as a "Separate dark colors" toggle that adds a
  dark value per role and emits the platform's dynamic color construct.

## 9. Code snippet

Generated from the current state every time it changes. Rules:

1. With no custom colors, the snippet is just the one-line call that applies the
   built-in preset. iOS: `WhiskrKit.shared.setTheme(.systemStyle)`.
2. Otherwise:
   - Declare one variable per role, named by role `id`, in role order.
   - A custom color is a literal built from RGB components (iOS:
     `Color(red: 0.000, green: 0.400, blue: 0.800)`, three decimals, sRGB) followed by
     a comment with its hex value (`// #0066CC`).
   - A system color is the platform's expression for that role's default.
   - Then the full theme construction, using only those variables and the fixed
     values from section 6.
   - Then the call that applies the theme.
3. The snippet **must** compile when pasted into an app that imports the SDK, with no
   helper code (no hex extension). Check this whenever the generator changes. On iOS
   it was checked by type-checking the copied output against the built module.
4. The generator and the theme builder are two views of the same mapping. Keep them
   next to each other in one file and change them together.

iOS output for the Ocean preset:

```swift
let accent = Color(red: 0.000, green: 0.400, blue: 0.800) // #0066CC
let onAccent = Color(red: 1.000, green: 1.000, blue: 1.000) // #FFFFFF
let background = Color(.secondarySystemBackground)
let text = Color.primary
let secondaryText = Color.secondary
let selection = Color(red: 0.000, green: 0.400, blue: 0.800) // #0066CC

let theme = WhiskrKitTheme(
    container: .init(
        toast: .init(cornerRadius: 8, backgroundColor: background, withShadow: false)
    ),
    selectionColor: .init(tintColor: selection, backgroundColor: Color(.tertiarySystemBackground)),
    button: .init(
        primary: .variant(.init(backgroundColor: accent, textColor: onAccent, font: .body.weight(.medium), cornerRadius: 10)),
        secondary: .variant(.init(backgroundColor: .clear, textColor: text, font: .body, cornerRadius: 8))
    ),
    title: .init(font: .title2.weight(.bold), color: text),
    subtitle: .init(font: .headline.weight(.semibold), color: secondaryText),
    headline: .init(font: .headline, color: text),
    subheadline: .init(font: .subheadline, color: secondaryText),
    body: .init(font: .body, color: text)
)

WhiskrKit.shared.setTheme(theme)
```

When `background` is customized, `container` also gets
`sheet: .init(backgroundColor: background),` and
`fullScreen: .init(backgroundColor: background),` before `toast`.

## 10. Persistence

- Store: the platform's simple key-value store (iOS `UserDefaults.standard`, Android
  `SharedPreferences` or DataStore, React Native AsyncStorage, Flutter
  `shared_preferences`).
- Key: `whiskrkit.playground.colors`.
- Value: a JSON object from role `id` to an uppercase `#RRGGBB` string, holding
  **only customized roles**. For example `{"accent":"#0066CC","onAccent":"#FFFFFF"}`.
  An empty object or a missing key means everything is System.
- Load: drop unknown role ids and values that aren't valid 6-digit hex.
- Save after every change.
- Colors are opaque. The picker hides opacity and any alpha is dropped. Picked colors
  are converted to sRGB and rounded to 8 bits per channel before saving, so a value
  round-trips exactly.
- The appearance preview (System, Light, Dark) and the last presented survey are not
  saved.

## 11. SDK requirements and the changes made on iOS

Check each item in the other SDK before building its playground.

1. **Mocked surveys flag** on initialize. It must swap every backend-facing
   dependency for a mock.
2. **Mock survey ids and content** from section 4. Add any that are missing, ideally
   with the same content, so the playgrounds look alike.
3. **Present by id on demand,** skipping eligibility. On iOS this already existed
   (`present(surveyId:)`) and needed no change.
4. **Theme changes at runtime.** On iOS, `setTheme` stores the theme on an observable
   singleton, and the attachment point reads it every time it renders. A new theme
   reaches the next survey, and sheets, toasts and full-screen forms already on screen
   update too. Exception: the iPad floating panel takes the theme when it opens, so it
   changes from the next presentation. If another SDK reads the theme only once at
   initialize, change it to read the current theme at presentation time.
5. **Mock mode must not leak.** Two fixes were needed on iOS
   (`Sources/WhiskrKit/API/WhiskrKit.swift`):
   - `initialize` configured the real configuration service before swapping in the
     mock. Configuring it starts a retry of queued real submissions against the
     production backend, sent with the fake key. Now the mock is swapped in first and
     only the active service is configured.
   - Completing a survey in mock mode wrote "completed" eligibility state to local
     storage. Completion tracking now returns early in mock mode, like seen-tracking
     and impressions already did.

   Look for the same two patterns in the other SDK: setup work on the real service
   before the mock branch, and local eligibility writes that skip the mock check.
6. **Theme API shape.** iOS exposes a public initializer only; the theme's text styles
   have no public getters. So the playground builds the whole theme instead of copying
   `systemStyle` and changing a few values. If another SDK allows `copy(...)` or
   similar, the snippet may use it, as long as the result matches section 6.

## 12. Decisions and reasons

| Decision | Reason |
|---|---|
| One screen, sections in a list | Keeps the sample small; it's a demo, not a showcase app |
| Surveys, roles and presets are data | So every platform can mirror the structure |
| Six color roles, not every theme property | The colors a developer actually brands; fonts and radii are out of scope |
| Selection background not exposed | Its system default reads well against both background states; one fewer control |
| System or one fixed color per role | Snippet stays copy-pasteable and short; see section 8 |
| No custom colors → built-in preset as-is | "System" matches the SDK default exactly, including unset sheet backgrounds |
| Brand presets only set accent roles | They keep working in dark mode; Midnight shows the fully fixed alternative |
| `#RRGGBB` storage, no alpha | Portable across platforms; opacity rarely makes sense for these roles |
| Snippet uses RGB literals, not hex helpers | Compiles without extra code |
| Six named variables in the snippet | Shorter than repeating literals, and the names tie back to the roles |
| Classic `project.pbxproj` (`objectVersion = 77`) on iOS | The Xcode 27.2 JSON format (`project.xcproj`) needs Xcode 27+ to open; the SDK supports Xcode 26 (swift-tools 6.2). Convert later with `xcodebuild -convert-project` once Xcode 27.2+ is common |
| Local path dependency on the SDK | The sample always reflects current SDK code |
| CI builds the sample | Catches drift between SDK and sample |

## 13. Known limitations (iOS)

- Not themeable in the SDK: star color (yellow), thumbs colors, the scale rating color
  gradient, error red, and the text field's character counter. Changing the theme
  doesn't affect them.
- Mock content quirks, left as they are because they are visible content: the
  scale rating subtitle says "0 = Not at all likely, 8 = Extremely likely" but the range
  is 1–8; `super-survey` reuses the template id `form-3` of `satisfaction-survey`.
- On iPad (regular width), sheet surveys show as a floating panel. See section 11.4
  for theming.

## 14. Checklist for a new platform

1. Read this file and the SDK's theme, mock and presentation code.
2. Go through section 11 and fix the SDK where needed. Add the fixes to that SDK's own
   notes and to its version of this spec.
3. Create `Examples/<PlaygroundName>/` with a local path dependency on the SDK.
4. Port the data from sections 4, 6 and 7 one-to-one: same ids, names, hex values.
5. Build the screen (section 3), persistence (section 10) and snippet (section 9).
6. Check: every row presents its survey; presets and pickers change the next survey;
   reset returns a role to System; colors survive a restart; the copied snippet
   compiles; both preview modes look right; nothing is sent over the network in mock
   mode.
7. Add a CI job that builds the sample, and a short README section that points to it.
8. Copy this spec into that repo and add a "Platform notes" section for anything that
   differs (role mapping to that SDK's theme properties, system color expressions,
   unsupported question types).
