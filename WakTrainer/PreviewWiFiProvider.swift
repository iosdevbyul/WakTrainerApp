import TrisPlaceRecognitionKit

/// Keeps the personal-team preview independent of Wi-Fi network access.
struct PreviewWiFiProvider: WiFiProviding {
    func currentNetwork() async -> WiFiNetwork? {
        nil
    }
}
