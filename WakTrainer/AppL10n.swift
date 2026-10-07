import Foundation

enum AppL10n {
    static let bundle =
        Bundle(
            for:
                AppLocalizationBundleToken.self
        )

    static var locale: Locale {
        let identifier =
            bundle.preferredLocalizations.first
            ?? "en"

        return Locale(
            identifier: identifier
        )
    }

    static func string(
        _ key: String
    ) -> String {
        NSLocalizedString(
            key,
            bundle: bundle,
            comment: ""
        )
    }

    static func format(
        _ key: String,
        _ arguments: CVarArg...
    ) -> String {
        String(
            format: string(key),
            locale: locale,
            arguments: arguments
        )
    }

    static func date(
        _ date: Date,
        dateStyle: DateFormatter.Style,
        timeStyle: DateFormatter.Style = .none
    ) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = .autoupdatingCurrent
        formatter.dateStyle = dateStyle
        formatter.timeStyle = timeStyle

        return formatter.string(
            from: date
        )
    }
}

private final class AppLocalizationBundleToken {}
