import UIKit

/// Maps prices into a plot rect. A flat series stays on the midline; a single point stays centered.
enum PriceChartLayout {
    static func points(prices: [Decimal], in rect: CGRect) -> [CGPoint] {
        guard rect.width > 0, rect.height > 0, !prices.isEmpty else { return [] }

        let values = prices.map { NSDecimalNumber(decimal: $0).doubleValue }
        let lowest = values.min() ?? 0
        let highest = values.max() ?? 0
        let span = highest - lowest
        let lastIndex = CGFloat(values.count - 1)

        return values.enumerated().map { index, value in
            let x = values.count == 1
                ? rect.midX
                : rect.minX + (CGFloat(index) / lastIndex) * rect.width
            let y: CGFloat
            if span == 0 {
                y = rect.midY
            } else {
                let progress = (value - lowest) / span
                y = rect.maxY - CGFloat(progress) * rect.height
            }
            return CGPoint(x: x, y: y)
        }
    }
}

/// Seven-day price line. Draws only the series it receives.
final class PriceChartView: UIView {
    private let lineLayer = CAShapeLayer()
    private var prices: [Decimal] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        lineLayer.frame = bounds
        updatePath()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        backgroundColor = MWColor.card.resolvedColor(with: traitCollection)
        updateStrokeColor()
    }

    func configure(prices: [Decimal], accessibilityLabel: String) {
        self.prices = prices
        isAccessibilityElement = true
        accessibilityTraits = .image
        self.accessibilityLabel = accessibilityLabel
        updateStrokeColor()
        setNeedsLayout()
    }

    private func setup() {
        backgroundColor = MWColor.card
        layer.cornerRadius = MWLayout.radiusCard
        layer.cornerCurve = .continuous
        clipsToBounds = true

        lineLayer.fillColor = nil
        lineLayer.lineWidth = 2
        lineLayer.lineCap = .round
        lineLayer.lineJoin = .round
        layer.addSublayer(lineLayer)
        updateStrokeColor()
    }

    private func updateStrokeColor() {
        lineLayer.strokeColor = strokeColor().resolvedColor(with: traitCollection).cgColor
    }

    private func strokeColor() -> UIColor {
        guard let first = prices.first, let last = prices.last, prices.count > 1 else {
            return MWColor.accent
        }
        if last > first { return MWColor.positive }
        if last < first { return MWColor.negative }
        return MWColor.neutral
    }

    private func updatePath() {
        let plot = bounds.insetBy(dx: MWLayout.spaceSM, dy: MWLayout.spaceSM)
        let samples = PriceChartLayout.points(prices: prices, in: plot)
        guard !samples.isEmpty else {
            lineLayer.path = nil
            return
        }

        let path = UIBezierPath()
        if let only = samples.first, samples.count == 1 {
            path.move(to: CGPoint(x: only.x - MWLayout.spaceSM, y: only.y))
            path.addLine(to: CGPoint(x: only.x + MWLayout.spaceSM, y: only.y))
        } else {
            path.move(to: samples[0])
            for point in samples.dropFirst() {
                path.addLine(to: point)
            }
        }
        lineLayer.path = path.cgPath
    }
}
