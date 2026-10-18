import CoreText
import Testing
import UIKit
@testable import MarketWatch

@MainActor
@Suite("Design system")
struct DesignSystemTests {
    @Test("Canvas, label and accent resolve to the approved Light and Dark tokens")
    func colorsResolveForLightAndDark() {
        let light = UITraitCollection(userInterfaceStyle: .light)
        let dark = UITraitCollection(userInterfaceStyle: .dark)

        expect(MWColor.canvas, equals: 0xF8FAFC, trait: light)
        expect(MWColor.canvas, equals: 0x0B1220, trait: dark)
        expect(MWColor.label, equals: 0x0F172A, trait: light)
        expect(MWColor.label, equals: 0xF8FAFC, trait: dark)
        expect(MWColor.accent, equals: 0x10B981, trait: light)
        expect(MWColor.accent, equals: 0x10B981, trait: dark)
        expect(MWColor.positive, equals: 0x16A34A, trait: light)
        expect(MWColor.negative, equals: 0xDC2626, trait: dark)
        expect(MWColor.card, equals: 0xFFFFFF, trait: light)
        expect(MWColor.card, equals: 0x151F32, trait: dark)
        expect(MWColor.positiveLabel, equals: 0x166534, trait: light)
        expect(MWColor.positiveLabel, equals: 0x4ADE80, trait: dark)
        expect(MWColor.negativeLabel, equals: 0xB91C1C, trait: light)
        expect(MWColor.negativeLabel, equals: 0xF87171, trait: dark)
        expect(MWColor.onAccent, equals: 0x0B1220, trait: light)
        expect(MWColor.onAccent, equals: 0x0B1220, trait: dark)
    }

    @Test("Percent font uses tabular figures and title grows with Dynamic Type")
    func typographyScalesAndKeepsTabularFigures() {
        let percent = MWFont.percent()
        let features = percent.fontDescriptor.fontAttributes[.featureSettings] as? [[UIFontDescriptor.FeatureKey: Int]]
        let usesTabularFigures = features?.contains { feature in
            feature[.type] == kNumberSpacingType
                && feature[.selector] == kMonospacedNumbersSelector
        } ?? false
        #expect(usesTabularFigures)

        let small = MWFont.title(compatibleWith: UITraitCollection(preferredContentSizeCategory: .extraSmall))
        let accessibility = MWFont.title(
            compatibleWith: UITraitCollection(preferredContentSizeCategory: .accessibilityExtraExtraExtraLarge)
        )
        #expect(accessibility.pointSize > small.pointSize)
    }

