import XCTest
@testable import WeatherCore

final class LocationDisplayNameResolverTests: XCTestCase {
    func testPrefersLocalityOverOtherCandidates() {
        let name = LocationDisplayNameResolver.displayName(
            for: LocationNameComponents(
                locality: "Petah Tikva",
                subLocality: "Ramat Sivan",
                administrativeArea: "Central District",
                country: "Israel"
            )
        )

        XCTAssertEqual(name, "Petah Tikva")
    }

    func testFallsBackToSubLocalityThenAdministrativeArea() {
        let subLocalityName = LocationDisplayNameResolver.displayName(
            for: LocationNameComponents(
                locality: nil,
                subLocality: "White City",
                administrativeArea: "Tel Aviv District",
                country: "Israel"
            )
        )

        let areaName = LocationDisplayNameResolver.displayName(
            for: LocationNameComponents(
                locality: nil,
                subLocality: nil,
                administrativeArea: "Haifa District",
                country: "Israel"
            )
        )

        XCTAssertEqual(subLocalityName, "White City")
        XCTAssertEqual(areaName, "Haifa District")
    }
}
