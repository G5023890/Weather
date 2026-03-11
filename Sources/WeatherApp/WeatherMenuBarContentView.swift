import SwiftUI
import AppKit
import WeatherCore

struct LiquidGlassBackground: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .hudWindow
    var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ view: NSVisualEffectView, context: Context) {
        view.material = material
        view.blendingMode = blendingMode
    }
}

private enum Glass {
    static let divider = Color.white.opacity(0.14)
    static let rowHover = Color.white.opacity(0.08)
    static let labelSec = Color.white.opacity(0.80)
    static let labelTert = Color.white.opacity(0.62)
    static let valuePri = Color.white.opacity(0.99)
    static let rainBlue = Color(red: 0.47, green: 0.78, blue: 1.00)
    static let feelsBlue = Color(red: 0.56, green: 0.83, blue: 1.00)
    static let barTrack = Color.white.opacity(0.13)

    static func barGradient(rainy: Bool) -> LinearGradient {
        rainy
            ? LinearGradient(
                colors: [
                    Color(red: 0.31, green: 0.76, blue: 0.97),
                    Color(red: 0.12, green: 0.53, blue: 0.90)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            : LinearGradient(
                colors: [
                    Color(red: 0.31, green: 0.76, blue: 0.97),
                    Color(red: 1.00, green: 0.72, blue: 0.30)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
    }
}

private struct GlassTintBackground: View {
    var body: some View {
        ZStack {
            LiquidGlassBackground(material: .hudWindow, blendingMode: .withinWindow)

            LinearGradient(
                stops: [
                    .init(color: Color(red: 0.11, green: 0.28, blue: 0.66).opacity(0.84), location: 0.00),
                    .init(color: Color(red: 0.08, green: 0.24, blue: 0.59).opacity(0.76), location: 0.34),
                    .init(color: Color(red: 0.05, green: 0.20, blue: 0.52).opacity(0.72), location: 0.68),
                    .init(color: Color(red: 0.23, green: 0.24, blue: 0.60).opacity(0.74), location: 1.00)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [
                    Color.white.opacity(0.16),
                    Color.white.opacity(0.04),
                    Color.clear
                ],
                center: .topLeading,
                startRadius: 12,
                endRadius: 220
            )

            LinearGradient(
                colors: [
                    Color.white.opacity(0.08),
                    Color.clear,
                    Color.black.opacity(0.14)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
    }
}

private enum Typ {
    static let cityName = Font.system(size: 15, weight: .semibold, design: .rounded)
    static let heroCond = Font.system(size: 11, weight: .regular, design: .rounded)
    static let heroMinMax = Font.system(size: 11, weight: .medium, design: .rounded)
    static let heroTemp = Font.system(size: 36, weight: .ultraLight, design: .rounded)

    static let hourLabel = Font.system(size: 10, weight: .medium, design: .rounded)
    static let hourTemp = Font.system(size: 12, weight: .semibold, design: .rounded)
    static let hourRain = Font.system(size: 9, weight: .medium, design: .rounded)

    static let dayName = Font.system(size: 12, weight: .semibold, design: .rounded)
    static let dayTemp = Font.system(size: 12, weight: .semibold, design: .rounded)
    static let dayTempMin = Font.system(size: 11, weight: .regular, design: .rounded)
    static let dayRain = Font.system(size: 10, weight: .medium, design: .rounded)

    static let feelsLbl = Font.system(size: 9, weight: .semibold, design: .rounded)
    static let feelsVal = Font.system(size: 28, weight: .ultraLight, design: .rounded)
    static let feelsDelta = Font.system(size: 10, weight: .medium, design: .rounded)
    static let statLbl = Font.system(size: 9, weight: .semibold, design: .rounded)
    static let statVal = Font.system(size: 12, weight: .medium, design: .rounded)
}

struct WeatherMenuBarContentView: View {
    @ObservedObject var viewModel: WeatherMenuBarViewModel

    var body: some View {
        Group {
            if let snapshot = viewModel.snapshot {
                WeatherPopoverContentView(snapshot: snapshot)
            } else {
                loadingState
            }
        }
        .frame(width: 300)
    }

    private var loadingState: some View {
        ZStack {
            GlassTintBackground()

            VStack(alignment: .leading, spacing: 10) {
                Text("Petah Tikva")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(Glass.valuePri)

                Text(viewModel.isLoading ? "Loading weather…" : "Waiting for first successful update")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(Glass.labelSec)

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(Glass.rainBlue)
                        .fixedSize(horizontal: false, vertical: true)
                } else if viewModel.isLoading {
                    ProgressView()
                        .tint(.white.opacity(0.92))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(14)
        }
        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
    }
}

private struct WeatherPopoverContentView: View {
    let snapshot: WeatherSnapshot

    var body: some View {
        ZStack {
            GlassTintBackground()

            VStack(spacing: 0) {
                HeroRow(snapshot: snapshot)
                GlassDivider()
                HourlyStrip(items: Array(snapshot.hourlyForecast.prefix(6)))
                GlassDivider()
                DailyList(
                    items: Array(snapshot.dailyForecast.prefix(5)),
                    globalMin: snapshot.dailyForecast.map(\.minTemperatureC).min() ?? 0,
                    globalMax: snapshot.dailyForecast.map(\.maxTemperatureC).max() ?? 1
                )
                GlassDivider()
                FooterRow(
                    current: snapshot.currentConditions,
                    actual: snapshot.status.temperatureC
                )
            }
        }
        .frame(width: 300)
        .overlay(alignment: .top) {
            LinearGradient(
                colors: [
                    .clear,
                    .white.opacity(0.50),
                    .white.opacity(0.65),
                    .white.opacity(0.50),
                    .clear
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 0.5)
        }
        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
    }
}

private struct GlassDivider: View {
    var body: some View {
        Rectangle()
            .fill(Glass.divider)
            .frame(height: 0.5)
    }
}

private struct HeroRow: View {
    let snapshot: WeatherSnapshot

    private var current: CurrentConditionsDetails { snapshot.currentConditions }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: 3) {
                Text(snapshot.locationName)
                    .font(Typ.cityName)
                    .foregroundStyle(Glass.valuePri)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Text("\(snapshot.status.conditionText) · Updated \(snapshot.fetchedAt.formatted(date: .omitted, time: .shortened))")
                    .font(Typ.heroCond)
                    .foregroundStyle(Glass.labelSec)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Label("\(current.maxTemperatureC)°", systemImage: "arrow.up")
                    Label("\(current.minTemperatureC)°", systemImage: "arrow.down")
                }
                .font(Typ.heroMinMax)
                .foregroundStyle(Glass.labelSec)
                .labelStyle(InlineIconLabelStyle())
            }

            Spacer(minLength: 8)

            HStack(alignment: .top, spacing: 5) {
                Image(systemName: snapshot.status.symbolName)
                    .symbolRenderingMode(.multicolor)
                    .font(.system(size: 28, weight: .light))
                    .frame(width: 32, height: 36, alignment: .top)

                Text("\(snapshot.status.temperatureC)°")
                    .font(Typ.heroTemp)
                    .foregroundStyle(Glass.valuePri)
                    .tracking(-1)
                    .monospacedDigit()
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

private struct HourlyStrip: View {
    let items: [HourlyForecastItem]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                HourlyCell(item: item, isFirst: index == 0)

                if index < items.count - 1 {
                    Rectangle()
                        .fill(Glass.divider)
                        .frame(width: 0.5)
                        .padding(.vertical, 6)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 6)
    }
}

private struct HourlyCell: View {
    let item: HourlyForecastItem
    let isFirst: Bool
    @State private var hovered = false

    private var timeLabel: String {
        isFirst ? "Now" : item.date.formatted(.dateTime.hour(.defaultDigits(amPM: .omitted)))
    }

    var body: some View {
        VStack(spacing: 3) {
            Text(timeLabel)
                .font(Typ.hourLabel)
                .foregroundStyle(Glass.labelTert)

            Image(systemName: item.symbolName)
                .symbolRenderingMode(.multicolor)
                .font(.system(size: 14, weight: .light))
                .frame(height: 18)

            Text("\(item.temperatureC)°")
                .font(Typ.hourTemp)
                .foregroundStyle(Glass.valuePri)
                .monospacedDigit()

            if item.chanceOfRain > 0 {
                Text("\(item.chanceOfRain)%")
                    .font(Typ.hourRain)
                    .foregroundStyle(Glass.rainBlue)
                    .monospacedDigit()
            } else {
                Text("–")
                    .font(Typ.hourRain)
                    .foregroundStyle(Glass.labelTert)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 3)
        .background(hovered ? Glass.rowHover : .clear)
        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
        .onHover { hovered = $0 }
        .animation(.easeInOut(duration: 0.12), value: hovered)
    }
}

private struct DailyList: View {
    let items: [DailyForecastItem]
    let globalMin: Int
    let globalMax: Int

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                DailyRow(item: item, globalMin: globalMin, globalMax: globalMax)
                if index < items.count - 1 {
                    Rectangle()
                        .fill(Glass.divider)
                        .frame(height: 0.5)
                        .padding(.horizontal, 14)
                }
            }
        }
    }
}

private struct DailyRow: View {
    let item: DailyForecastItem
    let globalMin: Int
    let globalMax: Int
    @State private var hovered = false

    private var isRainy: Bool { item.chanceOfRain > 50 }

    private var dayText: String {
        item.date.formatted(.dateTime.weekday(.abbreviated))
    }

    private var barLeading: CGFloat {
        let range = CGFloat(globalMax - globalMin)
        guard range > 0 else { return 0 }
        return CGFloat(item.minTemperatureC - globalMin) / range
    }

    private var barFill: CGFloat {
        let range = CGFloat(globalMax - globalMin)
        guard range > 0 else { return 1 }
        return CGFloat(item.maxTemperatureC - item.minTemperatureC) / range
    }

    var body: some View {
        HStack(spacing: 0) {
            Text(dayText)
                .font(Typ.dayName)
                .foregroundStyle(Glass.valuePri)
                .frame(width: 28, alignment: .leading)
                .padding(.trailing, 6)

            Image(systemName: item.symbolName)
                .symbolRenderingMode(.multicolor)
                .font(.system(size: 13, weight: .light))
                .frame(width: 20, height: 16)
                .padding(.trailing, 8)

            Text("\(item.minTemperatureC)°")
                .font(Typ.dayTempMin)
                .foregroundStyle(Glass.labelTert)
                .monospacedDigit()
                .frame(width: 24, alignment: .trailing)
                .padding(.trailing, 5)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(Glass.barTrack)

                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(Glass.barGradient(rainy: isRainy))
                        .frame(width: max(4, geometry.size.width * barFill))
                        .offset(x: geometry.size.width * barLeading)
                }
            }
            .frame(height: 3)
            .padding(.trailing, 5)

            Text("\(item.maxTemperatureC)°")
                .font(Typ.dayTemp)
                .foregroundStyle(Glass.valuePri)
                .monospacedDigit()
                .frame(width: 24, alignment: .leading)
                .padding(.trailing, 6)

            if item.chanceOfRain > 0 {
                HStack(spacing: 2) {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 7, weight: .medium))
                        .foregroundStyle(Glass.rainBlue.opacity(0.8))
                    Text("\(item.chanceOfRain)%")
                        .font(Typ.dayRain)
                        .foregroundStyle(Glass.rainBlue)
                        .monospacedDigit()
                }
                .frame(width: 36, alignment: .trailing)
            } else {
                Text("–")
                    .font(Typ.dayRain)
                    .foregroundStyle(Glass.labelTert)
                    .frame(width: 36, alignment: .trailing)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(hovered ? Glass.rowHover : .clear)
        .onHover { hovered = $0 }
        .animation(.easeInOut(duration: 0.12), value: hovered)
    }
}

private struct FooterRow: View {
    let current: CurrentConditionsDetails
    let actual: Int

    private var delta: Int { actual - current.feelsLikeC }

    private var deltaText: String {
        switch delta {
        case 1...:
            return "\(delta)° colder than actual"
        case ..<0:
            return "\(abs(delta))° warmer than actual"
        default:
            return "Same as actual"
        }
    }

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            HStack(alignment: .center, spacing: 7) {
                Image(systemName: "thermometer.medium")
                    .font(.system(size: 16, weight: .light))
                    .foregroundStyle(Glass.labelSec)
                    .frame(width: 18)

                VStack(alignment: .leading, spacing: 0) {
                    Text("FEELS LIKE")
                        .font(Typ.feelsLbl)
                        .foregroundStyle(Glass.labelTert)
                        .kerning(0.6)

                    Text("\(current.feelsLikeC)°")
                        .font(Typ.feelsVal)
                        .foregroundStyle(Glass.valuePri)
                        .tracking(-1)
                        .monospacedDigit()

                    Text(deltaText)
                        .font(Typ.feelsDelta)
                        .foregroundStyle(Glass.feelsBlue.opacity(0.75))
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 10)

            VStack(alignment: .trailing, spacing: 7) {
                FooterStat(
                    symbol: "humidity",
                    label: "Humidity",
                    value: "\(current.humidityMin)–\(current.humidityMax)%"
                )
                FooterStat(
                    symbol: "gauge.with.needle",
                    label: "Pressure",
                    value: "\(current.pressureMMHg) mmHg"
                )
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 9)
        .padding(.bottom, 11)
    }
}

private struct FooterStat: View {
    let symbol: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: symbol)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(Glass.labelTert)

            VStack(alignment: .trailing, spacing: 0) {
                Text(label.uppercased())
                    .font(Typ.statLbl)
                    .foregroundStyle(Glass.labelTert)
                    .kerning(0.4)

                Text(value)
                    .font(Typ.statVal)
                    .foregroundStyle(Glass.labelSec)
                    .lineLimit(1)
                    .monospacedDigit()
            }
        }
    }
}

private struct InlineIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 2) {
            configuration.icon
                .font(.system(size: 9, weight: .medium))
            configuration.title
        }
    }
}
