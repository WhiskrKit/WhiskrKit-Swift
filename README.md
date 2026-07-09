![WhiskrKit logo](https://whiskrkit.eu/WhiskrKit_logo.png)

![version](https://img.shields.io/badge/version-0.1.8-blue) ![MIT](https://img.shields.io/badge/license-MIT-green) 

# WhiskrKit for iOS (Swift) - The purr-fect feedback toolkit for modern apps.

WhiskrKit provides a flexible and easy-to-use API for presenting various types of 
questionnaires and feedback forms in your SwiftUI applications.

## To do

Before this framework has *production state*, the following items need to be added:

- [x] Mechanism to show surveys based on triggers like: time, app restarts, user 
      size of the host app, or manual triggering.
- [x] iPad specific layout.
- [ ] Implement follow-up option to App Store Rating.

For feature requests or changes to this native Swift version of WhiskrKit, you can 
create an issue. If you have requests or questions for WhiskrKit in general, please 
contact us directly via the dashboard (once available) or via mail.

## Features

* **Multiple Questionnaire Types**: Star ratings, thumbs up/down, NPS ratings, textual entry, multiple choice
* **Flexible Presentation Styles**: Sheets, toasts, full-screen covers
* **SwiftUI and UIKit**: a one-line view modifier for SwiftUI apps, a one-line window attachment for UIKit and hybrid apps
* **Adaptive iPad Layout**: on wide screens, sheet surveys become floating panels and toasts can be corner-anchored, with integrator-selectable placement
* **Highly Customizable**: Colors, fonts, layouts, behaviors, and content
* **Accessibility First**: Full VoiceOver and Dynamic Type support
* **Haptic Feedback**: Enhanced user experience

## Quick Start

### Initialization and theming

WhiskrKit is completely customizable to fit the look of your app. Just supply your 
fonts and colors. Get the API key from the WhiskrKit dashboard that you created for your app.
```swift
import SwiftUI
import WhiskrKit

@main
struct SampleApp: App {

    let sampleTheme = WhiskrKitTheme(...)

    init() {
        WhiskrKit.shared.initialize(apiKey: "your-api-key")
        WhiskrKit.shared.setTheme(sampleTheme)
    }
}
```

To set a theme, you supply:

<ul>
  <li>A container theme, optional for
    <ul>
      <li>Sheets</li>
      <li>Fullscreen modal views</li>
      <li>Toasts</li>
    </ul>
  </li>
  <li>A button theme
    <ul>
      <li>A primary and secondary option</li>
    </ul>
  </li>
  <li>Several text themes, with font and color
    <ul>
      <li>Title, subtitle, headline, subheadline and body</li>
    </ul>
  </li>
</ul>

WhiskrKit supports Dynamic Type and dark mode natively, but you have to make sure to 
supply adaptive colors and fonts for optimal results.

Go to the `Theme.swift` file in this project to look for an example of how to make 
a theme. You can also use the provided `systemStyle` theme preset for your project 
by assigning it as your theme constant.

## Presenting Surveys

WhiskrKit supports two ways to present surveys: automatically based on eligibility 
rules, or manually via an imperative trigger.

### Automatic presentation

When you create a survey in the WhiskrKit dashboard you will receive an identifier. Add 
`.whiskrKitSurvey(identifier:)` to a view that is in the context of where you would like to show your survey.
 WhiskrKit will automatically evaluate eligibility and present the survey based on the conditions you configure in the dashboard, 
such as after a certain number of sessions, a time interval, or for a percentage of your users.
```swift
import SwiftUI
import WhiskrKit

struct HomeView: View {
    var body: some View {
        VStack {
            Text("Welcome to WhiskrKit")
                .font(.title)
        }
        .whiskrKitSurvey(identifier: "your-survey-id")
    }
}
```

### Event-driven trigger with backend targeting (hybrid)

Sometimes you want the timing to be yours but the targeting decision to stay with the backend, for example, checking whether to show a survey after a user dismisses a sheet or completes a flow.

Use `checkAndPresent(surveyId:)` for this. It runs the eligibility check and only presents the survey if the user qualifies:

```swift
.sheet(isPresented: $showingSettings, onDismiss: {
    WhiskrKit.shared.checkAndPresent(surveyId: "settings-feedback")
}) {
    SettingsView()
}
```

Unlike `present(surveyId:)`, this method respects your targeting and repeat policy rules. Unlike the `.whiskrKitSurvey(identifier:)` modifier, the moment it fires is entirely up to you.

> **Note:** `.whiskrKit()` must still be present somewhere in the view hierarchy for the survey to appear.

### Manual presentation

For cases where you want full control over when a survey appears, such as a feedback 
button, a push notification, or any other in-app trigger, use the imperative API instead.

**Step 1:** Add `.whiskrKit()` once, high in your view hierarchy. This registers the 
attachment point that WhiskrKit uses to present surveys.
```swift
@main
struct SampleApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .whiskrKit()
        }
    }
}
```

**Step 2:** Call `WhiskrKit.shared.present(surveyId:)` from anywhere in your app.
```swift
// From a button
Button("Give Feedback") {
    WhiskrKit.shared.present(surveyId: "your-survey-id")
}

// From a push notification handler
func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
) {
    if let surveyId = response.notification.request.content.userInfo["whiskrkit_survey_id"] as? String {
        WhiskrKit.shared.present(surveyId: surveyId)
    }
    completionHandler()
}
```

> **Note:** If `present(surveyId:)` is called but no view with `.whiskrKit()` is 
> active in the hierarchy, the call is a no-op and no survey will appear.

## Using WhiskrKit in UIKit apps

Not a SwiftUI app? No problem. WhiskrKit works just as well in classic UIKit apps, 
and in apps built with hybrid frameworks (React Native, Flutter add-to-app) where 
the SwiftUI modifiers have no view hierarchy to attach to.

Instead of the `.whiskrKit()` modifier, register your window once with 
`attach(to:)`, typically right after your scene sets it up:

```swift
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = MainViewController()
        window.makeKeyAndVisible()
        self.window = window

        WhiskrKit.shared.initialize(apiKey: "your-api-key")
        WhiskrKit.shared.attach(to: window)
    }
}
```

That's the whole integration. From here the entire API works exactly as in a 
SwiftUI app: trigger surveys with `present(surveyId:)` or 
`checkAndPresent(surveyId:)`, style them with `setTheme(_:)`, and set placement 
defaults with `WhiskrKit.configure { ... }`. All presentation styles render, 
including the adaptive iPad floating panel.

Surveys appear in a transparent overlay above your window. While nothing is on 
screen the overlay is completely pass-through, and a toast survey only captures 
touches on the toast itself, so your app stays fully interactive.

Use one attachment point per app: either `attach(to:)` **or** the SwiftUI 
modifiers, not both. Multi-scene apps can call `detach()` from 
`sceneDidDisconnect(_:)` and re-attach when the next scene connects.

## Adaptive iPad presentation

On wide (regular width) screens, iPad full screen, and large Stage Manager or 
Split View windows, a `sheet`-style survey renders as a **floating panel** instead 
of a full-width bottom sheet, and a `toast`-style survey can be anchored to a corner 
or centered. On compact width (iPhone, narrow Split View, Slide Over) both fall back 
to the familiar full-width bottom presentation. Layout follows the horizontal size 
class, so it re-resolves live as windows resize.

Placement is a code-owned, ambient preference, only the integrating app knows which 
edges of its layout are free, so you set it like SwiftUI's own `.tint`, never as an 
argument to `.whiskrKitSurvey(identifier:)`. It is read only when a survey resolves to 
the matching style in regular width: toasts ignore sheet placement and vice versa, and 
fullscreen surveys ignore both.

Three placements are available for each style:

* `.leading` - bottom-leading corner card
* `.trailing` - bottom-trailing corner card
* `.bottomCentered` - centered, width-capped card

Both default to `.bottomCentered`, which is safe in any layout (it never lands on top 
of a host's edge navigation), so existing apps get the adaptive upgrade for free 
without any code change.

### App-wide defaults

Set the defaults once, typically at launch:

```swift
WhiskrKit.configure {
    $0.defaultSheetPlacement = .trailing
    $0.defaultToastPlacement = .bottomCentered
}
```

### Per-subtree override

Override placement for part of your view hierarchy when you know that edge is free. 
Sheet and toast placement are independent axes, so you can set them separately. Place 
the modifier in the same view tree where the survey is triggered:

```swift
SomeDetailView()
    .whiskrKitSheetPlacement(.leading)   // sheet surveys here → leading panel
    .whiskrKitToastPlacement(.trailing)  // toast surveys here → trailing
```

The iPad sheet panel is **non-modal**: it sizes to the survey, can be swiped down to 
dismiss, and taps outside the card pass through to your app, which stays interactive 
behind it.

## Platform Compatibility

* iOS 17+
* iPadOS 17+

## License

WhiskrKit is available under the MIT license.
