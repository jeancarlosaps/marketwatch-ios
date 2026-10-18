import Kingfisher
import UIKit

final class MarketCoinCell: UITableViewCell {
    static let reuseIdentifier = "MarketCoinCell"

    private let iconView = UIImageView()
    private let nameLabel = UILabel()
    private let symbolLabel = UILabel()
    private let priceLabel = UILabel()
    private let badgeView = VariationBadgeView()
    private let textStack = UIStackView()
    private let priceStack = UIStackView()
    private let contentStack = UIStackView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        iconView.kf.cancelDownloadTask()
        iconView.image = nil
        nameLabel.text = nil
        symbolLabel.text = nil
        priceLabel.text = nil
        badgeView.isHidden = true
        accessibilityLabel = nil
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard previousTraitCollection?.preferredContentSizeCategory
            != traitCollection.preferredContentSizeCategory
        else { return }
        updatePriceScalingForContentSize()
    }

    func configure(with item: MarketListItem) {
        nameLabel.text = item.name
        symbolLabel.text = item.symbol
        priceLabel.text = item.priceText
        accessibilityLabel = item.accessibilityLabel

        if let change = item.changePercent {
            badgeView.isHidden = false
            badgeView.configure(percent: change)
        } else {
            badgeView.isHidden = true
        }

        iconView.kf.setImage(
            with: item.imageURL,
            placeholder: UIImage(systemName: "bitcoinsign.circle"),
            options: [.transition(.fade(0.2))]
        )
    }

    private func setup() {
        backgroundColor = .clear
        contentView.backgroundColor = MWColor.card
        selectionStyle = .default
        isAccessibilityElement = true
        accessibilityTraits = .button
        configureLabels()
        configureStacks()
        activateConstraints()
    }

    private func configureLabels() {
        iconView.contentMode = .scaleAspectFit
        iconView.clipsToBounds = true
        iconView.layer.cornerRadius = 20
        iconView.layer.cornerCurve = .continuous
        iconView.tintColor = MWColor.secondaryLabel
        iconView.backgroundColor = MWColor.elevated
        iconView.translatesAutoresizingMaskIntoConstraints = false

        nameLabel.font = MWFont.action()
        nameLabel.adjustsFontForContentSizeCategory = true
        nameLabel.textColor = MWColor.label

        symbolLabel.font = MWFont.body()
        symbolLabel.adjustsFontForContentSizeCategory = true
        symbolLabel.textColor = MWColor.secondaryLabel

        priceLabel.font = MWFont.percent()
        priceLabel.adjustsFontForContentSizeCategory = true
        priceLabel.textColor = MWColor.label
        priceLabel.textAlignment = .right
        priceLabel.minimumScaleFactor = 0.85
        updatePriceScalingForContentSize()
    }

    private func updatePriceScalingForContentSize() {
        let isAccessibility = traitCollection.preferredContentSizeCategory.isAccessibilityCategory
        // Avoid shrinking prices at accessibility sizes; let the label wrap instead.
        priceLabel.adjustsFontSizeToFitWidth = !isAccessibility
        priceLabel.numberOfLines = isAccessibility ? 0 : 1
    }

    private func configureStacks() {
        textStack.axis = .vertical
        textStack.spacing = MWLayout.space2xs
        textStack.alignment = .leading
        textStack.addArrangedSubview(nameLabel)
        textStack.addArrangedSubview(symbolLabel)

        priceStack.axis = .vertical
        priceStack.spacing = MWLayout.space2xs
        priceStack.alignment = .trailing
        priceStack.addArrangedSubview(priceLabel)
        priceStack.addArrangedSubview(badgeView)

        contentStack.axis = .horizontal
        contentStack.alignment = .center
        contentStack.spacing = MWLayout.spaceSM
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.addArrangedSubview(iconView)
        contentStack.addArrangedSubview(textStack)
        contentStack.addArrangedSubview(priceStack)

        textStack.setContentHuggingPriority(.defaultLow, for: .horizontal)
        priceStack.setContentHuggingPriority(.required, for: .horizontal)
        priceStack.setContentCompressionResistancePriority(.required, for: .horizontal)
        contentView.addSubview(contentStack)
    }

    private func activateConstraints() {
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 40),
            iconView.heightAnchor.constraint(equalToConstant: 40),
            contentStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: MWLayout.spaceMD),
            contentStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: MWLayout.spaceMD),
            contentStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -MWLayout.spaceMD),
            contentStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -MWLayout.spaceMD),
            contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 64),
        ])
    }
}
