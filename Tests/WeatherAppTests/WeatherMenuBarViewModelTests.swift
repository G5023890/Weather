import Foundation
import XCTest
@testable import Weather
@testable import WeatherCore

final class WeatherMenuBarViewModelTests: XCTestCase {
    @MainActor
    func testRefreshFetchesWeatherForResolvedLocation() async throws {
        let location = ResolvedWeatherLocation(
            latitude: 32.0853,
            longitude: 34.7818,
            displayName: "Petah Tikva"
        )
        let locationProvider = MockWeatherLocationProvider(result: location)
        let service = MockWeatherService()
        let viewModel = WeatherMenuBarViewModel(
            apiKey: "api-key",
            locationProvider: locationProvider,
            weatherServiceFactory: { _ in service },
            autoStart: false
        )

        await viewModel.refresh(force: true)

        XCTAssertEqual(viewModel.locationName, "Petah Tikva")
        XCTAssertEqual(viewModel.snapshot?.locationName, "Petah Tikva")
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(service.lastDisplayLocationName, "Petah Tikva")
        XCTAssertEqual(locationProvider.requestCount, 1)
    }

    @MainActor
    func testRefreshShowsPermissionErrorWhenLocationFails() async throws {
        let locationProvider = MockWeatherLocationProvider(error: WeatherLocationError.permissionDenied)
        let viewModel = WeatherMenuBarViewModel(
            apiKey: "api-key",
            locationProvider: locationProvider,
            weatherServiceFactory: { _ in MockWeatherService() },
            autoStart: false
        )

        await viewModel.refresh(force: true)

        XCTAssertNil(viewModel.snapshot)
        XCTAssertEqual(viewModel.errorMessage, WeatherLocationError.permissionDenied.errorDescription)
        XCTAssertNil(viewModel.locationName)
        XCTAssertEqual(locationProvider.requestCount, 1)
    }
}

private final class MockWeatherLocationProvider: WeatherLocationProviding, @unchecked Sendable {
    private let result: Result<ResolvedWeatherLocation, Error>
    private(set) var requestCount = 0

    init(result: ResolvedWeatherLocation) {
        self.result = .success(result)
    }

    init(error: Error) {
        self.result = .failure(error)
    }

    func resolveCurrentLocation() async throws -> ResolvedWeatherLocation {
        requestCount += 1
        return try result.get()
    }
}

private final class MockWeatherService: WeatherServing, @unchecked Sendable {
    private(set) var lastDisplayLocationName: String?

    func fetchWeather(displayLocationName: String?) async throws -> WeatherSnapshot {
        lastDisplayLocationName = displayLocationName

        return WeatherSnapshot(
            locationName: displayLocationName ?? "Mock City",
            status: StatusSummary(symbolName: "sun.max.fill", temperatureC: 21, conditionText: "Clear"),
            hourlyForecast: [],
            dailyForecast: [],
            currentConditions: CurrentConditionsDetails(
                conditionText: "Clear",
                minTemperatureC: 19,
                maxTemperatureC: 23,
                chanceOfRain: 0,
                humidityMin: 40,
                humidityMax: 55,
                uvIndexMax: nil,
                feelsLikeC: 20,
                pressureMMHg: 760
            ),
            fetchedAt: Date()
        )
    }
}
