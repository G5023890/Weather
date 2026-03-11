import Foundation

public enum WeatherError: LocalizedError, Equatable {
    case missingAPIKey
    case invalidResponse
    case noForecastData
    case requestFailed(statusCode: Int)
    case apiMessage(String)

    public var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Missing OpenWeather API key. Add WEATHER_API_KEY to Config/Secrets.xcconfig."
        case .invalidResponse:
            return "Weather service returned an invalid response."
        case .noForecastData:
            return "Weather forecast is unavailable right now."
        case let .requestFailed(statusCode):
            return "Weather request failed with status \(statusCode)."
        case let .apiMessage(message):
            return message
        }
    }
}
