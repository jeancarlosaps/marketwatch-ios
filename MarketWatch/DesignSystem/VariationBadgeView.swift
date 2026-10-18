import UIKit

final class VariationBadgeView: UIView {
    enum Trend: Equatable {
        case positive
        case negative
        case neutral
    }

    private let iconView = UIImageView()
    private let valueLabel = UILabel()
    private let contentStack = UIStackView()
    private let percentFormatter = VariationBadgeView.makePercentFormatter()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(percent: Decimal) {
        let trend = Trend(percent: percent)
        let formatted = formattedPercent(percent)

        valueLabel.text = formatted
        iconView.image = UIImage(systemName: trend.symbolName)
        iconView.tintColor = trend.foregroundColor
        valueLabel.textColor = trend.foregroundColor
        backgroundColor = trend.fillColor

        isAccessibilityElement = true
        accessibilityTraits = .staticText
        accessibilityLabel = trend.accessibilityLabel(formattedPercent: formatted)
    }

    private func setup() {
        valueLabel.font = MWFont.percent()
        valueLabel.adjustsFontForContentSizeCategory = true
        valueLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        iconView.contentMode = .scaleAspectFit
        iconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(textStyle: .caption1, scale: .small)
        iconView.adjustsImageSizeForAccessibilityContentSizeCategory = true
        iconView.setContentHuggingPriority(.required, for: .horizontal)

        contentStack.axis = .horizontal
        contentStack.alignment = .center
        contentStack.spacing = MWLayout.space2xs
        contentStack.isLayoutMarginsRelativeArrangement = true
        contentStack.layoutMargins = UIEdgeInsets(
            top: MWLayout.space2xs,
            left: MWLayout.spaceXS,
            bottom: MWLayout.space2xs,
            right: MWLayout.spaceXS
        )
        contentStack.addArrangedSubview(iconView)
        contentStack.addArrangedSubview(valueLabel)
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        layer.cornerRadius = MWLayout.radiusPill
        layer.cornerCurve = .continuous
        clipsToBounds = true

        addSubview(contentStack)
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        isAccessibilityElement = true
    }

    private func formattedPercent(_ percent: Decimal) -> String {
        let number = NSDecimalNumber(decimal: percent.magnitude)
        let value = percentFormatter.string(from: number) ?? "0,00%"
        switch Trend(percent: percent) {
        case .positive:
            return "+\(value)"
        case .negative:
            return "-\(value)"
        case .neutral:
            return value
        }
    }

    private static func makePercentFormatter() -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.numberStyle = .percent
        formatter.multiplier = 1
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.positivePrefix = ""
        formatter.negativePrefix = ""
        return formatter
    }
}

private extension VariationBadgeView.Trend {
    init(percent: Decimal) {
        if percent > 0 {
            self = .positive
        } else if percent < 0 {
            self = .negative
        } else {
            self = .neutral
        }
    }

    var symbolName: String {
        switch self {
        case .positive:
            return "arrow.up.right"
        case .negative:
            return "arrow.down.right"
        case .neutral:
            return "minus"
        }
    }

    var foregroundColor: UIColor {
        switch self {
        case .positive:
            return MWColor.positiveLabel
        case .negative:
            return MWColor.negativeLabel
        case .neutral:
            return MWColor.neutralLabel
        }
    }

    var fillColor: UIColor {
        switch self {
        case .positive:
            return MWColor.positiveFill
        case .negative:
            return MWColor.negativeFill
        case .neutral:
            return MWColor.neutralFill
        }
    }

    func accessibilityLabel(formattedPercent: String) -> String {
        switch self {
        case .positive:
            return "Alta \(formattedPercent)"
        case .negative:
            return "Baixa \(formattedPercent)"
        case .neutral:
            return "Estável \(formattedPercent)"
        }
    }
}
