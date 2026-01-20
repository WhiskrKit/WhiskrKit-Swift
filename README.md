![WhiskrKit logo](https://whiskrkit.eu/_astro/WhiskrKit_logo.ForvUlK9_2cXvNV.webp)

![version](https://img.shields.io/badge/version-0.1.0-blue) ![MIT](https://img.shields.io/badge/license-MIT-green) 

# WhiskrKit for iOS (Swift) - The purr-fect feedback toolkit for modern apps.

WhiskrKit provides a flexible and easy-to-use API for presenting various types of questionnaires and feedback forms in your SwiftUI applications.

## To do

Before this framework has *production state*, the following items need to be added: 

- [ ] Mechanism to show surveys based on triggers like: time, app restarts, user size of the host app, or manual triggering with a button.
- [ ] iPad specific layout.
- [ ] Implement follow-up option to App Store Rating.
- [ ] (In consideration) A dedicated WhiskrKit button that developers can add to their apps to let users manually open a questionnaire.

For feature requests or changes to this native Swift version of WhiskrKit, you can create an issue. If you have requests or questions for WhiskrKit in general, please contact us directly via the portal (once available) or via mail.

## Features

* **Multiple Questionnaire Types**: Star ratings, thumbs up/down, NPS ratings, textual entry
* **Flexible Presentation Styles**: Sheets, toasts, full-screen covers
* **Highly Customizable**: Colors, fonts, layouts, behaviors, and content
* **Accessibility First**: Full VoiceOver and accessibility support
* **Haptic Feedback**: Enhanced user experience

## Quick Start

### Initialization and theming

 WhiskrKit is completely customizable to fit the look of your app. Just supply your fonts and colors. Get the API key from the WhiskrKit portal that you created for your app.


```swift
import SwiftUI
import WhiskrKit

 @main struct SampleApp: App {

    let sampleTheme = WhiskrKitTheme(...)

    init () {
        WhiskrKit.shared.initialize(apiKey: "sample-app-key")
        WhiskrKit.shared.setTheme(sampleTheme)
    }
 }
 ```

 To set a theme, you supply:
  
  <ul>
  <li> A container theme, optional for
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

WhiskrKit supports font scaling and dark mode natively, but you have to make sure to supply supporting colors and fonts for optimal results.

Go to the `Theme.swift` file in this project to look for an example of how to make a theme. You can also use the provided `systemStyle` theme preset for your project by assigning it as your theme constant.

### Basic Usage

When you create a survey for your project in the WhiskrKit portal, you will receive an identifier for your survey. Simply add `.WhiskrKitSurvey(identifier:)` to your view with the identifier as argument, and WhiskrKit will automatically present the questionnaire based on the conditions you configure in the portal, such as after a certain amount of time, number of views, or for a percentage of your users.

```swift
import SwiftUI
import WhiskrKit

struct ContentView: View {    
    var body: some View {
    VStack {
        Text("Welcome to WhiskrKit")
            .font(.title)
        Text("for iOS")
        }
        .WhiskrKitSurvey(identifier: "sample-app-id")
    }
}

```

## Platform Compatibility

* iOS 17+
* iPadOS 17+

## License

WhiskrKit is available under the MIT license.
