import Foundation
import XCTest
@testable import WeatherCore

final class WeatherSnapshotBuilderTests: XCTestCase {
    func testDecodesOpenWeatherFixtures() throws {
        let currentData = try fixture(named: "openweather_current")
        let forecastData = try fixture(named: "openweather_forecast")

        let current = try JSONDecoder().decode(OpenWeatherCurrentResponse.self, from: currentData)
        let forecast = try JSONDecoder().decode(OpenWeatherForecastResponse.self, from: forecastData)

        XCTAssertEqual(current.name, "Petah Tikva")
        XCTAssertEqual(current.main.pressure, 1014)
        XCTAssertEqual(forecast.city.name, "Petah Tikva")
        XCTAssertEqual(forecast.list.count, 13)
    }

    func testBuildsSnapshotFromOpenWeatherFixtures() throws {
        let currentData = try fixture(named: "openweather_current")
        let forecastData = try fixture(named: "openweather_forecast")
        let current = try JSONDecoder().decode(OpenWeatherCurrentResponse.self, from: currentData)
        let forecast = try JSONDecoder().decode(OpenWeatherForecastResponse.self, from: forecastData)

        let snapshot = try WeatherSnapshotBuilder.build(
            current: current,
            forecast: forecast,
            fetchedAt: .distantPast
        )

        XCTAssertEqual(snapshot.status.temperatureC, 21)
        XCTAssertEqual(snapshot.status.symbolName, "cloud.sun.fill")
        XCTAssertEqual(snapshot.hourlyForecast.count, 6)
        XCTAssertEqual(snapshot.hourlyForecast.first?.chanceOfRain, 5)
        XCTAssertEqual(snapshot.dailyForecast.count, 5)
        XCTAssertEqual(snapshot.currentConditions.humidityMin, 54)
        XCTAssertEqual(snapshot.currentConditions.humidityMax, 67)
        XCTAssertNil(snapshot.currentConditions.uvIndexMax)
        XCTAssertEqual(snapshot.currentConditions.pressureMMHg, 761)
    }

    func testBuildsSnapshotWhenCurrentDayForecastIsMissing() throws {
        let current = OpenWeatherCurrentResponse(
            name: "Petah Tikva",
            timezone: 10_800,
            dt: 1_774_808_930,
            weather: [
                OpenWeatherCondition(
                    id: 801,
                    main: "Clouds",
                    description: "few clouds",
                    icon: "02d"
                )
            ],
            main: OpenWeatherMain(
                temp: 14.3,
                feelsLike: 13.8,
                tempMin: 12.7,
                tempMax: 15.0,
                pressure: 1012,
                humidity: 74
            )
        )

        let forecast = OpenWeatherForecastResponse(
            list: [
                OpenWeatherForecastItem(
                    dt: 1_774_818_000,
                    pop: 0.0,
                    weather: [
                        OpenWeatherCondition(
                            id: 800,
                            main: "Clear",
                            description: "clear sky",
                            icon: "01n"
                        )
                    ],
                    main: OpenWeatherMain(
                        temp: 13.9,
                        feelsLike: 13.3,
                        tempMin: 13.1,
                        tempMax: 13.9,
                        pressure: 1011,
                        humidity: 73
                    )
                )
            ],
            city: OpenWeatherCity(name: "Petah Tikva", timezone: 10_800)
        )

        let snapshot = try WeatherSnapshotBuilder.build(
            current: current,
            forecast: forecast,
            fetchedAt: .distantPast
        )

        XCTAssertEqual(snapshot.locationName, "Petah Tikva")
        XCTAssertEqual(snapshot.hourlyForecast.count, 1)
        XCTAssertEqual(snapshot.dailyForecast.count, 1)
        XCTAssertEqual(snapshot.currentConditions.minTemperatureC, 13)
        XCTAssertEqual(snapshot.currentConditions.maxTemperatureC, 14)
    }

    func testMapsCommonOpenWeatherCodesToSymbols() {
        XCTAssertEqual(ConditionSymbolMapper.symbolName(for: 800, iconCode: "01d"), "sun.max.fill")
        XCTAssertEqual(ConditionSymbolMapper.symbolName(for: 800, iconCode: "01n"), "moon.stars.fill")
        XCTAssertEqual(ConditionSymbolMapper.symbolName(for: 801, iconCode: "02d"), "cloud.sun.fill")
        XCTAssertEqual(ConditionSymbolMapper.symbolName(for: 803, iconCode: "04n"), "cloud.fill")
        XCTAssertEqual(ConditionSymbolMapper.symbolName(for: 500, iconCode: "10d"), "cloud.sun.rain.fill")
        XCTAssertEqual(ConditionSymbolMapper.symbolName(for: 210, iconCode: "11n"), "cloud.bolt.rain.fill")
        XCTAssertEqual(ConditionSymbolMapper.symbolName(for: 741, iconCode: "50d"), "cloud.fog.fill")
    }

    private func fixture(named name: String) throws -> Data {
        guard let url = Bundle(for: Self.self).url(forResource: name, withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }

        return try Data(contentsOf: url)
    }
}
