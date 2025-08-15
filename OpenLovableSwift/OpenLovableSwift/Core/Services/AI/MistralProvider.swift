//
//  MistralProvider.swift
//  OpenLovableSwift
//
//  Created by Arya Mirsepasi on 12.08.25.
//

import Foundation
import AIProxy

public struct MistralProvider: AIProvider {
  public struct Config: Sendable {
    public var model: String
    public var partialKey: String?
    public var serviceURL: String?
    public var unprotectedAPIKey: String?

    public init(
      model: String,
      partialKey: String? = nil,
      serviceURL: String? = nil,
      unprotectedAPIKey: String? = nil
    ) {
      self.model = model
      self.partialKey = partialKey
      self.serviceURL = serviceURL
      self.unprotectedAPIKey = unprotectedAPIKey
    }
  }

  enum ProviderError: Error { case missingCredentials }

  private let config: Config

  public init(config: Config) {
    self.config = config
  }

  public func stream(
    messages: [AIMessage]
  ) -> AsyncThrowingStream<String, Error> {
    AsyncThrowingStream { continuation in
      Task {
        do {
          let service = try makeService()

          let msgs: [MistralChatCompletionRequestBody.Message] =
            messages.map { m in
              switch m.role {
              case .user: return .user(content: m.content)
              case .assistant: return .assistant(content: m.content)
              case .system:
                // Send system as a user instruction for simplicity
                return .user(content: m.content)
              }
            }

          let body = MistralChatCompletionRequestBody(
            messages: msgs,
            model: config.model
          )

          let stream = try await service.streamingChatCompletionRequest(
            body: body, secondsToWait: 60
          )
          for try await chunk in stream {
            if let t = chunk.choices.first?.delta.content, !t.isEmpty {
              continuation.yield(t)
            }
          }
          continuation.finish()
        } catch {
          continuation.finish(throwing: error)
        }
      }
    }
  }

  private func makeService() throws -> any MistralService {
    if let p = config.partialKey, let u = config.serviceURL {
      return AIProxy.mistralService(partialKey: p, serviceURL: u)
    }
    if let k = config.unprotectedAPIKey {
      return AIProxy.mistralDirectService(unprotectedAPIKey: k)
    }
    throw ProviderError.missingCredentials
  }
}
