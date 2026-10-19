import CoreText
import UIKit

enum MWFont {
    static func title(compatibleWith traitCollection: UITraitCollection? = nil) -> UIFont {
        scaled(size: 20, weight: .semibold, textStyle: .title3, compatibleWith: traitCollection)
    }

    static func body(compatibleWith traitCollection: UITraitCollection? = nil) -> UIFont {
        scaled(size: 13, weight: .regular, textStyle: .footnote, compatibleWith: traitCollection)
    }

    static func action(compatibleWith traitCollection: UITraitCollection? = nil) -> UIFont {
        scaled(size: 17, weight: .semibold, textStyle: .headline, compatibleWith: traitCollection)
    }

    static func percent(compatibleWith traitCollection: UITraitCollection? = nil) -> UIFont {
        scaled(size: 12, weight: .semibold, textStyle: .caption1,
               tabular: true, compatibleWith: traitCollection)
    }

    private static func scaled(size: CGFloat, weight: UIFont.Weight, textStyle: UIFont.TextStyle,
                               tabular: Bool = false, compatibleWith traitCollection: UITraitCollection?) -> UIFont {
        var descriptor = UIFont.systemFont(ofSize: size, weight: weight).fontDescriptor
        if tabular {
            descriptor = descriptor.addingAttributes([
                .featureSettings: [
                    [
                        UIFontDescriptor.FeatureKey.type: kNumberSpacingType,
                        UIFontDescriptor.FeatureKey.selector: kMonospacedNumbersSelector,
                    ],
                ],
            ])
        }

        let font = UIFont(descriptor: descriptor, size: size)
        let metrics = UIFontMetrics(forTextStyle: textStyle)
        if let traitCollection {
            return metrics.scaledFont(for: font, compatibleWith: traitCollection)
        }
        return metrics.scaledFont(for: font)
    }
}
