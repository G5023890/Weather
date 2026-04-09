import CoreLocation
import Foundation
import WeatherCore

struct ResolvedWeatherLocation: Sendable, Equatable {
    let latitude: Double
    let longitude: Double
    let displayName: String
}

protocol WeatherLocationProviding: AnyObject, Sendable {
    func resolveCurrentLocation() async throws -> ResolvedWeatherLocation
}

enum WeatherLocationError: LocalizedError {
    case permissionDenied
    case locationUnavailable
    case geocodingUnavailable

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Location access is required to determine your city. Enable it in System Settings and try again."
        case .locationUnavailable:
            return "We could not determine your current location."
        case .geocodingUnavailable:
            return "We could not translate your location into a city name."
        }
    }
}

@MainActor
final class SystemWeatherLocationProvider: NSObject, WeatherLocationProviding, CLLocationManagerDelegate, @unchecked Sendable {
    private let locationManager: CLLocationManager
    private let geocoder = CLGeocoder()
    private var locationContinuation: CheckedContinuation<CLLocation, Error>?
    private var cachedLocation: ResolvedWeatherLocation?

    override init() {
        locationManager = CLLocationManager()
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.pausesLocationUpdatesAutomatically = true
    }

    func resolveCurrentLocation() async throws -> ResolvedWeatherLocation {
        if let cachedLocation {
            return cachedLocation
        }

        let location = try await requestLocation()
        let placemark = try await reverseGeocode(location)
        let displayName = LocationDisplayNameResolver.displayName(for: placemark.weatherLocationNameComponents)
            ?? placemark.name
            ?? "Current location"

        let resolvedLocation = ResolvedWeatherLocation(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            displayName: displayName
        )
        cachedLocation = resolvedLocation
        return resolvedLocation
    }

    private func requestLocation() async throws -> CLLocation {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<CLLocation, Error>) in
            locationContinuation = continuation
            requestLocationIfAuthorized()
        }
    }

    private func requestLocationIfAuthorized() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.requestLocation()
        case .denied, .restricted:
            failLocationRequest(with: WeatherLocationError.permissionDenied)
        @unknown default:
            failLocationRequest(with: WeatherLocationError.locationUnavailable)
        }
    }

    private func failLocationRequest(with error: Error) {
        guard let continuation = locationContinuation else {
            return
        }

        locationContinuation = nil
        continuation.resume(throwing: error)
    }

    private func reverseGeocode(_ location: CLLocation) async throws -> CLPlacemark {
        let placemarks = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[CLPlacemark], Error>) in
            geocoder.reverseGeocodeLocation(location) { placemarks, error in
                if error != nil {
                    continuation.resume(throwing: WeatherLocationError.geocodingUnavailable)
                    return
                }

                continuation.resume(returning: placemarks ?? [])
            }
        }

        guard let placemark = placemarks.first else {
            throw WeatherLocationError.geocodingUnavailable
        }

        return placemark
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.requestLocationIfAuthorized()
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            guard let location = locations.last else {
                self.failLocationRequest(with: WeatherLocationError.locationUnavailable)
                return
            }

            guard let continuation = self.locationContinuation else {
                return
            }

            self.locationContinuation = nil
            continuation.resume(returning: location)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            if let locationError = error as? CLError {
                switch locationError.code {
                case .denied:
                    self.failLocationRequest(with: WeatherLocationError.permissionDenied)
                default:
                    self.failLocationRequest(with: WeatherLocationError.locationUnavailable)
                }
                return
            }

            self.failLocationRequest(with: WeatherLocationError.locationUnavailable)
        }
    }
}
