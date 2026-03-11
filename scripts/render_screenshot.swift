import AppKit
import SwiftUI
import WeatherCore

@MainActor
final class WeatherMenuBarViewModel: ObservableObject {
    @Published private(set) var snapshot: WeatherSnapshot?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var lastUpdated: Date?

    init(snapshot: WeatherSnapshot) {
        self.snapshot = snapshot
        self.lastUpdated = snapshot.fetchedAt
    }
}

@main
struct ScreenshotRenderer {
    static func main() {
        let outputURL = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? "docs/weather-popover.png")
        let snapshot = makeSnapshot()
        let viewModel = WeatherMenuBarViewModel(snapshot: snapshot)

        let rootView = WeatherMenuBarContentView(viewModel: viewModel)
            .frame(width: 300)

        let hostingView = NSHostingView(rootView: rootView)
        hostingView.appearance = NSAppearance(named: .darkAqua)
        hostingView.frame = NSRect(x: 0, y: 0, width: 300, height: 420)
        hostingView.layoutSubtreeIfNeeded()

        let fitting = hostingView.fittingSize
        let size = NSSize(width: 300, height: max(420, fitting.height))
        hostingView.setFrameSize(size)
        hostingView.layoutSubtreeIfNeeded()

        guard let bitmap = hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds) else {
            fputs("Failed to create bitmap image rep.\n", stderr)
            exit(1)
        }

        hostingView.cacheDisplay(in: hostingView.bounds, to: bitmap)

        guard let data = bitmap.representation(using: .png, properties: [:]) else {
            fputs("Failed to encode PNG.\n", stderr)
            exit(1)
        }

        do {
            try FileManager.default.createDirectory(at: outputURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try data.write(to: outputURL)
            print(outputURL.path)
        } catch {
            fputs("Failed to write screenshot: \(error)\n", stderr)
            exit(1)
        }
    }

    static func makeSnapshot() -> WeatherSnapshot {
        let calendar = Calendar(identifier: .gregorian)
        let baseDate = calendar.date(from: DateComponents(year: 2026, month: 3, day: 11, hour: 9, minute: 14))!

        return WeatherSnapshot(
            locationName: "Petah Tikva",
            status: StatusSummary(
                symbolName: "sun.max.fill",
                temperatureC: 19,
                conditionText: "Clear Sky"
            ),
            hourlyForecast: [
                HourlyForecastItem(date: baseDate, symbolName: "sun.max.fill", temperatureC: 19, chanceOfRain: 0),
                HourlyForecastItem(date: baseDate.addingTimeInterval(3 * 3600), symbolName: "cloud.sun.fill", temperatureC: 19, chanceOfRain: 0),
                HourlyForecastItem(date: baseDate.addingTimeInterval(6 * 3600), symbolName: "cloud.sun.fill", temperatureC: 18, chanceOfRain: 0),
                HourlyForecastItem(date: baseDate.addingTimeInterval(9 * 3600), symbolName: "cloud.fill", temperatureC: 16, chanceOfRain: 0),
                HourlyForecastItem(date: baseDate.addingTimeInterval(12 * 3600), symbolName: "moon.fill", temperatureC: 15, chanceOfRain: 0),
                HourlyForecastItem(date: baseDate.addingTimeInterval(15 * 3600), symbolName: "cloud.moon.fill", temperatureC: 14, chanceOfRain: 0)
            ],
            dailyForecast: [
                DailyForecastItem(date: baseDate, symbolName: "sun.max.fill", minTemperatureC: 15, maxTemperatureC: 20, chanceOfRain: 0),
                DailyForecastItem(date: baseDate.addingTimeInterval(86400), symbolName: "sun.max.fill", minTemperatureC: 13, maxTemperatureC: 19, chanceOfRain: 0),
                DailyForecastItem(date: baseDate.addingTimeInterval(172800), symbolName: "cloud.fill", minTemperatureC: 12, maxTemperatureC: 20, chanceOfRain: 0),
                DailyForecastItem(date: baseDate.addingTimeInterval(259200), symbolName: "cloud.sun.rain.fill", minTemperatureC: 16, maxTemperatureC: 27, chanceOfRain: 10),
                DailyForecastItem(date: baseDate.addingTimeInterval(345600), symbolName: "cloud.sun.rain.fill", minTemperatureC: 15, maxTemperatureC: 19, chanceOfRain: 100)
            ],
            currentConditions: CurrentConditionsDetails(
                conditionText: "Clear Sky",
                minTemperatureC: 15,
                maxTemperatureC: 20,
                chanceOfRain: 0,
                humidityMin: 29,
                humidityMax: 63,
                uvIndexMax: nil,
                feelsLikeC: 14,
                pressureMMHg: 764
            ),
            fetchedAt: baseDate
        )
    }
}
