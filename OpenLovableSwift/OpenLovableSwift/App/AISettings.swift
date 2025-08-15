//
//  AISettings.swift
//  OpenLovableSwift
//
//  Created by Arya Mirsepasi on 12.08.25.
//

//  AISettings.swift

import Foundation

struct AISettings: Codable, Sendable {
  enum Backend: String, CaseIterable, Codable, Sendable {
    case openai, anthropic, openrouter, mistral
  }

  var backend: Backend

  // AIProxy protected mode (recommended in production)
  var partialKey: String
  var serviceURL: String

  // Direct provider keys (BYOK / local dev)
  var openAIKey: String
  var anthropicKey: String
  var openRouterKey: String
  var mistralKey: String

  // Model per backend
  var modelOpenAI: String
  var modelAnthropic: String
  var modelOpenRouter: String
  var modelMistral: String

  static let storageKey = "ai.settings.v1"

  static func `default`() -> AISettings {
    AISettings(
      backend: .openai,
      partialKey: "",
      serviceURL: "",
      openAIKey: "",
      anthropicKey: "",
      openRouterKey: "",
      mistralKey: "",
      modelOpenAI: "gpt-4o-mini",
      modelAnthropic: "claude-3-5-sonnet-20241022",
      modelOpenRouter: "google/gemini-2.0-flash-exp:free",
      modelMistral: "mistral-small-latest"
    )
  }

  static func load() -> AISettings {
    let d = UserDefaults.standard
    guard let data = d.data(forKey: storageKey) else { return .default() }
    return (try? JSONDecoder().decode(AISettings.self, from: data)) ?? .default()
  }

  func save() {
    let d = UserDefaults.standard
    guard let data = try? JSONEncoder().encode(self) else { return }
    d.set(data, forKey: AISettings.storageKey)
  }
}

extension String {
  var nilIfEmpty: String? {
    trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : self
  }
}
