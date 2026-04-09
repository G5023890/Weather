import Foundation

public protocol WeatherServing: Sendable {
    func fetchWeather(displayLocationName: String?) async throws -> WeatherSnapshot
}

public final class OpenWeatherService: WeatherServing, @unchecked Sendable {
    private let apiKey: String
    private let latitude: Double
    private let longitude: Double
    private let session: URLSession
    private let decoder: JSONDecoder
    private let baseURL: URL

    public init(
        apiKey: String,
        latitude: Double,
        longitude: Double,
        session: URLSession = .shared,
        decoder: JSONDecoder = JSONDecoder(),
        baseURL: URL = URL(string: "https://api.openweathermap.org")!
    ) {
        self.apiKey = apiKey
        self.latitude = latitude
        self.longitude = longitude
        self.session = session
        self.decoder = decoder
        self.baseURL = baseURL
    }

    public func fetchWeather(displayLocationName: String?) async throws -> WeatherSnapshot {
        guard !apiKey.isEmpty else {
            throw WeatherError.missingAPIKey
        }

        async let current = fetchCurrent()
        async let forecast = fetchForecast()

        return try WeatherSnapshotBuilder.build(
            current: try await current,
            forecast: try await forecast,
            fetchedAt: Date(),
            locationName: displayLocationName
        )
    }

    func makeCurrentURL() -> URL? {
        makeURL(path: "/data/2.5/weather")
    }

    func makeForecastURL() -> URL? {
        makeURL(path: "/data/2.5/forecast")
    }

    private func makeURL(path: String) -> URL? {
        var components = URLComponents(
            url: baseURL.appending(path: path),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [
            URLQueryItem(name: "appid", value: apiKey),
            URLQueryItem(name: "lat", value: String(latitude)),
            URLQueryItem(name: "lon", value: String(longitude)),
            URLQueryItem(name: "units", value: "metric")
        ]
        return components?.url
    }

    private func fetchCurrent() async throws -> OpenWeatherCurrentResponse {
        try await fetch(OpenWeatherCurrentResponse.self, from: makeCurrentURL())
    }

    private func fetchForecast() async throws -> OpenWeatherForecastResponse {
        try await fetch(OpenWeatherForecastResponse.self, from: makeForecastURL())
    }

    private func fetch<Response: Decodable>(_ type: Response.Type, from url: URL?) async throws -> Response {
        guard let url else {
            throw WeatherError.invalidResponse
        }

        let (data, response) = try await session.data(for: URLRequest(url: url))
        guard let httpResponse = response as? HTTPURLResponse else {
            throw WeatherError.invalidResponse
        }

        guard (200 ..< 300).contains(httpResponse.statusCode) else {
            if let apiError = try? decoder.decode(OpenWeatherErrorResponse.self, from: data),
               let message = apiError.message,
               !message.isEmpty {
                throw WeatherError.apiMessage(message.capitalized)
            }
            throw WeatherError.requestFailed(statusCode: httpResponse.statusCode)
        }

        return try decoder.decode(type, from: data)
    }
}
