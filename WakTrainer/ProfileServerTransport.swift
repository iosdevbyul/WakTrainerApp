import AuthenticationKit
import Foundation
import UserProfileFeature
import WakTrainerCoreModels

/// WakTrainerServer /v1/profile adapter. Read-only until migration and conflict rules are defined.
struct ProfileServerTransport: UserProfileRemoteTransport {
    let baseURL: URL
    let ownerUserID: UUID

    func fetchProfile() async throws -> UserProfile? {
        guard let session = await MainActor.run(body: { AuthenticationService.shared.currentSession }),
              UUID(uuidString: session.user.id) == ownerUserID else {
            throw ProfileServerError.authenticationRequired
        }

        let url = baseURL.appending(path: "v1/profile")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 10

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw ProfileServerError.invalidResponse
        }
        switch http.statusCode {
        case 200:
            let payload = try JSONDecoder().decode(ProfileServerPayload.self, from: data)
            return try payload.profile
        case 404:
            return nil
        case 401, 403:
            throw ProfileServerError.authenticationRequired
        default:
            throw ProfileServerError.serverStatus(http.statusCode)
        }
    }

    func saveProfile(_ profile: UserProfile) async throws {
        // No server writes until data migration and conflict handling are implemented.
        throw ProfileServerError.writeNotEnabled
    }
}

private struct ProfileServerPayload: Decodable {
    let gender: String
    let birthDate: String
    let heightCm: Double
    let weightKg: Double

    var profile: UserProfile {
        get throws {
            guard let gender = UserProfile.Gender(rawValue: gender),
                  let birthDate = Self.dateFormatter.date(from: birthDate),
                  heightCm.isFinite, weightKg.isFinite else {
                throw ProfileServerError.invalidResponse
            }
            return UserProfile(
                gender: gender, birthDate: birthDate,
                heightCm: heightCm, weightKg: weightKg
            )
        }
    }

    private static var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)!
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.isLenient = false
        return formatter
    }
}

enum ProfileServerError: Error {
    case authenticationRequired
    case invalidResponse
    case serverStatus(Int)
    case writeNotEnabled
}
