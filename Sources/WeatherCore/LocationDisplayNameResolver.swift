import CoreLocation
import Foundation

public struct LocationNameComponents: Sendable, Equatable {
    public let locality: String?
    public let subLocality: String?
    public let administrativeArea: String?
    public let country: String?

    public init(
        locality: String? = nil,
        subLocality: String? = nil,
        administrativeArea: String? = nil,
        country: String? = nil
    ) {
        self.locality = locality
        self.subLocality = subLocality
        self.administrativeArea = administrativeArea
        self.country = country
    }
}

public enum LocationDisplayNameResolver {
    public static func displayName(for components: LocationNameComponents) -> String? {
        [
            components.locality,
            components.subLocality,
            components.administrativeArea,
            components.country
        ]
        .compactMap { value in
            value?.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        .first(where: { !$0.isEmpty })
    }
}

public extension CLPlacemark {
    var weatherLocationNameComponents: LocationNameComponents {
        LocationNameComponents(
            locality: locality,
            subLocality: subLocality,
            administrativeArea: administrativeArea,
            country: country
        )
    }
}
