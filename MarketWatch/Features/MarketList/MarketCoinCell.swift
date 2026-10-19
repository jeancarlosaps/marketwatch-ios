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

    private var badgeTopConstraint: NSLayoutConstraint?
    private var badgeBottomConstraint: NSLayoutConstraint?
    private var priceBottomConstraint: NSLayoutConstraint?

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
        updateBadgeConstraints(showingBadge: false)
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
            updateBadgeConstraints(showingBadge: true)
        } else {
            badgeView.isHidden = true
            updateBadgeConstraints(showingBadge: false)
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
        configureHierarchy()
        activateConstraints()
        updateBadgeConstraints(showingBadge: false)
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
        priceLabel.translatesAutoresizingMaskIntoConstraints = false
        priceLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        priceLabel.setContentHuggingPriority(.required, for: .vertical)
        updatePriceScalingForContentSize()

        badgeView.translatesAutoresizingMaskIntoConstraints = false
    }

    private func updatePriceScalingForContentSize() {
        let isAccessibility = traitCollection.preferredContentSizeCategory.isAccessibilityCategory
        // Avoid shrinking prices at accessibility sizes; let the label wrap instead.
        priceLabel.adjustsFontSizeToFitWidth = !isAccessibility
        priceLabel.numberOfLines = isAccessibility ? 0 : 1
    }

    private func configureHierarchy() {
        textStack.axis = .vertical
        textStack.spacing = MWLayout.space2xs
        textStack.alignment = .leading
        textStack.translatesAutoresizingMaskIntoConstraints = false
        textStack.addArrangedSubview(nameLabel)
        textStack.addArrangedSubview(symbolLabel)

        // Keep the badge out of UIStackView. An arranged subview without a self-owned
        // height is collapsed to padding-only (8pt) during table self-sizing.
        contentView.addSubview(iconView)
        contentView.addSubview(textStack)
        contentView.addSubview(priceLabel)
        contentView.addSubview(badgeView)
    }

    private func activateConstraints() {
        badgeTopConstraint = badgeView.topAnchor.constraint(
            equalTo: priceLabel.bottomAnchor,
            constant: MWLayout.space2xs
        )
        badgeBottomConstraint = contentView.bottomAnchor.constraint(
            greaterThanOrEqualTo: badgeView.bottomAnchor,
            constant: MWLayout.spaceMD
        )
        priceBottomConstraint = priceLabel.bottomAnchor.constraint(
            equalTo: contentView.bottomAnchor,
            constant: -MWLayout.spaceMD
        )

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: MWLayout.spaceMD),
            iconView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: MWLayout.spaceMD),
            iconView.widthAnchor.constraint(equalToConstant: 40),
            iconView.heightAnchor.constraint(equalToConstant: 40),
            contentView.bottomAnchor.constraint(greaterThanOrEqualTo: iconView.bottomAnchor,
                                                constant: MWLayout.spaceMD),

            textStack.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: MWLayout.spaceSM),
            textStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: MWLayout.spaceMD),
            textStack.trailingAnchor.constraint(lessThanOrEqualTo: priceLabel.leadingAnchor,
                                                constant: -MWLayout.spaceSM),
            contentView.bottomAnchor.constraint(greaterThanOrEqualTo: textStack.bottomAnchor,
                                                constant: MWLayout.spaceMD),

            priceLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: MWLayout.spaceMD),
            priceLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor,
                                                 constant: -MWLayout.spaceMD),
            priceLabel.leadingAnchor.constraint(greaterThanOrEqualTo: textStack.trailingAnchor,
                                                constant: MWLayout.spaceSM),

            badgeView.trailingAnchor.constraint(equalTo: priceLabel.trailingAnchor),
            badgeView.leadingAnchor.constraint(greaterThanOrEqualTo: textStack.trailingAnchor,
                                               constant: MWLayout.spaceSM),

            contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 64),
        ])
    }

    private func updateBadgeConstraints(showingBadge: Bool) {
        badgeTopConstraint?.isActive = showingBadge
        badgeBottomConstraint?.isActive = showingBadge
        priceBottomConstraint?.isActive = !showingBadge
    }
}
