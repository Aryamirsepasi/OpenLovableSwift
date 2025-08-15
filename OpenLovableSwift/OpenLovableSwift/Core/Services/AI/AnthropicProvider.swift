//
//  AnthropicProvider.swift
//  OpenLovableSwift
//
//  Created by Arya Mirsepasi on 12.08.25.
//

import Foundation
import AIProxy

public struct AnthropicProvider: AIProvider {
  public struct Config: Sendable {
    public var model: String
    public var partialKey: String?
    public var serviceURL: String?
    public var unprotectedAPIKey: String?
    public var maxTokens: Int

    public init(
      model: String,
      partialKey: String? = nil,
      serviceURL: String? = nil,
      unprotectedAPIKey: String? = nil,
      maxTokens: Int = 2048
    ) {
      self.model = model
      self.partialKey = partialKey
      self.serviceURL = serviceURL
      self.unprotectedAPIKey = unprotectedAPIKey
      self.maxTokens = maxTokens
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

          var input: [AnthropicInputMessage] = []
          for m in messages {
            switch m.role {
            case .user:
              input.append(.init(content: [.text(m.content)], role: .user))
            case .assistant:
              input.append(.init(content: [.text(m.content)], role: .assistant))
            case .system:
              // Simple approach: include system as first user instruction
              input.insert(
                .init(content: [.text(m.content)], role: .user),
                at: 0
              )
            }
          }

          let body = AnthropicMessageRequestBody(
            maxTokens: config.maxTokens,
            messages: input,
            model: config.model
          )

          let stream = try await service.streamingMessageRequest(body: body)
          for try await chunk in stream {
            switch chunk {
            case .text(let text):
              if !text.isEmpty { continuation.yield(text) }
            case .toolUse:
              break
            }
          }
          continuation.finish()
        } catch {
          continuation.finish(throwing: error)
        }
      }
    }
  }

  private func makeService() throws -> any AnthropicService {
    if let p = config.partialKey, let u = config.serviceURL {
      return AIProxy.anthropicService(partialKey: p, serviceURL: u)
    }
    if let k = config.unprotectedAPIKey {
      return AIProxy.anthropicDirectService(unprotectedAPIKey: k)
    }
    throw ProviderError.missingCredentials
  }
}
