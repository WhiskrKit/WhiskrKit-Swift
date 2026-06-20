//
//  FloatingPanelView.swift
//  WhiskrKit
//
//  Copyright (c) 2025 Dennis Vermeulen
//  Licensed under the MIT License. See LICENSE file for details.
//

import SwiftUI

/// A non-modal floating card that hosts a `sheet`-style survey on wide screens,
/// modelled on the Apple Maps side panel.
///
/// The same view renders all three placements and the compact fallback, driven by
/// `horizontalSizeClass` (not device idiom) so Stage Manager, Split View, and
/// Slide Over re-resolve live:
///
/// - regular `leading` / `trailing`: a bottom-anchored, edge-inset side card.
/// - regular `bottomCentered`: a centered, width-capped bottom card.
/// - compact (any placement): the standard full-width bottom card.
///
/// It reuses ``SheetContainerView`` verbatim for its content. The card sizes
/// itself to that content (capped to the available height, scrolling only if a
/// survey is taller than the screen), and behaves like a single-detent sheet:
/// dragging up rubber-bands and springs back, dragging down dismisses. It is
/// *not* a real `UISheetPresentationController`, so it models height explicitly
/// and is hosted in WhiskrKit's own non-modal window (see `SurveyPanelWindow`).
struct FloatingPanelView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let template: SheetTemplate
    let placement: SheetPlacement
    /// Tears down the hosting window. Forwarded into ``SheetContainerView`` via
    /// `\.whiskrKitDismiss`, and invoked by the VoiceOver escape action.
    let onDismiss: @MainActor @Sendable () -> Void
    /// Reports the card's window-coordinate frame so the hosting window can route
    /// touches to the card and pass everything else through to the host.
    let onCardFrameChange: @MainActor @Sendable (CGRect) -> Void
    /// Test-only fixed content height. Production measures the content
    /// asynchronously, which never settles inside a snapshot, so snapshots inject
    /// a deterministic value here instead.
    private let previewContentHeight: CGFloat?

    @State private var contentHeight: CGFloat = 0
    /// Full height of the hosting area, used to slide the card fully off-screen.
    @State private var containerHeight: CGFloat = 0
    /// Live vertical offset of the whole card. Starts off-screen for the entrance
    /// slide-up, then `0` at rest; downward drags follow the finger and can dismiss,
    /// upward drags are rubber-banded, and the exit slides it back off the bottom.
    @State private var dragOffset: CGFloat
    /// Guards against re-triggering the exit slide (e.g. close button after a drag).
    @State private var isDismissing = false
    /// Ensures the entrance slide-up runs once, on first appear.
    @State private var hasEntered = false

    /// Height of the grabber row above the content (capsule + its padding).
    private static let grabberHeight: CGFloat = 21
    /// How far the card must be projected to drag-dismiss (folds in flick velocity).
    private static let dismissThreshold: CGFloat = 140
    /// A slow drag this far down dismisses even without a flick.
    private static let dismissDistance: CGFloat = 110
    /// Distance the card sits below its resting position before the entrance
    /// slide-up. Large enough to start fully off-screen on any device.
    private static let entranceOffset: CGFloat = 2000

    init(
        template: SheetTemplate,
        placement: SheetPlacement,
        onDismiss: @escaping @MainActor @Sendable () -> Void,
        onCardFrameChange: @escaping @MainActor @Sendable (CGRect) -> Void = { _ in },
        previewContentHeight: CGFloat? = nil
    ) {
        self.template = template
        self.placement = placement
        self.onDismiss = onDismiss
        self.onCardFrameChange = onCardFrameChange
        self.previewContentHeight = previewContentHeight
        // Production starts the card off-screen and slides it up on appear.
        // Snapshots/previews (which pass a fixed height) start at rest so the
        // resting layout is captured without waiting on the entrance animation.
        self._dragOffset = State(initialValue: previewContentHeight == nil ? Self.entranceOffset : 0)
    }

    private var isCompact: Bool { horizontalSizeClass != .regular }
    private var isSideCard: Bool {
        !isCompact && (placement == .leading || placement == .trailing)
    }

    var body: some View {
        GeometryReader { proxy in
            let insets = cardInsets
            let availableHeight = proxy.size.height - insets.top - insets.bottom
            let measured = previewContentHeight ?? contentHeight
            // Hug the content, but never taller than the screen — overflow scrolls.
            let cardHeight = min(measured + Self.grabberHeight, availableHeight)

            card(height: cardHeight, availableHeight: availableHeight)
                .frame(maxWidth: cardMaxWidth)
                .offset(y: dragOffset)
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { newValue in
                    onCardFrameChange(newValue)
                }
                .padding(insets)
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: cardAlignment
                )
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { containerHeight = $0 }
                .onAppear {
                    // Panel-owned entrance: slide up from off-screen, symmetric with
                    // the exit slide-down. Runs once. Monotonic ease-out so it never
                    // overshoots upward past rest.
                    guard !hasEntered else { return }
                    hasEntered = true
                    withAnimation(.easeOut(duration: 0.45)) { dragOffset = 0 }
                }
        }
    }

    // MARK: - Card

    private func card(height: CGFloat, availableHeight: CGFloat) -> some View {
        VStack(spacing: 0) {
            // Bottom-anchored with the grabber on top: the card's bottom edge stays
            // pinned, and the grabber is the drag handle for rubber-band / dismiss.
            grabber(availableHeight: availableHeight)

            ScrollView {
                SheetContainerView(template: template)
                    // Route the close button and post-submit dismissal through the
                    // same slide-off animation as a drag dismiss.
                    .environment(\.whiskrKitDismiss, { performDismiss() })
                    .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { contentHeight = $0 }
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .modifier(PanelSurface())
        .accessibilityElement(children: .contain)
        .accessibilityAction(.escape) { performDismiss() }
    }

    private func grabber(availableHeight: CGFloat) -> some View {
        Capsule()
            .fill(.secondary)
            .frame(width: 36, height: 5)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .accessibilityHidden(true)
            .gesture(dragGesture(availableHeight: availableHeight))
    }

    // MARK: - Drag: rubber-band up, dismiss down

    private func dragGesture(availableHeight: CGFloat) -> some Gesture {
        // Measure in the global space, not the grabber's local space: the grabber
        // moves with the card as `dragOffset` changes, so a local-space translation
        // would feed the card's own movement back into the gesture and jitter
        // (most visible on the 1:1 downward drag; the rubber-banded upward drag
        // barely moves, so it stays smooth).
        DragGesture(coordinateSpace: .global)
            .onChanged { value in
                let dy = value.translation.height
                // Follow the finger downward; resist upward (no taller state exists).
                dragOffset = dy > 0 ? dy : Self.rubberBand(dy)
            }
            .onEnded { value in
                let shouldDismiss = value.translation.height > Self.dismissDistance
                    || value.predictedEndTranslation.height > Self.dismissThreshold
                if shouldDismiss {
                    // Hand the finger's release velocity to the exit so the slide
                    // continues at the same speed instead of jolting.
                    performDismiss(initialVelocity: value.velocity.height)
                } else {
                    // Critically damped so it returns to rest without overshooting
                    // upward past its resting position.
                    withAnimation(.spring(response: 0.3, dampingFraction: 1)) {
                        dragOffset = 0
                    }
                }
            }
    }

    /// The single exit animation, shared by the drag, the close button, and the
    /// VoiceOver escape: slide the whole card straight off the bottom, then tear the
    /// window down once it's gone.
    private func performDismiss(initialVelocity: CGFloat = 0) {
        guard !isDismissing else { return }
        isDismissing = true
        // Far enough to clear the screen from any resting position; falls back to a
        // large constant before the container height has been measured.
        let target = (containerHeight > 0 ? containerHeight : 1400) + 100
        // Normalise points/sec into the spring's units (fraction of the remaining
        // distance per second).
        let distance = max(target - dragOffset, 1)
        let normalizedVelocity = Double(initialVelocity / distance)
        withAnimation(.interpolatingSpring(mass: 1, stiffness: 200, damping: 30, initialVelocity: normalizedVelocity)) {
            dragOffset = target
        } completion: {
            onDismiss()
        }
    }

    /// Diminishing-returns resistance for upward drags: a negative input maps to a
    /// small negative output that asymptotes, so the card "bands" rather than moving
    /// freely.
    private static func rubberBand(_ offset: CGFloat) -> CGFloat {
        let limit: CGFloat = 80
        return -limit * (1 - exp(offset / limit))
    }

    // MARK: - Placement geometry

    private var cardMaxWidth: CGFloat {
        placement.edge.maxWidth(isCompact: isCompact, side: 360, centered: 520)
    }

    private var cardAlignment: Alignment {
        placement.edge.alignment(isCompact: isCompact)
    }

    /// Inset from the screen edges. Every placement is pinned to the bottom, so
    /// the top edge is left free and the card never sits on the host's bottom
    /// safe-area edge. The compact fallback spans the full width, like the
    /// existing bottom sheet.
    private var cardInsets: EdgeInsets {
        guard !isCompact else {
            return EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        }
        switch placement {
        case .leading, .trailing:
            return EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
        case .bottomCentered:
            return EdgeInsets(top: 0, leading: 12, bottom: 12, trailing: 12)
        }
    }
}

/// The card surface: Liquid Glass on iOS 26+, a material fallback before that.
/// Continuous corners and a soft drop shadow. Corner radius and the fallback
/// match the existing `CloseButtonStyle` convention.
private struct PanelSurface: ViewModifier {
    private static let cornerRadius: CGFloat = 22

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous)
        return Group {
            if #available(iOS 26.0, *) {
                content.glassEffect(.regular, in: shape)
            } else {
                content
                    .background(.regularMaterial, in: shape)
                    .clipShape(shape)
            }
        }
        .shadow(color: .black.opacity(0.18), radius: 16, x: 0, y: 6)
    }
}

#Preview("Floating panel — trailing") {
    FloatingPanelView(
        template: SheetTemplate(
            id: "1234",
            title: "Quick feedback",
            description: "We'd love to hear from you",
            followUpQuestion: "Tell us more about your experience",
            survey: SurveyPresentation(
                surveyBase: .scaleRating(
                    base: ScaleRatingTemplate(
                        id: "1234",
                        title: "How likely are you to recommend us?",
                        subtitle: "Your feedback helps us improve",
                        ratingRange: .init(min: 1, max: 7),
                        isRequired: true,
                        A11yLabel: "Likelihood to recommend rating",
                        A11yHint: "Rate from 0 to 10"
                    )
                )
            )
        ),
        placement: .trailing,
        onDismiss: {}
    )
    .environment(\.WhiskrKitTheme, .systemStyle)
}
