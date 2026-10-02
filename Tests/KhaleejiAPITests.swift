import XCTest
@testable import KhaleejiAPI

final class KhaleejiAPITests: XCTestCase {
    func testDefaultConfigurationUsesProductionApiAndBoundedRetries() {
        let config = KhaleejiAPIConfig(apiKey: "test-key")
        XCTAssertEqual(config.baseURL, "https://khaleejiapi.dev/api/v1")
        XCTAssertEqual(config.timeout, 30)
        XCTAssertEqual(config.maxRetries, 2)
    }
}