import Combine
import Foundation
import WeatherCore

@MainActor
final class WeatherMenuBarViewModel: ObservableObject {
    @Published private(set) var snapshot: WeatherSnapshot?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var lastUpdated: Date?

    private let service: any WeatherServing
    private let nowProvider: () -> Date
    private var refreshTask: Task<Void, Never>?
    private var hasStarted = false

    init(service: any WeatherServing, nowProvider: @escaping () -> Date = Date.init) {
        self.service = service
        self.nowProvider = nowProvider
        startIfNeeded()
    }

    deinit {
        refreshTask?.cancel()
    }

    static func live() -> WeatherMenuBarViewModel {
        let configuration = AppConfiguration.load()
        let service = OpenWeatherService(
            apiKey: configuration.apiKey,
            locationQuery: configuration.locationQuery
        )
        return WeatherMenuBarViewModel(service: service)
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
        defer { isLoading = false }

        do {
            let snapshot = try await service.fetchWeather()
            self.snapshot = snapshot
            lastUpdated = nowProvider()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
