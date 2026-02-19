//
//  Theme.swift
//  WhiskrKit
//
//  Copyright (c) 2025 Dennis Vermeulen
//  Licensed under the MIT License. See LICENSE file for details.
//

import SwiftUI

public struct WhiskrKitTheme: Sendable {
    var container: ContainerTheme?
    var button: ButtonTheme
    var title: TextTheme
    var subtitle: TextTheme
    var headline: TextTheme
    var subheadline: TextTheme
    var body: TextTheme
    
    public init(
        container: ContainerTheme? = nil,
        button: ButtonTheme,
        title: TextTheme,
        subtitle: TextTheme,
        headline: TextTheme,
        subheadline: TextTheme,
        body: TextTheme
    ) {
        self.container = container
        self.button = button
        self.title = title
        self.subtitle = subtitle
        self.headline = headline
        self.subheadline = subheadline
        self.body = body
    }
    
	public struct ButtonTheme: Sendable {
		var primary: ButtonAppearance
		var secondary: ButtonAppearance

		public init(primary: ButtonAppearance, secondary: ButtonAppearance) {
			self.primary = primary
			self.secondary = secondary
		}

		public enum ButtonAppearance: Sendable {
			case variant(ButtonVariant)
			case custom(AnyButtonStyle)
		}
	}

    public struct TextTheme: Sendable {
        var font: Font
        var color: Color
        
        public init(
            font: Font,
            color: Color
        ) {
            self.font = font
            self.color = color
        }
    }

    public struct ButtonVariant: Sendable {
        public var backgroundColor: Color
        public var borderColor: Color?
        public var textColor: Color
        public var font: Font
        public var cornerRadius: CGFloat

        public init(
            backgroundColor: Color,
            borderColor: Color? = nil,
            textColor: Color,
            font: Font,
            cornerRadius: CGFloat,
            size: ButtonSize = .normal
        ) {
            self.backgroundColor = backgroundColor
            self.borderColor = borderColor
            self.textColor = textColor
            self.font = font
            self.cornerRadius = cornerRadius
        }
    }
    
    public struct ContainerTheme: Sendable {
        public var sheet: OverlayView?
        public var fullScreen: OverlayView?
        public var toast: Toast?
        
        public init(
            sheet: OverlayView? = nil,
            fullScreen: OverlayView? = nil,
            toast: Toast? = nil
        ) {
            self.sheet = sheet
            self.fullScreen = fullScreen
            self.toast = toast
        }
        
        
        public struct OverlayView: Sendable {
            public var backgroundColor: Color
            
            public init(
                backgroundColor: Color = Color(.secondarySystemBackground)
            ) {
                self.backgroundColor = backgroundColor
            }
        }
        
        public struct Toast: Sendable {
            public var cornerRadius: CGFloat
            public var backgroundColor: Color
            public var withShadow: Bool
            
            public init(
                cornerRadius: CGFloat = 8,
                backgroundColor: Color = Color(.secondarySystemBackground),
                withShadow: Bool = true
            ) {
                self.cornerRadius = cornerRadius
                self.backgroundColor = backgroundColor
                self.withShadow = withShadow
            }
        }
    }
}

extension WhiskrKitTheme {
    public static let systemStyle = WhiskrKitTheme(
        container: .init(
            toast: .init(
                cornerRadius: 8,
                backgroundColor: Color(.secondarySystemBackground),
                withShadow: false
            )
        ),
        button: .init(
			primary: .variant(.init(backgroundColor: Color(.label), textColor: Color(.systemBackground), font: .body.weight(.medium), cornerRadius: 10, size: .compact)),
			secondary: .variant(.init(backgroundColor: .clear, textColor: Color(.label), font: .body, cornerRadius: 8))
		),
        title: .init(font: .title2.weight(.bold), color: .primary),
        subtitle: .init(font: .headline.weight(.semibold), color: .secondary),
        headline: .init(font: .headline, color: .primary),
        subheadline: .init(font: .subheadline, color: .secondary),
        body: .init(font: .body, color: .primary)
    )
}

public extension WhiskrKitTheme.ButtonTheme.ButtonAppearance {
	static func style<S: ButtonStyle>(_ style: S) -> Self {
		.custom(AnyButtonStyle(style))
	}
}

enum WhiskrKitButtonVariant {
	case primary, secondary
}
public enum ButtonSize {
    case normal, compact
}

struct WhiskrKitButtonStyle: ButtonStyle {
	@Environment(\.WhiskrKitTheme) private var whiskrKitTheme
	var variant: WhiskrKitButtonVariant
	var isCompact: Bool = false

	func makeBody(configuration: Configuration) -> some View {
		let appearance: WhiskrKitTheme.ButtonTheme.ButtonAppearance = {
			switch variant {
			case .primary: whiskrKitTheme.button.primary
			case .secondary: whiskrKitTheme.button.secondary
			}
		}()

		switch appearance {
		case .variant(let theme):
			configuration.label
				.padding(.all, isCompact ? 10 : nil)
				.font(theme.font)
				.background(theme.backgroundColor)
				.foregroundStyle(theme.textColor)
				.background(
					RoundedRectangle(cornerRadius: theme.cornerRadius)
						.stroke(theme.borderColor ?? .clear,
								lineWidth: (theme.borderColor != nil) ? 2 : 0)
				)
				.clipShape(RoundedRectangle(cornerRadius: theme.cornerRadius))
				.opacity(configuration.isPressed ? 0.8 : 1.0)

		case .custom(let customStyle):
			customStyle.makeBody(configuration: configuration)
		}
	}
}

