import Foundation

public enum WeatherSnapshotBuilder {
    private static let pressureRatio = 0.75006156

    public static func build(
        current: OpenWeatherCurrentResponse,
        forecast: OpenWeatherForecastResponse,
        fetchedAt: Date = Date()
    ) throws -> WeatherSnapshot {
        guard !forecast.list.isEmpty else {
            throw WeatherError.noForecastData
        }

        let timezone = TimeZone(secondsFromGMT: current.timezone) ?? .gmt
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timezone

        let nowDate = Date(timeIntervalSince1970: TimeInterval(current.dt))
        let currentCondition = current.weather.first ?? OpenWeatherCondition(
            id: 800,
            main: "Clear",
            description: "clear sky",
            icon: "01d"
        )

        let upcomingItems = forecast.list.filter { $0.dt >= current.dt }
        let hourlyItems = Array(upcomingItems.prefix(6))
        let selectedHourlyItems = hourlyItems.isEmpty ? Array(forecast.list.prefix(6)) : hourlyItems

        let currentDayItems = forecast.list.filter {
            calendar.isDate(
                Date(timeIntervalSince1970: TimeInterval($0.dt)),
                equalTo: nowDate,
                toGranularity: .day
            )
        }

        let referenceItems = currentDayItems.isEmpty
            ? (upcomingItems.isEmpty ? Array(forecast.list.prefix(8)) : upcomingItems)
            : currentDayItems

        let groupedDailyItems = Dictionary(grouping: forecast.list) {
            calendar.startOfDay(for: Date(timeIntervalSince1970: TimeInterval($0.dt)))
        }
        let orderedDays = groupedDailyItems.keys.sorted().prefix(5)

        let status = StatusSummary(
            symbolName: ConditionSymbolMapper.symbolName(
                for: currentCondition.id,
                iconCode: currentCondition.icon
            ),
            temperatureC: Int(current.main.temp.rounded()),
            conditionText: currentCondition.description.capitalized
        )

        let hourlyForecast = selectedHourlyItems.map { item in
            let condition = item.weather.first ?? currentCondition
            return HourlyForecastItem(
                date: Date(timeIntervalSince1970: TimeInterval(item.dt)),
                symbolName: ConditionSymbolMapper.symbolName(
                    for: condition.id,
                    iconCode: condition.icon
                ),
                temperatureC: Int(item.main.temp.rounded()),
                chanceOfRain: Int((item.pop * 100).rounded())
            )
        }

        let dailyForecast = orderedDays.compactMap { dayStart -> DailyForecastItem? in
            guard let items = groupedDailyItems[dayStart], let representative = mostRelevantItem(in: items) else {
                return nil
            }

            let tempsMin = items.map(\.main.tempMin)
            let tempsMax = items.map(\.main.tempMax)
            let maxPop = items.map(\.pop).max() ?? 0

            return DailyForecastItem(
                date: dayStart,
                symbolName: ConditionSymbolMapper.symbolName(
                    for: representative.id,
                    iconCode: representative.icon
                ),
                minTemperatureC: Int((tempsMin.min() ?? representativeTempMin(in: items)).rounded()),
                maxTemperatureC: Int((tempsMax.max() ?? representativeTempMax(in: items)).rounded()),
                chanceOfRain: Int((maxPop * 100).rounded())
            )
        }

        let humidityValues = referenceItems.map(\.main.humidity)
        let currentConditions = CurrentConditionsDetails(
            conditionText: currentCondition.description.capitalized,
            minTemperatureC: Int((referenceItems.map(\.main.tempMin).min() ?? current.main.tempMin).rounded()),
            maxTemperatureC: Int((referenceItems.map(\.main.tempMax).max() ?? current.main.tempMax).rounded()),
            chanceOfRain: Int(((referenceItems.map(\.pop).max() ?? 0) * 100).rounded()),
            humidityMin: humidityValues.min() ?? current.main.humidity,
            humidityMax: humidityValues.max() ?? current.main.humidity,
            uvIndexMax: nil,
            feelsLikeC: Int((current.main.feelsLike ?? current.main.temp).rounded()),
            pressureMMHg: Int((Double(current.main.pressure) * pressureRatio).rounded())
        )

        return WeatherSnapshot(
            locationName: current.name,
            status: status,
            hourlyForecast: hourlyForecast,
            dailyForecast: dailyForecast,
            currentConditions: currentConditions,
            fetchedAt: max(fetchedAt, nowDate)
        )
    }

    private static func mostRelevantItem(in items: [OpenWeatherForecastItem]) -> OpenWeatherCondition? {
        let sortedItems = items.sorted { lhs, rhs in
            abs((lhs.dt % 86_400) - 43_200) < abs((rhs.dt % 86_400) - 43_200)
        }
        return sortedItems.first?.weather.first
    }

    private static func representativeTempMin(in items: [OpenWeatherForecastItem]) -> Double {
        items.first?.main.tempMin ?? 0
    }

    private static func representativeTempMax(in items: [OpenWeatherForecastItem]) -> Double {
        items.first?.main.tempMax ?? 0
    }
}
