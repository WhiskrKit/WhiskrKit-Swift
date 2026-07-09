//
//  WhiskrKitUIKitAPI.swift
//  WhiskrKit
//
//  Copyright (c) 2026 Dennis Vermeulen
//  Licensed under the MIT License. See LICENSE file for details.
//

import SwiftUI
import UIKit
import OSLog

public extension WhiskrKit {

	/// Registers a UIKit window as the attachment point for surveys, the UIKit
	/// counterpart of the SwiftUI ``SwiftUI/View/whiskrKit()`` modifier.
	///
	/// Use this in apps that are not SwiftUI-based: classic UIKit apps, or apps
	/// built with hybrid frameworks (React Native, Flutter add-to-app) whose root
	/// view hierarchy WhiskrKit's view modifiers cannot reach. After attaching,
	/// the full WhiskrKit API behaves exactly as it does in a SwiftUI app:
	/// `present(surveyId:)`, `checkAndPresent(surveyId:)`, theming via
	/// ``setTheme(_:)``, and the placement preferences set through
	/// ``configure(_:)`` all apply. All survey styles render: toast, sheet,
	/// fullscreen, and the adaptive floating panel on wide screens.
	///
	/// Call it once your window is set up, typically at the end of
	/// `scene(_:willConnectTo:options:)`:
	///
	/// ```swift
	/// func scene(
	///     _ scene: UIScene,
	///     willConnectTo session: UISceneSession,
	///     options connectionOptions: UIScene.ConnectionOptions
	/// ) {
	///     guard let windowScene = scene as? UIWindowScene else { return }
	///     let window = UIWindow(windowScene: windowScene)
	///     window.rootViewController = MainViewController()
	///     window.makeKeyAndVisible()
	///     self.window = window
	///
	///     WhiskrKit.shared.initialize(apiKey: "your-api-key")
	///     WhiskrKit.shared.attach(to: window)
	/// }
	/// ```
	///
	/// Surveys are hosted in a transparent overlay window above `window`. While
	/// no survey is on screen the overlay is invisible and lets every touch pass
	/// through, so your app stays fully interactive; toast surveys only capture
	/// touches on the toast itself.
	///
	/// - Parameter window: The app window surveys should appear above. It must
	///   already belong to a `UIWindowScene` (i.e. be part of your scene setup);
	///   if it does not, the call logs an error and does nothing.
	///
	/// - Note: Use one attachment point per app: either this method *or* the
	///   SwiftUI `.whiskrKit()` / `.whiskrKitSurvey(identifier:)` modifiers, not
	///   both. Calling `attach(to:)` again for the same scene is a no-op;
	///   calling it with a window in a different scene moves the attachment there.
	///
	/// - Important: This method must be called after `initialize(apiKey:withMockedSurveys:)`.
	func attach(to window: UIWindow) {
		SurveyHostPresenter.shared.attach(to: window)
	}

	/// Removes the attachment point registered with ``attach(to:)``.
	///
	/// You only need this in multi-scene apps: call it from
	/// `sceneDidDisconnect(_:)` for the scene you attached to, and re-attach in
	/// the next scene that connects. Single-window apps can attach once and
	/// never call this. Calling it while no attachment exists does nothing.
	func detach() {
		SurveyHostPresenter.shared.detach()
	}
}

/// Owns the lifecycle of the transparent overlay window that hosts surveys for
/// UIKit-based apps.
///
/// One attachment exists at a time (mirroring the SDK's single
/// `pendingSurveyRequest` and the "apply `.whiskrKit()` once" rule on the
/// SwiftUI side), so a shared instance is sufficient.
@MainActor
final class SurveyHostPresenter {
	static let shared = SurveyHostPresenter()

	private var window: SurveyHostWindow?

	private init() {}

	func attach(to hostWindow: UIWindow) {
		guard let scene = hostWindow.windowScene else {
			Logger.wkUI.error("⚠️ Cannot attach WhiskrKit: the window does not belong to a UIWindowScene.")
			return
		}

		if let window, window.windowScene === scene {
			// Already attached here; just refresh the pass-back target.
			window.hostWindow = hostWindow
			return
		}

		detach()

		let window = SurveyHostWindow(windowScene: scene)
		window.hostWindow = hostWindow

		let controller = UIHostingController(rootView: SurveyHostRootView())
		controller.view.backgroundColor = .clear
		controller.view.isOpaque = false

		window.rootViewController = controller
		window.backgroundColor = .clear
		window.windowLevel = .normal + 1
		// Non-modal while showing a toast: VoiceOver must be able to reach the
		// host app behind the overlay, matching the pass-through hit testing.
		// Modal styles (sheet, fullscreen) present their own containers, which
		// UIKit treats as modal in the usual way.
		window.accessibilityViewIsModal = false
		controller.view.accessibilityViewIsModal = false
		window.isHidden = false

		self.window = window
		Logger.wkUI.info("ℹ️ WhiskrKit attached to UIKit window scene.")
	}

	func detach() {
		window?.isHidden = true
		window?.rootViewController = nil
		window = nil
	}

	func updateToastFrame(_ frame: CGRect) {
		window?.interactiveFrame = frame
	}
}

/// A transparent overlay window that hosts the survey attachment point for
/// UIKit apps.
///
/// The same pass-through contract as `SurveyPanelWindow`: only the survey
/// itself is interactive, everything else falls through to the host app. The
/// interactive region is tracked geometrically (see `SurveyPanelWindow` for why
/// a hit-test identity check cannot work with SwiftUI hosting), except when a
/// sheet or fullscreen survey is presented, which modally owns the screen.
final class SurveyHostWindow: UIWindow {

	/// The toast's frame in window coordinates, `.zero` while no toast is shown.
	/// Kept current by `ToastModifier`'s frame preference.
	var interactiveFrame: CGRect = .zero

	/// The app window to hand key status back to. Text input inside a survey
	/// needs this window to be key, but the host must regain key (and with it
	/// its own keyboard and focus behavior) the moment touches fall through again.
	weak var hostWindow: UIWindow?

	override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
		// A sheet or fullscreen survey is a modal presentation and owns the
		// whole screen for its lifetime; a toast owns only its own frame.
		let ownsPoint = rootViewController?.presentedViewController != nil
			|| interactiveFrame.contains(point)

		guard ownsPoint else {
			if isKeyWindow { hostWindow?.makeKey() }
			return nil
		}

		if !isKeyWindow { makeKey() }
		return super.hitTest(point, with: event)
	}
}

/// The SwiftUI content of the overlay window: an invisible, full-size view with
/// the standard `.whiskrKit()` attachment applied, so the UIKit path reuses the
/// exact trigger/resolution/presentation pipeline of the SwiftUI path.
struct SurveyHostRootView: View {
	var body: some View {
		Color.clear
			.whiskrKit()
			.onPreferenceChange(SurveyToastFramePreferenceKey.self) { frame in
				Task { @MainActor in
					SurveyHostPresenter.shared.updateToastFrame(frame)
				}
			}
	}
}

/// Reports the on-screen toast's frame up to ``SurveyHostRootView`` so the
/// overlay window can route touches to the toast and pass everything else
/// through. Emitted by `ToastModifier`; at most one toast exists at a time, so
/// the last non-zero value wins. Reverts to `.zero` when the toast leaves the
/// hierarchy, which reopens full pass-through.
struct SurveyToastFramePreferenceKey: PreferenceKey {
	static let defaultValue: CGRect = .zero

	static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
		let next = nextValue()
		if next != .zero { value = next }
	}
}
