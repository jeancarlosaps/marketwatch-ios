import Kingfisher
import RxCocoa
import RxSwift
import UIKit

final class AssetDetailViewController: UIViewController {
    private let viewModel: AssetDetailViewModel
    private let disposeBag = DisposeBag()

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let iconView = UIImageView()
    private let nameLabel = UILabel()
    private let symbolLabel = UILabel()
    private let priceLabel = UILabel()
    private let badgeView = VariationBadgeView()
    private let chartView = PriceChartView()
    private let chartMessageLabel = UILabel()
    private let chartRetryButton = UIButton(type: .system)
    private let feedbackView = FeedbackStateView()
    private let skeletonStack = UIStackView()

    private let referenceValue = UILabel()
    private let highValue = UILabel()
    private let lowValue = UILabel()
    private let marketCapValue = UILabel()

    init(viewModel: AssetDetailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bind()
        viewModel.load()
    }

    private func setupUI() {
        view.backgroundColor = MWColor.canvas
        navigationItem.largeTitleDisplayMode = .never
        configureHeader()
        configureChart()
        configureScroll()
        configureOverlays()
        activateConstraints()
    }

    private func configureHeader() {
        iconView.contentMode = .scaleAspectFit
        iconView.clipsToBounds = true
        iconView.layer.cornerRadius = 28
        iconView.layer.cornerCurve = .continuous
        iconView.tintColor = MWColor.secondaryLabel
        iconView.backgroundColor = MWColor.elevated
        iconView.translatesAutoresizingMaskIntoConstraints = false

        nameLabel.font = MWFont.title()
        nameLabel.adjustsFontForContentSizeCategory = true
        nameLabel.textColor = MWColor.label
        nameLabel.numberOfLines = 0

        symbolLabel.font = MWFont.body()
        symbolLabel.adjustsFontForContentSizeCategory = true
        symbolLabel.textColor = MWColor.secondaryLabel
        symbolLabel.numberOfLines = 0

        priceLabel.font = MWFont.action()
        priceLabel.adjustsFontForContentSizeCategory = true
        priceLabel.textColor = MWColor.label
        priceLabel.numberOfLines = 0

        badgeView.translatesAutoresizingMaskIntoConstraints = false
        badgeView.isHidden = true
    }

    private func configureChart() {
        chartView.translatesAutoresizingMaskIntoConstraints = false
        chartMessageLabel.font = MWFont.body()
        chartMessageLabel.adjustsFontForContentSizeCategory = true
        chartMessageLabel.textColor = MWColor.secondaryLabel
        chartMessageLabel.numberOfLines = 0
        chartMessageLabel.isHidden = true

        chartRetryButton.setTitle("Recarregar gráfico", for: .normal)
        chartRetryButton.titleLabel?.font = MWFont.action()
        chartRetryButton.titleLabel?.adjustsFontForContentSizeCategory = true
        chartRetryButton.addTarget(self, action: #selector(retryChart), for: .touchUpInside)
        chartRetryButton.isHidden = true
    }

    private func configureScroll() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true

        contentStack.axis = .vertical
        contentStack.spacing = MWLayout.spaceMD
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        contentStack.addArrangedSubview(makeIdentityRow())
        contentStack.addArrangedSubview(makePriceRow())
        contentStack.addArrangedSubview(makeFactsCard())
        contentStack.addArrangedSubview(chartView)
        contentStack.addArrangedSubview(chartMessageLabel)
        contentStack.addArrangedSubview(chartRetryButton)

        scrollView.addSubview(contentStack)
        view.addSubview(scrollView)
    }

    private func configureOverlays() {
        feedbackView.translatesAutoresizingMaskIntoConstraints = false
        feedbackView.isHidden = true
        feedbackView.onAction = { [weak self] in
            self?.viewModel.retry()
        }

        skeletonStack.axis = .vertical
        skeletonStack.spacing = MWLayout.spaceSM
        skeletonStack.translatesAutoresizingMaskIntoConstraints = false
        skeletonStack.isHidden = true
        for height in [88, 64, 160] {
            let block = SkeletonBlockView()
            block.translatesAutoresizingMaskIntoConstraints = false
            block.heightAnchor.constraint(equalToConstant: CGFloat(height)).isActive = true
            skeletonStack.addArrangedSubview(block)
        }
        view.addSubview(feedbackView)
        view.addSubview(skeletonStack)
    }

