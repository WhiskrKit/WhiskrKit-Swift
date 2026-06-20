//
//  SurveyPanelWindow.swift
//  WhiskrKit
//
//  Copyright (c) 2025 Dennis Vermeulen
//  Licensed under the MIT License. See LICENSE file for details.
//

import SwiftUI
import UIKit
import OSLog

/// A transparent, non-modal overlay window that floats the survey panel above the
/// host app.
///
/// Touches that land outside the card pass straight through to the host, so the
/// app behind the panel stays interactive — the Maps-panel behaviour the spec
/// asks for. This is *not* a reuse of the existing sheet path: the `sheet` style
/// is presented as a modal SwiftUI `.sheet`, which cannot be edge-anchored or made
/// non-modal. The window is introduced solely to host the floating panel; the
/// survey trigger/resolution pipeline is unchanged.
final class SurveyPanelWindow: UIWindow {

    /// The card's frame in window coordinates. Touches inside it are handled by
    /// the panel; everything outside passes through to the host below.
    ///
    /// This is tracked geometrically rather than by comparing the hit-test result
    /// to the hosting view: SwiftUI collapses the whole card (buttons, scroll
    /// view, drag) into a single hosting view, so a result-identity check would
    /// swallow every touch and leave the panel inert.
    var interactiveFrame: CGRect = .zero

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard interactiveFrame.contains(point) else { return nil }
        return super.hitTest(point, with: event)
    }
}

/// Owns the lifecycle of the single floating-panel window.
///
/// One panel shows at a time (mirroring the SDK's single `pendingSurveyRequest`),
/// so a shared instance is sufficient and avoids spawning a window per modifier.
@MainActor
final class SurveyPanelPresenter {
    static let shared = SurveyPanelPresenter()

    private var window: SurveyPanelWindow?

    private init() {}

    /// Shows `template` in a floating panel at `placement`. The window does not
    /// inherit the host's SwiftUI environment, so `theme` is injected explicitly.
    func show(
        template: SheetTemplate,
        placement: SheetPlacement,
        theme: WhiskrKitTheme
    ) {
        guard let scene = activeWindowScene else {
            Logger.wkUI.error("⚠️ No active UIWindowScene; cannot present survey panel.")
            return
        }

        // Replace any panel already on screen without waiting for its exit anim.
        teardownImmediately()

        let window = SurveyPanelWindow(windowScene: scene)

        // The panel owns its own entrance (slide-up) and exit (slide-down)
        // animations, so it is hosted directly with no enclosing presentation state.
        let root = FloatingPanelView(
            template: template,
            placement: placement,
            onDismiss: { [weak self] in self?.dismiss() },
            onCardFrameChange: { [weak window] frame in window?.interactiveFrame = frame }
        )
        .environment(\.WhiskrKitTheme, theme)

        let controller = UIHostingController(rootView: root)
        controller.view.backgroundColor = .clear
        controller.view.isOpaque = false

        window.rootViewController = controller
        window.backgroundColor = .clear
        window.windowLevel = .normal + 1
        // Non-modal: VoiceOver must not treat the frontmost overlay window as modal,
        // so the host behind the panel stays reachable (matching the pass-through
        // hit testing). The panel never becomes key, so the host keeps keyboard
        // and focus ownership.
        window.accessibilityViewIsModal = false
        controller.view.accessibilityViewIsModal = false
        window.isHidden = false

        self.window = window
        Logger.wkUI.info("ℹ️ Presented survey panel (\(String(describing: placement))).")
    }

    /// Tears the window down. The visible exit (the card sliding off the bottom)
    /// is owned by `FloatingPanelView`, which calls this only once that slide has
    /// finished — so the removal here is instant and unanimated.
    func dismiss() {
        guard window != nil else { return }
        teardownImmediately()
    }

    private func teardownImmediately() {
        window?.isHidden = true
        window?.rootViewController = nil
        window = nil
    }

    private var activeWindowScene: UIWindowScene? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        return scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
    }
}
