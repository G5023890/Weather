import Foundation
import XCTest
@testable import WeatherCore

final class WeatherServiceTests: XCTestCase {
    func testBuildsCoordinateBasedWeatherURLs() throws {
        let service = OpenWeatherService(
            apiKey: "api-key",
            latitude: 32.0853,
            longitude: 34.7818,
            baseURL: URL(string: "https://example.com")!
        )

        let currentURL = try XCTUnwrap(service.makeCurrentURL())
        let forecastURL = try XCTUnwrap(service.makeForecastURL())

        XCTAssertEqual(currentURL.host, "example.com")
        XCTAssertEqual(currentURL.path, "/data/2.5/weather")
        XCTAssertEqual(forecastURL.path, "/data/2.5/forecast")

        let currentItems = try XCTUnwrap(URLComponents(url: currentURL, resolvingAgainstBaseURL: false)?.queryItems)
        let forecastItems = try XCTUnwrap(URLComponents(url: forecastURL, resolvingAgainstBaseURL: false)?.queryItems)

        XCTAssertEqual(currentItems.first(where: { $0.name == "appid" })?.value, "api-key")
        XCTAssertEqual(currentItems.first(where: { $0.name == "lat" })?.value, "32.0853")
        XCTAssertEqual(currentItems.first(where: { $0.name == "lon" })?.value, "34.7818")
        XCTAssertEqual(currentItems.first(where: { $0.name == "units" })?.value, "metric")

        XCTAssertEqual(forecastItems.first(where: { $0.name == "lat" })?.value, "32.0853")
        XCTAssertEqual(forecastItems.first(where: { $0.name == "lon" })?.value, "34.7818")
    }
}
