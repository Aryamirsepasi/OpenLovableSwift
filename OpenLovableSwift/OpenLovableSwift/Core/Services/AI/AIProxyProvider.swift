//
//  AIProxyProvider.swift
//  OpenLovableSwift
//
//  Created by Arya Mirsepasi on 12.08.25.
//

import Foundation

#if canImport(AIProxy)
import AIProxy
#endif

/// Configure this with your AI Proxy endpoint + API key (OpenAI-compatible).
struct AIProxyConfig: Sendable {
  var baseURL: URL = URL(string: "https://api.aiproxy.dev/v1")! // example
  var apiKey: String = (ProcessInfo.processInfo.environment["AIPROXY_API_KEY"] ?? "")
  var model: String = "gpt-4o-mini" // choose your default
}

/// Uses AIProxySwift if available; otherwise falls back to OpenAI-compatible SSE.
final class AIProxyProvider: AIProvider {
  private let config: AIProxyConfig
  init(config: AIProxyConfig = .init()) { self.config = config }

  func stream(messages: [AIMessage]) -> AsyncThrowingStream<String, Error> {
    AsyncThrowingStream { continuation in
      Task {
        do {
          var req = URLRequest(url: config.baseURL.appendingPathComponent("chat/completions"))
          req.httpMethod = "POST"
          req.addValue("application/json", forHTTPHeaderField: "Content-Type")
          req.addValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")

          let body: [String: Any] = [
            "model": config.model,
            "stream": true,
            "messages": messages.map { ["role": $0.role.rawValue, "content": $0.content] }
          ]
          req.httpBody = try JSONSerialization.data(withJSONObject: body)

          let (bytes, response) = try await URLSession.shared.bytes(for: req)
          guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
          }

          for try await line in bytes.lines {
            guard line.hasPrefix("data: ") else { continue }
            let payload = String(line.dropFirst(6))
            if payload == "[DONE]" {
              continuation.finish()
              break
            }
            if let delta = Self.parseDeltaText(payload) {
              continuation.yield(delta)
            }
          }

          continuation.finish()
        } catch {
          continuation.finish(throwing: error)
        }
      }
    }
  }

  private static func parseDeltaText(_ jsonLine: String) -> String? {
    guard let data = jsonLine.data(using: .utf8),
          let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let choices = obj["choices"] as? [[String: Any]],
          let delta = choices.first?["delta"] as? [String: Any],
          let content = delta["content"] as? String
    else { return nil }
    return content
  }
}
