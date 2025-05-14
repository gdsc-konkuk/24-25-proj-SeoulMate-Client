import Foundation
import Combine

protocol ChatServiceProtocol {
    func sendMessage(placeId: String, chatType: ChatType, text: String) async throws -> ChatResponseModel
}

final class ChatService: ChatServiceProtocol {
    private let networkProvider: NetworkProviderProtocol
    
    init(networkProvider: NetworkProviderProtocol) {
        self.networkProvider = networkProvider
    }
    
    func sendMessage(placeId: String, chatType: ChatType, text: String) async throws -> ChatResponseModel {
        let endpoint = ChatEndpoint.sendMessage(placeId: placeId, chatType: chatType, text: text)
        return try await withCheckedThrowingContinuation { continuation in
            networkProvider.request(endpoint)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            continuation.resume(throwing: error)
                        }
                    },
                    receiveValue: { (response: ChatResponseModel) in
                        continuation.resume(returning: response)
                    }
                )
                .store(in: &cancellables)
        }
    }
    
    private var cancellables = Set<AnyCancellable>()
} 