//
//  ChatView.swift
//  OpenLovableSwift
//
//  Created by Arya Mirsepasi on 12.08.25.
//

import SwiftUI

struct ChatView: View {
  @Environment(AppState.self) private var app
  @Namespace private var bottomID

  var body: some View {
    // ✅ make the environment object bindable for `$` access
    @Bindable var app = app

    VStack(spacing: 0) {
      ScrollView {
        LazyVStack(alignment: .leading, spacing: 12) {
          ForEach(app.messages) { msg in
            MessageRow(message: msg)
              .padding(.horizontal)
          }
          Color.clear.frame(height: 1).id(bottomID)
        }
        .padding(.vertical, 8)
      }
      .background(.background)

      Divider()

      HStack(spacing: 8) {
        TextField("Ask Lovable to build or modify…", text: $app.draft, axis: .vertical)
          .textFieldStyle(.roundedBorder)
          .lineLimit(1...4)
          .font(.body.monospaced())

        Button {
          app.sendDraftMessage()
        } label: {
          if app.isSending { ProgressView().controlSize(.small) }
          else { Label("Send", systemImage: "paperplane.fill").labelStyle(.iconOnly) }
        }
        .keyboardShortcut(.return, modifiers: [.command])
        .buttonStyle(.borderedProminent)
        .disabled(app.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || app.isSending)
      }
      .padding(10)
      .background(.bar)
    }
  }
}
