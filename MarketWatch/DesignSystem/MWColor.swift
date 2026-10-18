import UIKit

enum MWColor {
    static let canvas = UIColor.mwDynamic(light: 0xF8FAFC, dark: 0x0B1220)
    static let card = UIColor.mwDynamic(light: 0xFFFFFF, dark: 0x151F32)
    static let elevated = UIColor.mwDynamic(light: 0xFFFFFF, dark: 0x1E293B)
    static let separator = UIColor.mwDynamic(light: 0xE2E8F0, dark: 0x243247)
    static let label = UIColor.mwDynamic(light: 0x0F172A, dark: 0xF8FAFC)
    static let secondaryLabel = UIColor.mwDynamic(light: 0x64748B, dark: 0x94A3B8)
    static let tertiaryLabel = UIColor.mwDynamic(light: 0x94A3B8, dark: 0x64748B)

    static let accent = UIColor.mwRGB(0x10B981)
    static let onAccent = UIColor.mwRGB(0x0B1220)
    static let positive = UIColor.mwRGB(0x16A34A)
    static let negative = UIColor.mwRGB(0xDC2626)
    static let neutral = UIColor.mwDynamic(light: 0x64748B, dark: 0x64748B)

    /// Texto do badge. Os fills seguem o Stitch; estas cores passam WCAG AA sobre o pill.
    static let positiveLabel = UIColor.mwDynamic(light: 0x166534, dark: 0x4ADE80)
    static let negativeLabel = UIColor.mwDynamic(light: 0xB91C1C, dark: 0xF87171)
    static let neutralLabel = UIColor.mwDynamic(light: 0x475569, dark: 0x94A3B8)

    static let positiveFill = UIColor { traitCollection in
        UIColor.mwRGB(0x16A34A, alpha: traitCollection.userInterfaceStyle == .dark ? 0.20 : 0.12)
    }

    static let negativeFill = UIColor { traitCollection in
        UIColor.mwRGB(0xDC2626, alpha: traitCollection.userInterfaceStyle == .dark ? 0.20 : 0.12)
    }

    static let neutralFill = UIColor.mwRGB(0x64748B, alpha: 0.14)
}

private extension UIColor {
    static func mwRGB(_ hex: UInt32, alpha: CGFloat = 1) -> UIColor {
        UIColor(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha
        )
    }

    static func mwDynamic(light: UInt32, dark: UInt32) -> UIColor {
        UIColor { traitCollection in
            mwRGB(traitCollection.userInterfaceStyle == .dark ? dark : light)
        }
    }
}
