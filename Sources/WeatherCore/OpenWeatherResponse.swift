import Foundation

public struct OpenWeatherCurrentResponse: Decodable, Sendable {
    public let name: String
    public let timezone: Int
    public let dt: Int
    public let weather: [OpenWeatherCondition]
    public let main: OpenWeatherMain
}

public struct OpenWeatherForecastResponse: Decodable, Sendable {
    public let list: [OpenWeatherForecastItem]
    public let city: OpenWeatherCity
}

public struct OpenWeatherCity: Decodable, Sendable {
    public let name: String
    public let timezone: Int
}

public struct OpenWeatherForecastItem: Decodable, Sendable {
    public let dt: Int
    public let pop: Double
    public let weather: [OpenWeatherCondition]
    public let main: OpenWeatherMain
}

public struct OpenWeatherMain: Decodable, Sendable {
    public let temp: Double
    public let feelsLike: Double?
    public let tempMin: Double
    public let tempMax: Double
    public let pressure: Int
    public let humidity: Int

    enum CodingKeys: String, CodingKey {
        case temp
        case feelsLike = "feels_like"
        case tempMin = "temp_min"
        case tempMax = "temp_max"
        case pressure
        case humidity
    }
}

public struct OpenWeatherCondition: Decodable, Sendable {
    public let id: Int
    public let main: String
    public let description: String
    public let icon: String
}

public struct OpenWeatherErrorResponse: Decodable, Sendable {
    public let cod: String?
    public let message: String?
}
