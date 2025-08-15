//
//  CodeEditorView.swift
//  OpenLovableSwift
//
//  Created by Arya Mirsepasi on 12.08.25.
//

import SwiftUI

struct CodeEditorView: View {
  @Binding var text: String
  var fileName: String?

  var body: some View {
    VStack(spacing: 0) {
      HStack {
        Text(fileName ?? "—")
          .font(.subheadline)
          .foregroundStyle(.secondary)
        Spacer()
      }
      .padding(.horizontal, 10)
      .padding(.vertical, 6)
      .background(.bar)

      TextEditor(text: $text)
        .font(.system(.body, design: .monospaced))
        .textSelection(.enabled)
        .scrollContentBackground(.hidden)
        .background(Color(nsColor: .textBackgroundColor))
    }
    .clipShape(RoundedRectangle(cornerRadius: 8))
    .padding(6)
  }
}
