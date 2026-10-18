import Foundation
import Testing
@testable import MarketWatch

@Suite("App launch")
struct AppLaunchTests {
    @Test("Test bundle is hosted by the MarketWatch app")
    func hostAppBundleIdentifier() {
        #expect(Bundle.main.bundleIdentifier == "com.jeancarlosaps.MarketWatch")
    }
}
