import UIKit

final class FeedbackStateView: UIView {
    enum Kind {
        case empty
        case error
    }

    var onAction: (() -> Void)?

    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let actionButton = UIButton(type: .system)
    private let contentStack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(kind: Kind, title: String,
                   message: String, actionTitle: String? = nil) {
        iconView.image = UIImage(systemName: kind.symbolName)
        iconView.tintColor = kind == .error ? MWColor.negativeLabel : MWColor.secondaryLabel
        titleLabel.text = title
        messageLabel.text = message

        var configuration = actionButton.configuration ?? .filled()
        if let actionTitle, !actionTitle.isEmpty {
            configuration.title = actionTitle
            actionButton.configuration = configuration
            actionButton.isHidden = false
        } else {
            configuration.title = nil
            actionButton.configuration = configuration
            actionButton.isHidden = true
        }
    }

    private func setup() {
        backgroundColor = MWColor.card
        layer.cornerRadius = MWLayout.radiusCard
        layer.cornerCurve = .continuous

        iconView.contentMode = .scaleAspectFit
        iconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(textStyle: .largeTitle, scale: .medium)
        iconView.adjustsImageSizeForAccessibilityContentSizeCategory = true

        titleLabel.font = MWFont.title()
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textColor = MWColor.label
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0

        messageLabel.font = MWFont.body()
        messageLabel.adjustsFontForContentSizeCategory = true
        messageLabel.textColor = MWColor.secondaryLabel
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0

        actionButton.configuration = Self.actionConfiguration()
        actionButton.addTarget(self, action: #selector(handleAction), for: .touchUpInside)
        actionButton.isHidden = true

        contentStack.axis = .vertical
        contentStack.alignment = .center
        contentStack.spacing = MWLayout.spaceSM
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.addArrangedSubview(iconView)
        contentStack.addArrangedSubview(titleLabel)
        contentStack.addArrangedSubview(messageLabel)
        contentStack.addArrangedSubview(actionButton)
        contentStack.setCustomSpacing(MWLayout.spaceMD, after: messageLabel)

        addSubview(contentStack)
        activateConstraints()
    }

    private static func actionConfiguration() -> UIButton.Configuration {
        var configuration = UIButton.Configuration.filled()
        configuration.baseBackgroundColor = MWColor.accent
        configuration.baseForegroundColor = MWColor.onAccent
        configuration.cornerStyle = .capsule
        configuration.contentInsets = NSDirectionalEdgeInsets(
            top: MWLayout.spaceSM,
            leading: MWLayout.spaceLG,
            bottom: MWLayout.spaceSM,
            trailing: MWLayout.spaceLG
        )
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = MWFont.action()
            return outgoing
        }
        return configuration
    }

    private func activateConstraints() {
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: topAnchor, constant: MWLayout.spaceLG),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: MWLayout.spaceMD),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -MWLayout.spaceMD),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -MWLayout.spaceLG),
            titleLabel.widthAnchor.constraint(equalTo: contentStack.widthAnchor),
            messageLabel.widthAnchor.constraint(equalTo: contentStack.widthAnchor),
            actionButton.heightAnchor.constraint(greaterThanOrEqualToConstant: MWLayout.minTapTarget),
        ])
    }

    @objc
    private func handleAction() {
        onAction?()
    }
}

private extension FeedbackStateView.Kind {
    var symbolName: String {
        switch self {
        case .empty:
            return "magnifyingglass"
        case .error:
            return "exclamationmark.triangle"
        }
    }
}
