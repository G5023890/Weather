import Combine
import Foundation
import WeatherCore

@MainActor
final class WeatherMenuBarViewModel: ObservableObject {
    @Published private(set) var snapshot: WeatherSnapshot?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var lastUpdated: Date?
    @Published private(set) var locationName: String?

    private let apiKey: String
    private let locationProvider: any WeatherLocationProviding
    private let weatherServiceFactory: (ResolvedWeatherLocation) -> any WeatherServing
    private let nowProvider: () -> Date
    private var refreshTask: Task<Void, Never>?
    private var hasStarted = false
    private var resolvedLocation: ResolvedWeatherLocation?

    init(
        apiKey: String,
        locationProvider: any WeatherLocationProviding = SystemWeatherLocationProvider(),
        weatherServiceFactory: ((ResolvedWeatherLocation) -> any WeatherServing)? = nil,
        nowProvider: @escaping () -> Date = Date.init,
        autoStart: Bool = true
    ) {
        self.apiKey = apiKey
        self.locationProvider = locationProvider
        self.weatherServiceFactory = weatherServiceFactory ?? { location in
            OpenWeatherService(
                apiKey: apiKey,
                latitude: location.latitude,
                longitude: location.longitude
            )
        }
        self.nowProvider = nowProvider
        if autoStart {
            startIfNeeded()
        }
    }

    deinit {
        refreshTask?.cancel()
    }

    static func live() -> WeatherMenuBarViewModel {
        let configuration = AppConfiguration.load()
        return WeatherMenuBarViewModel(apiKey: configuration.apiKey)
    }

    var menuBarSymbolName: String {
        snapshot?.status.symbolName ?? "cloud.fill"
    }

    var menuBarText: String {
        guard let snapshot else {
            return "--°"
        }

        return snapshot.status.temperatureText
    }

    func startIfNeeded() {
        guard !hasStarted else { return }
        hasStarted = true

        Task {
            await refresh(force: true)
        }

        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 15 * 60 * 1_000_000_000)
                guard let self else { return }
                await self.refresh(force: true)
            }
        }
    }

    func handlePopoverAppear() async {
        let isStale = lastUpdated.map { nowProvider().timeIntervalSince($0) >= 5 * 60 } ?? true
        guard isStale else { return }
        await refresh(force: true)
    }

    func refresh(force: Bool) async {
        guard !isLoading else { return }
        if !force, let lastUpdated, nowProvider().timeIntervalSince(lastUpdated) < 5 * 60 {
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let resolvedLocation = try await resolveLocationIfNeeded()
            let service = weatherServiceFactory(resolvedLocation)
            let snapshot = try await service.fetchWeather(displayLocationName: resolvedLocation.displayName)
            self.snapshot = snapshot
            locationName = resolvedLocation.displayName
            lastUpdated = nowProvider()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func resolveLocationIfNeeded() async throws -> ResolvedWeatherLocation {
        if let resolvedLocation {
            return resolvedLocation
        }

        let location = try await locationProvider.resolveCurrentLocation()
        resolvedLocation = location
        locationName = location.displayName
        return location
    }
}
