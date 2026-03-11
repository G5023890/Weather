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
        guard let url = Bundle.module.url(forResource: name, withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }

        return try Data(contentsOf: url)
    }
}
