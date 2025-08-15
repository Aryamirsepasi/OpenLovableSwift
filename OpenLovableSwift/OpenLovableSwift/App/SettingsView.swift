//
//  SettingsView.swift
//  OpenLovableSwift
//
//  Created by Arya Mirsepasi on 12.08.25.
//

//  SettingsView.swift

import SwiftUI

struct SettingsView: View {
  @Environment(AppState.self) private var app

  @State private var working: AISettings = .load()
  @State private var savedBanner: String? = nil

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
    Text("AI Settings").font(.title2).bold()

      Picker("Provider", selection: $working.backend) {
        ForEach(AISettings.Backend.allCases, id: \.self) { b in
          Text(b.label).tag(b)
        }
      }
      .pickerStyle(.segmented)

      GroupBox("Model") {
        switch working.backend {
        case .openai:
          TextField("Model", text: $working.modelOpenAI)
        case .anthropic:
          TextField("Model", text: $working.modelAnthropic)
        case .openrouter:
          TextField("Model (e.g. google/gemini-2.0-flash-exp:free)",
                    text: $working.modelOpenRouter)
        case .mistral:
          TextField("Model (e.g. mistral-small-latest)",
                    text: $working.modelMistral)
        }
      }

      GroupBox("Credentials") {
        VStack(alignment: .leading, spacing: 10) {
          Text("Recommended: Use AIProxy partial key + service URL")
            .font(.caption)
            .foregroundStyle(.secondary)

          HStack {
            Text("Partial Key")
            SecureField("AIPROXY partial key", text: $working.partialKey)
          }
          HStack {
            Text("Service URL")
              TextField("https://api.aiproxy.dev/v1", text: $working.serviceURL)
                .disableAutocorrection(true)
          }

          Divider().padding(.vertical, 6)

          Text("Direct keys (optional, dev/BYOK)")
            .font(.caption)
            .foregroundStyle(.secondary)

          switch working.backend {
          case .openai:
            HStack {
              Text("OpenAI Key")
              SecureField("sk-...", text: $working.openAIKey)
            }
          case .anthropic:
            HStack {
              Text("Anthropic Key")
              SecureField("sk-ant-...", text: $working.anthropicKey)
            }
          case .openrouter:
            HStack {
              Text("OpenRouter Key")
              SecureField("or-...", text: $working.openRouterKey)
            }
          case .mistral:
            HStack {
              Text("Mistral Key")
              SecureField("mistral-...", text: $working.mistralKey)
            }
          }
        }
      }

      HStack {
        if let msg = savedBanner {
          Text(msg)
            .foregroundStyle(.green)
        } else {
          Spacer()
        }
        Spacer()
        Button("Restore Defaults") {
          working = .default()
        }
        Button("Save") {
          working.save()
          app.settings = working
          app.rebuildProvider()
          savedBanner = "Saved"
          DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            savedBanner = nil
          }
        }
        .buttonStyle(.borderedProminent)
      }
    }
    .padding(20)
    .onAppear { working = app.settings }
  }
}

private extension AISettings.Backend {
  var label: String {
    switch self {
    case .openai: return "OpenAI"
    case .anthropic: return "Anthropic"
    case .openrouter: return "OpenRouter"
    case .mistral: return "Mistral"
    }
  }
}
