import UIKit
import XCTest

final class LiveActivityBrandingTests: XCTestCase {
    func testLogoResolvesFromEmbeddedWidgetInEveryAppearanceAndScale() throws {
        let plugins = try XCTUnwrap(Bundle.main.builtInPlugInsURL)
        let widgetURL = try XCTUnwrap(
            try FileManager.default.contentsOfDirectory(at: plugins, includingPropertiesForKeys: nil)
                .first { $0.pathExtension == "appex" && $0.lastPathComponent.contains("Widget") }
        )
        let widget = try XCTUnwrap(Bundle(url: widgetURL))
        XCTAssertNotEqual(widget.bundleIdentifier, Bundle.main.bundleIdentifier)

        for style in [UIUserInterfaceStyle.light, .dark] {
            for scale in [CGFloat(1), 2, 3] {
                let traits = UITraitCollection { traits in
                    traits.userInterfaceStyle = style
                    traits.displayScale = scale
                }
                let logo = try XCTUnwrap(UIImage(named: "WakTrainerAppLogo", in: widget, compatibleWith: traits))
                // ActivityKit constrains the source size, not just the SwiftUI frame.
                XCTAssertEqual(logo.size.width, 24, accuracy: 0.01)
                XCTAssertEqual(logo.size.height, 24, accuracy: 0.01)
                XCTAssertLessThanOrEqual(try XCTUnwrap(logo.cgImage).width, 72)
                XCTAssertEqual(logo.renderingMode, .alwaysOriginal)
            }
        }
    }
}