    @Test("Badge announces trend besides color and formats the percent in Portuguese")
    func badgeConfigurationAndAccessibility() throws {
        let badge = VariationBadgeView()

        try badge.configure(percent: #require(Decimal(string: "3.45")))
        #expect(badge.accessibilityLabel == "Alta +3,45%")
        #expect(visibleText(in: badge) == "+3,45%")

        try badge.configure(percent: #require(Decimal(string: "-1.15")))
        #expect(badge.accessibilityLabel == "Baixa -1,15%")
        #expect(visibleText(in: badge) == "-1,15%")

        badge.configure(percent: 0)
        #expect(badge.accessibilityLabel == "Estável 0,00%")
        #expect(visibleText(in: badge) == "0,00%")
        #expect(badge.isAccessibilityElement)

        badge.overrideUserInterfaceStyle = .light
        try badge.configure(percent: #require(Decimal(string: "3.45")))
        expect(
            try #require(firstLabel(in: badge)).textColor,
            equals: 0x166534,
            trait: UITraitCollection(userInterfaceStyle: .light)
        )

        badge.overrideUserInterfaceStyle = .dark
        try badge.configure(percent: #require(Decimal(string: "-1.15")))
        expect(
            try #require(firstLabel(in: badge)).textColor,
            equals: 0xF87171,
            trait: UITraitCollection(userInterfaceStyle: .dark)
        )
    }

    @Test("Badge and feedback type scale with the content size category")
    func dynamicTypeScalesBadgeAndFeedback() throws {
        let badge = VariationBadgeView()
        badge.configure(percent: 1)
        let smallBadge = hosted(
            badge,
            contentSize: .extraSmall
        )
        let smallFont = try #require(firstLabel(in: badge)).font.pointSize
        let smallIcon = try #require(firstImageView(in: badge)).intrinsicContentSize.height
        _ = smallBadge

        let largeHost = hosted(badge, contentSize: .accessibilityExtraExtraExtraLarge)
        let largeFont = try #require(firstLabel(in: badge)).font.pointSize
        let largeIcon = try #require(firstImageView(in: badge)).intrinsicContentSize.height
        #expect(largeFont > smallFont)
        #expect(largeIcon > smallIcon)
        _ = largeHost

        let feedback = FeedbackStateView()
        feedback.configure(kind: .empty, title: "Nenhum resultado", message: "Tente outro termo.")
        let smallFeedback = hosted(feedback, contentSize: .extraSmall)
        let smallTitle = try #require(firstLabel(in: feedback)).font.pointSize
        _ = smallFeedback
        let largeFeedback = hosted(feedback, contentSize: .accessibilityExtraExtraExtraLarge)
        let largeTitle = try #require(firstLabel(in: feedback)).font.pointSize
        #expect(largeTitle > smallTitle)
        _ = largeFeedback
    }

    @Test("Feedback view shows the action only when asked and reports the tap")
    func feedbackStateActionAndEmptyConfiguration() throws {
        let view = FeedbackStateView()
        view.configure(
            kind: .empty,
            title: "Nenhum resultado",
            message: "Tente outro termo.",
            actionTitle: nil
        )
        #expect(actionButton(in: view)?.isHidden == true)

        var taps = 0
        view.onAction = { taps += 1 }
        view.configure(
            kind: .error,
            title: "Falha ao carregar",
            message: "Verifique a conexão.",
            actionTitle: "Tentar novamente"
        )

        let button = try #require(actionButton(in: view))
        #expect(button.isHidden == false)
        #expect(button.configuration?.title == "Tentar novamente")

        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: window.leadingAnchor, constant: 16),
            view.trailingAnchor.constraint(equalTo: window.trailingAnchor, constant: -16),
            view.centerYAnchor.constraint(equalTo: window.centerYAnchor),
        ])
        window.layoutIfNeeded()
        #expect(button.bounds.height >= MWLayout.minTapTarget)

        button.sendActions(for: .touchUpInside)
        #expect(taps == 1)
    }

    @Test("Skeleton is hidden from VoiceOver")
    func skeletonIsHiddenFromVoiceOver() {
        let skeleton = SkeletonBlockView()
        #expect(skeleton.isAccessibilityElement == false)
        #expect(skeleton.accessibilityElementsHidden)
    }
}

private func expect(_ color: UIColor, equals hex: UInt32, trait: UITraitCollection) {
    let resolved = color.resolvedColor(with: trait)
    var red: CGFloat = 0
    var green: CGFloat = 0
    var blue: CGFloat = 0
    var alpha: CGFloat = 0
    #expect(resolved.getRed(&red, green: &green, blue: &blue, alpha: &alpha))
    #expect(abs(red - CGFloat((hex >> 16) & 0xFF) / 255) < 0.001)
    #expect(abs(green - CGFloat((hex >> 8) & 0xFF) / 255) < 0.001)
    #expect(abs(blue - CGFloat(hex & 0xFF) / 255) < 0.001)
}

private func hosted(_ view: UIView, contentSize: UIContentSizeCategory) -> UIWindow {
    if view.superview != nil {
        view.removeFromSuperview()
    }

    let parent = UIViewController()
    let child = UIViewController()
    parent.addChild(child)
    child.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
    parent.view.addSubview(child.view)
    child.didMove(toParent: parent)
    parent.setOverrideTraitCollection(
        UITraitCollection(preferredContentSizeCategory: contentSize),
        forChild: child
    )

    view.translatesAutoresizingMaskIntoConstraints = false
    child.view.addSubview(view)
    NSLayoutConstraint.activate([
        view.centerXAnchor.constraint(equalTo: child.view.centerXAnchor),
        view.centerYAnchor.constraint(equalTo: child.view.centerYAnchor),
        view.leadingAnchor.constraint(greaterThanOrEqualTo: child.view.leadingAnchor, constant: 16),
        view.trailingAnchor.constraint(lessThanOrEqualTo: child.view.trailingAnchor, constant: -16),
    ])

    let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
    window.rootViewController = parent
    window.isHidden = false
    window.layoutIfNeeded()
    return window
}

private func firstLabel(in view: UIView) -> UILabel? {
    if let label = view as? UILabel {
        return label
    }
    for subview in view.subviews {
        if let label = firstLabel(in: subview) {
            return label
        }
    }
    return nil
}

private func firstImageView(in view: UIView) -> UIImageView? {
    if let imageView = view as? UIImageView {
        return imageView
    }
    for subview in view.subviews {
        if let imageView = firstImageView(in: subview) {
            return imageView
        }
    }
    return nil
}

private func visibleText(in view: UIView) -> String? {
    if let label = view as? UILabel {
        return label.text
    }
    for subview in view.subviews {
        if let text = visibleText(in: subview) {
            return text
        }
    }
    return nil
}

private func actionButton(in view: UIView) -> UIButton? {
    if let button = view as? UIButton {
        return button
    }
    for subview in view.subviews {
        if let button = actionButton(in: subview) {
            return button
        }
    }
    return nil
}
