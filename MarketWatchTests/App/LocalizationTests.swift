import Foundation
import Testing
@testable import MarketWatch

@Suite("Localization")
struct LocalizationTests {
    @Test("App is developed in Brazilian Portuguese")
    func developmentLocalization() {
        #expect(Bundle.main.developmentLocalization == "pt-BR")
        #expect(Bundle.main.localizations.contains("pt-BR"))
    }

    @Test("Strings load from the String Catalog")
    func loadsCatalogStrings() throws {
        let path = try #require(Bundle.main.path(forResource: "pt-BR", ofType: "lproj"))
        let bundle = try #require(Bundle(path: path))

        #expect(bundle.localizedString(forKey: "Sem conexão com a internet.", value: "missing", table: nil)
            == "Sem conexão com a internet.")
        #expect(bundle.localizedString(forKey: "Tentar novamente", value: "missing", table: nil) == "Tentar novamente")
    }

    @Test("Parameterized strings keep their format")
    func formatsParameterizedStrings() {
        let percent = "+3,45%"
        let name = "Bitcoin"
        let symbol = "BTC"
        let price = "US$ 1,00"
        let reference = "US$ 0,90"
        let chart = "Gráfico de 7 dias, tendência de alta"

        #expect(String(localized: "Alta \(percent)") == "Alta +3,45%")
        #expect(String(localized: "\(name), \(symbol), \(price). Preço há 24h \(reference). \(chart)")
            == "Bitcoin, BTC, US$ 1,00. Preço há 24h US$ 0,90. Gráfico de 7 dias, tendência de alta")
    }

    @Test("Missing keys fall back to the default value")
    func fallsBackToDefaultValue() {
        #expect(Bundle.main.localizedString(forKey: "mw.missing.key", value: "Padrão", table: nil) == "Padrão")
    }
}
