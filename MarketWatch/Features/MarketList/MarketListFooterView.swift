import UIKit

final class MarketListFooterView: UIView {
    var onRetry: (() -> Void)?

    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    private let messageLabel = UILabel()
    private let retryButton = UIButton(type: .system)
    private let stack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(_ state: MarketListFooterState) {
        switch state {
        case .hidden:
            isHidden = true
            activityIndicator.stopAnimating()
            retryButton.isHidden = true
            messageLabel.isHidden = true
        case .loading:
            isHidden = false
            activityIndicator.startAnimating()
            retryButton.isHidden = true
            messageLabel.isHidden = true
            accessibilityElementsHidden = true
        case let .error(message):
            isHidden = false
            activityIndicator.stopAnimating()
            messageLabel.isHidden = false
            messageLabel.text = message
            retryButton.isHidden = false
            accessibilityElementsHidden = false
        }
    }

    private func setup() {
        backgroundColor = .clear

        activityIndicator.color = MWColor.accent
        activityIndicator.hidesWhenStopped = true

        messageLabel.font = MWFont.body()
        messageLabel.adjustsFontForContentSizeCategory = true
        messageLabel.textColor = MWColor.secondaryLabel
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0

        var configuration = UIButton.Configuration.plain()
        configuration.title = String(localized: "Tentar novamente")
        configuration.baseForegroundColor = MWColor.accent
        configuration.contentInsets = NSDirectionalEdgeInsets(top: MWLayout.spaceXS,
                                                              leading: MWLayout.spaceMD,
                                                              bottom: MWLayout.spaceXS,
                                                              trailing: MWLayout.spaceMD)
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = MWFont.action()
            return outgoing
        }
        retryButton.configuration = configuration
        retryButton.addTarget(self, action: #selector(handleRetry), for: .touchUpInside)

        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = MWLayout.spaceXS
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.addArrangedSubview(activityIndicator)
        stack.addArrangedSubview(messageLabel)
        stack.addArrangedSubview(retryButton)

        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: MWLayout.spaceMD),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: MWLayout.spaceMD),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -MWLayout.spaceMD),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -MWLayout.spaceMD),
            retryButton.heightAnchor.constraint(greaterThanOrEqualToConstant: MWLayout.minTapTarget),
            heightAnchor.constraint(greaterThanOrEqualToConstant: 72),
        ])

        configure(.hidden)
    }

    @objc
    private func handleRetry() {
        onRetry?()
    }
}