struct WhiskrKitSheetContainerStyle: ViewModifier {
    @Environment(\.WhiskrKitTheme) private var whiskrKitTheme

    func body(content: Content) -> some View {
        content
            .ignoresSafeArea()
            .optionalSheetBackground(whiskrKitTheme.container?.sheet?.backgroundColor)
    }
}

struct WhiskrKitToastContainerStyle: ViewModifier {
    @Environment(\.WhiskrKitTheme) private var whiskrKitTheme

    func body(content: Content) -> some View {
        content
            .background(whiskrKitTheme.container?.toast?.backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: whiskrKitTheme.container?.toast?.cornerRadius ?? 0))
            .shadow(radius: whiskrKitTheme.container?.toast?.withShadow == true ? 10 : 0)
    }
}

struct OptionalSheetBackgroundModifier: ViewModifier {
    let color: Color?
    
    func body(content: Content) -> some View {
        if let color {
            content.presentationBackground(color)
        } else {
            content
        }
    }
}

struct WhiskrKitTitleStyle: ViewModifier {
    @Environment(\.WhiskrKitTheme) private var WhiskrKitTheme
    
    func body(content: Content) -> some View {
        content
            .font(WhiskrKitTheme.title.font)
            .foregroundStyle(WhiskrKitTheme.title.color)
    }
}

struct WhiskrKitSubtitleStyle: ViewModifier {
    @Environment(\.WhiskrKitTheme) private var WhiskrKitTheme
    
    func body(content: Content) -> some View {
        content
            .font(WhiskrKitTheme.subtitle.font)
            .foregroundStyle(WhiskrKitTheme.subtitle.color.secondary)
    }
}

struct WhiskrKitHeadlineStyle: ViewModifier {
    @Environment(\.WhiskrKitTheme) private var WhiskrKitTheme
    
    func body(content: Content) -> some View {
        content
            .font(WhiskrKitTheme.headline.font)
            .foregroundStyle(WhiskrKitTheme.headline.color)
    }
}

struct WhiskrKitSubheadlineStyle: ViewModifier {
    @Environment(\.WhiskrKitTheme) private var WhiskrKitTheme
    
    func body(content: Content) -> some View {
        content
            .font(WhiskrKitTheme.subheadline.font)
            .foregroundStyle(WhiskrKitTheme.subheadline.color.secondary)
    }
}

struct WhiskrKitBodyStyle: ViewModifier {
    @Environment(\.WhiskrKitTheme) private var WhiskrKitTheme
    
    func body(content: Content) -> some View {
        content
            .font(WhiskrKitTheme.body.font)
            .foregroundStyle(WhiskrKitTheme.body.color)
    }
}

extension View {
    func title() -> some View {
        self.modifier(WhiskrKitTitleStyle())
    }
    
    func subtitle() -> some View {
        self.modifier(WhiskrKitSubtitleStyle())
    }
    
    func headline() -> some View {
        self.modifier(WhiskrKitHeadlineStyle())
    }
    
    func subheadline() -> some View {
        self.modifier(WhiskrKitSubheadlineStyle())
    }
    
    func body() -> some View {
        self.modifier(WhiskrKitBodyStyle())
    }
    
    func sheetStyle() -> some View {
        self.modifier(WhiskrKitSheetContainerStyle())
    }
    
    func toastStyle() -> some View {
        self.modifier(WhiskrKitToastContainerStyle())
    }
    
    fileprivate func optionalSheetBackground(_ color: Color?) -> some View {
        modifier(OptionalSheetBackgroundModifier(color: color))
    }
}

private struct WhiskrKitThemeKey: EnvironmentKey {
    static let defaultValue: WhiskrKitTheme = .systemStyle
}

public extension EnvironmentValues {
    var WhiskrKitTheme: WhiskrKitTheme {
        get { self[WhiskrKitThemeKey.self] }
        set { self[WhiskrKitThemeKey.self] = newValue }
    }
}

public struct AnyButtonStyle: ButtonStyle, @unchecked Sendable {
	private let _makeBody: (ButtonStyle.Configuration) -> AnyView

	public init<S: ButtonStyle>(_ style: S) {
		_makeBody = { AnyView(style.makeBody(configuration: $0)) }
	}

	public func makeBody(configuration: Configuration) -> some View {
		_makeBody(configuration)
	}
}

#Preview {
	ScrollView {
		VStack(spacing: 16) {
			Text("Hello WhiskrKit")
				.title()
			Text("The feedback framework")
				.subtitle()
			Text("Important Information")
				.headline()
			Text("Additional details here")
				.subheadline()
			Text("coming to an iPhone near you")
				.body()
			Button("Primary", action: {})
				.buttonStyle(WhiskrKitButtonStyle(variant: .primary))
			Button("Secondary", action: {})
				.buttonStyle(WhiskrKitButtonStyle(variant: .secondary))
		}
		.environment(\.WhiskrKitTheme, .systemStyle)
		.padding()
		.background(RoundedRectangle(cornerRadius: 8).stroke(Color(.systemGray4)))
	}
}

