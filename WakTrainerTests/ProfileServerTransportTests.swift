import Foundation
import Testing
import WakTrainerCoreModels
@testable import WakTrainer

private final class ProfileURLProtocol: URLProtocol, @unchecked Sendable {
    static let lock = NSLock()
    static var responseCode = 200
    static var responseData = Data()
    static var lastRequest: URLRequest?

    static func configure(code: Int, data: Data) {
        lock.lock()
        responseCode = code
        responseData = data
        lastRequest = nil
        lock.unlock()
    }

    static func capturedRequest() -> URLRequest? {
        lock.lock()
        defer { lock.unlock() }
        return lastRequest
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        Self.lock.lock()
        Self.lastRequest = request
        let code = Self.responseCode
        let data = Self.responseData
        Self.lock.unlock()
        client?.urlProtocol(self, didReceive: HTTPURLResponse(url: request.url!, statusCode: code, httpVersion: nil, headerFields: nil)!, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}

@Suite("Profile server transport", .serialized)
struct ProfileServerTransportTests {
    private func makeTransport(owner: UUID, tokenOwner: UUID?) -> ProfileServerTransport {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [ProfileURLProtocol.self]
        return ProfileServerTransport(
            baseURL: URL(string: "https://example.test/")!,
            ownerUserID: owner,
            session: URLSession(configuration: config),
            accessToken: { tokenOwner.map { ($0, "test-token") } }
        )
    }

    @Test("Successful fetch decodes the server profile and carries bearer token")
    func success() async throws {
        ProfileURLProtocol.configure(code: 200, data: Data(#"{"gender":"남성","birthDate":"2005-10-24","heightCm":175,"weightKg":70}"#.utf8))
        let user = UUID()
        let profile = try #require(try await makeTransport(owner: user, tokenOwner: user).fetchProfile())
        #expect(profile.gender == .male)
        #expect(profile.heightCm == 175)
        let request = ProfileURLProtocol.capturedRequest()
        #expect(request?.value(forHTTPHeaderField: "Authorization") == "Bearer test-token")
        #expect(request?.url?.path == "/v1/profile")
    }

    @Test("Missing profile does not invent local data")
    func notFound() async throws {
        ProfileURLProtocol.configure(code: 404, data: Data())
        let user = UUID()
        #expect(try await makeTransport(owner: user, tokenOwner: user).fetchProfile() == nil)
    }

    @Test("Mismatched identity is rejected without sending a request")
    func identityMismatch() async {
        ProfileURLProtocol.configure(code: 200, data: Data())
        await #expect(throws: ProfileServerError.self) {
            _ = try await makeTransport(owner: UUID(), tokenOwner: UUID()).fetchProfile()
        }
        let request = ProfileURLProtocol.capturedRequest()
        #expect(request == nil)
    }

    @Test("Remote writes stay disabled")
    func noWrites() async {
        let user = UUID()
        await #expect(throws: ProfileServerError.self) {
            try await makeTransport(owner: user, tokenOwner: user).saveProfile(
                UserProfile(gender: .male, birthDate: Date(), heightCm: 175, weightKg: 70)
            )
        }
    }
}
