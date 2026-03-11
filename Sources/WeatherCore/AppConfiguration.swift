import Foundation

public struct AppConfiguration: Sendable {
    public let apiKey: String
    public let locationQuery: String

    public init(apiKey: String, locationQuery: String) {
        self.apiKey = apiKey
        self.locationQuery = locationQuery
    }

    public static func load(from bundle: Bundle = .main) -> AppConfiguration {
        let apiKey = (bundle.object(forInfoDictionaryKey: "WEATHER_API_KEY") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let locationQuery = (bundle.object(forInfoDictionaryKey: "WEATHER_QUERY") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .nonEmpty ?? "Petah Tikva,IL"

        return AppConfiguration(apiKey: apiKey, locationQuery: locationQuery)
    }
}

private extension String {
    var nonEmpty: String? {
        isEmpty ? nil : self
    }
}
