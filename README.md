![WhiskrKit logo](https://whiskrkit.eu/_astro/WhiskrKit_logo.ForvUlK9_2cXvNV.webp)

![version](https://img.shields.io/badge/version-0.1.5-blue) ![MIT](https://img.shields.io/badge/license-MIT-green) 

# WhiskrKit for iOS (Swift) - The purr-fect feedback toolkit for modern apps.

WhiskrKit provides a flexible and easy-to-use API for presenting various types of 
questionnaires and feedback forms in your SwiftUI applications.

## To do

Before this framework has *production state*, the following items need to be added:

- [x] Mechanism to show surveys based on triggers like: time, app restarts, user 
      size of the host app, or manual triggering.
- [ ] iPad specific layout.
- [ ] Implement follow-up option to App Store Rating.

For feature requests or changes to this native Swift version of WhiskrKit, you can 
create an issue. If you have requests or questions for WhiskrKit in general, please 
contact us directly via the dashboard (once available) or via mail.

## Features

* **Multiple Questionnaire Types**: Star ratings, thumbs up/down, NPS ratings, textual entry
* **Flexible Presentation Styles**: Sheets, toasts, full-screen covers
* **Highly Customizable**: Colors, fonts, layouts, behaviors, and content
* **Accessibility First**: Full VoiceOver and accessibility support
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
      <li>A primary, secondary and tertiary option</li>
    </ul>
  </li>
  <li>Several text themes, with font and color
    <ul>
      <li>Title, subtitle, headline, subheadline and body</li>
    </ul>
  </li>
</ul>

WhiskrKit supports font scaling and dark mode natively, but you have to make sure to 
supply supporting colors and fonts for optimal results.

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

## Platform Compatibility

* iOS 17+
* iPadOS 17+

## License

WhiskrKit is available under the MIT license.
