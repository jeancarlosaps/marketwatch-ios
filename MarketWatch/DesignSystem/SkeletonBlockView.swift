import UIKit

final class SkeletonBlockView: UIView {
    private let shimmerKey = "mw.shimmer"

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        updateShimmer()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        backgroundColor = MWColor.elevated.resolvedColor(with: traitCollection)
    }

    private func setup() {
        backgroundColor = MWColor.elevated
        layer.cornerRadius = MWLayout.radiusCard
        layer.cornerCurve = .continuous
        clipsToBounds = true
        isAccessibilityElement = false
        accessibilityElementsHidden = true
        isUserInteractionEnabled = false

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateShimmer),
            name: UIAccessibility.reduceMotionStatusDidChangeNotification,
            object: nil
        )
    }

    @objc
    private func updateShimmer() {
        layer.removeAnimation(forKey: shimmerKey)
        layer.opacity = 1

        guard window != nil, !UIAccessibility.isReduceMotionEnabled else {
            return
        }

        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 1
        animation.toValue = 0.55
        animation.duration = 0.9
        animation.autoreverses = true
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        layer.add(animation, forKey: shimmerKey)
    }
}
