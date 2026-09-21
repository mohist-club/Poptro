import Foundation

enum AppleTranslationSupport {
    static var isAvailable: Bool {
        if #available(macOS 15.0, *) { return true }
        return false
    }

    static var supportsTranslationStrategies: Bool {
        if #available(macOS 26.4, *) { return true }
        return false
    }
}
