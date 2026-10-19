import UIKit

final class VariationBadgeView: UIView {
    enum Trend: Equatable {
        case positive
        case negative
        case neutral
    }

    private let iconView = UIImageView()
    private let valueLabel = UILabel()
    private let percentFormatter = VariationBadgeView.makePercentFormatter()
    private lazy var widthConstraint = widthAnchor.constraint(equalToConstant: 1)
    private lazy var heightConstraint = heightAnchor.constraint(equalToConstant: 1)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        measuredContentSize()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard previousTraitCollection?.preferredContentSizeCategory
                != traitCollection.preferredContentSizeCategory
        else { return }
        refreshSizeConstraints()
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
        refreshSizeConstraints()
    }

    private func setup() {
        valueLabel.font = MWFont.percent()
        valueLabel.adjustsFontForContentSizeCategory = true
        valueLabel.translatesAutoresizingMaskIntoConstraints = false

        iconView.contentMode = .scaleAspectFit
        iconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(textStyle: .caption1, scale: .small)
        iconView.adjustsImageSizeForAccessibilityContentSizeCategory = true
        iconView.translatesAutoresizingMaskIntoConstraints = false

        // Capsule radius must stay finite relative to height — an enormous constant with
        // continuous corner curve can clip the entire fill on recent iOS versions.
        layer.cornerRadius = 8
        layer.cornerCurve = .continuous
        clipsToBounds = true

        setContentHuggingPriority(.required, for: .horizontal)
        setContentHuggingPriority(.required, for: .vertical)
        setContentCompressionResistancePriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .vertical)

        addSubview(iconView)
        addSubview(valueLabel)

        // Size owned by explicit constraints. Subviews centered — never pin top+bottom to self.
        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: MWLayout.spaceXS),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            valueLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: MWLayout.space2xs),
            valueLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -MWLayout.spaceXS),
            valueLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            widthConstraint,
            heightConstraint,
        ])

        isAccessibilityElement = true
        refreshSizeConstraints()
    }

    private func refreshSizeConstraints() {
        let size = measuredContentSize()
        widthConstraint.constant = size.width
        heightConstraint.constant = size.height
        // Keep the pill radius proportional to height after size is known.
        layer.cornerRadius = size.height / 2
        invalidateIntrinsicContentSize()
    }

    private func measuredContentSize() -> CGSize {
        let iconSize = iconView.intrinsicContentSize
        let labelSize = valueLabel.intrinsicContentSize
        let contentHeight = max(iconSize.height, labelSize.height, valueLabel.font.lineHeight)
        let width = MWLayout.spaceXS * 2
            + max(iconSize.width, 0)
            + MWLayout.space2xs
            + max(labelSize.width, 0)
        let height = MWLayout.space2xs * 2 + max(contentHeight, 0)
        return CGSize(width: max(width, 1), height: max(height, 1))
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
