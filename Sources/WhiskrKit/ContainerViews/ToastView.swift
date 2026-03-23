//
//  ToastView.swift
//  WhiskrKit
//
//  Copyright (c) 2025 Dennis Vermeulen
//  Licensed under the MIT License. See LICENSE file for details.
//

import Foundation
import OSLog
import SwiftUI

struct ToastView: View {
	@AccessibilityFocusState private var isFocused: Bool
    @State private var offSetY: CGFloat = 50
    @State private var formed: Bool = false
    @State private var submissionAlert = SubmissionAlert()

    @Binding var isVisible: Bool
    let template: ToastTemplate
    var openFollowUp: (String) -> Void
    
    @State private var surveyResponse: SurveyResponse

    private var canSubmit: Bool {
        guard let survey = template.survey, survey.surveyBase.isRequired else { return true }
		return surveyResponse.results[survey.surveyBase.id] != nil
    }

    init(
        isVisible: Binding<Bool>,
        template: ToastTemplate,
        openFollowUp: @escaping (String) -> Void
    ) {
        self._isVisible = isVisible
        self.template = template
        self.openFollowUp = openFollowUp
        self.surveyResponse = SurveyResponse(
            results: [:]
        )
    }

    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top) {
                titleAndDescription
					.accessibilityFocused($isFocused)
                Spacer()
                closeButton
            }
            if let survey = template.survey {
                TemplateViewBuilder.buildSingleContent(
                    for: survey,
                    surveyResponse: $surveyResponse
                )
                .environment(submissionAlert)
                submitButton
            } else {
                buttonArea
            }
        }
        .frame(maxWidth: .infinity)
        .fixedSize(horizontal: false, vertical: true)
        .padding()
        .toastStyle()
        .padding()
        .offset(y: offSetY)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                offSetY = 0
                isVisible = true
            }
        }
		.task {
			try? await Task.sleep(for: .milliseconds(300))
			isFocused = true
		}
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    print(gesture.translation.height)
                    if gesture.translation.height > 0 {
                        offSetY = gesture.translation.height
                    }
                }
                .onEnded { gesture in
                    if gesture.translation.height > 50 {
                        withAnimation {
                            isVisible = false
                        }
                    } else {
                        withAnimation {
                            offSetY = 0
                        }
                    }
                }
        )
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    var titleAndDescription: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let title = template.title {
                Text(title)
                    .headline()
            }
            if let description = template.description {
                Text(description)
                    .subheadline()
            }
        }
    }

    var submitButton: some View {
        Button {
            submitSurvey()
        } label: {
            Text(.submitButtonLabel)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(
            WhiskrKitButtonStyle(
                variant: .primary,
                isCompact: true
            )
        )
    }

    var closeButton: some View {
        Button(.closeButtonLabel, systemImage: "xmark") {
            dismissToast()
        }
        .body()
        .labelStyle(.iconOnly)
    }

    var buttonArea: some View {
        Group {
            HStack {
                Button {
                    guard let followUpIdentifier = template.followUpIdentifier else { return }
                    openFollowUp(followUpIdentifier)
                } label: {
                    Text(.giveFeedbackButtonLabel)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(
                    WhiskrKitButtonStyle(
                        variant: .primary
                    )
                )
                Button {
                    dismissToast()
                } label: {
                    Text(.noThanksButtonLabel)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(
                    WhiskrKitButtonStyle(
						variant: .secondary
                    )
                )
            }
            .padding(.top)
        }
    }

    private func submitSurvey() {
        if canSubmit {
            Logger.wkUI.info("ℹ️ User submitted survey in toast.")
            Task {
                await WhiskrKit.shared.submitSurveyResponse(
                    surveyId: template.id,
                    response: surveyResponse
                )
            }
			dismissToast()
        } else {
			guard let survey = template.survey else { return }
            withAnimation {
				submissionAlert.showAlert[survey.surveyBase.id] = true
            }
        }
    }

    private func dismissToast() {
        withAnimation {
            isVisible = false
            offSetY = 100
        }
    }
}

struct ToastModifier: ViewModifier {
    @Binding var isPresented: Bool
    let template: ToastTemplate?
    var openFollowUp: (String) -> Void

    func body(content: Content) -> some View {
        ZStack(alignment: .bottom) {
            content
            if isPresented, let template {
                ToastView(
                    isVisible: $isPresented,
                    template: template,
                    openFollowUp: openFollowUp
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(1)
            }
        }
    }
}

extension View {
    func toast(
        isPresented: Binding<Bool>,
        template: ToastTemplate?,
        openFollowUp: @escaping (String) -> Void
    ) -> some View {
        self.modifier(
            ToastModifier(
                isPresented: isPresented,
                template: template,
                openFollowUp: openFollowUp
            )
        )
    }
}

#Preview("Toast - inline feedback") {
    @Previewable @State var showToast: Bool = true
    ZStack {
        VStack {
            Spacer()
            Button("Show Toast") {
                showToast.toggle()
            }
        }
        .frame(maxWidth: .infinity)
        .toast(
            isPresented: $showToast,
            template: .init(
                id: "1345",
                title: "Planning your trip",
                description: "How satisfied are you with our new travelplanner?",
                followUpIdentifier: nil,
                survey: .init(
                    surveyBase: .thumbsRating(
                        base: ThumbsSurveyTemplate(
                            id: "1234",
                            title: nil,
                            subtitle: nil, isRequired: false,
                            A11yLabel: "",
                            A11yHint: ""
                        )
                    )
                )
            ),
            openFollowUp: {_ in }
        )
    }
    .environment(\.WhiskrKitTheme, .systemStyle)
}

#Preview("Toast - opens sheet") {
    @Previewable @State var showToast: Bool = true
    ZStack {
        VStack {
            Spacer()
            Button("Show Toast") {
                showToast.toggle()
            }
        }
        .frame(maxWidth: .infinity)
        .toast(
            isPresented: $showToast,
            template: .init(
                id: "1345",
                title: "Planning your trip",
                description: "How satisfied are you with our new travelplanner?",
                followUpIdentifier: "follow-up-id-1",
                survey: nil
            ),
            openFollowUp: { _ in }
        )
    }
    .environment(\.WhiskrKitTheme, .systemStyle)
}
