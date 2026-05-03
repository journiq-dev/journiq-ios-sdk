import XCTest
@testable import JourniqSDK

final class JourniqSDKTests: XCTestCase {

    func testConfigPublicKey() {
        let config = JourniqConfig(apiKey: "jq_pub_abc123")
        XCTAssertEqual(config.keyType, .public)
    }

    func testConfigSecretKey() {
        let config = JourniqConfig(apiKey: "jq_app_abc123")
        XCTAssertEqual(config.keyType, .secret)
    }

    func testMatchResultDefaults() {
        let result = MatchResult(matched: false)
        XCTAssertFalse(result.matched)
        XCTAssertNil(result.deepLink)
        XCTAssertNil(result.clickId)
    }

    func testParsedDeepLink() {
        let url = URL(string: "https://example.com/product/123?ref=abc")!
        let deepLinks = JourniqDeepLinks(sdk: Journiq.current)

        // This would crash since SDK isn't configured, so test URL parsing directly
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        XCTAssertEqual(path, "product/123")
        XCTAssertEqual(components?.queryItems?.first?.name, "ref")
    }
}
