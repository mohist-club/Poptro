import Combine
import Foundation
import SwiftUI
import Translation

@available(macOS 15.0, *)
final class AppleTranslationService: ObservableObject {
    static let shared = AppleTranslationService()

    struct Request {
        let id = UUID()
        let text: String
        let targetLanguageCode: String
        let mode: AppleTranslationMode
        let onToken: (String) -> Void
        let onComplete: (Error?) -> Void
    }

    @Published fileprivate var pendingRequest: Request?
    private var claimedRequestID: UUID?

    private init() {}

    func translate(
        text: String,
        targetLanguageCode: String,
        mode: AppleTranslationMode,
        onToken: @escaping (String) -> Void,
        onComplete: @escaping (Error?) -> Void
    ) {
        guard mode != .highFidelity || AppleTranslationSupport.supportsTranslationStrategies else {
            onComplete(Self.error("Apple 高质量翻译需要 macOS 26.4 或更高版本。"))
            return
        }

        let request = Request(
            text: text,
            targetLanguageCode: targetLanguageCode,
            mode: mode,
            onToken: onToken,
            onComplete: onComplete
        )
        DispatchQueue.main.async { [weak self] in
            self?.claimedRequestID = nil
            self?.pendingRequest = request
        }
    }

    @MainActor
    fileprivate func perform(using session: TranslationSession) async {
        guard let request = pendingRequest,
              claimedRequestID != request.id else { return }
        claimedRequestID = request.id

        do {
            let response = try await session.translate(request.text)
            guard pendingRequest?.id == request.id else { return }
            request.onToken(response.targetText)
            request.onComplete(nil)
            pendingRequest = nil
            claimedRequestID = nil
        } catch {
            guard pendingRequest?.id == request.id else { return }
            request.onComplete(error)
            pendingRequest = nil
            claimedRequestID = nil
        }
    }

    fileprivate static func targetLanguage(for code: String) -> Locale.Language {
        let identifier: String
        switch code.uppercased() {
        case "ZH": identifier = "zh-Hans"
        case "EN-US": identifier = "en-US"
        case "EN-GB": identifier = "en-GB"
        case "PT-BR": identifier = "pt-BR"
        case "PT-PT": identifier = "pt-PT"
        default: identifier = code.replacingOccurrences(of: "_", with: "-").lowercased()
        }
        return Locale.Language(identifier: identifier)
    }

    private static func error(_ message: String) -> NSError {
        NSError(
            domain: "Poptro.AppleTranslation",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: message]
        )
    }
}

/// Apple 要求 TranslationSession 由 SwiftUI `translationTask` 提供，才能在缺少
/// 语言模型时展示系统下载授权。浮窗和设置页各挂载一个无界面桥接，
/// 服务层会对每个 request ID 只领取一次，避免重复翻译。
@available(macOS 15.0, *)
struct AppleTranslationBridgeView: View {
    @ObservedObject private var service = AppleTranslationService.shared
    @State private var configuration: TranslationSession.Configuration?

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .accessibilityHidden(true)
            .onReceive(service.$pendingRequest) { request in
                guard let request else { return }
                configuration = nil
                DispatchQueue.main.async {
                    guard service.pendingRequest?.id == request.id else { return }
                    configuration = makeConfiguration(for: request)
                }
            }
            .translationTask(configuration) { session in
                await service.perform(using: session)
            }
    }

    private func makeConfiguration(
        for request: AppleTranslationService.Request
    ) -> TranslationSession.Configuration {
        let target = AppleTranslationService.targetLanguage(for: request.targetLanguageCode)
        if #available(macOS 26.4, *) {
            let strategy: TranslationSession.Strategy = request.mode == .highFidelity
                ? .highFidelity
                : .lowLatency
            return TranslationSession.Configuration(
                source: nil,
                target: target,
                preferredStrategy: strategy
            )
        }
        return TranslationSession.Configuration(source: nil, target: target)
    }
}

struct AppleTranslationBridgeContainer: View {
    @ViewBuilder
    var body: some View {
        if #available(macOS 15.0, *) {
            AppleTranslationBridgeView()
        }
    }
}
