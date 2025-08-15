//
//  OpenRouterProvider.swift
//  OpenLovableSwift
//
//  Created by Arya Mirsepasi on 12.08.25.
//

import Foundation
import AIProxy

public struct OpenRouterProvider: AIProvider {
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

          let body = OpenRouterChatCompletionRequestBody(
            messages: messages.map {
              switch $0.role {
              case .system: return .system(content: .text($0.content))
              case .user: return .user(content: .text($0.content))
              case .assistant: return .assistant(content: .text($0.content))
              }
            },
            models: [config.model],
            route: .fallback
          )

          let stream = try await service.streamingChatCompletionRequest(
            body: body
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

  private func makeService() throws -> any OpenRouterService {
    if let p = config.partialKey, let u = config.serviceURL {
      return AIProxy.openRouterService(partialKey: p, serviceURL: u)
    }
    if let k = config.unprotectedAPIKey {
      return AIProxy.openRouterDirectService(unprotectedAPIKey: k)
    }
    throw ProviderError.missingCredentials
  }
}
