import Foundation

public enum ConditionSymbolMapper {
    public static func symbolName(for openWeatherID: Int, iconCode: String) -> String {
        let isDay = iconCode.hasSuffix("d")

        switch openWeatherID {
        case 800:
            return isDay ? "sun.max.fill" : "moon.stars.fill"
        case 801, 802:
            return isDay ? "cloud.sun.fill" : "cloud.moon.fill"
        case 803, 804:
            return "cloud.fill"
        case 701, 711, 721, 731, 741, 751, 761, 762:
            return "cloud.fog.fill"
        case 300 ... 321, 500, 501, 520, 521, 531:
            return isDay ? "cloud.sun.rain.fill" : "cloud.moon.rain.fill"
        case 502 ... 504, 511, 522:
            return "cloud.rain.fill"
        case 600 ... 622:
            return "cloud.snow.fill"
        case 200 ... 232:
            return "cloud.bolt.rain.fill"
        case 771, 781:
            return "wind"
        default:
            return isDay ? "cloud.sun.fill" : "cloud.moon.fill"
        }
    }
}
