import Foundation

public struct AppConfiguration: Sendable {
    public let apiKey: String

    public init(apiKey: String) {
        self.apiKey = apiKey
    }

    public static func load() -> AppConfiguration {
        let apiKey = WeatherAPIKeyStore().read() ?? ""
        return AppConfiguration(apiKey: apiKey)
    }
}