    private func activateConstraints() {
        let guide = scrollView.contentLayoutGuide
        let frame = scrollView.frameLayoutGuide
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: guide.topAnchor, constant: MWLayout.spaceMD),
            contentStack.leadingAnchor.constraint(equalTo: frame.leadingAnchor, constant: MWLayout.spaceMD),
            contentStack.trailingAnchor.constraint(equalTo: frame.trailingAnchor, constant: -MWLayout.spaceMD),
            contentStack.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -MWLayout.spaceLG),

            iconView.widthAnchor.constraint(equalToConstant: 56),
            iconView.heightAnchor.constraint(equalToConstant: 56),
            chartView.heightAnchor.constraint(equalToConstant: 180),

            feedbackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: MWLayout.spaceMD),
            feedbackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -MWLayout.spaceMD),
            feedbackView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),

            skeletonStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: MWLayout.spaceMD),
            skeletonStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: MWLayout.spaceMD),
            skeletonStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -MWLayout.spaceMD),
        ])
    }

    private func bind() {
        viewModel.state
            .drive(onNext: { [weak self] state in
                self?.render(state)
            })
            .disposed(by: disposeBag)
    }

    private func render(_ state: AssetDetailState) {
        switch state {
        case .loading:
            scrollView.isHidden = true
            feedbackView.isHidden = true
            skeletonStack.isHidden = false
        case let .error(message):
            scrollView.isHidden = true
            skeletonStack.isHidden = true
            feedbackView.isHidden = false
            feedbackView.configure(
                kind: .error,
                title: "Não foi possível abrir",
                message: message,
                actionTitle: "Tentar novamente"
            )
        case let .content(content):
            skeletonStack.isHidden = true
            feedbackView.isHidden = true
            scrollView.isHidden = false
            apply(content)
        }
    }

    private func apply(_ content: AssetDetailContent) {
        title = content.name
        nameLabel.text = content.name
        symbolLabel.text = content.symbol
        priceLabel.text = content.priceText
        referenceValue.text = content.referencePriceText
        highValue.text = content.highText
        lowValue.text = content.lowText
        marketCapValue.text = content.marketCapText
        view.accessibilityLabel = content.accessibilityLabel

        if let change = content.changePercent {
            badgeView.isHidden = false
            badgeView.configure(percent: change)
        } else {
            badgeView.isHidden = true
        }

        iconView.kf.setImage(
            with: content.imageURL,
            placeholder: UIImage(systemName: "bitcoinsign.circle")
        )

        switch content.chart {
        case let .prices(prices):
            chartView.isHidden = false
            chartView.configure(prices: prices, accessibilityLabel: content.chartAccessibilityLabel)
            chartMessageLabel.isHidden = true
            chartRetryButton.isHidden = true
        case .empty:
            chartView.isHidden = false
            chartView.configure(prices: [], accessibilityLabel: content.chartAccessibilityLabel)
            chartMessageLabel.text = "Sem dados de preço neste período."
            chartMessageLabel.isHidden = false
            chartRetryButton.isHidden = true
        case .unavailable:
            chartView.isHidden = true
            chartMessageLabel.text = "Não foi possível carregar o gráfico."
            chartMessageLabel.isHidden = false
            chartRetryButton.isHidden = false
        }
    }

    @objc
    private func retryChart() {
        viewModel.retryChart()
    }
}

private extension AssetDetailViewController {
    func makeIdentityRow() -> UIView {
        let textStack = UIStackView(arrangedSubviews: [nameLabel, symbolLabel])
        textStack.axis = .vertical
        textStack.spacing = MWLayout.space2xs

        let row = UIStackView(arrangedSubviews: [iconView, textStack])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = MWLayout.spaceSM
        return row
    }

    func makePriceRow() -> UIView {
        let row = UIStackView(arrangedSubviews: [priceLabel, badgeView])
        row.axis = .vertical
        row.alignment = .leading
        row.spacing = MWLayout.spaceXS
        return row
    }

    func makeFactsCard() -> UIView {
        let card = UIStackView(arrangedSubviews: [
            factRow(title: "Preço há 24h", value: referenceValue),
            factRow(title: "Máxima 24h", value: highValue),
            factRow(title: "Mínima 24h", value: lowValue),
            factRow(title: "Market cap", value: marketCapValue),
        ])
        card.axis = .vertical
        card.spacing = MWLayout.spaceSM
        card.isLayoutMarginsRelativeArrangement = true
        card.layoutMargins = UIEdgeInsets(
            top: MWLayout.spaceMD,
            left: MWLayout.spaceMD,
            bottom: MWLayout.spaceMD,
            right: MWLayout.spaceMD
        )
        card.backgroundColor = MWColor.card
        card.layer.cornerRadius = MWLayout.radiusCard
        card.layer.cornerCurve = .continuous
        card.clipsToBounds = true
        return card
    }

    func factRow(title: String, value: UILabel) -> UIStackView {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = MWFont.body()
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textColor = MWColor.secondaryLabel
        titleLabel.numberOfLines = 0
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        value.font = MWFont.action()
        value.adjustsFontForContentSizeCategory = true
        value.textColor = MWColor.label
        value.textAlignment = .right
        value.numberOfLines = 0
        value.setContentCompressionResistancePriority(.required, for: .horizontal)

        let row = UIStackView(arrangedSubviews: [titleLabel, value])
        row.axis = .horizontal
        row.alignment = .firstBaseline
        row.spacing = MWLayout.spaceSM
        return row
    }
}
