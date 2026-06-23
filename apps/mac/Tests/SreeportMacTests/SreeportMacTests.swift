import XCTest

final class SreeportMacTests: XCTestCase {
    func testSmoke() {
        XCTAssertEqual("Sreeport".lowercased(), "sreeport")
    }
}
