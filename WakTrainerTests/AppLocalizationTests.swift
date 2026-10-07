import XCTest
@testable import WakTrainer

final class AppLocalizationTests:
    XCTestCase {

    func testEnglishAndKoreanLocalizationsExist() throws {
        for language in ["en", "ko"] {
            let path = try XCTUnwrap(
                AppL10n.bundle.path(
                    forResource: language,
                    ofType: "lproj"
                )
            )

            let bundle = try XCTUnwrap(
                Bundle(path: path)
            )

            XCTAssertNotEqual(
                bundle.localizedString(
                    forKey: "home.title",
                    value: nil,
                    table: nil
                ),
                "home.title"
            )
        }
    }
}
