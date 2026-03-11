import Foundation

public struct WeatherSnapshot: Sendable, Equatable {
    public let locationName: String
    public let status: StatusSummary
    public let hourlyForecast: [HourlyForecastItem]
    public let dailyForecast: [DailyForecastItem]
    public let currentConditions: CurrentConditionsDetails
    public let fetchedAt: Date

    public init(
        locationName: String,
        status: StatusSummary,
        hourlyForecast: [HourlyForecastItem],
        dailyForecast: [DailyForecastItem],
        currentConditions: CurrentConditionsDetails,
        fetchedAt: Date
    ) {
        self.locationName = locationName
        self.status = status
        self.hourlyForecast = hourlyForecast
        self.dailyForecast = dailyForecast
        self.currentConditions = currentConditions
        self.fetchedAt = fetchedAt
    }
}

public struct StatusSummary: Sendable, Equatable {
    public let symbolName: String
    public let temperatureC: Int
    public let conditionText: String

    public init(symbolName: String, temperatureC: Int, conditionText: String) {
        self.symbolName = symbolName
        self.temperatureC = temperatureC
        self.conditionText = conditionText
    }

    public var temperatureText: String {
        "\(temperatureC)°"
    }
}

public struct HourlyForecastItem: Sendable, Equatable, Identifiable {
    public let id: Date
    public let date: Date
    public let symbolName: String
    public let temperatureC: Int
    public let chanceOfRain: Int

    public init(date: Date, symbolName: String, temperatureC: Int, chanceOfRain: Int) {
        self.id = date
        self.date = date
        self.symbolName = symbolName
        self.temperatureC = temperatureC
        self.chanceOfRain = chanceOfRain
    }

    public var temperatureText: String {
        "\(temperatureC)°"
    }

    public var chanceOfRainText: String {
        "\(chanceOfRain)%"
    }
}

public struct DailyForecastItem: Sendable, Equatable, Identifiable {
    public let id: Date
    public let date: Date
    public let symbolName: String
    public let minTemperatureC: Int
    public let maxTemperatureC: Int
    public let chanceOfRain: Int

    public init(
        date: Date,
        symbolName: String,
        minTemperatureC: Int,
        maxTemperatureC: Int,
        chanceOfRain: Int
    ) {
        self.id = date
        self.date = date
        self.symbolName = symbolName
        self.minTemperatureC = minTemperatureC
        self.maxTemperatureC = maxTemperatureC
        self.chanceOfRain = chanceOfRain
    }

    public var minTemperatureText: String {
        "\(minTemperatureC)°"
    }

    public var maxTemperatureText: String {
        "\(maxTemperatureC)°"
    }
}

public struct CurrentConditionsDetails: Sendable, Equatable {
    public let conditionText: String
    public let minTemperatureC: Int
    public let maxTemperatureC: Int
    public let chanceOfRain: Int
    public let humidityMin: Int
    public let humidityMax: Int
    public let uvIndexMax: Int?
    public let feelsLikeC: Int
    public let pressureMMHg: Int

    public init(
        conditionText: String,
        minTemperatureC: Int,
        maxTemperatureC: Int,
        chanceOfRain: Int,
        humidityMin: Int,
        humidityMax: Int,
        uvIndexMax: Int?,
        feelsLikeC: Int,
        pressureMMHg: Int
    ) {
        self.conditionText = conditionText
        self.minTemperatureC = minTemperatureC
        self.maxTemperatureC = maxTemperatureC
        self.chanceOfRain = chanceOfRain
        self.humidityMin = humidityMin
        self.humidityMax = humidityMax
        self.uvIndexMax = uvIndexMax
        self.feelsLikeC = feelsLikeC
        self.pressureMMHg = pressureMMHg
    }
}
